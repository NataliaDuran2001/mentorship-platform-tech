# HANDOFF EJECUTABLE · E0 Bloque B · Cierre de las fundaciones

Continuación de [`HANDOFF-E0-BLOQUE-A.md`](HANDOFF-E0-BLOQUE-A.md). Este documento
es autosuficiente: no necesitas la conversación que lo originó, ni haber corrido
el bloque A. Contiene el estado real del repo, las decisiones cerradas y las 3
tareas que quedan para terminar el épico E0.

**El tablero de GitHub es la fuente de verdad del estado.** Los criterios de
aceptación canónicos viven en el cuerpo de cada issue y en sus comentarios, no
acá. Este documento resume y da contexto; **el issue manda**.

Repo: `NataliaDuran2001/mentorship-platform-tech`

---

## 1. Cómo ejecutar

Una tarea por iteración. En cada una:

**Sincronizar**

1. Leer el tablero y reescribir la tabla de §4 con lo que devuelva:
   ```
   gh issue list --repo NataliaDuran2001/mentorship-platform-tech \
     --state all --json number,title,state,labels \
     --jq '.[] | "#\(.number) \(.state) \(.labels|map(.name)|join(","))"'
   ```
2. Cruzar con `git log --oneline -10`. Si el tablero y el repo discrepan, **gana
   el repo**: corregir el tablero, no al revés.

**Elegir y abrir**

3. Tomar la primera tarea de §5 con `status:pendiente` cuyas dependencias estén
   cerradas o `status:hecha`.
4. Leer el issue **completo, incluidos los comentarios**. El #2 tiene un
   comentario de avance parcial que dice qué **no** hay que volver a hacer:
   ```
   gh issue view N --repo NataliaDuran2001/mentorship-platform-tech --comments
   ```
5. Marcarlo en curso:
   ```
   gh issue edit N --repo NataliaDuran2001/mentorship-platform-tech \
     --add-label "status:en-curso" --remove-label "status:pendiente"
   ```

**Implementar**

6. Leer los archivos que la tarea nombra **antes** de escribir.
7. Implementar completa.
8. Correr el comando de verificación. Si falla, arreglar; no avanzar con la
   verificación roja.
9. Commit en la rama `feat/e0-fundaciones` con el mensaje indicado.

**Cerrar**

10. Validar los criterios de aceptación uno por uno siguiendo **§6**. No es
    opcional ni resumible.
11. **Sincronizar el tablero siempre**: publicar el comentario de validación,
    mover las labels, cerrar o bloquear, y **asignar el issue a
    `NataliaDuran2001`** con `--add-assignee`. Esto no requiere pedir permiso:
    es parte del trabajo.
12. Actualizar la tabla de §4 con el resultado y el SHA corto.
13. Si no queda ninguna tarea ejecutable, ir a §8 y detenerse.

**Rama:** todo va a `feat/e0-fundaciones`, que **ya existe**. El push y el PR
**ya están autorizados** por la dueña del repo; el PR se abre dentro del
procedimiento de validación de B2, no antes.

**No afirmes acá el número de commits ni si la rama está pusheada.** Son hechos
volátiles que quedan obsoletos entre iteraciones y ya causaron una contradicción
en este documento. Consultalos siempre en vivo:
`git log --oneline` y `git ls-remote --heads origin`.

---

## 2. Estado real del repositorio

App Flutter de una plataforma de mentoría con IA para mujeres en Bolivia. Hoy:
una pantalla de login con autenticación **simulada** y el cliente de Supabase
integrado.

| | |
|---|---|
| Rama de trabajo | `feat/e0-fundaciones`. `main` sigue intacta en `f7d41cb`. Estado del push y cantidad de commits: **consultar en vivo**, no están fijados acá |
| Toolchain | Flutter **3.44.2** vía FVM (`.fvmrc`) · Dart **3.12.2**. Prefija todo con `fvm` |
| Backend | Supabase, proyecto `dtvfucqamakudgbwuhbw`. Sin tablas, `auth.users` en **0**. El schema `public` **no está vacío**: ver "Hallazgo del schema" abajo |
| Tablero | 14 issues. E0 = #1–#6, E1 = #7–#14 |
| Design system | "Luminous Clarity" · `C:\Users\Natalia\Downloads\mentor_ai\stitch_femtech_mentor_ai\luminous_clarity\DESIGN.md` (fuera del repo) |
| Doc de arranque | [`docs/DEVELOPMENT.md`](DEVELOPMENT.md), verificado clonando en limpio |

