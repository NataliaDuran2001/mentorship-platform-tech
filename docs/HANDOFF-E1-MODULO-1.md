# HANDOFF EJECUTABLE · E1 · Módulo 1: Onboarding y selección de roadmap

Continuación de [HANDOFF-E0-BLOQUE-A.md](HANDOFF-E0-BLOQUE-A.md) y
[HANDOFF-E0-BLOQUE-B.md](HANDOFF-E0-BLOQUE-B.md). E0 está cerrado al 100%
(#1–#6 + #16). Este documento es autosuficiente.

El tablero de GitHub es la fuente de verdad del estado. Los criterios de
aceptación canónicos viven en el cuerpo de cada issue y en sus comentarios;
este documento resume y da contexto — **el issue manda**.

Repo: `NataliaDuran2001/mentorship-platform-tech`

## 1. Cómo ejecutar

Una tarea por iteración. En cada una:

**Sincronizar.** Leer el tablero y reescribir la tabla de §4:

```bash
gh issue list --repo NataliaDuran2001/mentorship-platform-tech \
  --state all --json number,title,state,labels \
  --jq '.[] | "#\(.number) \(.state) \(.labels|map(.name)|join(","))"'
```

Cruzar con `git log --oneline -10`. Si el tablero y el repo discrepan, gana el
repo: corregir el tablero.

**Elegir y abrir.** Tomar la primera tarea de §5 con `status:pendiente` cuyas
dependencias estén cerradas. Leer el issue completo, incluidos los comentarios
(los #7 y #9 tienen comentarios que cambian su alcance):

```bash
gh issue view N --repo NataliaDuran2001/mentorship-platform-tech --comments
gh issue edit N --repo NataliaDuran2001/mentorship-platform-tech \
  --add-label "status:en-curso" --remove-label "status:pendiente"
```

**Implementar.** Leer los archivos que la tarea nombra antes de escribir.
Implementar completa. Correr `fvm flutter analyze --fatal-infos && fvm flutter
test`. Si falla, arreglar; no avanzar con la verificación roja. Commit en la
rama de la tarea con el mensaje indicado.

**Cerrar.** Validar los criterios de aceptación uno por uno siguiendo §6. No es
opcional ni resumible. Sincronizar el tablero siempre: comentario de
validación, labels, cierre o bloqueo, y `--add-assignee NataliaDuran2001`. No
requiere pedir permiso. Actualizar §4 con el resultado y el SHA corto.

Si no queda tarea ejecutable, ir a §8 y detenerse.

**Ramas y PRs — cambió respecto a E0.** `main` está protegida: exige el check
`analyze-y-test` en verde y `enforce_admins: true`. Nada entra por push
directo, ni siquiera de la dueña. Por lo tanto:

- Una rama por issue: `feat/e1-<slug>`.
- Push y PR hacia `main` están autorizados de forma durable. Abrir el PR apenas
  haya algo revisable.
- **Mergear NO está autorizado**: lo hace la dueña. Dejar el PR verde y avisar.
- No pushear a `main` — fallará, y está bien que falle.

## 2. Estado real del repositorio

App Flutter de una plataforma de mentoría con IA para mujeres en Bolivia.

| Qué | Valor |
|---|---|
| Rama por defecto | `main`, protegida (check `analyze-y-test` requerido, sin excepción para admin) |
| Toolchain | Flutter 3.44.2 vía FVM (`.fvmrc`) · Dart 3.12.2. Prefijar todo con `fvm` |
| Dependencias | `get_it ^9.2.1` · `signals_flutter ^7.1.0` · `supabase_flutter ^2.16.0` · `go_router ^17.3.0` |
| Backend | Supabase `dtvfucqamakudgbwuhbw`. Sin tablas, `auth.users` en 0. Advisors de seguridad: cero lints |
| Auth del proyecto | `email: true` · `google: false` (post-mvp, #15) · `disable_signup: false` · `mailer_autoconfirm: false` |
| URLs de auth | Site URL `http://localhost:5000` · redirects `http://localhost:5000/**`. Correr siempre con `--web-port 5000` |
| Plantillas de correo | En inglés (default de Supabase), por decisión de la dueña. Traducciones listas en el comentario de cierre del #3 si se revierte |
| Design system | «Luminous Clarity» · `C:\Users\Natalia\Downloads\mentor_ai\stitch_femtech_mentor_ai\luminous_clarity\DESIGN.md`. La fuente de verdad es su frontmatter YAML, no su prosa (salvo para specs de componentes) |
| Prototipos | `descubre_tu_ruta_onboarding/` y `orientaci_n_de_ruta_test/` en la misma carpeta de Downloads |
| Doc de arranque | [DEVELOPMENT.md](DEVELOPMENT.md), verificado clonando en limpio |

**Entorno, ya resuelto — no volver a investigarlo.** FVM instalado, SDK en
`C:\Users\Natalia\fvm\versions\3.44.2`. Modo Desarrollador de Windows activado
(sin él `pub get` falla por symlinks). El primer build web en debug tarda
~100 s antes de pintar; la pestaña en blanco no es un error. `fvm flutter test
--platform chrome` no completa en esta máquina (se abortó a los ~20 min
compilando): verificar con la suite normal, que corre en ~15 s.
`TimeoutException` de DWDS al conectar es un flake con la máquina cargada:
reintentar el run.

**Guardrail de RLS ya instalado — importa para el #7.** El schema `public` no
tiene tablas pero no está vacío: hay un event trigger `ensure_rls` →
`rls_auto_enable()` que corre `alter table ... enable row level security` en
cada `CREATE TABLE` sobre `public`.

- El AC1 del #7 se cumple solo. Igual conviene escribir el `enable` explícito en
  la migración, para que sea reproducible en un proyecto sin este trigger.
- El riesgo se invierte: el modo de falla por defecto ahora es una tabla con RLS
  activo y **cero políticas** — silenciosamente inaccesible, sin error visible.
  Eso es lo que el AC2 del #7 tiene que atrapar.

## 3. Invariantes — violarlas es un defecto, no una opción

### Decisiones de producto cerradas

| Decisión | Valor |
|---|---|
| Idioma | UI y comentarios en español. Identificadores y código en inglés |
| Marca | Sin decidir. Todo nombre de producto pasa por `AppBranding.name` |
| Tracks | Exactamente 3: `frontend`, `backend`, `infrastructure`. Sin Mobile ni UI/UX, aunque aparezcan en mockups |
| Auth del MVP | Email/password. Google va al #15, post-mvp |
| Confirmación por correo | Activa (`mailer_autoconfirm: false`). Un signup no devuelve sesión hasta confirmar |
| Router | `go_router` |
| Omitir en el onboarding | Permitido en pasos 1 y 3, **prohibido en el paso 2** (sin track no hay roadmap) |

### Reglas de arquitectura (de CLAUDE.md)

- Clean architecture, dependencia hacia adentro: `presentation → domain ← data`.
  `presentation` nunca importa `data`.
- `domain` es Dart puro: sin Flutter, sin JSON, sin paquetes externos.
- Atomic design: `atoms/` → `molecules/` → `organisms/` → `pages/`. Cada nivel
  compone solo desde los de abajo. Los átomos son libres de contexto y reciben
  comportamiento por callback. Solo las páginas tocan estado o DI.
- Estado con señales: `signal<T>` global en `lib/presentation/state/`. Widgets
  `StatelessWidget`, región reactiva en `SignalBuilder` (ver la bitácora de C1:
  reemplaza a `Watch`). Nunca `setState`.
- DI con get_it: todo por `getIt`. Ningún widget construye repositorios ni casos
  de uso.
- Supabase: la capa `data` toma `SupabaseClient` de `getIt`. Nunca
  `Supabase.instance.client` fuera de `supabase_config.dart`.
- Imports entre capas relativos (`../../domain/...`).
- Cada archivo nuevo bajo `lib/` abre con un comentario en español nombrando su
  capa.
- Cero colores o spacing literales en widgets. Todo de `AppColors` y
  `AppConstants`.
- Toda tabla nueva: RLS habilitado + al menos una política explícita.

### Prohibido

- Tocar el #15 (Google OAuth) o escribir su código. `signInWithGoogle` va al
  contrato lanzando `UnimplementedError` con referencia al #15 — así el #15 es
  puramente aditivo.
- Inventar contenido de currículum. Los tópicos reales son decisión abierta del
  Módulo 2; el #7 siembra placeholders y el #13 construye el contenedor.
- Cerrar un issue con criterios de aceptación sin cumplir (§6).
- Commitear una llave `service_role` de Supabase, ni credenciales de usuarias de
  prueba.
- Mergear a `main`. Push y PR sí; el merge lo hace la dueña.
- Aplicar migraciones a mano en el dashboard: van versionadas en
  `supabase/migrations/`.

### Deuda conocida — las tres, cerradas

1. ~~`Watch` está deprecado en signals_flutter 7.1~~ → **cerrada en C4**. Decidida
   en C1, ejecutada en C4: no queda ningún `Watch` ni ningún
   `// ignore: deprecated_member_use` en `lib/`.
2. ~~`main()` hace `await SupabaseConfig.initialize()` sin `try/catch`~~ →
   **cerrada en C4**. Ahora el arranque completo va en un `try/catch` y un fallo
   muestra `ArranqueFallido` con el detalle técnico, en vez de una pantalla en
   blanco indefinida.
3. ~~`isAuthenticated` es un signal escribible~~ → **cerrada en C4**. Es un
   `computed` derivado de `currentSession`, y `hasCompletedOnboarding` un
   `computed` derivado del perfil. La UI ya no puede declararse autenticada.

## 4. Espejo del tablero

Reescribir desde `gh` en cada iteración.

| Tarea | Issue | Estado | Depende de | Commit |
|---|---|---|---|---|
| C1 · Capa de dominio | #8 | `status:hecha` | — | `86fddba` |
| C2 · Esquema Supabase + RLS | #7 | `status:bloqueada` — 5/7 AC | — (#3, #4 cerrados) | `8c17ab5` |
| C3 · Átomos y moléculas del onboarding | #10 | `status:hecha` | — (#2 cerrado) | `d12a516` |
| C4 · Autenticación real | #9 | `status:bloqueada` — 5/7 AC | #7, #8 | `2ec1b98` |
| C5 · Onboarding directo (4 pasos) | #11 | `status:pendiente` | #8, #10 | |
| C6 · Cuestionario guía | #12 | `status:pendiente` | #11 | |
| C7 · Persistencia y reanudación | #14 | `status:pendiente` | #11 (afina #12) | |
| C8 · Árbol de tópicos | #13 | `status:pendiente` | #7, #8, #10 | |

Orden recomendado: C1 → C2 → C3 → C4 → C5 → C6 → C7 → C8.

**Lo único pendiente del #7** son el AC3 (aislamiento entre dos usuarias) y el
AC5 (el trigger crea el perfil). Los dos necesitan dos filas reales en
`auth.users`; se desbloquean corriendo `supabase/tests/rls_modulo_1.sql` desde
el SQL editor del dashboard. No bloquean a ninguna otra tarea: el esquema está
aplicado y las 5 tablas funcionan.

**El merge a `main` quedó autorizado para E1** (antes era exclusivo de la
dueña). `main` sigue protegida con el check `analyze-y-test` y
`enforce_admins: true`, así que hay que esperar el CI en verde antes de
mergear.

## 5. Tareas

Cada una remite al issue para los AC canónicos. Acá va el contexto y las
trampas.

### C1 · Capa de dominio — issue #8 · hecha

Entidades, contratos y casos de uso del Módulo 1. Ver §9 para las decisiones
tomadas y el mapa de lo que quedó en el repo.

### C2 · Esquema Supabase con RLS — issue #7

Migración versionada con 5 tablas (`profiles`, `tracks`, `topics`,
`user_progress`, `onboarding_answers`), trigger sobre `auth.users` que crea el
perfil al registrarse, políticas RLS explícitas y los 3 tracks sembrados.

Trampas:

- El event trigger `ensure_rls` ya activa RLS solo. El peligro real es una tabla
  con RLS y cero políticas — inaccesible en silencio, sin error. Escribir el
  `enable` igual, por reproducibilidad.
- `profiles`, `user_progress`, `onboarding_answers`: la usuaria solo lee/escribe
  sus propias filas (`auth.uid()`). `tracks` y `topics`: solo lectura para
  autenticadas.
- El AC3 exige verificar con dos usuarias distintas que A no ve datos de B. Eso
  necesita usuarias reales confirmadas — si el #9 aún no está, crear dos desde
  el dashboard y documentar que son de prueba (credenciales fuera del repo).
- Los tópicos son placeholder: no inventar currículum.
- **Alineación fijada en C1**: `tracks.id` y `profiles.track_id` usan los slugs
  del enum `RoadmapTrack` (`frontend`, `backend`, `infrastructure`), y
  `profiles.experience_level` / `profiles.learning_goal` los de
  `ExperienceLevel` / `LearningGoal`. `onboarding_answers` necesita clave única
  (usuaria, `step_key`) para el upsert del #14.

Verificar: `list_tables` con las 5 tablas y `rls_enabled: true`; cada tabla con
≥1 política; `get_advisors(security)` sin lints nuevos (hoy está en cero, que no
baje de ahí).

Commit: `feat(db): esquema del Modulo 1 con RLS y tracks sembrados`

### C3 · Átomos y moléculas del onboarding — issue #10

Átomos `AppProgressBar`, `StepCounterLabel`, `IconTile`, `AppRadio`; moléculas
`OptionCardTile`, `TrackCard`, `GoalRadioRow`, `OnboardingFooter`.

Trampas:

- Los átomos no pueden importar `getIt`, leer signals ni saber en qué paso
  están. Todo por parámetro, todo hacia afuera por callback. Es lo que hace que
  #11 y #12 los reutilicen sin duplicar.
- El estado `selected` de `OptionCardTile` tiene valores exactos en el
  prototipo: borde `#674BB5` (= `AppColors.primary`) y fondo `primary` al 8%.
  Usar el token, no el hex.
- `OnboardingFooter` recibe la visibilidad de cada botón desde fuera — el paso 2
  oculta «Omitir», y esa regla vive en #11, no acá.
- Las etiquetas en español de los 3 niveles, 3 tracks y 4 metas van en
  `presentation/utils/` (el dominio solo tiene slugs). Textos exactos del
  prototipo, transcritos en §9.

Verificar: grep de `Color(0x` y literales de padding en los archivos nuevos →
sin resultados. Tests de widget del callback de selección y del estado visual
`selected`.

Commit: `feat(presentation): atomos y moleculas del onboarding`

### C4 · Autenticación real — issue #9

**Este issue tiene alcance ampliado por sus comentarios. Leerlos antes de
estimar.**

`AuthRepositoryImpl` real contra el `SupabaseClient` de `getIt`, `UserModel` con
mapeo JSON ↔ `UserProfile`, `SignUpPage` nueva (hoy no hay forma de crear
cuenta), login email/password, sesión persistente, route guards y logout.

Alcance extra que suma la confirmación por correo activa:

- Estado «revisá tu correo para confirmar tu cuenta» después del registro —
  `signUp` devuelve `session == null`.
- Manejo del login de un usuario sin confirmar, con mensaje claro en español.
- Reenvío del correo de confirmación.

AC1 reformulado (vale este, no el del cuerpo): el registro crea la fila en
`auth.users` y la UI informa que falta confirmar; el login de un usuario
confirmado devuelve sesión válida y persistente; el de uno sin confirmar falla
con mensaje claro en español.

Trampas:

- La pantalla de login del prototipo es Google-first, pero el MVP es
  email/password. `google_login_button.dart` no se borra: queda visible pero
  deshabilitado, o detrás de una bandera hasta el #15. No dejarlo cableado a un
  stub.
- `signInWithGoogle` ya está en el contrato; la implementación lanza
  `UnimplementedError` con referencia al #15 (hecho en C1).
- Los guards: sin sesión → login · con sesión y `onboarding_completed_at == null`
  → onboarding · completo → dashboard. Probar también el acceso directo por URL a
  una ruta protegida. Ojo: `UserProfile.hasCompletedOnboarding` exige además
  `track != null` (ver §9).
- Ningún error crudo de Supabase a la vista: traducir cada `AuthFailureKind` de
  `domain/failures/auth_failure.dart` a un mensaje en español, en
  `presentation/`.
- Aprovechar para arreglar la deuda 2 y 3 de §3 (`try/catch` en `main()`,
  `isAuthenticated` como `computed`).
- Los tests de login necesitan un usuario ya confirmado: crearlo una vez desde
  el dashboard y documentar sus credenciales en `docs/SUPABASE.md`, fuera del
  repo.
- `AuthRepositoryImpl` es hoy un stub que lanza `UnimplementedError` y **no está
  registrado en `getIt`**. Registrarlo es parte de este issue.

Verificar: no queda ningún `Future.delayed` simulando auth en `lib/`
(`grep -rn "Future.delayed" lib/`). Recargar mantiene sesión. Los 3 guards
redirigen bien.

Commit: `feat(data): autenticacion real con Supabase y route guards`

### C5 · Onboarding directo, 4 pasos — issue #11

`onboarding_state.dart` (signals de paso, selecciones y total de pasos),
organismos `OnboardingStepRole` / `StepStack` / `StepGoal` / `Summary`, y
`OnboardingPage` como único nivel que toca `getIt` y estado.

Trampas:

- El paso 2 ofrece los 3 tracks más «Aún no lo sé», que no está en ningún
  mockup: es la opción que conecta ambos diseños y deriva al #12. Su valor
  persistido es `OnboardingKeys.unknownTrackValue`.
- «Omitir» prohibido en el paso 2. Sin track no hay roadmap y se viola el CA 1.3.
- El total de pasos es variable: 4 en la rama directa, 5 si entra a la guía. La
  barra de progreso y el contador se calculan sobre el total real — de ahí venía
  la discrepancia entre los dos mockups.
- Regresar preserva lo ya seleccionado.
- Auto-avance de 400 ms tras seleccionar, con feedback visual.
- `OnboardingPage` reemplaza el placeholder actual, que hoy tiene un botón
  «Continuar al dashboard» — desaparece.

Verificar: completar el flujo persiste `experience_level`, `track_id`,
`learning_goal` y `onboarding_completed_at` en `profiles`.

Commit: `feat(presentation): flujo de onboarding directo de 4 pasos`

### C6 · Cuestionario guía — issue #12

Organismo `GuidedQuizStep` reutilizando `TrackCard`, el set de preguntas,
consumo de `RecommendTrackUseCase` y pantalla de resultado con confirmación
explícita.

Trampas:

- La regla de decisión no vive en el widget. Sale de `RecommendTrackUseCase`
  (#8). Si tienta escribir un `if` en la UI, ese es el error que el AC3 busca.
- El mockup ofrece Front-end / Back-end / Infraestructura: alinearlos a los 3
  tracks decididos.
- El resultado exige confirmación y permite corregir manualmente. Si
  `TrackRecommendation.wasTie` es `true`, decirlo en vez de presentar el
  resultado como concluyente.
- Al confirmar, el flujo sigue en el paso 3 (meta) de #11 con el track ya
  asignado, y el contador pasa a «de 5».
- Cada respuesta se persiste en `onboarding_answers` con clave
  `OnboardingKeys.quizQuestion(n)` — eso alimenta la reanudación del #14.

Commit: `feat(presentation): rama de cuestionario guia y recomendacion de track`

### C7 · Persistencia y reanudación — issue #14

Contexto: esto llena un hueco del spec, no está en ningún CA original del
documento de producto. Sin esto, quien abandona el onboarding vuelve al paso 1,
y con «Omitir» se puede llegar a una sesión con track nulo — que rompe el
CA 1.3.

Persistir cada respuesta al seleccionarla (no al final), leer el estado parcial
al entrar y reanudar en el primer paso sin responder, con las selecciones
previas ya marcadas.

Trampas:

- Ningún camino puede llevar al dashboard con `track_id` nulo. Esa es la
  política, y afecta a los guards del #9.
- Reanudar no duplica filas: la respuesta de un paso se actualiza (upsert con
  clave por usuaria + `step_key`).
- La reanudación tiene que funcionar también dentro de la rama del cuestionario
  (#12). `RecommendTrackUseCase` acepta la lista completa de `loadAnswers()` sin
  filtrar, justamente para esto.

Nota para producto: este comportamiento debería incorporarse a la Historia 1.1
del documento como CA 4. Hoy es ingeniería tapando un vacío — mencionarlo en el
reporte de cierre.

Commit: `feat(data): persistencia y reanudacion del onboarding incompleto`

### C8 · Árbol de tópicos — issue #13

Cierra la Historia 1.1 con su CA 1.3: al definir la ruta se despliega el árbol
de tópicos secuenciales.

`RoadmapRepositoryImpl` + `TopicModel`, organismo `RoadmapTree`, `RoadmapPage`
con porcentaje de avance, estado vacío y manejo de error con reintento.

Trampas:

- No hay mockup de esta pantalla. El prototipo solo muestra la ruta en curso
  dentro del dashboard. Derivar el diseño del design system y de los patrones de
  card ya establecidos.
- **La jerarquía y la secuencialidad ya están resueltas en `domain`**:
  `RoadmapRepository.listTopics()` devuelve lista plana y
  `GetRoadmapTreeUseCase` arma el árbol por `parentId`, ordena por `sortOrder` y
  asigna `TopicStatus`. El widget solo pinta. No reimplementar la regla.
- Secuencialidad visible: `completed` / `available` / `locked`, y los bloqueados
  no responden al tap.
- El estado vacío es el caso real hoy, porque el currículum no está escrito: no
  puede ser una pantalla en blanco ni un error.
- Fuera de alcance: el contenido del currículum. Se prueba contra los
  placeholders del #7.

Commit: `feat(presentation): arbol de topicos secuenciales del roadmap`

## 6. Validación de criterios de aceptación y cierre

Al terminar de implementar, antes de marcar hecha:

1. Releer los criterios del cuerpo del issue y de sus comentarios
   (`gh issue view N --comments`). Son la lista canónica, no el resumen de §5.
2. Recorrerlos uno por uno: cumplido o no, y con qué evidencia. Evidencia es la
   salida real de un comando o una observación concreta, no «debería funcionar».
3. Publicar el comentario:

```bash
gh issue comment N --repo NataliaDuran2001/mentorship-platform-tech --body-file <archivo>
```

Formato:

```
## Validación de criterios de aceptación

- [x] **AC1** — <cómo se verificó> · evidencia: `<comando>` → <resultado real>
- [ ] **AC3** — **PENDIENTE**: <razón concreta y de qué depende>

Commit: <sha corto> en `<rama>`
```

| Situación | Acción |
|---|---|
| Todos los AC cumplidos | `gh issue edit N --add-label "status:hecha" --remove-label "status:en-curso" --add-assignee NataliaDuran2001` y `gh issue close N --reason completed` |
| Alguno sin cumplir | `gh issue edit N --add-label "status:bloqueada" --remove-label "status:en-curso" --add-assignee NataliaDuran2001`. Dejar el issue abierto |

**Regla dura**: no se cierra un issue con un AC en `[ ]`. Un issue abierto con 4
de 5 y el quinto nombrado es información útil; uno cerrado a medias convierte el
tablero en ficción.

## 7. Bloqueado y decisiones abiertas

| Qué | Bloquea | Estado |
|---|---|---|
| #15 · Google OAuth (`manual`, `fase:post-mvp`) | Nada del MVP. Es aditivo sobre el #9 | Diferido por decisión de producto |
| Contenido real del currículum (tópicos) | Nada de E1 — el #13 usa placeholders | Decisión abierta, se resuelve al planificar el Módulo 2 |
| Plantillas de correo en inglés | Nada técnico | Decisión de la dueña. Traducciones listas en el #3 si se revierte antes del lanzamiento |
| ~~Migrar `Watch` → `SignalBuilder`~~ | — | **Resuelta en C1**: se migra. Ver §9 |
| ~~Criterio de desempate de `RecommendTrackUseCase`~~ | — | **Resuelta en C1**: orden de declaración del enum. Ver §9 |
| Diseño del árbol de tópicos (sin mockup) | El #13 | Lo decide quien haga C8, derivándolo del design system |

Los módulos 2 a 6 del spec todavía no están bajados a issues. Este handoff
cubre solo el Módulo 1.

## 8. Término

Cuando los 8 issues estén `status:hecha` o `status:bloqueada`, detenerse y
reportar: tabla final de §4 con estados y SHA; issues abiertos con su AC
pendiente y de qué dependen; lo anotado en §9; salida real de `fvm flutter
analyze` y `fvm flutter test`; estado de los PRs y cuáles esperan merge de la
dueña; y la verificación end-to-end del Módulo 1, que es el entregable real
(registrar usuaria nueva → confirmar correo → login → onboarding completo, ambas
ramas → ver el árbol de tópicos, con `--web-port 5000`).

No arrancar el Módulo 2: necesita su propio handoff y el currículum es una
decisión abierta.

## 9. Bitácora

Decisiones técnicas dentro del ámbito de ingeniería, desviaciones necesarias con
su razón, y cosas que deberían discutirse pero no bloquean. Ver también la §9 de
los handoffs de E0.

- **C1 · `Watch` → `SignalBuilder`, decidido: se migra.** Era la decisión abierta
  de §7. `Watch` está deprecado en signals_flutter 7.1 y el CI corre
  `analyze --fatal-infos`, así que cada `Watch` nuevo arrastra su `// ignore`. Con
  6+ pantallas reactivas por delante en el Módulo 1, la deuda crece por pantalla.
  No se hizo un commit de migración suelto porque hoy hay **un solo** `Watch` en
  el repo (`login_page.dart`) y el #9 reescribe esa página completa: los widgets
  nuevos de C3/C5 nacen con `SignalBuilder` y el último `Watch` se va con el #9.
  §3 de este documento ya dice `SignalBuilder`; CLAUDE.md se actualiza en el
  primer commit que introduzca uno.

- **C1 · Desempate de `RecommendTrackUseCase`: orden de declaración del enum**
  (`frontend` → `backend` → `infrastructure`), y el resultado viaja con
  `wasTie: true`. Era la decisión abierta que exigía el AC3 del #8. El criterio
  es arbitrario a propósito: lo que importa es que sea determinístico y que el
  empate sea *visible*, porque el #12 obliga a que la usuaria confirme la
  recomendación y pueda corregirla a mano. `frontend` queda primero por ser la
  puerta de entrada más común para quien recién empieza, que es el perfil
  dominante del producto. Cubierto por tests, incluido uno que verifica que el
  orden de llegada de las respuestas no altera el resultado.

- **C1 · `RecommendTrackUseCase` acepta la lista completa de respuestas del
  onboarding, no solo las del cuestionario.** Cuenta un voto por cada respuesta
  cuyo valor mapee a un track; las que no mapean (`student`, `first_job`,
  `unknown`) no votan. Así el #12 y el #14 pueden pasarle tal cual lo que
  devuelve `loadAnswers()` al reanudar, sin filtrar antes ni duplicar la lógica
  de filtrado en dos pantallas.

- **C1 · Los stubs del scaffold se eliminaron, no se dejaron conviviendo.**
  `UserEntity{id,name}` → `UserProfile`; `LoginUseCase` (que llamaba a
  `loginWithGoogle`) → `SignInUseCase`; `AuthRepository.loginWithGoogle()` → el
  contrato ampliado. `data/models/user_model.dart` se borró en vez de adaptarse:
  el mapeo real necesita los nombres de columna del #7, que todavía no existen, y
  el #9 lo crea de cero. `AuthRepositoryImpl` se conservó porque el #9 lo
  reemplaza, pero cada método lanza `UnimplementedError('… issue #9')` en vez de
  simular éxito con un `Future.delayed`: un stub que devuelve datos falsos se
  cuela hasta producción, uno que explota no.

- **C1 · Los enums llevan `slug` y `fromSlug`, y las etiquetas en español quedan
  fuera del dominio.** El `slug` es el valor estable que se persiste
  (`profiles.experience_level`, `profiles.track_id`, `profiles.learning_goal`), y
  para los tracks es además la clave primaria de la tabla `tracks`: el mapeo
  enum ↔ base es directo, sin tabla de traducción. `fromSlug` devuelve `null` ante
  valores desconocidos o `null` a propósito, para que un perfil a medio llenar no
  haga explotar la lectura. Los textos visibles van en `presentation/utils/`
  (trabajo de C3), porque meterlos en el dominio lo ataría a la UI.

- **C1 · Se agregó `lib/domain/failures/`, una subcarpeta que CLAUDE.md no
  contemplaba.** Contiene `AuthFailure` + `AuthFailureKind`, el vocabulario
  tipado que los contratos lanzan. Es lo que permite cumplir «ningún error crudo
  de Supabase a la vista» (#9) sin que `presentation` importe `supabase_flutter`:
  `data` traduce la excepción del SDK a un caso, `presentation` el caso a un
  mensaje en español. CLAUDE.md quedó actualizado con la carpeta.

- **C1 · La jerarquía y la secuencialidad del roadmap viven en
  `GetRoadmapTreeUseCase`, no en el widget del #13.** El repositorio devuelve
  lista plana y el caso de uso arma el árbol (`parentId`, `sortOrder`) y deriva
  `TopicStatus`: el primer tópico hoja sin completar es `available`, los
  siguientes `locked`, y un nodo con hijos hereda de su descendencia. Es la regla
  que sostiene el CA 1.3 —ruta determinística, un solo tópico accionable— y en un
  widget no se podría testear sin montar Flutter. Un `parentId` inexistente se
  trata como raíz en vez de descartarse: preferimos mostrar el tópico huérfano a
  que desaparezca en silencio. Cubierto por 10 tests.

- **C1 · `UserProfile.hasCompletedOnboarding` exige `track != null` además de
  `onboardingCompletedAt != null`.** Es la política del #14 («ningún camino puede
  llevar al dashboard con `track_id` nulo») expresada en el dominio, para que los
  guards del #9 no puedan olvidarla. `SubmitOnboardingUseCase` refuerza lo mismo
  por tipos: el track es un parámetro `required` no nulable.

- **C1 · Textos exactos de los prototipos, para que C3/C5 no los inventen.**
  Niveles: «Estudiante / Autodidacta» (*Estoy aprendiendo las bases y busco mi
  primer empleo*), «Junior Developer» (*Tengo menos de 2 años de experiencia
  profesional*), «Cambiando de Carrera» (*Vengo de otro sector y quiero entrar a
  tech*). Metas: «Conseguir mi primer empleo profesional», «Aprender un nuevo
  lenguaje de programación», «Mejorar mis habilidades de entrevista técnica»,
  «Escalar a un puesto de nivel Middle». Tracks (del cuestionario guía):
  «Front-end» (*Crear interfaces visuales y experiencias de usuario que cautiven
  a primera vista*), «Back-end» (*Diseñar la lógica detrás de escena y bases de
  datos robustas para escalar sistemas*), «Infraestructura» (*Organizar procesos,
  automatizar tareas y optimizar flujos de trabajo masivos*). El paso 2 del
  onboarding directo usa «Frontend / Backend» a secas en su mockup; alinear a los
  nombres del cuestionario para no tener dos vocabularios.

- **C1 · Para producto, no bloquea**: el mockup del paso 2 del onboarding directo
  ofrece Mobile y UI/UX, que no son tracks del MVP. El enum tiene 3 valores y un
  test lo fija. Si producto quiere esos tracks, es un cambio de alcance, no un
  ajuste de UI.

- **C2 · La migración del esquema agregó 2 WARN al advisor, y cerrarlos tenía una
  trampa.** `handle_new_user()` es `SECURITY DEFINER` y quedaba expuesta como
  `/rest/v1/rpc/`, el mismo hallazgo que el #16 cerró para `rls_auto_enable()`.
  Se resolvió igual, revocando el `EXECUTE`, pero con una diferencia que importa:
  el ACL por defecto incluye un grant a `PUBLIC`, y **al revocar `PUBLIC` el rol
  que dispara el trigger (`supabase_auth_admin`) pierde el acceso**. Sin el grant
  explícito previo, el arreglo de seguridad habría roto el registro de usuarias
  en silencio. Está en `20260726232005_revoke_execute_triggers_modulo_1.sql`.
  Lección general: al revocar `PUBLIC` sobre una función que dispara un trigger,
  identificar antes quién la ejecuta.

- **C2 · Dos invariantes del CA 1.3 se forzaron en la base, no solo en Dart.**
  `profiles_completo_exige_track` (`check (onboarding_completed_at is null or
  track_id is not null)`) y `topics_orden_unico_entre_hermanos`
  (`unique nulls not distinct (track_id, parent_id, sort_order)`). La primera es
  la misma regla que `UserProfile.hasCompletedOnboarding` y la política del #14;
  la segunda evita que dos hermanos con el mismo `sort_order` vuelvan el orden
  ambiguo. Duplicar la regla en la base es a propósito: la UI puede tener un bug,
  el constraint no.

- **C2 · `user_progress` solo guarda hechos.** El enum es
  `('in_progress','completed')`. Los `available` y `locked` de `TopicStatus` no
  están porque son derivados: los calcula `GetRoadmapTreeUseCase`. Guardarlos
  obligaría a reescribir filas en cada avance, y dos fuentes de verdad para lo
  mismo se desincronizan.

- **C2 · Los tópicos placeholder se sembraron solo en `frontend`.** El #13 tiene
  que manejar un árbol con jerarquía *y* el estado vacío, y así prueba los dos
  contra datos reales: `frontend` tiene 5 tópicos en 2 niveles, `backend` e
  `infrastructure` quedan vacíos —que es el caso normal hoy—. Los títulos dicen
  «(placeholder)» para que se note si alguno llega a una captura de pantalla.

- **C2 · `supabase/tests/` es carpeta nueva.** `rls_modulo_1.sql` no es una
  migración: es el guion reproducible de la verificación de políticas, envuelto
  en una transacción que termina en `ROLLBACK`. Se puede correr sobre el proyecto
  de desarrollo sin ensuciarlo, y hay que volver a correrlo cada vez que cambien
  las políticas.

- **C3 · `HoverBuilder` es el único widget con estado de todo el onboarding, y es
  deliberado.** El prototipo usa `group-hover` de Tailwind: pasar el mouse por la
  card cambia también el fondo del recuadro del ícono que tiene adentro, así que
  alguien tiene que conocer el hover y propagarlo por parámetro. El hover es
  estado efímero de presentación, no estado de la aplicación: en un signal global
  quedaría compartido por todas las cards de la pantalla, que es exactamente lo
  contrario de lo que hace falta. La regla de §3 —signals, no `setState`— sigue
  valiendo para el estado de la app.

- **C3 · Los estados visuales viven en `presentation/utils/selectable_card_style.dart`,
  no duplicados en cada molécula.** `OptionCardTile`, `TrackCard` y `GoalRadioRow`
  comparten exactamente los mismos estados; si se desincronizan, la pantalla se ve
  distinta entre pasos. El anillo del seleccionado es un `BoxShadow` con
  `spreadRadius: 1` y sin difuminado —el `box-shadow: 0 0 0 1px` del prototipo—
  en vez de subir el borde a 2px, que movería el layout.

- **C3 · Desviación del prototipo, con razón: la barra de progreso mide 4px, no
  1px.** El cuerpo del #10 dice «barra de 1px de alto», pero el prototipo la
  declara `h-1`, que en Tailwind es 0.25rem = **4px**. Un `rounded-full` sobre
  1px no se ve. Vale el prototipo, que es lo que pide el AC3 del issue.

- **C3 · Desviación del prototipo, con razón: la fila de meta seleccionada se
  resalta.** En el prototipo las filas del paso 3 no son `.option-card`, así que
  solo cambian el borde en hover y dejan la selección al punto de 12px del
  círculo. `GoalRadioRow` usa la misma decoración que las tarjetas: un punto de
  12px es poca señal para el estado elegido, y el resto del flujo ya marca la
  selección así.

- **C3 · `CustomButton.onPressed` pasó a ser nullable.** Es el idioma de Material
  para un botón deshabilitado, y es lo que necesita el paso 2 del #11 para
  impedir avanzar sin track. Los llamadores existentes pasan valores no nulos, así
  que no hubo que tocarlos.

- **C3 · Para el #9, no bloquea**: el pie del onboarding necesita botones ghost en
  `onSurfaceVariant`, y `CustomButton` no tiene esa variante (su secundaria es un
  `OutlinedButton`, con borde). Quedó resuelto con un `TextButton` privado dentro
  de `OnboardingFooter`. Cuando el #9 toque los botones del login, conviene
  extraer una variante `ghost` de `CustomButton` y que las dos la usen. **Sigue
  abierto después de C4**: el login usa `TextButton` directo para sus enlaces.

- **C4 · `auth_actions.dart` es el único archivo de `presentation` que toca
  `getIt`.** Los widgets llaman funciones (`signInWithEmail`, `signOut`,
  `resendConfirmationEmail`) y no resuelven casos de uso. La alternativa —cada
  página resolviendo lo suyo— duplicaba la misma lógica en login, registro y
  logout, y dejaba sin hogar la suscripción al stream de sesión, que no pertenece
  a ninguna pantalla. `auth_state.dart` quedó con solo señales, sin
  dependencias, para poder resetearlo desde un test sin arrastrar getIt.

- **C4 · El tipo del error viaja en un signal aparte del mensaje.**
  `authErrorKind` existe porque la UI necesita decidir *qué ofrecer*, no solo
  *qué decir*: el botón de reenviar el correo aparece únicamente cuando el fallo
  es `emailNotConfirmed`. Decidirlo comparando cadenas de texto sería frágil.

- **C4 · Un correo ya registrado se detecta por `identities` vacío.** Con la
  protección contra enumeración de correos activada, Supabase **no** devuelve
  error al registrar un correo existente: devuelve un usuario con la lista de
  identidades vacía. Sin ese chequeo, la app diría «revisá tu correo» a alguien
  que ya tiene cuenta y que nunca iba a recibir nada. Es el tipo de bug que no
  aparece en ninguna prueba feliz.

- **C4 · Las páginas de autenticación no navegan; redirigen los guards.** Después
  de un login exitoso, `LoginPage` solo cambia `currentSession`. El puente
  `_SignalsRefreshListenable` dispara el `refreshListenable` de go_router y el
  guard decide entre onboarding y dashboard. Un `context.go()` en la página
  competiría con el guard y podría mandar a la usuaria al lugar equivocado.

- **C4 · Los formularios guardan sus campos en signals, no en
  `TextEditingController`.** Un controller necesita un `State` que lo libere, y
  los widgets del proyecto son `StatelessWidget`. La contrapartida es que la
  contraseña queda en una señal global, así que se limpia en cuanto se usa. Nota:
  limpiar la señal no borra lo que muestra el `TextField`, que tiene su propio
  estado interno; no molesta porque después de entrar se navega y el widget se
  destruye.

- **C4 · `OnboardingRepositoryImpl` se implementó completo acá**, no repartido
  entre #9, #11 y #14. Los guards necesitan `loadProfile()`, y dejar los otros
  tres métodos lanzando obligaba a volver a la misma clase dos veces más. #11 y
  #14 quedan como trabajo de presentación y de comportamiento, que es donde está
  su valor.

- **C4 · `setupDependencies()` es idempotente y hay `overrideDependency<T>()`.**
  Los tests montan la app más de una vez en el mismo proceso y necesitan
  reemplazar los repositorios por dobles. Sin eso, probar login, registro,
  logout y los tres guards habría exigido tocar Supabase de verdad.

- **C4 · Para producto, no bloquea**: el AC7 del #9 pedía que las páginas usaran
  `Watch(...)`. Se usa `SignalBuilder`, que es su reemplazo no deprecado. La
  intención del AC —páginas `StatelessWidget` con la región reactiva alimentada
  por signals, sin `setState`— se cumple; lo que cambió es el nombre del widget,
  por la decisión de C1.
