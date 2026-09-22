-- Row Level Security: replica (y corrige) la semantica de
-- firestore.rules / storage.rules de la version Firebase.

-- ── Funciones helper ──────────────────────────────────────────
-- security definer para poder leer administradores sin recursion de RLS.
create or replace function public.is_admin(uid uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.administradores a where a.id = uid);
$$;

-- A diferencia de adminRole() en firestore.rules (que caia a 'super_admin'
-- por defecto si faltaba el campo rol/role), aqui NO hay rama por defecto:
-- sin fila o con rol <> 'super_admin' siempre evalua a false.
create or replace function public.is_super_admin(uid uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.administradores a
    where a.id = uid and a.rol = 'super_admin'
  );
$$;

-- ── Habilitar RLS ─────────────────────────────────────────────
alter table public.usuarios enable row level security;
alter table public.administradores enable row level security;
alter table public.vehiculos enable row level security;
alter table public.vehiculo_documentos enable row level security;
alter table public.trips enable row level security;
alter table public.combustible_cargas enable row level security;
alter table public.audited_invoices enable row level security;
alter table public.porticos enable row level security;
alter table public.tarifas enable row level security;
alter table public.beneficios enable row level security;
alter table public.auditoria enable row level security;

-- ── usuarios: dueño-o-admin ───────────────────────────────────
create policy usuarios_select on public.usuarios
  for select using (id = auth.uid() or is_admin());
create policy usuarios_insert on public.usuarios
  for insert with check (id = auth.uid());
create policy usuarios_update on public.usuarios
  for update using (id = auth.uid() or is_admin()) with check (id = auth.uid() or is_admin());
create policy usuarios_delete on public.usuarios
  for delete using (is_admin());

-- ── administradores: self-o-superadmin lee, superadmin-only escribe ──
create policy administradores_select on public.administradores
  for select using (id = auth.uid() or is_super_admin());
create policy administradores_insert on public.administradores
  for insert with check (is_super_admin());
create policy administradores_update on public.administradores
  for update using (is_super_admin()) with check (is_super_admin());
create policy administradores_delete on public.administradores
  for delete using (is_super_admin());

-- ── vehiculos: dueño-o-admin (FK uuid real, sin ambiguedad Reference/string) ──
create policy vehiculos_select on public.vehiculos
  for select using (usuario_id = auth.uid() or is_admin());
create policy vehiculos_insert on public.vehiculos
  for insert with check (usuario_id = auth.uid());
create policy vehiculos_update on public.vehiculos
  for update using (usuario_id = auth.uid() or is_admin()) with check (usuario_id = auth.uid() or is_admin());
create policy vehiculos_delete on public.vehiculos
  for delete using (usuario_id = auth.uid() or is_admin());

-- ── vehiculo_documentos: dueño via el vehiculo padre ──────────
create policy vehiculo_documentos_all on public.vehiculo_documentos
  for all using (
    is_admin() or exists (
      select 1 from public.vehiculos v
      where v.id = vehiculo_documentos.vehiculo_id and v.usuario_id = auth.uid()
    )
  ) with check (
    is_admin() or exists (
      select 1 from public.vehiculos v
      where v.id = vehiculo_documentos.vehiculo_id and v.usuario_id = auth.uid()
    )
  );

-- ── trips, combustible_cargas, audited_invoices: dueño-o-admin ──
create policy trips_all on public.trips
  for all using (usuario_id = auth.uid() or is_admin()) with check (usuario_id = auth.uid() or is_admin());

-- combustible_cargas: dueño-o-admin, y ademas el vehiculo_id (si viene) debe
-- pertenecer al mismo usuario (mismo patron que vehiculo_documentos_all)
create policy combustible_cargas_all on public.combustible_cargas
  for all using (
    is_admin() or (
      usuario_id = auth.uid() and (
        vehiculo_id is null or exists (
          select 1 from public.vehiculos v
          where v.id = combustible_cargas.vehiculo_id and v.usuario_id = auth.uid()
        )
      )
    )
  ) with check (
    is_admin() or (
      usuario_id = auth.uid() and (
        vehiculo_id is null or exists (
          select 1 from public.vehiculos v
          where v.id = combustible_cargas.vehiculo_id and v.usuario_id = auth.uid()
        )
      )
    )
  );

create policy audited_invoices_all on public.audited_invoices
  for all using (usuario_id = auth.uid() or is_admin()) with check (usuario_id = auth.uid() or is_admin());

-- ── porticos / tarifas / beneficios: lectura-todo-autenticado, escritura-admin ──
create policy porticos_select on public.porticos for select using (auth.role() = 'authenticated');
create policy porticos_insert on public.porticos for insert with check (is_admin());
create policy porticos_update on public.porticos for update using (is_admin()) with check (is_admin());
create policy porticos_delete on public.porticos for delete using (is_admin());

create policy tarifas_select on public.tarifas for select using (auth.role() = 'authenticated');
create policy tarifas_insert on public.tarifas for insert with check (is_admin());
create policy tarifas_update on public.tarifas for update using (is_admin()) with check (is_admin());
create policy tarifas_delete on public.tarifas for delete using (is_admin());

create policy beneficios_select on public.beneficios for select using (auth.role() = 'authenticated');
create policy beneficios_insert on public.beneficios for insert with check (is_admin());
create policy beneficios_update on public.beneficios for update using (is_admin()) with check (is_admin());
create policy beneficios_delete on public.beneficios for delete using (is_admin());

-- ── auditoria: admin create/read; sin update/delete == imposible para
-- cualquier rol de cliente (equivalente a "allow update, delete: if false") ──
create policy auditoria_select on public.auditoria for select using (is_admin());
create policy auditoria_insert on public.auditoria for insert with check (is_admin());

-- ── Bootstrap: el primer super_admin no puede crearse desde la app,
-- porque administradores_insert exige is_super_admin(). Ejecutar una vez
-- a mano desde el SQL editor de Supabase, con un usuario ya creado en
-- Authentication > Users:
--
-- insert into public.administradores (id, email, rol)
-- values ('<uid-del-usuario>', 'tu@email.com', 'super_admin');
