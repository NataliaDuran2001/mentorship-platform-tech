# HANDOFF EJECUTABLE · E0 Bloque A · Trabajo codificable

Este documento es autosuficiente: no necesitas la conversación que lo originó. Contiene el contexto, las decisiones cerradas y las 5 tareas codificables del épico E0.

**El tablero de GitHub es la fuente de verdad del estado.** Los criterios de aceptación canónicos viven en el cuerpo de cada issue, no acá. Este documento resume y da contexto; **el issue manda**. La tabla de §4 es un espejo que se reescribe desde `gh` al empezar cada iteración.

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
2. Cruzar con `git log --oneline -10`. Si el tablero y el repo discrepan, **gana el repo**: corregir el tablero, no al revés.

**Elegir y abrir**

3. Tomar la primera tarea de §5 con `status:pendiente` cuyas dependencias estén cerradas o `status:hecha`.
4. Leer el issue **completo, incluidos los comentarios** — varios tienen alcance ampliado ahí:
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
8. Correr el comando de verificación de la tarea. Si falla, arreglar; no avanzar con la verificación roja.
9. Commit en la rama `feat/e0-fundaciones` con el mensaje indicado.

**Cerrar**

10. Validar los criterios de aceptación uno por uno y cerrar o bloquear el issue siguiendo **§6**. Este paso no es opcional ni resumible.
11. Actualizar la tabla de §4 con el resultado y el SHA corto.
12. Si no queda ninguna tarea ejecutable, ir a §8 y detenerse.

Si una tarea resulta bloqueada por algo externo, márcala `status:bloqueada` con la razón y pasa a la siguiente. **No la dejes a medias.**

**Rama:** todo va a `feat/e0-fundaciones`. Créala desde `main` si no existe. **No hagas push ni abras PR sin pedirlo** — `main` es la rama por defecto de un repo público.

---

## 2. Contexto del proyecto

App Flutter de una plataforma de mentoría con IA para mujeres en Bolivia. Hoy es un andamio: una pantalla de login con autenticación simulada.

| | |
|---|---|
| Repo | `NataliaDuran2001/mentorship-platform-tech`, público, `main`, 1 commit |
| Toolchain | Flutter **3.44.2** vía FVM (`.fvmrc`) · Dart 3.12.2. Prefija todo con `fvm` |
| Backend | Supabase, proyecto `dtvfucqamakudgbwuhbw`. Schema `public` **vacío**, `auth.users` en **0** |
| Tablero | 14 issues. E0 = #1–#6, E1 = #7–#14 |
| Design system | "Luminous Clarity", en `luminous_clarity/DESIGN.md` del prototipo Stitch |

Prototipo Stitch (7 pantallas HTML + PNG + el DESIGN.md), fuera del repo:
`C:\Users\Natalia\Downloads\mentor_ai\stitch_femtech_mentor_ai\`

**E0 son las fundaciones.** Nada de E1 (Módulo 1: onboarding, auth real, roadmap) entra en este bloque.

---

## 3. Invariantes — violarlas es un defecto, no una opción

### Decisiones de producto cerradas

| Decisión | Valor |
|---|---|
| Idioma | UI y comentarios en **español**. Identificadores y código en inglés |
| Marca | **Sin decidir.** Todo nombre de producto pasa por `AppBranding.name` |
| Tracks del roadmap | `frontend`, `backend`, `infrastructure` |
| `AppColors.primary` | `#674BB5`. El `#A78BFA` que hay hoy es `primary-container`, está mal |

### Reglas de arquitectura (de `CLAUDE.md`)

- **Clean architecture**, dependencia hacia adentro: `presentation → domain ← data`. `presentation` nunca importa `data`.
- `domain` es **Dart puro**: sin Flutter, sin JSON, sin paquetes externos.
- **Atomic design** en `lib/presentation/widgets/`: `atoms/` → `molecules/` → `organisms/` → `pages/`. Cada nivel compone solo desde los de abajo. Los átomos son libres de contexto y reciben comportamiento por callback. **Solo las páginas tocan estado o DI.**
- **Estado con señales**: `signal<T>` global en `lib/presentation/state/`. Widgets `StatelessWidget`, región reactiva en `Watch((context) { ... })`. **Nunca `setState`.**
- **DI con get_it**: todo por `getIt`. Ningún widget construye repositorios ni casos de uso.
- **Supabase**: la capa `data` toma `SupabaseClient` de `getIt`. **Nunca `Supabase.instance.client`** fuera de `supabase_config.dart`.
- **Router**: `go_router`. Decisión cerrada.
- Imports entre capas **relativos** (`../../domain/...`), no `package:aspire_app/...`.
- Cada archivo nuevo bajo `lib/` abre con un comentario en español nombrando su capa, como los existentes.
- **Cero colores o spacing literales en widgets.** Todo de `AppColors` y `AppConstants`.