### Ya hecho en la rama

| Commit | Qué |
|---|---|
| `838ec6f` | **#1 cerrado.** `test/widget_test.dart` reescrito (3 tests verdes), `.gitattributes`, borrado del basura `3.10`, `docs/DEVELOPMENT.md` enlazado desde el README |
| `4dfb0d0` | **#4 cerrado, `status:hecha`.** Cliente de Supabase integrado: `supabase_config.dart` versionado, `SupabaseClient` en `getIt`, `publishableKey` en vez del deprecado `anonKey`, `environment.sdk` a `^3.10.0`. El AC1 fue reformulado y aplicado al cuerpo del issue: "establece sesión" pasó al #9, este issue solo integra el cliente |
| `2d484f6` | **#2 avance parcial.** Sección `fonts:` de Geist declarada, `assets/fonts/` versionado con su `OFL.txt`, `fontFamily` repetido eliminado de 4 `TextStyle` |
| `0b7d8fc` | Bitácora de desviaciones en la §9 del bloque A |

### Entorno, ya resuelto — no volver a investigarlo

- **FVM instalado**, SDK 3.44.2 en `C:\Users\Natalia\fvm\versions\3.44.2`.
- **Modo Desarrollador de Windows activado.** Sin él, `pub get` falla con
  `Building with plugins requires symlink support`.
- El **primer build web en debug tarda ~100 s** antes de pintar. La pestaña en
  blanco durante ese rato no es un error.
- `Failed to connect to the web debug service: TimeoutException after 0:00:05`
  es un flake de DWDS con la máquina cargada: reintentar el `run`.
- `.gitattributes` ya normaliza los finales de línea. `git status` en un clon
  limpio sale vacío.

### Hallazgo del schema — no es trabajo de E0, importa para el #7

El schema `public` no tiene tablas, pero **no está vacío**: hay un event trigger
activo, `ensure_rls`, que ejecuta la función `rls_auto_enable()` en cada
`ddl_command_end`. En todo `CREATE TABLE` sobre `public` corre
`alter table ... enable row level security` automáticamente.

Dos consecuencias para el #7, no para este bloque:

1. El AC1 del #7 ("todas las tablas con `rls_enabled: true`") **se cumple solo**.
   Lo que hay que escribir a mano son las **políticas**, no el `enable`.
2. El riesgo se invierte: una tabla con RLS activo y **cero políticas** queda
   silenciosamente inaccesible, y ahora ese es el estado por defecto.

También había un warning del advisor de seguridad: `anon` y `authenticated`
tenían `EXECUTE` sobre `rls_auto_enable()`, que es `SECURITY DEFINER`. En la
práctica no era explotable — la función retorna `event_trigger` y Postgres
rechaza invocar ese tipo de funciones directamente — pero el grant no tenía
propósito, porque el trigger la ejecuta como owner.

**Resuelto** por decisión de la dueña del repo, como cambio propio fuera de
B1–B3: issue **#16** (cerrado, 4/4 AC), migración
`supabase/migrations/20260726073609_revoke_execute_rls_auto_enable.sql`, commit
`b948568`. El REVOKE se extendió a `PUBLIC` porque el ACL traía `=X/postgres`,
del que ambos roles heredaban; ver la validación en el #16. `get_advisors`
(security) quedó **sin lints**.

---

## 3. Invariantes — violarlas es un defecto, no una opción

### Decisiones de producto cerradas

| Decisión | Valor |
|---|---|
| Idioma | UI y comentarios en **español**. Identificadores y código en inglés |
| Marca | **Sin decidir.** Todo nombre de producto pasa por `AppBranding.name` |
| Tracks del roadmap | `frontend`, `backend`, `infrastructure` |
| Router | `go_router` |

