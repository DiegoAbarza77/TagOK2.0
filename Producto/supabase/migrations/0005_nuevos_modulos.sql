-- Migración para los nuevos módulos de la Fase 2: Mantenciones, Estacionamientos y Beneficios (ampliado)

-- ── 1. Tabla: mantenciones ──────────────────────────────────────────
create table public.mantenciones (
  id            uuid primary key default gen_random_uuid(),
  usuario_id    uuid not null references public.usuarios(id) on delete cascade,
  vehiculo_id   uuid not null references public.vehiculos(id) on delete cascade,
  fecha         timestamptz not null,
  kilometraje   numeric,
  tipo          text check (tipo in ('preventiva', 'aceite', 'frenos', 'neumaticos', 'otra')),
  taller        text,
  costo         numeric(12,2) not null default 0,
  descripcion   text,
  ai_report     text,
  created_at    timestamptz not null default now()
);

create index mantenciones_usuario_id_idx on public.mantenciones(usuario_id);
create index mantenciones_vehiculo_id_idx on public.mantenciones(vehiculo_id);

alter table public.mantenciones enable row level security;

-- RLS: Dueño-o-admin. Además valida que el vehiculo_id pertenezca al usuario.
create policy mantenciones_all on public.mantenciones
  for all using (
    is_admin() or (
      usuario_id = auth.uid() and exists (
        select 1 from public.vehiculos v
        where v.id = mantenciones.vehiculo_id and v.usuario_id = auth.uid()
      )
    )
  ) with check (
    is_admin() or (
      usuario_id = auth.uid() and exists (
        select 1 from public.vehiculos v
        where v.id = mantenciones.vehiculo_id and v.usuario_id = auth.uid()
      )
    )
  );

-- ── 2. Tabla: estacionamientos ──────────────────────────────────────
create table public.estacionamientos (
  id            uuid primary key default gen_random_uuid(),
  usuario_id    uuid not null references public.usuarios(id) on delete cascade,
  vehiculo_id   uuid not null references public.vehiculos(id) on delete cascade,
  fecha         timestamptz not null,
  lugar         text,
  lat           double precision,
  lng           double precision,
  hora_entrada  timestamptz,
  hora_salida   timestamptz,
  costo         numeric(12,2) not null default 0,
  ai_report     text,
  created_at    timestamptz not null default now()
);

create index estacionamientos_usuario_id_idx on public.estacionamientos(usuario_id);
create index estacionamientos_vehiculo_id_idx on public.estacionamientos(vehiculo_id);

alter table public.estacionamientos enable row level security;

-- RLS: Dueño-o-admin.
create policy estacionamientos_all on public.estacionamientos
  for all using (
    is_admin() or (
      usuario_id = auth.uid() and exists (
        select 1 from public.vehiculos v
        where v.id = estacionamientos.vehiculo_id and v.usuario_id = auth.uid()
      )
    )
  ) with check (
    is_admin() or (
      usuario_id = auth.uid() and exists (
        select 1 from public.vehiculos v
        where v.id = estacionamientos.vehiculo_id and v.usuario_id = auth.uid()
      )
    )
  );

-- ── 3. Ampliar tabla: beneficios ────────────────────────────────────
-- Se añaden los campos requeridos para el catálogo completo y backoffice
alter table public.beneficios
  add column imagen text,
  add column categoria text,
  add column ubicacion text,
  add column vigencia_desde timestamptz,
  add column vigencia_hasta timestamptz,
  add column condiciones text,
  add column destacado boolean not null default false,
  add column activo boolean not null default true;

-- NOTA: La tabla beneficios ya tiene políticas de RLS en 0003_rls.sql
-- (lectura pública para autenticados, escritura para admins) por lo que 
-- no se requieren nuevas políticas.
