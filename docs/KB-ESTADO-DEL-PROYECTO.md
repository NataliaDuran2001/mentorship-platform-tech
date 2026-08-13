# KB · Estado del proyecto al 2026-07-29 (actualizado tras el PR #54)

Documento de traspaso completo, pensado como base de conocimiento para una IA
que actúe como tutora del avance de Natalia. Todo lo afirmado acá fue
**verificado contra el repo (`main` en `2d0fba3`), el tablero de GitHub y la
base de Supabase el 2026-07-29** — no contra la memoria de sesiones
anteriores. Donde algo no se pudo verificar, se dice.

Complementa, no reemplaza, a los handoffs por épico:
[HANDOFF-E0-BLOQUE-A.md](HANDOFF-E0-BLOQUE-A.md),
[HANDOFF-E0-BLOQUE-B.md](HANDOFF-E0-BLOQUE-B.md) y
[HANDOFF-E1-MODULO-1.md](HANDOFF-E1-MODULO-1.md), que conservan el detalle y la
bitácora de decisiones de su época.

---

## 1. Qué es el producto

Plataforma de mentoría con IA para mujeres en Bolivia que quieren entrar o
crecer en tecnología. El recorrido de la usuaria hoy: se registra con email y
contraseña, confirma su correo, pasa un onboarding que le asigna una ruta de
aprendizaje (track), y avanza por un árbol de tópicos secuenciales resolviendo
micro-laboratorios interactivos. Cada laboratorio completado cierra su tópico y
desbloquea el siguiente. Desde el PR #54, la IA acompaña el recorrido: un
brief diario personalizado en el dashboard, un mensaje de coach en el roadmap,
pistas en los laboratorios y análisis de perfil en el cuestionario guía.