### Prohibido

- Tocar issues #7–#14 o escribir código de E1.
- Tocar el issue #3: está etiquetado `manual` y no es codificable (§7).
- Cambiar cualquier decisión de §3. Si crees que una está mal, anótalo en §9 y sigue.
- **Cerrar un issue con criterios de aceptación sin cumplir** (§6).
- Commitear una llave `service_role` de Supabase.
- Inventar contenido de currículum (tópicos, ejercicios). No es parte de E0.
- Push o PR sin pedirlo.

---

## 4. Espejo del tablero — reescribir desde `gh` en cada iteración

Estado al momento de escribir este documento. **No es autoritativo**: la verdad está en las labels de GitHub.

| Tarea | Issue | Estado | Depende de | Commit |
|---|---|---|---|---|
| A1 · Entorno y línea base verde | #1 | `status:pendiente` · implementada, AC verificados | — | `838ec6f` |
| A2 · Cerrar integración de Supabase | #4 | `status:pendiente` · implementada, AC1 depende del #9 | A1 | `4dfb0d0` |
| A3 · Design system a tema Flutter | #2 | `status:pendiente` · solo el item 5 (Geist) | A1 | `2d484f6` |
| A4 · Router y shell responsivo | #5 | `status:pendiente` | A3 | |
| A5 · CI en GitHub Actions | #6 | `status:pendiente` | A1 | |

**El tablero no fue sincronizado.** Las labels siguen en `status:pendiente` y no
se publicaron los comentarios de validación de §6, porque modificar issues de un
repositorio público es una acción hacia afuera que no estaba autorizada en esta
iteración. Los commits existen solo en local: la rama `feat/e0-fundaciones` **no
fue pusheada**.

Labels de estado: `status:pendiente` · `status:en-curso` · `status:hecha` · `status:bloqueada`. La label `manual` marca lo que el loop no debe tocar.

---

## 5. Tareas

### A1 · Entorno y línea base verde — issue #1

**Problema.** `test/widget_test.dart` es la plantilla intacta del contador de Flutter: asevera sobre `'0'`, `'1'` e `Icons.add`, que no existen en esta app. **`fvm flutter test` está rojo.** Además no hay documentación de arranque, no hay `.gitattributes` (por eso Windows marca archivos como modificados sin cambio real) y quedó un archivo basura `3.10` en la raíz con la salida de `flutter --version`.

**Hacer.**
1. Borrar el archivo `3.10` de la raíz del repo.
2. Crear `.gitattributes` con `* text=auto eol=lf` y las extensiones binarias marcadas (`*.png binary`, `*.ttf binary`, `*.ico binary`, `*.jpg binary`).
3. Reescribir `test/widget_test.dart` contra la app real: que `LoginPage` monta, que renderiza sus textos en español, que el botón de Google está presente. Lee primero `lib/presentation/widgets/pages/login_page.dart`.
4. Escribir `docs/DEVELOPMENT.md`:
   - Secuencia verificada: `fvm install` → `fvm flutter pub get` → `fvm flutter analyze` → `fvm flutter test` → `fvm flutter run -d chrome`.
   - Por qué `fvm install` es obligatorio en un clon nuevo: `.fvm/` está en `.gitignore`, así que el IDE no resuelve el SDK sin él.
   - Comando de un solo test con `--plain-name`.
   - Matriz de troubleshooting Windows: `fvm` fuera del PATH · Developer Mode desactivado (lo exigen los symlinks de FVM) · el plugin de Dart de VS Code apuntando al SDK global en vez del de FVM · `pub get` fallando tras cambiar de versión.
5. Enlazar `docs/DEVELOPMENT.md` desde el README.

**Verificar.** `fvm flutter analyze && fvm flutter test` verdes. `git status` sin archivos marcados por puro fin de línea.