### Reglas de arquitectura (de `CLAUDE.md`)

- **Clean architecture**, dependencia hacia adentro: `presentation → domain ← data`.
  `presentation` nunca importa `data`.
- `domain` es **Dart puro**: sin Flutter, sin JSON, sin paquetes externos.
- **Atomic design** en `lib/presentation/widgets/`: `atoms/` → `molecules/` →
  `organisms/` → `pages/`. Cada nivel compone solo desde los de abajo. Los
  átomos son libres de contexto y reciben comportamiento por callback. **Solo
  las páginas tocan estado o DI.**
- **Estado con señales**: `signal<T>` global en `lib/presentation/state/`.
  Widgets `StatelessWidget`, región reactiva en `Watch((context) { ... })`.
  **Nunca `setState`.**
- **DI con get_it**: todo por `getIt`. Ningún widget construye repositorios ni
  casos de uso.
- **Supabase**: la capa `data` toma `SupabaseClient` de `getIt`. **Nunca
  `Supabase.instance.client`** fuera de `supabase_config.dart`.
- Imports entre capas **relativos** (`../../domain/...`), no `package:aspire_app/...`.
- Cada archivo nuevo bajo `lib/` abre con un comentario en español nombrando su capa.
- **Cero colores o spacing literales en widgets.** Todo de `AppColors` y `AppConstants`.

### Prohibido

- Tocar issues #7–#14 o escribir código de E1 (onboarding, auth real, roadmap).
  **Ya pasó una vez y hubo que revertirlo entero**; ver la §9 del bloque A.
- Tocar el issue #3: está etiquetado `manual` y no es codificable (§7).
- Cambiar cualquier decisión de §3. Si crees que una está mal, anótalo en §9 y sigue.
- Cerrar un issue con criterios de aceptación sin cumplir (§6).
- Commitear una llave `service_role` de Supabase.
- Inventar contenido de currículum. No es parte de E0.
- Push o PR sin pedirlo.

### Deuda conocida que vas a encontrar

`Watch` está **deprecado** en signals_flutter 7.1 a favor de `SignalBuilder`.
§3 fija `Watch` como decisión cerrada, pero el aviso de deprecación hace que
`analyze` termine en exit 1. La solución actual es un
`// ignore: deprecated_member_use` localizado en `login_page.dart`, con el motivo
escrito ahí. **Esto importa para B2**: `analyze --fatal-infos` pasa solo porque
el aviso está suprimido a mano. Si migras a `SignalBuilder`, hay que actualizar
§3 de este documento y `CLAUDE.md` en el mismo commit.

---

## 4. Espejo del tablero — reescribir desde `gh` en cada iteración

Estado al momento de escribir este documento. **No es autoritativo**.

| Tarea | Issue | Estado | Depende de | Commit |
|---|---|---|---|---|
| ~~A1 · Entorno y línea base verde~~ | #1 | `status:hecha` · **cerrado** | — | `838ec6f` |
| ~~A2 · Integración de Supabase~~ | #4 | `status:hecha` · **cerrado**, 4/4 AC | A1 | `4dfb0d0` |
| ~~B1 · Design system a tema Flutter~~ | #2 | `status:hecha` · **cerrado**, 5/5 AC | A1 | `f1567f3` (+ `2d484f6` parcial) |
| **B2 · CI en GitHub Actions** | #6 | `status:pendiente` | A1 | |
| **B3 · Router y shell responsivo** | #5 | `status:pendiente` | **B1** | |

Extra fuera de B1–B3: **#16** (revocar EXECUTE de `rls_auto_enable()`) cerrado,
4/4 AC, commit `b948568`. Ver §2 y §9.

Los tres issues abiertos de E0 están asignados a `NataliaDuran2001`.

**Orden recomendado: B1 → B2 → B3.** B3 depende de B1 porque necesita
`containerMax`, `sidebarWidth` y los breakpoints. B2 es independiente, pero
conviene después de B1 para que el primer CI corra sobre la paleta ya corregida.

---

## 5. Tareas

### B1 · Design system Luminous Clarity al tema — issue #2