| Decisión de negocio | Valor | Origen |
|---|---|---|
| Público | Mujeres en Bolivia entrando a tech | Spec de producto |
| Tracks | Exactamente 3: `frontend`, `backend`, `infrastructure`. Mobile y UI/UX quedaron fuera aunque aparecen en mockups | Decisión cerrada en E1 |
| Auth del MVP | Email/contraseña con confirmación por correo obligatoria. Google OAuth diferido a post-MVP (#15) | Decisión cerrada en E0/E1 |
| Idioma | UI y código en **inglés**; issues y documentación en **español** | Decisión del 2026-07-27, issue #35 |
| Marca | **Sin decidir.** Todo nombre de producto pasa por `AppBranding.name` | Abierta |
| Proveedor de IA | **Kimi3 (`kimi-k3`, Moonshot AI)** vía Edge Functions — decisión **de facto** del PR #54, sin registro de decisión. El issue #37 (E2) proponía Claude como default. Ver §4.2 | PR #54, 2026-07-29 |
| Quién escribe el currículum | Nadie a mano: una administradora carga material a una knowledge base y la IA genera el árbol de tópicos | Decisión del 2026-07-27, issue #37 (E2, sin implementar) |
| Plantillas de correo | En inglés (default de Supabase). Traducciones listas en el cierre del #3 si se revierte | Decisión de la dueña |

El spec de producto tiene módulos 1 a 6. **Solo el Módulo 1 está bajado a
issues y entregado.** Los módulos 2–6 no tienen ni desglose. El trabajo de IA
del PR #54 no corresponde a ningún módulo desglosado.

**Personas.** El repo dejó de ser unipersonal: el PR #54 es de un segundo
colaborador, **Sebastian Gonzales Tito (`Sebas21gt`)**. Natalia
(`NataliaDuran2001`) es la dueña del repo y quien mergea.

---

## 2. Estado técnico verificado (2026-07-29)

```
fvm flutter analyze --fatal-infos  → No issues found!
fvm flutter test                   → All tests passed! (132 tests)
```

| Qué | Estado real |
|---|---|
| Rama | `main` en `2d0fba3` (merge del PR #54), protegida (check `analyze-y-test` obligatorio, `enforce_admins: true`) |
| Toolchain | Flutter 3.44.2 vía FVM · Dart 3.12.2 · prefijar todo con `fvm` |
| Árbol de trabajo | Sin código pendiente. Solo tooling local sin commitear: `.mcp.json` modificado, `.claude/`, `.agents/`, `skills-lock.json` y este documento |
| CI | GitHub Actions corre `analyze --fatal-infos` + `test` en cada PR |
| Supabase | Proyecto `dtvfucqamakudgbwuhbw`. 7 tablas en `public`, **todas con RLS habilitado** |
| Migraciones | **Historial remoto y repo coinciden 1:1** (10 versiones). La deriva que denunciaba el #49 fue reparada — el issue sigue abierto solo por su parte de documentación y cierre |
| Edge Functions | 4 desplegadas y `ACTIVE`, todas con `verify_jwt: true`: `analyze-profile`, `daily-brief`, `roadmap-coach`, `lab-hint` |
| Advisor de seguridad | **1 WARN**: `auth_leaked_password_protection` deshabilitado (issue #43, tarea manual de dashboard). Las funciones y la tabla nuevas no agregaron lints |

Contenido real de la base:

| Tabla | Filas | Nota |
|---|---|---|
| `tracks` | 3 | `frontend`, `backend`, `infrastructure` |
| `topics` | 9 | 3 por track, **árbol plano** (ningún `parent_id`). Currículum real en inglés |
| `lab_challenges` | 12 | frontend 5, backend 4, infrastructure 3. Tipos: opción múltiple, ordenar bloques, completar espacios |
| `profiles` | 3 | Cuentas de prueba. Incluyen columna `role` (estudiante/administradora, #36) |
| `user_progress` | 1 | Una fila real — ver la nota sobre el #47 en §5 |
| `onboarding_answers` | 12 | Respuestas de las cuentas de prueba |
| `ai_profile_insights` | **0** | Caché de respuestas de la IA, RLS por dueña. **Cero filas = el flujo de IA nunca corrió contra el backend real** — ver §4.2 |

---

## 3. Qué se entregó, en orden

| Épico / bloque | Qué | Estado |
|---|---|---|
| **E0 · Fundaciones** (#1–#6, #16) | Entorno FVM documentado, tema desde el design system Luminous Clarity, `go_router` + shell de navegación responsivo, integración Supabase con DI, CI, y hardening de una función expuesta como RPC | **Cerrado al 100%** |
| **E1 · Módulo 1: Onboarding y roadmap** (#7–#14) | Esquema con RLS y verificación reproducible (`supabase/tests/rls_modulo_1.sql`), capa de dominio completa, auth real (registro, confirmación, login, sesión persistente, guards, logout), onboarding de 4 pasos con rama de cuestionario guía (5 pasos), persistencia y reanudación, árbol de tópicos con secuencialidad | **Cerrado al 100%**, validado de punta a punta contra el backend real por la dueña el 2026-07-27 |
| **Transversal post-E1** | #35 migración de UI y código a inglés · #36 modelo de roles con RLS por rol (una estudiante **no puede** autopromoverse a administradora, forzado en la base) · #33 revelar contraseña · #34 pantalla propia para el enlace de confirmación | #35, #36, #33 cerrados · #34 con 5/6 AC (ver §5) |
| **Perfil + micro-labs** (PR #46, sin issue previo) | Página de perfil, entidad y repositorio de laboratorios, 3 tipos de reto interactivo, currículum real sembrado, dashboard | Mergeado y funcional, **entró fuera del proceso** — ver §4.1 |
| **Progreso del roadmap** (PR #52 → #47) | `CompleteTopicUseCase`: completar un laboratorio marca el tópico y desbloquea el siguiente, con manejo de error y reintento | Código mergeado, issue **abierto** esperando validación manual |
| **Pulido de demo** (PR #53 → #48) | Textos del perfil que quedaron en español | Cerrado |
| **Módulo AI-first** (PR #54, sin issue previo, autor `Sebas21gt`) | Capa de IA completa: contrato `AiRepository` en dominio con `AiFailure` tipado, `AiRepositoryImpl` que invoca 4 Edge Functions (brief diario, coach del roadmap, pistas de labs, análisis de perfil), caché en `ai_profile_insights` (24 h para el brief), `RecommendTrackUseCase` ahora consulta la IA con **fallback determinístico** a la regla de votos si falla, dashboard rediseñado (+360 líneas) | Mergeado con CI verde y desplegado, **entró fuera del proceso y sin revisión** — ver §4.2. Sin validar contra el backend real |

---

## 4. La verdad incómoda — leer sin maquillar

Nada de esto rompe la app hoy; todo esto cuesta más caro mañana.

**1. El PR #46 rompió el proceso que el propio proyecto se dio.** Todo el
trabajo de E0/E1 siguió un pipeline disciplinado: issue con criterios de
aceptación → rama → implementación → validación AC por AC con evidencia → PR →
merge. El PR #46 (perfil + laboratorios + currículum + dashboard) entró sin
issue previo, con commits genéricos y migraciones aplicadas a mano. La revisión
posterior lo convirtió en tres issues de deuda (#49, #50, #51) — eso estuvo
bien hecho. Pero ya no es un caso aislado: ver el punto siguiente.

**2. El PR #54 (AI-first) repitió el patrón, ahora con un colaborador nuevo y
sin revisión.** Sin issue previo, sin labels, **sin revisores** y mergeado el
mismo día. Es la segunda de las últimas tres features que saltea el pipeline —
el patrón se está volviendo la norma para el trabajo nuevo. Sobre el contenido,
lo bueno y lo malo, con evidencia:

- **Bien resuelto**: la clave del proveedor (`KIMI_API_KEY`) vive solo en el
  entorno de las Edge Functions — nunca en el bundle ni en el repo, que era la
  regla dura del #37. Las 4 funciones exigen JWT, verifican el usuario, y
  `ai_profile_insights` tiene RLS por dueña. Hay degradación elegante: si la
  IA falla, la recomendación de track cae a la regla determinística de votos y
  el resto muestra mensajes estáticos.
- **Decisión de producto tomada de facto y sin registro**: el proveedor es
  Kimi3 (`kimi-k3`, Moonshot AI), cuando el #37 proponía Claude como default.
  Puede ser una decisión válida (costo, acceso), pero hoy no está escrita en
  ningún lado más que en el código. Los datos de perfil y progreso de las
  usuarias **viajan a un tercero** (Moonshot) — eso es una decisión de negocio
  y de privacidad, no técnica, y nadie la registró como tal.
- **Validado de punta a punta el 2026-07-29 — después de encontrar y arreglar
  un bug**: la primera prueba real falló con 502 en todas las funciones. Causa
  (del log de la Edge Function): `kimi-k3` solo acepta su temperatura por
  defecto y las 4 funciones mandaban valores propios (0.3–0.8) →
  `400 invalid temperature`. Se quitó el parámetro en los 4 archivos y se
  redesplegaron `daily-brief` y `lab-hint` (v5); **`roadmap-coach` y
  `analyze-profile` quedaron corregidas en el repo pero sin redesplegar** (el
  permiso de deploy fue bloqueado). Tras el fix: brief diario personalizado
  visible en el dashboard, pista socrática real en un lab, y 2 filas en
  `ai_profile_insights` con `model: kimi-k3`. **El fix está solo en el árbol
  local: falta commit y PR.**
- **Sin tests propios**: el PR adaptó tests existentes (el fallback del
  `RecommendTrackUseCase` sí quedó cubierto), pero `AiRepositoryImpl` y el
  parseo de las respuestas no tienen cobertura, y las Edge Functions (TypeScript)
  no tienen ningún test.
- **Basura commiteada**: `supabase/.temp/` (artefactos del CLI: pooler URL,
  versiones, project ref) entró al repo. No expone secretos —no hay contraseña
  en la URL— pero no debería estar versionado; falta gitignorarlo.
- **Semántica alterada sin discutir**: `wasTie` ahora también se enciende si la
  confianza de la IA es < 0.85 o si hay alternativas — ya no significa solo
  «empate de votos». El comportamiento visible (pedir confirmación) es
  coherente, pero el nombre miente.

**3. El historial de migraciones ya no miente — el tablero sí, un poco.** La
deriva que denunciaba el #49 fue reparada: las 10 versiones remotas coinciden
1:1 con `supabase/migrations/`, incluidas las dos de labs y la de
`ai_profile_insights`. El issue #49 sigue `status:pendiente` aunque su problema
de fondo está resuelto; queda su parte de documentación en `docs/SUPABASE.md` y
el cierre con evidencia.

**4. Laboratorios, perfil e IA casi no tienen tests (#51, ampliado de facto).**
De los 132 tests, la enorme mayoría cubre el Módulo 1. La validación de
respuestas de los 3 tipos de reto, el mapeo del `content` jsonb —que revienta
en runtime si falta una clave— y ahora toda la capa de IA se verifican jugando
a mano. La suite en verde da una confianza que en estas zonas no está
respaldada. El #51 se escribió antes del PR #54 y **no menciona la capa de IA**:
está desactualizado en alcance.

**5. CLAUDE.md está gravemente desactualizado.** Todavía describe el proyecto
como «scaffold con una pantalla de login y auth simulada», lista como «gaps
conocidos» cosas resueltas hace días, y no menciona `go_router`, los guards, el
onboarding, los labs, los roles ni la capa de IA. Cualquier agente de IA que
arranque leyéndolo trabaja con un mapa falso. Es la deuda de documentación más
urgente y no tiene issue.

**6. El design system vive fuera del repo.** La fuente de verdad de «Luminous
Clarity» es un `DESIGN.md` en `C:\Users\Natalia\Downloads\...` — una carpeta de
descargas de **otra máquina** (esta máquina es `natalia.duran`). Si ese archivo
se pierde, el design system queda solo en lo ya traducido a `AppTheme`. Las
notas de entorno del handoff de E1 también refieren a la máquina anterior.

**7. Deuda de convenciones registrada y sin pagar.** #50 (labs/perfil), #39
(7 hallazgos de higiene, incluidos comentarios que mienten sobre el código) y
#40 (el repo **no** está `dart format` limpio; el formato es disciplina manual,
no verificación de máquina — y acaban de entrar 2.300 líneas nuevas).

**8. Seguridad: un WARN real y accionable.** La protección contra contraseñas
filtradas sigue apagada (#43) y el mínimo de contraseña es 6 caracteres. Con
auth de solo contraseña y sin 2FA, es el eslabón más débil del sistema. Es una
pantalla del dashboard.

---

## 5. Tablero: lo abierto, con su estado real

El tablero **no refleja el trabajo de IA**: el PR #54 no tiene issue, y los
issues de deuda que le corresponderían (tests, decisión de proveedor, gitignore
de `.temp`) no existen todavía.

| Issue | Qué | Estado real |
|---|---|---|
| #47 | Completar un laboratorio persiste el progreso | `status:en-curso`. Código mergeado (PR #52), 3/7 AC con evidencia, **4 AC esperan validación en navegador**. Hay 1 fila en `user_progress`, lo que sugiere que alguien ya jugó un lab contra el backend real — pero el cierre no está registrado en el issue |
| #34 | El enlace de confirmación aterriza en pantalla propia | `status:bloqueada`, 5/6 AC. Falta **un** clic humano: registrarse con una casilla real y abrir el enlace. Se cerró solo por un `Closes` mal redactado y fue reabierto — la regla de no cerrar con AC pendientes se sostuvo |
| #49 | Registrar las migraciones de labs en el historial | **Su problema de fondo ya está resuelto** (historial 1:1 con el repo). Queda documentar en `docs/SUPABASE.md` y cerrar con evidencia |
| #50 | Deuda de convenciones de labs y perfil | Pendiente, chico |
| #51 | Tests de laboratorios y perfil | Pendiente, mediano. **Desactualizado**: no cubre la capa de IA del PR #54. El más importante de los de deuda |
| #43 | Activar protección de contraseñas filtradas | Pendiente, manual (dashboard) |
| #40 | Adoptar `dart format` + check en CI | Pendiente. Decisión de fondo: formato verificado por máquina vs disciplina humana |
| #39 | Higiene detectada en la migración de idioma | Pendiente, chico |
| #37 | **E2**: knowledge base y generación de roadmaps con IA | Encabezado de épico, sin desglosar. El PR #54 le pisó una decisión (proveedor) sin resolver el épico — ver §7 |
| #15 | Google OAuth | Post-MVP, deliberadamente intocable |

**Validaciones manuales — estado al 2026-07-29 (madrugada):**

1. **#47 — validado en la práctica, falta registrarlo en el issue.** La dueña
   jugó el lab de Docker completo: tópico marcado `Completed`, siguiente
   desbloqueado, 33% en pantalla, 2 filas en `user_progress` (una por tópico
   completado, sin duplicados). Hay screenshots en
   `Documents\Grant Aspire\screenshots - app mentorship`. Falta el comentario
   de validación y el cierre en GitHub.
2. **#34 — AC5 validado en la práctica, falta registrarlo.** Registro con
   casilla real (`duranolivanatalia42@gmail.com`), el enlace aterrizó en la
   pantalla «Email confirmed». Screenshot disponible. Falta comentario y
   cierre.
3. **#43 — sigue pendiente**: activar el toggle en el dashboard y probar
   registrarse con `password123`.
4. **Flujo de IA — brief y pistas validados** (ver §4.2). Pendiente: probar el
   análisis de perfil del cuestionario guía y el coach del roadmap **después**
   de redesplegar sus funciones, que hoy siguen con el bug en producción.

---

## 6. Decisiones técnicas vigentes (las que un tutor debe conocer)

Las bitácoras completas están en los §9 de los handoffs. Lo esencial:

- **Clean architecture + atomic design como grilla obligatoria.** Dependencia
  hacia adentro (`presentation → domain ← data`), `domain` en Dart puro, átomos
  libres de contexto, solo las páginas tocan estado y DI. Cada archivo declara
  su capa en un comentario de apertura.
- **Estado con signals, no `setState`.** `SignalBuilder` (nunca `Watch`, que
  está deprecado). Derivados como `computed` — la UI no puede declararse
  autenticada. `HoverBuilder` es el único `StatefulWidget` sancionado (aunque
  `LabPage` lo viola hoy, ver #50).
- **Los archivos `*_actions.dart` son los únicos de `presentation` que tocan
  `getIt`.** Los widgets llaman funciones.
- **Las páginas de auth no navegan: redirigen los guards.** Un `context.go()`
  en la página competiría con el guard.
- **Toda llamada a IA pasa por una Edge Function** (patrón del PR #54): la
  clave del proveedor vive en el servidor, la función verifica el JWT y el
  usuario, y la respuesta se cachea en `ai_profile_insights` (24 h el brief).
  Toda feature de IA degrada con elegancia: fallback determinístico o mensaje
  estático, nunca una pantalla rota.
- **Invariantes duplicadas en la base a propósito**: RLS en toda tabla con
  políticas explícitas; «completado exige track» como `CHECK`; el rol es
  inmutable por trigger; orden único entre hermanos. La UI puede tener bugs,
  el constraint no.
- **Reglas de proceso**: nada entra a `main` sin CI verde; ningún issue se
  cierra con un AC sin cumplir; las migraciones van versionadas y se aplican
  desde el repo (regla violada una vez y reparada, ver §4.3); ni `service_role`
  ni credenciales en el repo; los tópicos bloqueados no son tocables ni por
  accidente.
- **Verificación de RLS reproducible**: `supabase/tests/rls_modulo_1.sql`
  (transacción con ROLLBACK, 13 pruebas). Re-correrlo cada vez que cambien las
  políticas — el #36 y `ai_profile_insights` agregaron políticas después de su
  última corrida registrada, y el guion **no cubre la tabla nueva**.

---

## 7. Futuro: qué sigue y qué hay que decidir

**Orden razonable del trabajo pendiente** (criterio: pagar la deuda que
abarata lo que viene, antes de construir encima):

1. Validar el flujo de IA contra el backend real (§5.4) — hoy es la feature
   más nueva y la única que nunca corrió de verdad.
2. Cerrar las otras 3 validaciones manuales (§5) — es una sesión.
3. Poner el tablero al día: cerrar #49 (ya reparado), crear los issues del
   PR #54 (tests de la capa de IA, gitignore de `supabase/.temp`, registro de
   la decisión de proveedor) y actualizar el alcance del #51.
4. #51 ampliado: tests de labs, perfil e IA. E2 va a construir exactamente
   sobre estas zonas.
5. #40 (`dart format` + CI) antes de que E2 agregue decenas de archivos.
6. Actualizar CLAUDE.md al estado real (sin issue todavía — crearlo).
7. Planificar E2 (#37): desglosarlo en issues con AC, como se hizo con E1.

**Decisiones abiertas que hay que cerrar explícitamente** (son de producto o
de arquitectura, no se resuelven codificando):

| Decisión | Contexto |
|---|---|
| Proveedor de IA — ratificar o revertir | El PR #54 instaló Kimi3 (Moonshot) de facto; el #37 proponía Claude. Incluye una arista de privacidad: datos de perfil y progreso de las usuarias viajan al proveedor. Decidir, registrar, y alinear #37 con lo decidido |
| Proceso para colaboradores | Ya hay un segundo colaborador y su primer PR entró sin issue ni revisión. ¿El pipeline issue→AC→PR aplica a todos, y quién revisa? Sin esto, la protección de `main` solo verifica que compile |
| Formatos de material de la KB (E2) | ¿PDF, Markdown, enlaces, video? |
| Alcance de la generación (E2) | ¿La IA genera el árbol completo o sugiere y la administradora edita? |
| Regeneración vs progreso (E2) | Si un roadmap se regenera, el avance en `user_progress` no puede perderse |
| Marca del producto | Sigue sin nombre |
| Paso omitido en el onboarding | ¿Se recuerda como omitido (comportamiento actual) o se vuelve a ofrecer? Pendiente de formalizar como CA 4 de la Historia 1.1 |
| Mínimo de contraseña | 6 caracteres es el default de Supabase y es poco (ver #43) |

---

## 8. Para la tutoría: lectura honesta del avance

Lo que el repo permite afirmar con evidencia:

- **El proceso es la fortaleza principal del proyecto — y está en erosión.**
  E0 y E1 son ejemplo de disciplina real: issues con criterios de aceptación,
  validación con evidencia AC por AC, la regla de no cerrar a medias sostenida
  incluso cuando GitHub cerró un issue solo (#34 fue reabierto), deuda
  registrada como issues, decisiones documentadas con su porqué. Pero dos de
  las últimas tres features (PR #46 y PR #54) saltearon ese pipeline por
  completo. La reacción al #46 fue la correcta (auditar y registrar deuda);
  al #54 todavía no se le hizo esa auditoría — este documento es lo más
  cercano que existe.
- **El rol demostrado por Natalia en el historial es el de dueña de producto y
  validadora**: decisiones de alcance (tracks, idioma, KB con IA), validación
  manual de punta a punta contra el backend real, gestión del tablero y
  merges. La ejecución del código la hizo mayormente el pipeline con Claude
  Code como ejecutor, y el módulo de IA lo aportó un colaborador. Este
  documento no puede medir cuánto del código Natalia escribió o entiende a
  fondo, y **un tutor no debería asumirlo en ninguna dirección: debería
  sondearlo**.
- **Zonas que más rinden como material de tutoría**, porque el proyecto las usa
  de verdad: RLS y el modelo de seguridad de Supabase (incluida la trampa de
  revocar `PUBLIC` sobre funciones de trigger), signals vs `setState` y por qué
  los derivados son `computed`, la regla de dependencia de clean architecture,
  route guards como única fuente de navegación, por qué las invariantes se
  duplican en la base, y —nuevo con el PR #54— por qué las claves de IA viven
  en Edge Functions, qué es la degradación elegante, y qué implica mandar
  datos de usuarias a un proveedor de IA externo.
- **La lección de gestión más valiosa disponible hoy**: el contraste entre E1
  (pipeline completo, cero deuda registrada) y los PRs #46/#54 (fuera de
  pipeline, deuda real). Con la entrada de un segundo colaborador, la pregunta
  ya no es solo de disciplina personal sino de gobernanza del repo: revisar
  PRs ajenos, exigir issue previo, y registrar las decisiones que un PR toma
  de facto — como el proveedor de IA — antes de que el código las vuelva
  irreversibles por inercia.
