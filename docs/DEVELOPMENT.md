# Entorno de desarrollo

Cómo llevar un clon nuevo de este repositorio a la app corriendo. Verificado en
Windows 11 25H2 con Flutter 3.44.2 · Dart 3.12.2.

---

## 1. Requisitos

| Requisito | Por qué |
|---|---|
| **Git** | FVM descarga el SDK clonando el repositorio de Flutter |
| **FVM ≥ 3.1** | `.vscode/settings.json` apunta a `.fvm/versions/3.44.2`, ruta que solo genera FVM 3.1+ |
| **Modo Desarrollador de Windows activado** | Los plugins nativos de `supabase_flutter` se registran con symlinks, y Windows los prohíbe sin él |
| **~4 GB de disco** | El SDK vive en el cache de FVM (`fvm list` imprime la ruta exacta) |
| **Chrome** | Objetivo de desarrollo por defecto |

No hace falta instalar Flutter aparte: FVM lo descarga. La versión la fija
[`.fvmrc`](../.fvmrc) y **no se cambia sin actualizar también**
`.vscode/settings.json` y el workflow de CI.

Opcionales, solo si vas a compilar a esos objetivos:

| Objetivo | Requisito extra |
|---|---|
| Windows desktop | Visual Studio 2022 con el workload *Desktop development with C++* |
| Android | Android Studio o cmdline-tools, y `fvm flutter doctor --android-licenses` |

---

## 2. Arranque en un clon nuevo

Secuencia verificada. Correr en la raíz del repositorio, en este orden:

```bash
fvm install               # descarga Flutter 3.44.2 leyendo .fvmrc
fvm flutter pub get
fvm flutter analyze       # debe terminar sin issues
fvm flutter test
fvm flutter run -d chrome
```

**`fvm install` es obligatorio.** `.fvm/` está en `.gitignore`, así que en un
clon nuevo esa carpeta no existe: hasta correrlo, el `dart.flutterSdkPath` de
`.vscode/settings.json` apunta a una ruta inexistente y la extensión de Dart
marca errores en todo `lib/` aunque el código esté bien.

Después de `fvm install`, recarga la ventana de VS Code
(`Ctrl+Shift+P` → *Developer: Reload Window*) para que la extensión resuelva el
SDK recién descargado.

**Prefija todo con `fvm`.** Un `flutter` suelto usa el SDK global, si existe, y
deja de coincidir con la versión del proyecto.

### Qué esperar la primera vez

El primer build web en debug tarda del orden de **100 segundos** antes de que la
pantalla muestre algo. La pestaña queda en blanco mientras compila; no es un
error. Los arranques siguientes son mucho más rápidos y, con la sesión activa,
`r` (hot reload) aplica cambios en menos de un segundo.

---

## 3. Ciclo de desarrollo

```bash
fvm flutter run -d chrome              # r = hot reload · R = hot restart · q = salir
fvm flutter run -d chrome --web-port 5000   # puerto fijo (ver nota abajo)
fvm flutter devices                    # objetivos disponibles
fvm flutter analyze
fvm flutter test
```

Un solo archivo de test:

```bash
fvm flutter test test/widget_test.dart
```

Un solo test por nombre:

```bash
fvm flutter test --plain-name 'LoginPage monta y renderiza sus textos en español'
```

**Sobre `--web-port`:** sin él, `flutter run` elige un puerto distinto en cada
arranque. Como las *Redirect URLs* de Supabase son una allow-list explícita, un
puerto variable obliga a re-autorizar cada vez. Fija uno para trabajar contra
auth.

---

## 4. Configuración por entorno

La URL y la publishable key de Supabase viven **solo** en
[`lib/core/config/supabase_config.dart`](../lib/core/config/supabase_config.dart),
leídas con `String.fromEnvironment` y con el proyecto de desarrollo como valor
por defecto. Para apuntar a otro proyecto no se toca el código: se pasan por
`--dart-define`.

Correr contra otro proyecto:

```bash
fvm flutter run -d chrome --dart-define=SUPABASE_URL=https://TU_REF.supabase.co --dart-define=SUPABASE_KEY=sb_publishable_TU_LLAVE
```

Compilar para producción:

```bash
fvm flutter build web --release --dart-define=SUPABASE_URL=https://TU_REF.supabase.co --dart-define=SUPABASE_KEY=sb_publishable_TU_LLAVE
```

En PowerShell, si necesitas partir el comando en varias líneas, el carácter de
continuación es la comilla invertida (`` ` ``), no la barra invertida.

**La publishable key es pública por diseño.** Se expone en cualquier build de
cliente, así que tenerla como default en un repositorio público es correcto y no
se reemplaza por un placeholder ni se mueve a un `.env`: eso rompería el arranque
sin agregar seguridad. La protección real de los datos son las políticas RLS de
la base de datos. **Nunca** commitear una llave `service_role`.

Regla de acceso al cliente: la capa `data` toma `SupabaseClient` desde `getIt`.
`Supabase.instance.client` solo aparece dentro de `supabase_config.dart`.

---

## 5. Problemas frecuentes en Windows

| Síntoma | Causa | Solución |
|---|---|---|
| `fvm: command not found` justo después de instalarlo | El PATH de la terminal abierta no se refrescó | Abrir una terminal nueva |
| `Building with plugins requires symlink support. Please enable Developer Mode` al correr `pub get` | Modo Desarrollador de Windows desactivado | `start ms-settings:developers` y activarlo. Equivalente por registro, como Administrador: `reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"`. Después, terminal nueva |
| VS Code marca errores en todo `lib/`, imports sin resolver | Falta `fvm install`, o la extensión de Dart apunta al SDK global en vez de al de FVM | Correr `fvm install`, verificar que `.fvm/versions/3.44.2` exista y recargar la ventana. `dart.flutterSdkPath` debe ser `.fvm/versions/3.44.2`, nunca una ruta absoluta a un Flutter global |
| `pub get` falla tras cambiar de versión de Flutter | Artefactos de la versión anterior en `.dart_tool/` y `build/` | `fvm flutter clean` y después `fvm flutter pub get` |
| El navegador muestra `net::ERR_CONNECTION_REFUSED` y la página en blanco | El proceso `flutter run` no está vivo: se cerró, se interrumpió o nunca terminó de arrancar | Volver a correr `fvm flutter run -d chrome` y esperar a que la terminal imprima `Debug service listening on ws://…` |
| `Failed to connect to the web debug service: TimeoutException after 0:00:05` | Flake de DWDS cuando la máquina está cargada; no es un fallo de la app | Reintentar el `run`. Si insiste, cerrar las ventanas de Chrome que dejó el intento anterior |
| Archivos marcados como modificados sin cambio real | Conversión CRLF de Windows | Ya cubierto por [`.gitattributes`](../.gitattributes). Si aparece en un clon viejo: `git add --renormalize .` |

---

## 6. Arquitectura

Las reglas de capas, atomic design, estado con signals y DI están en
[`CLAUDE.md`](../CLAUDE.md), en la raíz del repositorio. Todo archivo nuevo bajo
`lib/` abre con un comentario en español nombrando su capa.