**Problema.** `DESIGN.md` define 40+ tokens de color, 7 niveles tipográficos,
grid de 4px, radios y elevación. El repo tiene **6 colores** y **2 constantes**,
con valores desviados.

**La causa raíz del desvío, y la trampa a evitar:** `DESIGN.md` se contradice
consigo mismo. Su **prosa** (sección *Elevation & Depth*) dice
`surface #f8fafc` y `border #e2e8f0` — exactamente los valores equivocados que
están hoy en `app_colors.dart` —, mientras su **frontmatter YAML** dice
`surface #f7f9fb` y `outline-variant #cac4d4`. **La fuente de verdad es el
frontmatter.** Ignora los hex que aparezcan en la prosa.

Desvíos actuales, verificados contra el frontmatter:

| Constante actual | Valor actual | Correcto | Nota |
|---|---|---|---|
| `AppColors.primary` | `#A78BFA` | **`#674BB5`** | el actual es `primary-container` |
| `AppColors.secondary` | `#7C3AED` | **`#712AE2`** | |
| `AppColors.tertiary` | `#AF9E00` | **`#6A5F00`** | el actual es `tertiary-container` |
| `AppColors.neutral` | `#F8FAFC` | **`#F7F9FB`** | renombrar a `surface` |
| `AppColors.border` | `#E2E8F0` | **`#CAC4D4`** | renombrar a `outlineVariant` |
| `AppColors.textHeadline` | `#1E293B` | **`#191C1E`** | renombrar a `onSurface` |

**Tokens de color del frontmatter** (usa estos nombres, en camelCase):

```
surface #f7f9fb · surfaceDim #d8dadc · surfaceBright #f7f9fb
surfaceContainerLowest #ffffff · surfaceContainerLow #f2f4f6
surfaceContainer #eceef0 · surfaceContainerHigh #e6e8ea
surfaceContainerHighest #e0e3e5 · surfaceVariant #e0e3e5
onSurface #191c1e · onSurfaceVariant #494552
inverseSurface #2d3133 · inverseOnSurface #eff1f3
outline #7a7583 · outlineVariant #cac4d4 · surfaceTint #674bb5
primary #674bb5 · onPrimary #ffffff · primaryContainer #a78bfa
onPrimaryContainer #3c1989 · inversePrimary #cebdff
secondary #712ae2 · onSecondary #ffffff · secondaryContainer #8a4cfc
onSecondaryContainer #fffbff
tertiary #6a5f00 · onTertiary #ffffff · tertiaryContainer #af9e00
onTertiaryContainer #3b3500
error #ba1a1a · onError #ffffff · errorContainer #ffdad6
onErrorContainer #93000a
primaryFixed #e8ddff · primaryFixedDim #cebdff · onPrimaryFixed #21005e
onPrimaryFixedVariant #4f319c
secondaryFixed #eaddff · secondaryFixedDim #d2bbff · onSecondaryFixed #25005a
onSecondaryFixedVariant #5a00c6
tertiaryFixed #f8e454 · tertiaryFixedDim #dbc839 · onTertiaryFixed #201c00
onTertiaryFixedVariant #504700
background #f7f9fb · onBackground #191c1e
```

**Escala tipográfica del frontmatter** (todos `Geist`):

| Nivel | Tamaño | Peso | Line height | Letter spacing |
|---|---|---|---|---|
| `headlineLg` | 32 | 600 | 40 | -0.02em |
| `headlineMd` | 24 | 600 | 32 | -0.01em |
| `headlineSm` | 20 | 500 | 28 | — |
| `bodyLg` | 16 | 400 | 24 | — |
| `bodyMd` | 14 | 400 | 20 | — |
| `labelMd` | 12 | 500 | 16 | 0.02em |
| `code` | 13 | 400 | 20 | — |

**Spacing y radios del frontmatter:** unidad 4px · `xs:4 sm:8 md:16 lg:24 xl:40`
· `containerMax:1200` · `sidebarWidth:260` · radios `sm:4 default:8 md:12 lg:16
xl:24 full:9999` · breakpoints **768** (tablet, sidebar colapsa a drawer) y
**480** (móvil, márgenes a 16) · ancho máximo legible **800** para vistas de texto.

