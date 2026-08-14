# QA end-to-end de My Path para los 5 tracks.
#
# Se loguea con cada cuenta QA y lee el catálogo por la misma API REST que usa
# la app, con la misma key pública. Nada de service-role: si RLS bloquea algo,
# esto lo siente igual que la usuaria.
#
# REQUISITO: correr antes supabase/tests/fixture_cuentas_qa.sql, que crea las
# 5 cuentas (una por track).
#
# CÓMO CORRERLO
#   pwsh supabase/tests/qa_paths.ps1
#
# Sale con código 1 y una tabla de fallas si algo no cumple. Es idempotente: el
# progreso se escribe con upsert, así que correrlo N veces da el mismo estado.
#
# QUÉ CUBRE QUE LOS TESTS DE FLUTTER NO PUEDEN
#   Los 154 tests unitarios corren contra dobles de los repositorios: nunca ven
#   PostgREST, ni RLS, ni el contenido real de la base. Esto sí. En particular
#   el CU6 ejercita el upsert con on_conflict —el replay de un lab— que contra
#   un doble pasa siempre y contra la base real devolvía 409 sin ese parámetro.

$ErrorActionPreference = 'Stop'
$U = 'https://dtvfucqamakudgbwuhbw.supabase.co'
$APIKEY = 'sb_publishable_bAzEua7Wl02VoNofOuI7_g_iSXKUIwv'

$accounts = @(
  @{ email = 'qa.frontend@aspire.dev'; track = 'frontend' }
  @{ email = 'qa.backend@aspire.dev';  track = 'backend' }
  @{ email = 'qa.infra@aspire.dev';    track = 'infrastructure' }
  @{ email = 'qa.uiux@aspire.dev';     track = 'uiux' }
  @{ email = 'qa.pm@aspire.dev';       track = 'project_management' }
)
$PASS = 'QaAspire2026!'

$fails = New-Object System.Collections.ArrayList
$summary = New-Object System.Collections.ArrayList

function Fail($track, $case, $detail) {
  [void]$fails.Add([pscustomobject]@{ track = $track; case = $case; detail = $detail })
}

function Rest($token, $path) {
  return Invoke-RestMethod -Method Get -Uri "$U/rest/v1/$path" -Headers @{
    apikey        = $APIKEY
    Authorization = "Bearer $token"
  }
}

