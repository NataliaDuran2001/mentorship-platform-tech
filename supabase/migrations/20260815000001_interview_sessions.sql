-- Historial de sesiones de práctica de entrevista terminadas, para que la
-- estudiante vea su progreso en el tiempo. Las filas son inmutables una vez
-- creadas (se escriben una sola vez desde finishInterviewSession y nunca se
-- editan), así que a diferencia de onboarding_answers no hay política de
-- update — solo select e insert.
create table public.interview_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  track_id text not null references public.tracks(id),
  desired_role text,
  average_score int not null,
  overall_summary text,
  questions jsonb not null,
  answers jsonb not null,
  feedback jsonb not null,
  created_at timestamptz not null default now()
);

create index interview_sessions_user_id_idx on public.interview_sessions (user_id);

alter table public.interview_sessions enable row level security;

create policy "interview_sessions_select_propio"
  on public.interview_sessions for select to authenticated
  using (auth.uid() = user_id);

create policy "interview_sessions_insert_propio"
  on public.interview_sessions for insert to authenticated
  with check (auth.uid() = user_id);
