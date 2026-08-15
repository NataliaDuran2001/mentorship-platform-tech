-- ===========================================================================
-- user_progress: guardar cómo se resolvió el lab, no solo que se cerró
-- ===========================================================================
--
-- Hasta ahora una fila de user_progress decía únicamente que el tema quedó
-- completado. Quien acertó todo al primer intento y quien reintentó cada
-- ejercicio dejaban exactamente el mismo rastro, así que el puntaje que ve la
-- usuaria al cerrar el lab moría con la pantalla.
--
-- Se guardan los dos números en crudo —aciertos al primer intento y ejercicios
-- calificables— y no un porcentaje ya calculado. El porcentaje se deriva
-- cuando se necesita; al revés no: de un 67% no se recupera si fue 2 de 3 o
-- 20 de 30, y esa diferencia importa para decidir si vale la pena sugerir un
-- repaso.
--
-- La teoría NO entra acá. En pantalla el total son los pasos de la lección
-- (teoría incluida), pero eso se deriva del árbol de topics, que ya sabe
-- cuántas explicaciones tiene cada sección. Guardar un total que mezcle ambas
-- cosas dejaría la fila sin poder responder "cuántos ejercicios había" el día
-- que se agregue o se saque una explicación de una sección.
--
-- Ambas columnas son nullable a propósito: las filas que ya existen se
-- completaron antes de que hubiera puntaje y no hay forma honesta de
-- inventarles uno. NULL significa "se completó, no sabemos cómo", que es
-- exactamente lo que pasó.
--
-- Nada de RLS que tocar: las políticas de user_progress son a nivel fila y
-- los grants a nivel tabla, así que las columnas nuevas quedan escribibles
-- por la misma política de update que ya usa el upsert.
-- ===========================================================================

alter table public.user_progress
  add column if not exists score_exercises_correct smallint,
  add column if not exists score_exercises_total smallint;

comment on column public.user_progress.score_exercises_correct is
  'Ejercicios acertados al PRIMER intento. NULL en filas anteriores al puntaje.';

comment on column public.user_progress.score_exercises_total is
  'Ejercicios calificables de la sección. Excluye la teoría, que no puntúa.';

-- Las tres cosas que no pueden pasar: media fila de puntaje, un total
-- negativo, y más aciertos que ejercicios.
--
-- `add constraint if not exists` no existe para check en Postgres, de ahí el
-- guard: la migración tiene que poder correrse dos veces sin fallar.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'user_progress_score_coherente'
      and conrelid = 'public.user_progress'::regclass
  ) then
    alter table public.user_progress
      add constraint user_progress_score_coherente check (
        (score_exercises_correct is null) = (score_exercises_total is null)
        and (
          score_exercises_total is null
          or (
            score_exercises_total >= 0
            and score_exercises_correct >= 0
            and score_exercises_correct <= score_exercises_total
          )
        )
      );
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- Verificación
-- ---------------------------------------------------------------------------

select
  count(*) as filas_de_progreso,
  count(score_exercises_total) as con_puntaje,
  case
    when not exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = 'user_progress'
        and column_name = 'score_exercises_correct'
    ) then 'FALLA: no se creo score_exercises_correct'
    when not exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = 'user_progress'
        and column_name = 'score_exercises_total'
    ) then 'FALLA: no se creo score_exercises_total'
    when not exists (
      select 1 from pg_constraint
      where conname = 'user_progress_score_coherente'
    ) then 'FALLA: no se creo el check de coherencia'
    else 'OK'
  end as ok
from public.user_progress;