**Hacer.**
1. Reescribir `lib/presentation/utils/app_colors.dart` con el set completo, con
   los nombres del design system.
2. Extender `lib/presentation/utils/constants.dart` con la escala de 4px, los
   radios, `containerMax`, `sidebarWidth`, el máximo de 800 y los breakpoints.
3. Crear `lib/core/theme/app_theme.dart` con el `ThemeData` completo y
   consumirlo desde `main.dart`, que hoy arma el tema inline con
   `ColorScheme.fromSeed`. Especificaciones de componentes, de la prosa de
   `DESIGN.md` (que para componentes **sí** es la fuente, solo sus hex no lo son):
   - Botón primario: fondo `primary`, texto blanco, radio 8, **sin sombra**.
   - Secundario: transparente, borde 1px, texto oscuro.
   - Ghost: sin fondo ni borde, texto violeta.
   - Inputs: fondo blanco, borde 1px; al foco el borde pasa a `primary` con glow
     de 2px del mismo color al 20% de opacidad.
   - Cards: definidas por **borde de 1px, no por sombra**. Sombra muy leve solo
     en hover.
   - Chips: pill, fondo gris claro, texto slate.
   - Ítem de lista seleccionado: tinte violeta al 5% y barra vertical activa de
     2px en el borde izquierdo.
4. Crear `AppBranding` con `name`, único lugar donde vive el nombre del producto.
5. ~~Declarar la sección `fonts:` de Geist~~ — **ya hecho** en `2d484f6`. No lo
   repitas. `Geist` 400/500/600 y `GeistMono` 400 están registrados y la familia
   está declarada una sola vez, en el `ThemeData`.

**Gotcha que te va a romper la compilación.** Renombrar los tokens rompe todos
los call sites. Hay que actualizarlos en el mismo commit:
`lib/main.dart`, `lib/presentation/widgets/pages/login_page.dart`,
`lib/presentation/widgets/atoms/custom_button.dart`,
`lib/presentation/widgets/atoms/custom_input.dart`,
`lib/presentation/widgets/molecules/google_login_button.dart`,
`lib/presentation/widgets/organisms/login_form.dart`.

**Queda un `Colors.grey` literal** en `login_form.dart` (el separador "O"), que
viola la regla de cero colores literales. Corrígelo con el token que
corresponda — probablemente `onSurfaceVariant`.

**Decidir y anotar en §9:** el frontmatter declara `code.fontFamily: Geist`,
pero la prosa habla de mono-integración y en `pubspec.yaml` está registrado
`GeistMono`. Elige uno para el nivel `code` y déjalo escrito.

**Verificar.** `fvm flutter analyze && fvm flutter test` verdes. Buscar
`Color(0x` y literales de padding en `lib/presentation/widgets/`: sin resultados
fuera de `utils/`. Geist renderizando de verdad, comparado contra la fuente del
sistema.

**Cerrable.** Los 5 criterios se validan con código.

**Commit.** `feat(core): aplicar los tokens del design system Luminous Clarity al tema`

---

### B2 · CI en GitHub Actions — issue #6

**Problema.** El repo no tiene ningún workflow. Nada impide que entre a `main`
código que no compila.

**Hacer.**
1. `.github/workflows/ci.yml`, disparado en `pull_request` hacia `main` y en
   `push` a `main`.
2. Instalar Flutter **3.44.2** en el runner — la misma versión de `.fvmrc`. Deja
   un comentario en el YAML obligando a actualizar ambos juntos.
3. Pasos: `flutter pub get` → `flutter analyze --fatal-infos` → `flutter test`.
   En el runner no hay FVM: usa `subosito/flutter-action` con la versión fijada,
   y **sin** el prefijo `fvm`.
4. Cache de dependencias de pub.
5. Activar la protección de `main` por `gh api` exigiendo que el check de CI
   pase. El token tiene `admin: true`, verificado.