foreach ($acct in $accounts) {
  $tr = $acct.track
  Write-Host "`n=== $tr ($($acct.email)) ===" -ForegroundColor Cyan

  # --- CU1: login real -----------------------------------------------------
  try {
    $auth = Invoke-RestMethod -Method Post `
      -Uri "$U/auth/v1/token?grant_type=password" `
      -Headers @{ apikey = $APIKEY } -ContentType 'application/json' `
      -Body (@{ email = $acct.email; password = $PASS } | ConvertTo-Json)
    $token = $auth.access_token
    $uid = $auth.user.id
    Write-Host "  CU1 login: OK"
  } catch {
    Fail $tr 'CU1 login' $_.Exception.Message
    Write-Host "  CU1 login: FALLA" -ForegroundColor Red
    continue
  }

  # --- CU2: el perfil trae su track ---------------------------------------
  $prof = Rest $token "profiles?select=track_id,display_name,experience_level,learning_goal,onboarding_completed_at"
  if ($prof.Count -ne 1) { Fail $tr 'CU2 perfil' "devolvio $($prof.Count) filas (RLS deberia dar 1)" }
  if ($prof[0].track_id -ne $tr) { Fail $tr 'CU2 perfil' "track_id=$($prof[0].track_id), esperaba $tr" }
  if (-not $prof[0].onboarding_completed_at) { Fail $tr 'CU2 perfil' 'onboarding incompleto: el guard mandaria al cuestionario' }
  Write-Host "  CU2 perfil trae su track: OK"

  # --- CU3: estructura del path -------------------------------------------
  $topics = Rest $token "topics?track_id=eq.$tr&select=id,parent_id,title,description,sort_order&order=sort_order"
  $levels = @($topics | Where-Object { -not $_.parent_id })
  $leaves = @($topics | Where-Object { $_.parent_id })

  if ($levels.Count -ne 3) { Fail $tr 'CU3 estructura' "$($levels.Count) niveles, esperaba 3" }
  $lvlOrder = ($levels | Sort-Object sort_order | ForEach-Object { $_.sort_order }) -join ','
  if ($lvlOrder -ne '1,2,3') { Fail $tr 'CU3 estructura' "sort_order de niveles: $lvlOrder" }

  foreach ($lv in $levels) {
    $kids = @($leaves | Where-Object { $_.parent_id -eq $lv.id } | Sort-Object sort_order)
    if ($kids.Count -ne 5) { Fail $tr 'CU3 estructura' "nivel '$($lv.title)' tiene $($kids.Count) secciones, esperaba 5" }
    $ord = ($kids | ForEach-Object { $_.sort_order }) -join ','
    if ($ord -ne '1,2,3,4,5') { Fail $tr 'CU3 estructura' "nivel '$($lv.title)' sort_order: $ord" }
    if (-not $lv.description) { Fail $tr 'CU3 estructura' "nivel '$($lv.title)' sin descripcion" }
  }
  $lvlNames = ($levels | Sort-Object sort_order | ForEach-Object { $_.title }) -join ' > '
  Write-Host "  CU3 estructura ($lvlNames): $($levels.Count) niveles / $($leaves.Count) secciones"

  # --- CU4: retos resolubles ----------------------------------------------
  $ids = ($leaves | ForEach-Object { $_.id }) -join ','
  $ch = Rest $token "lab_challenges?topic_id=in.($ids)&select=id,topic_id,challenge_type,question,content,sort_order&order=sort_order"
  $byTopic = @{}
  foreach ($c in $ch) {
    if (-not $byTopic.ContainsKey($c.topic_id)) { $byTopic[$c.topic_id] = New-Object System.Collections.ArrayList }
    [void]$byTopic[$c.topic_id].Add($c)
  }

  $theoryCount = 0
  foreach ($c in $ch) {
    $q = $c.question
    $ct = $c.content
    switch ($c.challenge_type) {
      'theory' {
        $theoryCount++
        if (-not $ct.blocks -or @($ct.blocks).Count -eq 0) { Fail $tr 'CU4 retos' "theory sin blocks: '$q'" }
        foreach ($b in @($ct.blocks)) {
          if ($b.type -notin @('paragraph', 'code', 'list')) { Fail $tr 'CU4 retos' "bloque desconocido '$($b.type)' en '$q'" }
          if ($b.type -eq 'list' -and @($b.items).Count -eq 0) { Fail $tr 'CU4 retos' "list sin items en '$q'" }
          if ($b.type -ne 'list' -and -not $b.text) { Fail $tr 'CU4 retos' "$($b.type) sin text en '$q'" }
        }
        if (-not $ct.keyTakeaway) { Fail $tr 'CU4 retos' "theory sin keyTakeaway: '$q'" }
      }
      'multiple_choice' {
        $opts = $ct.options.PSObject.Properties.Name
        if ($opts.Count -lt 2) { Fail $tr 'CU4 retos' "mc con $($opts.Count) opciones: '$q'" }
        if ($ct.correctOptionId -notin $opts) { Fail $tr 'CU4 retos' "mc irresoluble, correctOptionId '$($ct.correctOptionId)' fuera de [$($opts -join ',')]: '$q'" }
      }
      'fill_blank' {
        $holes = [regex]::Matches($ct.codeSnippet, '\{\{(\d+)\}\}') | ForEach-Object { $_.Groups[1].Value }
        $holes = @($holes | Sort-Object -Unique)
        $keys = @($ct.correctAnswers.PSObject.Properties.Name | Sort-Object)
        if (($holes -join ',') -ne ($keys -join ',')) { Fail $tr 'CU4 retos' "fb huecos [$($holes -join ',')] != respuestas [$($keys -join ',')]: '$q'" }
        if ($ct.availableOptions) {
          foreach ($p in $ct.correctAnswers.PSObject.Properties) {
            if ($p.Value -notin @($ct.availableOptions)) { Fail $tr 'CU4 retos' "fb irresoluble, respuesta '$($p.Value)' no esta entre las opciones: '$q'" }
          }
        }
      }
      'order_logic' {
        $bk = @($ct.blocks.PSObject.Properties.Name | Sort-Object)
        $co = @($ct.correctOrder | Sort-Object)
        if (($bk -join ',') -ne ($co -join ',')) { Fail $tr 'CU4 retos' "ol bloques [$($bk -join ',')] != orden [$($co -join ',')]: '$q'" }
      }
      default { Fail $tr 'CU4 retos' "challenge_type desconocido '$($c.challenge_type)': '$q'" }
    }
  }
  Write-Host "  CU4 retos resolubles: $($ch.Count) retos ($theoryCount teoria)"

  # --- CU5: toda seccion tiene retos, y Basic empieza con teoria ----------
  foreach ($lf in $leaves) {
    if (-not $byTopic.ContainsKey($lf.id)) { Fail $tr 'CU5 secuencia' "seccion '$($lf.title)' sin ningun reto: seria un lab vacio" }
  }
  $basic = $levels | Sort-Object sort_order | Select-Object -First 1
  $basicKids = @($leaves | Where-Object { $_.parent_id -eq $basic.id } | Sort-Object sort_order)
  $first = $basicKids | Select-Object -First 1
  if ($byTopic.ContainsKey($first.id)) {
    $firstCh = ($byTopic[$first.id] | Sort-Object sort_order)[0]
    if ($firstCh.challenge_type -ne 'theory') { Fail $tr 'CU5 secuencia' "el primer reto del path es '$($firstCh.challenge_type)', deberia ser teoria" }
  }
  # densidad de teoria: debe caer de Basic a Advanced
  $dens = @()
  foreach ($lv in ($levels | Sort-Object sort_order)) {
    $kids = @($leaves | Where-Object { $_.parent_id -eq $lv.id })
    $tot = 0; $th = 0
    foreach ($kid in $kids) { if ($byTopic.ContainsKey($kid.id)) { foreach ($c in $byTopic[$kid.id]) { $tot++; if ($c.challenge_type -eq 'theory') { $th++ } } } }
    $dens += "$($lv.title) $th/$tot"
  }
  Write-Host "  CU5 teoria primero + densidad: $($dens -join ' | ')"

  # --- CU6: completar el primer topic y verificar el avance ---------------
  #
  # Reproduce lo que hace markTopicCompleted: upsert declarando el conflicto
  # contra user_progress_una_fila_por_topico. Sin on_conflict, PostgREST
  # responde 409 en el segundo intento, asi que esto tambien cubre el replay de
  # un lab, que los tests unitarios no pueden ver: alli el repositorio es doble.
  #
  # No hay "fojas cero" posible: user_progress no tiene policy de DELETE, y esta
  # bien que no la tenga. La idempotencia la da el propio upsert.
  $upsert = @{
    apikey        = $APIKEY
    Authorization = "Bearer $token"
    Prefer        = 'resolution=merge-duplicates'
  }
  $body = @{
    user_id      = $uid
    topic_id     = $first.id
    status       = 'completed'
    completed_at = (Get-Date).ToUniversalTime().ToString('o')
  } | ConvertTo-Json

  try {
    # Dos veces a proposito: la segunda es el replay.
    foreach ($intento in 1, 2) {
      $null = Invoke-RestMethod -Method Post `
        -Uri "$U/rest/v1/user_progress?on_conflict=user_id,topic_id" `
        -Headers $upsert -ContentType 'application/json' -Body $body
    }

    $prog = Rest $token "user_progress?select=topic_id,status&status=eq.completed"
    $done = @($prog).Count
    # Dos upserts, una sola fila: es la garantia de que rejugar un lab no
    # duplica ni revierte nada.
    if ($done -ne 1) { Fail $tr 'CU6 progreso' "$done topicos completados tras 2 upserts, esperaba 1" }
    if (@($prog)[0].topic_id -ne $first.id) { Fail $tr 'CU6 progreso' 'se registro contra otro topico' }

    $pct = [math]::Round(($done / $leaves.Count) * 100)
    $expected = [math]::Round((1 / 15) * 100)
    if ($pct -ne $expected) { Fail $tr 'CU6 progreso' "$pct% calculado sobre $($leaves.Count) hojas, esperaba $expected%" }
    Write-Host "  CU6 progreso: 1 de $($leaves.Count) = $pct% (coincide con el resumen del perfil)"
  } catch {
    Fail $tr 'CU6 progreso' $_.Exception.Message
    Write-Host "  CU6 progreso: FALLA" -ForegroundColor Red
  }

  # --- CU7: aislamiento entre cuentas -------------------------------------
  # Las 5 cuentas QA tienen progreso escrito, asi que si RLS estuviera abierta
  # esta consulta traeria filas ajenas. Es la prueba, no un detalle.
  try {
    $otros = Rest $token "user_progress?select=user_id"
    $ajenos = @($otros | Where-Object { $_.user_id -ne $uid }).Count
    if ($ajenos -gt 0) { Fail $tr 'CU7 RLS' "ve $ajenos filas de progreso de otras cuentas" }
    Write-Host "  CU7 RLS aislamiento: OK ($(@($otros).Count) filas, todas propias)"
  } catch {
    Fail $tr 'CU7 RLS' $_.Exception.Message
    Write-Host "  CU7 RLS aislamiento: FALLA" -ForegroundColor Red
  }

  # --- CU8: las funciones de IA del path responden para este track ---------
  #
  # Los tracks nuevos nunca las habian ejercitado, y el prompt del resumen dejo
  # de enumerar los tres tecnicos: si alguna rechazara un slug desconocido, la
  # tarjeta del dashboard y el encabezado del path quedarian en su estado de
  # error para uiux y project_management.
  $ia = @{}
  foreach ($fn in 'daily-brief', 'roadmap-coach') {
    $fnBody = @{
      trackSlug = $tr; experienceLevelSlug = 'student'; learningGoalSlug = 'first_job'
      completedTopics = 1; totalTopics = $leaves.Count
      progressFraction = 0.07; nextTopicTitle = $first.title
    } | ConvertTo-Json
    try {
      $r = Invoke-RestMethod -Method Post -Uri "$U/functions/v1/$fn" `
        -Headers @{ apikey = $APIKEY; Authorization = "Bearer $token" } `
        -ContentType 'application/json' -Body $fnBody
      $txt = if ($r.brief) { $r.brief } else { $r.message }
      if (-not $txt) { Fail $tr "CU8 IA/$fn" 'respondio 200 pero sin texto' }
      $ia[$fn] = 'OK'
    } catch {
      Fail $tr "CU8 IA/$fn" $_.ErrorDetails.Message
      $ia[$fn] = 'FALLA'
    }
  }
  Write-Host "  CU8 IA del path: daily-brief=$($ia['daily-brief']) roadmap-coach=$($ia['roadmap-coach'])"

  [void]$summary.Add([pscustomobject]@{
    track = $tr; niveles = $levels.Count; secciones = $leaves.Count
    retos = $ch.Count; teoria = $theoryCount
    ia = "$($ia['daily-brief'])/$($ia['roadmap-coach'])"
  })
}

# --- CU9: anonimo no lee el catalogo -----------------------------------------
Write-Host "`n=== RLS anonima ===" -ForegroundColor Cyan
foreach ($tabla in 'topics', 'lab_challenges', 'profiles', 'user_progress') {
  try {
    $anon = Invoke-RestMethod -Method Get -Uri "$U/rest/v1/$tabla`?select=*&limit=1" -Headers @{ apikey = $APIKEY }
    if (@($anon).Count -gt 0) {
      Fail 'global' 'CU9 RLS anonima' "sin sesion lee $tabla"
      Write-Host "  $tabla : FUGA" -ForegroundColor Red
    } else { Write-Host "  $tabla : OK (0 filas)" }
  } catch {
    Write-Host "  $tabla : OK (denegado)"
  }
}

# --- Informe -----------------------------------------------------------------
Write-Host "`n===== RESUMEN =====" -ForegroundColor Yellow
$summary | Format-Table -AutoSize | Out-String | Write-Host
$totRetos = ($summary | Measure-Object retos -Sum).Sum
Write-Host "Total: $($summary.Count) tracks, $totRetos retos verificados"

if ($fails.Count -gt 0) {
  Write-Host "`n===== FALLAS ($($fails.Count)) =====" -ForegroundColor Red
  $fails | Format-Table -AutoSize -Wrap | Out-String -Width 200 | Write-Host
  exit 1
} else {
  Write-Host "`nSIN FALLAS" -ForegroundColor Green
}