**AC que exige esfuerzo extra.** El criterio "un clon limpio llega a la app corriendo siguiendo solo el doc" solo se valida clonando de verdad en un directorio temporal y siguiendo el documento al pie de la letra. Hazlo. Si no es posible, márcalo como pendiente de verificación humana en el comentario de cierre; no lo declares cumplido sin evidencia.

**Commit.** `chore: documentar entorno de desarrollo y reparar la suite de tests`

---

### A2 · Cerrar integración de Supabase — issue #4

**Estado.** Casi todo está ya en el working tree, **sin commitear**. Verifica antes de escribir:

- `pubspec.yaml`: `supabase_flutter: ^2.16.0`, SDK a `^3.9.0` ✔
- `lib/core/config/supabase_config.dart` — **untracked**. Completo: `String.fromEnvironment` para `SUPABASE_URL` y `SUPABASE_KEY` con default del proyecto dev, y `initialize()` ✔
- `lib/core/di/injection.dart`: `SupabaseClient` como lazy singleton ✔
- `lib/main.dart`: `ensureInitialized` → `SupabaseConfig.initialize()` → `setupDependencies()` → `runApp` ✔

**Hacer.**
1. Revisar ese código contra las invariantes de §3. Si cumple, no lo reescribas.
2. Agregar a `docs/DEVELOPMENT.md` la sección de `--dart-define`, con los comandos de `run` y `build` para sobreescribir `SUPABASE_URL` y `SUPABASE_KEY` por entorno.
3. Confirmar que ningún archivo de `lib/` usa `Supabase.instance.client` salvo `supabase_config.dart`.
4. Commitear **incluyendo `lib/core/config/`**, que hoy está untracked.

**Sobre la llave.** La publishable key queda como default en un repo público. Es correcto por diseño de Supabase: es pública en cualquier build de cliente. La protección real vive en las políticas RLS, que llegan con el issue #7. **No la reemplaces por un placeholder ni la muevas a un `.env`** — eso rompería el arranque sin agregar seguridad.

**Verificar.** `fvm flutter analyze && fvm flutter test` verdes, y `fvm flutter run -d chrome` arranca sin excepción de inicialización.

**No cerrable.** El AC1 dice "arranca **y establece sesión** contra el proyecto Supabase real". El arranque se verifica; establecer sesión necesita los proveedores de auth del #3, que es manual. Al terminar: `status:bloqueada`, issue abierto, dependencia nombrada.

**Commit.** `feat(core): integrar el cliente de Supabase con configuracion por entorno`

---

### A3 · Design system a tema Flutter — issue #2

**Problema.** `luminous_clarity/DESIGN.md` define 40+ tokens de color, 7 niveles tipográficos, grid de 4px, radios y elevación. El repo tiene **6 colores** y **2 constantes**, con valores desviados porque se tomaron de la prosa del documento en vez del bloque de tokens del frontmatter.

| Constante actual | Valor actual | Correcto |
|---|---|---|
| `AppColors.primary` | `#A78BFA` | **`#674BB5`** (el actual es `primary-container`) |
| `AppColors.secondary` | `#7C3AED` | `#712AE2` |
| `AppColors.neutral` | `#F8FAFC` | `#F7F9FB` (`surface`) |
| `AppColors.border` | `#E2E8F0` | `#CAC4D4` (`outline-variant`) |

**La fuente de verdad es el frontmatter YAML de `DESIGN.md`, no su prosa.**

**Hacer.**
1. Reescribir `lib/presentation/utils/app_colors.dart` con el set completo, usando los nombres del design system: `surface`, `surfaceContainerLowest`, `onSurface`, `onSurfaceVariant`, `outline`, `outlineVariant`, `primary`, `onPrimary`, `primaryContainer`, `secondary`, `tertiary`, `error`, `errorContainer`, etc.
2. Extender `lib/presentation/utils/constants.dart`: escala de 4px (`xs:4, sm:8, md:16, lg:24, xl:40`), radios (`sm:4, default:8, md:12, lg:16, xl:24, full`), `containerMax:1200`, `sidebarWidth:260`, y los breakpoints 768 y 480.
3. Crear `lib/core/theme/app_theme.dart` con el `ThemeData` completo y consumirlo desde `main.dart`, que hoy define estilos inline:
   - Botón primario: fondo `primary`, texto blanco, radio 8, **sin sombra**
   - Secundario: transparente, borde de 1px, texto oscuro
   - Ghost: sin fondo ni borde, texto violeta
   - Inputs: fondo blanco, borde 1px; al foco el borde pasa a `primary` con glow de 2px al 20%
   - Cards: definidas por **borde de 1px, no por sombra**
   - Chips: pill, fondo gris claro