**Sobre `--fatal-infos`.** Hoy `analyze` sale limpio, pero solo porque el aviso
de deprecación de `Watch` está suprimido con un `// ignore` en
`login_page.dart`. Con `--fatal-infos` cualquier deprecación nueva rompe el
build, que es lo deseable. Si en B1 aparecen más deprecaciones, arréglalas en
lugar de suprimirlas.

**Verificar los AC1–3 con PR real. Autorizado explícitamente por la dueña del
repo.** Es la única forma de tener evidencia:

1. Push de `feat/e0-fundaciones` y abrir el PR hacia `main`. Confirmar que el
   check corre y pasa → **AC3**.
2. Rama desechable `ci/validate-red` desde `feat/e0-fundaciones` con un error de
   análisis deliberado (una variable sin usar basta). PR en **draft**, confirmar
   que el check falla → **AC1**.
3. En la misma rama, reemplazar el error de análisis por un test roto. Confirmar
   que falla → **AC2**.
4. Cerrar el PR draft y borrar `ci/validate-red`. **No mergearlo nunca.**

Esta autorización es **solo para esto**: el PR de `feat/e0-fundaciones` y el
draft desechable. No cubre mergear a `main`.

**Verificar.** Los tres checks se comportaron como se espera, con los enlaces de
las corridas como evidencia.

**Cerrable.** Sí.

**Commit.** `ci: agregar analyze y test en cada PR`

---

### B3 · Router y shell responsivo — issue #5

**Problema.** La app tiene una sola pantalla y ningún router. El prototipo
necesita al menos 6 destinos y el shell cambia de forma según el ancho.

**Hacer.**
1. Agregar `go_router` a `pubspec.yaml`.
2. `AppRouter` en `lib/core/router/`, con los destinos del prototipo: dashboard,
   chat, lógica, entrevistas, perfil, más login y onboarding.
3. Shell responsivo: bottom navigation en ≤768px, sidebar de 260px arriba de
   eso, drawer en el rango intermedio.
4. Aplicar `containerMax` (1200) y el máximo de 800px para contenido textual.
5. **Login y onboarding fuera del shell**, sin nav visible.
6. Placeholders navegables para los destinos que aún no existen.

**Gotcha que te va a romper los tests.** `MyApp` hoy usa `home: const LoginPage()`
y los 3 tests de `test/widget_test.dart` montan `const MyApp()` esperando ver la
pantalla de login. Al pasar a `routerConfig`, esos tests dejan de compilar o de
pasar. **Hay que actualizarlos en el mismo commit**, no borrarlos: el issue #1
está cerrado con la línea base verde como criterio, y dejarla roja lo invalida.

**Nota, no bloquea.** En el prototipo el bottom nav tiene 4 slots pero aparecen
5 destinos entre pantallas. Es decisión de producto; elige una distribución
razonable y anótala en §9.

**Verificar.** `analyze` y `test` verdes. En `fvm flutter run -d chrome`: se
navega entre todos los destinos, redimensionar cruza 768 y 480 sin scroll
horizontal, la URL refleja la ruta, recargar mantiene la pantalla, y
login/onboarding no muestran nav.

**Cerrable.** Sí.

**Commit.** `feat(core): agregar go_router y el shell de navegacion responsivo`

---

## 6. Validación de criterios de aceptación y cierre

Al terminar de implementar una tarea, **antes** de marcarla hecha:

1. Releer los criterios del cuerpo del issue (`gh issue view N --comments`). Son
   la lista canónica, no el resumen de §5.
2. Recorrerlos **uno por uno**. Para cada uno: cumplido o no, y **con qué
   evidencia**. Evidencia es la salida real de un comando o una observación
   concreta, no "debería funcionar".
3. Publicar el comentario de validación:

```
gh issue comment N --repo NataliaDuran2001/mentorship-platform-tech --body-file <archivo>
```

Formato:

```markdown
## Validación de criterios de aceptación

- [x] **AC1** — <cómo se verificó> · evidencia: `<comando>` → <resultado real>
- [x] **AC2** — …
- [ ] **AC3** — **PENDIENTE**: <razón concreta y de qué depende>

Commit: <sha corto> en `feat/e0-fundaciones`
```

4. Según el resultado:

