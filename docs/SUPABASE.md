# Supabase — proyecto, verificación y usuarias de prueba

Proyecto de desarrollo: `dtvfucqamakudgbwuhbw`.

La URL y la **publishable key** son públicas por diseño y viven en
[lib/core/config/supabase_config.dart](../lib/core/config/supabase_config.dart),
sobreescribibles por entorno:

```bash
fvm flutter run -d chrome --web-port 5000 \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
```

**Nunca** se commitea la llave `service_role` ni la contraseña de una usuaria de
prueba. Este documento dice qué cuentas hacen falta y cómo crearlas; las
contraseñas se comparten por fuera del repositorio.

## Configuración de auth

| Ajuste | Valor | Por qué importa |
|---|---|---|
| `email` | `true` | Es el único proveedor del MVP |
| `google` | `false` | Diferido al issue #15 (`fase:post-mvp`) |
| `disable_signup` | `false` | La app tiene registro propio (`/registro`) |
| `mailer_autoconfirm` | **`false`** | Un `signUp` **no** devuelve sesión hasta que se confirme el correo |
| Site URL | `http://localhost:5000` | Correr siempre con `--web-port 5000` o el enlace del correo no vuelve a la app |
| Redirects | `http://localhost:5000/**` | idem |

Las plantillas de correo están en inglés (default de Supabase), por decisión de
producto. Las traducciones quedaron en el comentario de cierre del issue #3.

**Cuota de correos**: el SMTP integrado de Supabase tiene un límite bajo por
hora. Cada registro y cada reenvío de confirmación consume uno. Conviene no
gastarlos en pruebas automatizadas.

## Usuarias de prueba

### 1. Aislamiento de RLS — issues #7 (AC3) y #9

No hace falta crearlas de forma permanente. El guion
[supabase/tests/rls_modulo_1.sql](../supabase/tests/rls_modulo_1.sql) crea dos
usuarias, corre las pruebas y termina en `ROLLBACK`, así que no deja rastro ni
manda correos.

```bash
# En el SQL editor del dashboard, o:
psql "$DATABASE_URL" -f supabase/tests/rls_modulo_1.sql
```

Cada bloque tiene el resultado esperado comentado al lado. Hay cuatro pruebas de
`insert` comentadas al final que abortan la transacción, así que van de a una.

Volver a correrlo cada vez que cambien las políticas.

### 2. Usuaria confirmada para probar el login — issue #9

Esta sí tiene que existir de forma permanente: el AC1 del #9 pide verificar que
el login de una cuenta **confirmada** devuelve sesión persistente, y confirmar
un correo requiere abrir el enlace que llega a una casilla real.

Cómo crearla, una sola vez:

1. Dashboard → Authentication → Users → **Add user** → *Create new user*.
2. Correo real al que se tenga acceso, contraseña a elección.
3. Marcar **Auto Confirm User** para no gastar un correo de la cuota.
4. Verificar que el trigger hizo su trabajo:

   ```sql
   select u.email, p.id is not null as tiene_perfil, p.onboarding_completed_at
   from auth.users u left join public.profiles p on p.id = u.id;
   ```

   `tiene_perfil` en `true` y `onboarding_completed_at` en `null`: la cuenta
   entra al onboarding, que es lo que se quiere para probar el flujo completo.

| Qué | Dónde |
|---|---|
| Correo de la cuenta de prueba | acordado con la dueña del proyecto |
| Contraseña | **fuera del repositorio** |

Para probar el camino de «cuenta sin confirmar» alcanza con registrar una
dirección cualquiera desde `/registro` y **no** abrir el enlace: el login tiene
que fallar con el mensaje en español y ofrecer el reenvío.

## Migraciones

Van versionadas en [supabase/migrations/](../supabase/migrations/), nunca
aplicadas a mano en el dashboard.

| Versión | Qué hace |
|---|---|
| `20260726073609` | Revoca `EXECUTE` sobre `rls_auto_enable()` (issue #16) |
| `20260726231624` | Esquema del Módulo 1: 5 tablas, RLS, trigger de perfil, 3 tracks (issue #7) |
| `20260726232005` | Revoca `EXECUTE` sobre `handle_new_user()` y `touch_updated_at()` (issue #7) |

Después de cada migración, correr el linter de seguridad y verificar que no
aparezcan hallazgos nuevos:

```
get_advisors(security)   → esperado: {"lints":[]}
```

## Guardrail heredado

El schema `public` tiene un event trigger `ensure_rls` → `rls_auto_enable()` que
habilita RLS en cada `CREATE TABLE`. Consecuencia: el modo de falla por defecto
no es una tabla sin RLS, es una tabla **con RLS y cero políticas**, que queda
silenciosamente inaccesible sin ningún error visible. Toda tabla nueva necesita
su política explícita, y las migraciones escriben el `enable` igual para ser
reproducibles sobre un proyecto que no tenga este trigger.