4. Crear `AppBranding` con `name`, como único punto donde vive el nombre del producto.
5. Declarar la sección `fonts:` de Geist en `pubspec.yaml`. **Los archivos ya están en el repo**, este bloqueo se resolvió:

| Archivo en `assets/fonts/` | Peso | Uso según `DESIGN.md` |
|---|---|---|
| `Geist-Regular.ttf` | 400 | `body-lg`, `body-md` |
| `Geist-Medium.ttf` | 500 | `headline-sm`, `label-md` |
| `Geist-SemiBold.ttf` | 600 | `headline-lg`, `headline-md` |
| `GeistMono-Regular.ttf` | 400 | bloques de código |

`OFL.txt` está junto a ellos: la licencia OFL-1.1 exige incluirla al redistribuir. **No lo borres.** No agregues más pesos de los que el design system usa; cada uno infla el bundle web.

**Verificar.** `fvm flutter analyze && fvm flutter test` verdes. Buscar `Color(0x` y literales de padding en `lib/presentation/widgets/`: sin resultados fuera de `utils/`. Geist renderizando de verdad, comparado contra la fuente del sistema.

**Cerrable.** Los 5 criterios se validan con código. Este issue cierra.

**Commit.** `feat(core): aplicar los tokens del design system Luminous Clarity al tema`

---

### A4 · Router y shell responsivo — issue #5

**Problema.** La app tiene una sola pantalla y ningún router. El prototipo necesita al menos 6 destinos y el shell cambia de forma según el ancho.

Reglas de layout de `DESIGN.md`: sidebar fijo de **260px**, contenido fluido con máximo legible de **800px** para vistas de texto, reflow a **768px** y a **480px** (márgenes a 16px).

**Hacer.**
1. Agregar `go_router` a `pubspec.yaml`.
2. `AppRouter` en `lib/core/router/`, con las rutas de los destinos del prototipo: dashboard, chat, lógica, entrevistas, perfil, más login y onboarding.
3. Shell responsivo: bottom navigation en ≤768px, sidebar de 260px arriba de eso, drawer en el rango intermedio.
4. Aplicar `containerMax` y el máximo de 800px para contenido textual.
5. **Login y onboarding fuera del shell**, sin nav visible.
6. Placeholders navegables para los destinos que aún no existen.

**Nota, no bloquea.** En el prototipo el bottom nav tiene 4 slots pero aparecen 5 destinos entre pantallas. Es decisión de producto; elige una distribución razonable y anótala en §9.

**Verificar.** `analyze` y `test` verdes. En `fvm flutter run -d chrome`: se navega entre todos los destinos, redimensionar cruza 768 y 480 sin scroll horizontal, la URL refleja la ruta y recargar mantiene la pantalla, y login/onboarding no muestran nav.

**Cerrable.** Los 5 criterios se validan solo con código. Este issue sí se cierra.

**Commit.** `feat(core): agregar go_router y el shell de navegacion responsivo`

---

### A5 · CI en GitHub Actions — issue #6

**Problema.** El repo no tiene ningún workflow. Nada impide que entre a `main` código que no compila.

**Hacer.**
1. `.github/workflows/ci.yml`, disparado en `pull_request` hacia `main` y en `push` a `main`.
2. Instalar Flutter **3.44.2** en el runner — la misma versión de `.fvmrc`. Deja un comentario en el YAML obligando a actualizar ambos juntos.
3. Pasos: `flutter pub get` → `flutter analyze --fatal-infos` → `flutter test`.
4. Cache de dependencias de pub.
5. Activar la protección de `main` por `gh api` exigiendo que el check de CI pase. **El token tiene `admin: true`, verificado**, así que esto es ejecutable.

**Verificar los AC1–3 con PR real. Autorizado explícitamente por la dueña del repo.** Es la única forma de tener evidencia de verdad:

1. Push de `feat/e0-fundaciones` y abrir el PR hacia `main`. Confirmar que el check corre y pasa → **AC3**.
2. Rama desechable `ci/validate-red` desde `feat/e0-fundaciones` con un error de análisis deliberado (una variable sin usar basta). PR en **draft**, confirmar que el check falla → **AC1**.
3. En la misma rama, reemplazar el error de análisis por un test roto. Confirmar que falla → **AC2**.
4. Cerrar el PR draft y borrar `ci/validate-red`. **No mergearlo nunca.**

Esta autorización es **solo para esto**: el PR de `feat/e0-fundaciones` y el draft desechable de validación. No cubre mergear a `main`.

**Verificar.** Los tres checks se comportaron como se espera, con los enlaces de las corridas como evidencia.

**Cerrable.** Los 5 criterios se validan. Este issue cierra.

**Commit.** `ci: agregar analyze y test en cada PR`

---

## 6. Validación de criterios de aceptación y cierre

Al terminar de implementar una tarea, **antes** de marcarla hecha:

1. Releer los criterios de aceptación del cuerpo del issue (`gh issue view N --comments`). Son la lista canónica, no el resumen de §5.
2. Recorrerlos **uno por uno**. Para cada uno: cumplido o no, y **con qué evidencia**. Evidencia es la salida real de un comando o una observación concreta, no "debería funcionar".
3. Publicar el comentario de validación:

```
gh issue comment N --repo NataliaDuran2001/mentorship-platform-tech --body-file <archivo>
```

Formato del comentario:

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
| **Todos los AC cumplidos** | `gh issue edit N --add-label "status:hecha" --remove-label "status:en-curso"` y `gh issue close N` |
| **Alguno sin cumplir** | `gh issue edit N --add-label "status:bloqueada" --remove-label "status:en-curso"`. **Dejar el issue abierto.** El comentario ya nombra qué falta y de qué depende |

**Regla dura: no se cierra un issue con un AC en `[ ]`.** Cerrar con criterios pendientes convierte el tablero en ficción, que es exactamente el problema que este protocolo existe para evitar. Un issue abierto con 4 de 5 cumplidos y el quinto nombrado es información útil; un issue cerrado a medias no.

**Expectativa de cierre.** #1, #2, #5 y #6 deberían cerrar limpios: sus bloqueos externos se resolvieron (los `.ttf` ya están en el repo, el token tiene admin, el PR está autorizado). El único con AC pendiente es **#4**, y por una razón que no es técnica: su AC1 dice "arranca **y establece sesión**", y establecer sesión es trabajo del #9. Si el AC1 ya fue reformulado en el issue, #4 cierra; si no, queda `status:bloqueada` señalando la reformulación pendiente. **Léelo en el issue, no asumas.**

---

## 7. Bloqueado — no intentar

Requiere consola web o archivos externos. **No es codificable. No lo intentes ni lo simules.**

| Qué | Bloquea | Estado |
|---|---|---|
| **Issue #3 · Configurar Supabase** (label `manual`). Site URL y allow-list · plantillas de correo en español · **decidir la política de confirmación por correo** | Ese último ítem gatea el **#9**. Ya **no** bloquea nada de E0 | Pendiente, de la dueña del repo |
| **Issue #15 · Google OAuth** (labels `manual`, `fase:post-mvp`) | Nada del MVP. Es aditivo sobre el #9 | Diferido por decisión de producto |
| Archivos `.ttf` de Geist | AC3 del #2 | **Resuelto.** Ya están en `assets/fonts/` con su `OFL.txt` |
| Protección de rama `main` | AC5 del #6 | **Resuelto.** El token tiene `admin: true`, verificado |
| Abrir un PR para ejercitar el CI | AC1–3 del #6 | **Autorizado** por la dueña del repo. Ver el procedimiento en A5 |

### Estado real de la autenticación, verificado

`GET /auth/v1/settings` del proyecto devuelve:

| Ajuste | Valor | Consecuencia |
|---|---|---|
| `email` | `true` | Email/password **ya funciona**: viene activo por defecto en Supabase. **Es el método de auth del MVP** |
| `google` | `false` | Diferido al #15. No se toca en el MVP |
| `disable_signup` | `false` | El registro está abierto |
| `mailer_autoconfirm` | `false` | Un signup crea el usuario pero **no devuelve sesión** hasta confirmar el correo |