| Situación | Acción |
|---|---|
| **Todos los AC cumplidos** | `gh issue edit N --add-label "status:hecha" --remove-label "status:en-curso" --add-assignee NataliaDuran2001` y `gh issue close N --reason completed` |
| **Alguno sin cumplir** | `gh issue edit N --add-label "status:bloqueada" --remove-label "status:en-curso" --add-assignee NataliaDuran2001`. **Dejar el issue abierto** |

**Regla dura: no se cierra un issue con un AC en `[ ]`.** Un issue abierto con
4 de 5 cumplidos y el quinto nombrado es información útil; uno cerrado a medias
convierte el tablero en ficción.

**Sincronizar el tablero es obligatorio y no se pide permiso.** Lo que sí se
pide es `git push` y abrir PR — con la única excepción del procedimiento de B2,
ya autorizado.

---

## 7. Bloqueado — no intentar

| Qué | Bloquea | Estado |
|---|---|---|
| **Issue #3 · Configurar Supabase** (label `manual`). Site URL y allow-list de redirects · plantillas de correo en español | Nada. Ya **no** bloquea E0 ni el #9 | Pendiente, de la dueña del repo |
| **Issue #15 · Google OAuth** (labels `manual`, `fase:post-mvp`) | Nada del MVP. Es aditivo sobre el #9 | **Diferido por decisión de producto.** El MVP autentica con email/password |
| ~~Reformulación del AC1 del #4~~ | — | **Resuelto.** Confirmada y aplicada al cuerpo del issue; #4 está cerrado |
| ~~Decidir la confirmación por correo~~ | — | **Resuelto.** Se mantiene activa (`mailer_autoconfirm: false`). El #9 debe construir el estado "revisá tu correo" |

### Decisiones abiertas menores — no bloquean B1–B3

| Qué | Quién decide | Estado |
|---|---|---|
| ~~`.mcp.json` untracked~~ | — | **Resuelto:** versionado en `6efb122`. Verificado que no tiene secretos: solo el endpoint del MCP, el `project_ref` y la lista de features. El `project_ref` ya es público, aparece en la URL de `supabase_config.dart` |
| Nivel `code` de la tipografía: el frontmatter declara `Geist`, pero `GeistMono` está registrado en `pubspec.yaml` y la prosa habla de mono-integración | Quien haga B1 | Elegir uno y anotarlo en §9 |
| Migrar `Watch` a `SignalBuilder` y actualizar §3 y `CLAUDE.md` | Dueña del repo | Recomendado antes de que la deuda de `// ignore` crezca. Ver §3 |
| Distribución del bottom nav: 4 slots para 5 destinos | Quien haga B3 | Elegir y anotar en §9 |

### Rescatar cuando toque el #9 (E1, no ahora)

Dos defectos reales que se detectaron y se revirtieron junto al código de auth
fuera de alcance. Están descritos en la §9 del [bloque A](HANDOFF-E0-BLOQUE-A.md):

1. `main()` hace `await SupabaseConfig.initialize()` **sin `try/catch`**, así que
   cualquier fallo del backend deja pantalla blanca indefinida y sin diagnóstico.
2. `isAuthenticated` es un `signal` escribible y la UI lo pone en `true` a mano.
   Debería ser `computed` derivado de la sesión real.

### Estado real de la autenticación, verificado

`GET /auth/v1/settings` del proyecto devuelve:

| Ajuste | Valor | Consecuencia |
|---|---|---|
| `email` | `true` | Email/password **ya funciona**: viene activo por defecto. **Es el método de auth del MVP** |
| `google` | `false` | Diferido al **#15**, `fase:post-mvp`. No se toca |
| `disable_signup` | `false` | El registro está abierto |
| `mailer_autoconfirm` | `false` | **Decisión cerrada: se mantiene así.** Un signup crea el usuario pero no devuelve sesión hasta confirmar el correo, y el #9 debe construir ese estado en la UI |

Nada de esto es trabajo de E0. **No implementes autenticación en este bloque.**

Detalle práctico para cuando toque el #9: `flutter run` usa un puerto aleatorio
en cada arranque, y las *Redirect URLs* de Supabase son una allow-list
explícita. Usar `--web-port 5000` y autorizar `http://localhost:5000`.

