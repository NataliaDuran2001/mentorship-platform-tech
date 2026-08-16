-- ===========================================================================
-- Opción «Otro» en el paso de nivel del onboarding.
--
-- Suma un cuarto valor al enum `experience_level`. Los tres existentes
-- —student, junior_developer, career_switcher— no se tocan: quien no se
-- reconocía en ninguno tenía que forzarse o saltear el paso.
--
-- El texto libre que escribe la usuaria NO se agrega a `profiles`. Vive en
-- `onboarding_answers` con la clave 'experience_other': esa tabla ya guarda
-- texto libre, ya tiene RLS por usuaria y ya es donde están el resto de las
-- respuestas del paso. Una columna nueva en el perfil daría dos fuentes para
-- el mismo dato, y habría que mantenerlas de acuerdo.
--
-- `add value` no puede correr dentro de la misma transacción que después usa
-- el valor nuevo, así que este archivo hace eso y nada más. `if not exists`
-- lo vuelve idempotente: volver a correrlo no falla.
-- ===========================================================================

alter type public.experience_level add value if not exists 'other';

-- ---------------------------------------------------------------------------
-- Para leer los motivos, una vez que haya respuestas:
--
--   select p.email, a.value as motivo, a.answered_at
--     from public.onboarding_answers a
--     join public.profiles p on p.id = a.user_id
--    where a.step_key = 'experience_other'
--    order by a.answered_at desc;
-- ---------------------------------------------------------------------------