Lo último importa para el #9, no para E0: cualquier prueba de "iniciar sesión" necesita un usuario ya confirmado, o desactivar la confirmación en dev.

`docs/SUPABASE.md` es parte del issue #3, pero conviene escribirlo *después* de configurar, documentando lo que realmente se hizo. Fuera de este bloque.

---

## 8. Término

Cuando A1–A5 estén `status:hecha` o `status:bloqueada`, **detente** y reporta:

1. Tabla final de §4 con estados y SHA.
2. Qué issues quedaron abiertos, con qué AC pendiente y de qué dependen.
3. Lo anotado en §9.
4. Salida real de `fvm flutter analyze` y `fvm flutter test`.
5. Que la rama `feat/e0-fundaciones` está lista y **no fue pusheada**.

No arranques E1. No hagas push. No abras PR.

---

## 9. Bitácora — anota acá, no cambies las decisiones de §3

Decisiones técnicas que tomaste dentro de tu ámbito, desviaciones necesarias con su razón, y cosas que deberían discutirse pero no bloquean.

<!-- Cada iteración agrega acá. Formato: `- **A_n**: qué y por qué` -->

- **A1**: `Watch` está deprecado en signals_flutter 7.1 a favor de `SignalBuilder`. Eso choca de frente con dos requisitos: §3 fija `Watch` como decisión cerrada, y el AC2 del #1 exige `analyze` sin issues — con el aviso de deprecación, `analyze` termina en exit 1. **No cambié la decisión**: dejé `Watch` y suprimí el aviso con un `// ignore: deprecated_member_use` localizado en `login_page.dart`, con el motivo escrito ahí mismo. **Recomendación para revisar**: migrar a `SignalBuilder` y actualizar §3 y `CLAUDE.md`. Es un rename, no un cambio de modelo reactivo, y el A5 planea `analyze --fatal-infos` en CI, que volverá a tropezar con cada deprecación suprimida a mano.
- **A2**: el `environment.sdk` estaba en `^3.9.0`, valor que el comentario del issue #4 daba por correcto. Es más bajo que el piso real: `pubspec.lock` registra `dart ">=3.10.0-0"`, así que un clon con Dart 3.9 falla al resolver dependencias. Lo subí a `^3.10.0`. El dato del comentario del issue ("mínimo que exige supabase_flutter 2.16.0") era el mínimo del paquete suelto, no el del conjunto ya resuelto.
- **A2**: `Supabase.initialize` recibía la publishable key por el parámetro `anonKey`, deprecado en supabase_flutter 2.16. Cambiado a `publishableKey`. No era opcional: el aviso de deprecación también rompía el AC2 del #1.
- **#2 (parcial, no cerrado)**: adelanté el item 5 —declarar la sección `fonts:` de Geist y quitar el `fontFamily` repetido en cuatro `TextStyle`— en un commit aparte, porque `fontFamily: 'Geist'` no resolvía a nada y Flutter caía en silencio a la fuente del sistema. **Falta todo el resto del #2**: corrección de la paleta (`primary` sigue en `#A78BFA`, debe ser `#674BB5`), escala de spacing, `app_theme.dart` y `AppBranding`. El commit usa un mensaje propio en vez del prescrito por A3, para no dar por hecho un trabajo que no está hecho.
- **Fuera de alcance, revertido**: en una iteración anterior se cableó autenticación real (`signInWithOAuth`, contrato de `AuthRepository` extendido con `currentUser` y `authStateChanges`, `LoginUseCase` registrado en `getIt`, binding de sesión a signals) y una pantalla de error de arranque. Es trabajo del **#9**, que §3 prohíbe en este bloque. Revertido por completo; el login vuelve a ser el `Future.delayed` simulado. **Vale la pena rescatar dos cosas cuando toque el #9**: (1) `main()` hace `await SupabaseConfig.initialize()` sin `try/catch`, así que cualquier fallo del backend deja pantalla blanca indefinida sin diagnóstico; (2) `isAuthenticated` es un `signal` escribible, y la UI lo estaba poniendo en `true` a mano — debería ser `computed` derivado de la sesión real.
- **Higiene, sin commitear**: `.mcp.json` quedó untracked. No tiene secretos (solo `project_ref` y la lista de features del servidor MCP de Supabase). Decidir si se versiona o se agrega a `.gitignore`.