---

## 8. Término

Cuando B1, B2 y B3 estén `status:hecha` o `status:bloqueada`, **detente** y
reporta:

1. Tabla final de §4 con estados y SHA.
2. Qué issues quedaron abiertos, con qué AC pendiente y de qué dependen.
3. Lo anotado en §9.
4. Salida real de `fvm flutter analyze` y `fvm flutter test`.
5. Estado de la rama `feat/e0-fundaciones`: si fue pusheada y por qué.

Con eso E0 queda cerrado. **No arranques E1**: necesita su propio handoff, y el
#9 depende del #3, que es manual.

---

## 9. Bitácora — anota acá, no cambies las decisiones de §3

Decisiones técnicas tomadas dentro de tu ámbito, desviaciones necesarias con su
razón, y cosas que deberían discutirse pero no bloquean.

Ver también la §9 del [bloque A](HANDOFF-E0-BLOQUE-A.md), que registra el
conflicto de `Watch`, la corrección del piso de `environment.sdk`, y el trabajo
de autenticación de E1 que hubo que revertir por estar fuera de alcance.

<!-- Cada iteración agrega acá. Formato: `- **B_n**: qué y por qué` -->

- **Extra (fuera de B1–B3) · #16**: la dueña del repo decidió aplicar la limpieza
  del grant de `rls_auto_enable()` (§2) como cambio propio. El SQL propuesto
  revocaba solo `anon, authenticated`; el ACL real traía además un grant a
  `PUBLIC` (`=X/postgres`) del que ambos heredaban, así que revocar solo esos dos
  roles no habría eliminado el acceso efectivo ni los warnings. La migración
  aplicada revoca `FROM PUBLIC, anon, authenticated` y conserva el grant de
  `service_role`. Evidencia y validación de AC en el #16. Commit `b948568`.

- **B1 · nivel `code` → GeistMono.** El frontmatter declara `Geist`, pero
  `GeistMono-Regular.ttf` es el único mono que el design system manda a
  registrar (la tabla del #2 lo destina a "bloques de código") y la prosa pide
  distinguir el código del texto corrido. Con `Geist` ahí, el `.ttf` mono sería
  peso muerto en el bundle. Queda expuesto como `AppTheme.code`, porque
  `TextTheme` no tiene slot para código.
- **B1 · variante secundaria de `CustomButton` → `OutlinedButton` temado.** El
  spec del botón secundario (transparente, borde 1px, texto oscuro) es
  exactamente `OutlinedButtonTheme`; así los tres niveles (primario, secundario
  y ghost) viven en el tema y el átomo queda sin un solo color. Los dos finders
  de `widget_test.dart` que buscaban `ElevatedButton` para el botón de Google
  se actualizaron en el mismo commit, como manda el gotcha de B3 para el caso
  análogo.
- **B1 · glow de foco de los inputs en `CustomInput`, no en el tema.** Un
  `InputBorder` no puede pintar sombras, así que el borde-a-primary va en
  `InputDecorationTheme` y el glow (2px, primary al 20%) en el átomo con
  `Focus` + `Builder` — sin `setState` ni estado propio, respetando §3.
- **B1 · ícono de prefijo de inputs: de `secondary` a `onSurfaceVariant`, vía
  tema.** Decoración descriptiva, no interactiva: con la paleta corregida,
  `secondary` (#712AE2) gritaba contra el minimalismo del design system. Vive
  en `prefixIconColor` del tema, ya no en el átomo.
- **B1 · `AppBranding.name` = `'Mentorship App'`.** Se conserva el valor neutro
  que ya usaba `MaterialApp.title`: la marca es decisión de producto sin tomar
  (§3), esto solo centraliza el punto de cambio.
- **B1 · `background`/`onBackground`/`surfaceVariant` no se pasan al
  `ColorScheme`.** Flutter los tiene deprecados como campos del scheme; con
  `--fatal-infos` en B2 romperían el build. Los tres tokens existen en
  `AppColors` (AC2) y `scaffoldBackgroundColor` usa `background` directo.
