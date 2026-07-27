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

### Trampa: crear usuarias por SQL rompe el login con un 500

Si en vez del dashboard se inserta la usuaria directo en `auth.users` —por
ejemplo desde el MCP, que no puede abrir el dashboard—, el login devuelve
**HTTP 500** aunque la contraseña sea correcta:

```
error finding user: sql: Scan error on column index 3, name "confirmation_token":
converting NULL to string is unsupported
→ 500: Database error querying schema
```

GoTrue lee varias columnas de token en un `string` de Go y no en un puntero, así
que un `NULL` lo hace fallar **antes** de validar nada. El dashboard las escribe
como cadena vacía; un `insert` que las omite las deja en `NULL`.

Hay que ponerlas explícitamente en `''`. `phone` sí puede quedar en `NULL`:

```sql
update auth.users
set confirmation_token         = coalesce(confirmation_token, ''),
    recovery_token             = coalesce(recovery_token, ''),
    email_change               = coalesce(email_change, ''),
    email_change_token_new     = coalesce(email_change_token_new, ''),
    email_change_token_current = coalesce(email_change_token_current, ''),
    phone_change               = coalesce(phone_change, ''),
    phone_change_token         = coalesce(phone_change_token, ''),
    reauthentication_token     = coalesce(reauthentication_token, '')
where email = '...';
```

Comprobación de que no quedó ninguna:

```sql
select string_agg(c.column_name, ', ')
from information_schema.columns c
where c.table_schema = 'auth' and c.table_name = 'users'
  and c.data_type in ('text', 'character varying')
  and c.column_name <> 'phone'
  and (select (to_jsonb(u) ->> c.column_name) is null
       from auth.users u where u.email = '...');
```

Además de la fila en `auth.users` hace falta una en `auth.identities` con
`provider = 'email'` y un `identity_data` que traiga `sub` y `email`. Sin ella,
la detección de «este correo ya está registrado» del `AuthRepositoryImpl` —que
mira si `identities` viene vacío— se confunde.

**Cómo verificarlo sin navegador**, que es lo que conviene hacer antes de
avisarle a alguien que pruebe:

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
  -X POST 'https://dtvfucqamakudgbwuhbw.supabase.co/auth/v1/token?grant_type=password' \
  -H 'apikey: <publishable key>' -H 'Content-Type: application/json' \
  -d '{"email":"...","password":"..."}'
```

`200` con `access_token` y `refresh_token` es login correcto. `400` es
contraseña incorrecta, que es lo esperable en ese caso. **`500` es esta
trampa**, no un problema de credenciales.

Nada de esto aplica a `supabase/tests/rls_modulo_1.sql`: esas usuarias nunca
pasan por GoTrue, se impersonan por SQL con `request.jwt.claims`.

## Migraciones

Van versionadas en [supabase/migrations/](../supabase/migrations/), nunca
aplicadas a mano en el dashboard.

| Versión | Qué hace |
|---|---|
| `20260726073609` | Revoca `EXECUTE` sobre `rls_auto_enable()` (issue #16) |
| `20260726231624` | Esquema del Módulo 1: 5 tablas, RLS, trigger de perfil, 3 tracks (issue #7) |
| `20260726232005` | Revoca `EXECUTE` sobre `handle_new_user()` y `touch_updated_at()` (issue #7) |
| `20260727042317` | Traduce el catálogo sembrado al inglés (issue #35) |
| `20260727044422` | Rol `student`/`admin` en `profiles`, RLS de escritura del catálogo (issue #36) |
| `20260727044728` | Corrige el trigger del rol: tenía que ser `SECURITY INVOKER` (issue #36) |
| `20260727050231` | El rol también es inmutable en el `insert` (issue #36) |

Después de cada migración, correr el linter de seguridad y verificar que no
aparezcan hallazgos nuevos:

```
get_advisors(security)   → esperado: {"lints":[]}
```

## Dónde aterriza el enlace de confirmación — issue #34

El correo de confirmación vuelve a la ruta **`/#/auth/confirmed`**, no a la
raíz. La app la registra como pública y el guard **nunca redirige fuera de
ella**, ni siquiera con sesión: quien hizo clic en el enlace tiene que ver que
funcionó. Antes aterrizaba en la raíz y la app mostraba el login pelado,
pidiendo de nuevo las credenciales recién tipeadas y sin decir si la
confirmación había salido bien.

La URL la calcula `SupabaseConfig.emailRedirectTo` desde el origen en el que la
app está corriendo, así que el mismo build sirve en localhost y en un dominio
real. Se puede forzar con `--dart-define=SUPABASE_EMAIL_REDIRECT=...`.

**Requisito**: la allow-list de *Redirect URLs* tiene que autorizarla. Con
`http://localhost:5000/**` ya queda cubierta; una URL que no esté en la lista
se ignora en silencio y Supabase cae al Site URL, que es justamente el
comportamiento viejo.

Recordá correr la app con `--web-port 5000`, o el enlace apuntará a un puerto
donde no hay nada escuchando.

## Promover a una administradora — issue #36

Hay dos roles: `student`, que es con el que nace toda usuaria al registrarse, y
`admin`, que es quien carga el material de estudio del que saldrán los roadmaps
(#37).

**Promover es un acto manual y deliberado. La app no lo puede hacer, y eso es
a propósito.** Un trigger (`profiles_role_is_immutable`) rechaza cualquier
cambio de rol que venga de una sesión del cliente, tanto en el `update` como
en el `insert`. Sin esa regla, cualquiera se promovería con una llamada desde
el navegador: la publishable key viaja en el bundle y la política de RLS ya
deja a cada usuaria escribir su propia fila de `profiles`.

Desde el **SQL editor** del dashboard, que corre como `postgres` y por eso el
trigger la deja pasar:

```sql
update public.profiles
set role = 'admin'
where email = 'la-que-corresponda@ejemplo.com';
```

Verificar:

```sql
select email, role from public.profiles order by role, email;
```

Para degradar, el mismo `update` con `role = 'student'`.

Ojo con lo que **no** cambia el rol: no da acceso a los datos de otras
usuarias. La administradora escribe `tracks` y `topics`, y sigue viendo solo su
propio perfil, su progreso y sus respuestas, igual que cualquiera. Está
verificado en [`supabase/tests/rls_roles.sql`](../supabase/tests/rls_roles.sql),
que hay que volver a correr cada vez que se toquen las políticas.

## Guardrail heredado

El schema `public` tiene un event trigger `ensure_rls` → `rls_auto_enable()` que
habilita RLS en cada `CREATE TABLE`. Consecuencia: el modo de falla por defecto
no es una tabla sin RLS, es una tabla **con RLS y cero políticas**, que queda
silenciosamente inaccesible sin ningún error visible. Toda tabla nueva necesita
su política explícita, y las migraciones escriben el `enable` igual para ser
reproducibles sobre un proyecto que no tenga este trigger.
