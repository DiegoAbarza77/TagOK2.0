-- TAG-OK: esquema inicial Postgres (migración desde Firestore)
-- Ver plan: C:\Users\diego\.claude\plans\joyful-noodling-pine.md

create extension if not exists "pgcrypto";

-- usuarios: fila de perfil 1:1 con auth.users
create table public.usuarios (
  id                          uuid primary key references auth.users(id) on delete cascade,
  email                       text not null,
  nombre_mostrar              text,
  telefono                    text,
  fecha_creacion              timestamptz not null default now(),
  -- antes "vehiculo_principal_id"; en realidad siempre guardó una patente, no un id
  vehiculo_principal_patente  text,
  limite_presupuesto_mensual  numeric(12,2) not null default 0,
  notif_cobros                boolean not null default true,
  notif_presupuesto           boolean not null default true,
  alertas_vistas              jsonb not null default '{}'::jsonb
);

comment on column public.usuarios.vehiculo_principal_patente is
  'Guarda una patente (string), no un id de vehiculo -- coincide con el comportamiento legacy.';

-- administradores: tabla de roles de backoffice
create table public.administradores (
  id              uuid primary key references auth.users(id) on delete cascade,
  email           text not null,
  -- 'operador' es el rol de administrador normal (no elevado); coincide con
  -- el vocabulario ya usado en admin/lib/main.dart, distinto de 'super_admin'
  rol             text not null default 'operador' check (rol in ('operador', 'super_admin')),
  fecha_creacion  timestamptz not null default now()
);

-- vehiculos
create table public.vehiculos (
  id                uuid primary key default gen_random_uuid(),
  usuario_id        uuid not null references public.usuarios(id) on delete cascade,
  patente           text not null,
  categoria         text not null default 'AUTO' check (categoria in ('AUTO', 'CAMIONETA', 'MOTO')),
  marca             text not null default 'No especificada',
  modelo            text,
  anio              integer,
  tipo_combustible  text check (tipo_combustible in ('Bencina', 'Diésel', 'Híbrido', 'Eléctrico')),
  kilometraje       numeric,
  alias             text,
  fecha_ingreso     timestamptz not null default now(),
  created_at        timestamptz not null default now(),
  unique (usuario_id, patente)
);

create index vehiculos_usuario_id_idx on public.vehiculos (usuario_id);
create index vehiculos_patente_idx on public.vehiculos (patente);

-- vehiculo_documentos (antes vehiculos/{id}/documentos/{tipo})
create table public.vehiculo_documentos (
  id                    uuid primary key default gen_random_uuid(),
  vehiculo_id           uuid not null references public.vehiculos(id) on delete cascade,
  tipo                  text not null check (tipo in ('permiso_circulacion', 'revision_tecnica', 'soap', 'seguro')),
  numero                text,
  fecha_emision         timestamptz,
  fecha_vencimiento     timestamptz,
  compania              text,
  fecha_actualizacion   timestamptz not null default now(),
  unique (vehiculo_id, tipo)
);

create index vehiculo_documentos_vehiculo_id_idx on public.vehiculo_documentos (vehiculo_id);

-- trips (antes usuarios/{uid}/trips/{tripId})
create table public.trips (
  id            uuid primary key default gen_random_uuid(),
  usuario_id    uuid not null references public.usuarios(id) on delete cascade,
  date          timestamptz not null,
  total_cost    numeric(12,2) not null default 0,
  distance_km   numeric not null default 0,
  duration      text,
  vehicle_name  text,
  -- array embebido {name, cost, timestamp}; ver plan (Decision Points) sobre normalizar despues
  tolls         jsonb not null default '[]'::jsonb,
  created_at    timestamptz not null default now()
);

create index trips_usuario_id_date_idx on public.trips (usuario_id, date desc);

-- combustible_cargas (antes usuarios/{uid}/combustible/{id})
create table public.combustible_cargas (
  id                uuid primary key default gen_random_uuid(),
  usuario_id        uuid not null references public.usuarios(id) on delete cascade,
  vehiculo_id       uuid references public.vehiculos(id) on delete set null,
  vehiculo_patente  text,
  fecha             timestamptz not null,
  kilometraje       numeric,
  estacion          text,
  tipo_combustible  text,
  litros            numeric(10,2) not null default 0,
  precio_litro      numeric(10,2) not null default 0,
  total             numeric(12,2) not null default 0,
  created_at        timestamptz not null default now()
);

create index combustible_cargas_usuario_id_idx on public.combustible_cargas (usuario_id);
create index combustible_cargas_vehiculo_id_idx on public.combustible_cargas (vehiculo_id);

-- audited_invoices (antes usuarios/{uid}/audited_invoices/{id})
create table public.audited_invoices (
  id                    uuid primary key default gen_random_uuid(),
  usuario_id            uuid not null references public.usuarios(id) on delete cascade,
  concessionaire        text,
  period                text,
  patent                text,
  total_billed          numeric(12,2) not null default 0,
  total_matched         numeric(12,2) not null default 0,
  status                text,
  reconciliation_rate   numeric(5,2) not null default 0,
  upload_date           timestamptz not null default now(),
  details               jsonb not null default '[]'::jsonb,
  ai_report             text,
  audited_by            text,
  created_at            timestamptz not null default now()
);

create index audited_invoices_usuario_id_idx on public.audited_invoices (usuario_id, upload_date desc);

-- porticos: una sola forma canonica (fix del mismatch GeoPoint vs lat/lng
-- entre portico_model.dart y el seed real de admin_service.dart)
create table public.porticos (
  id                    uuid primary key default gen_random_uuid(),
  nombre                text not null,
  autopista             text,
  lat                   double precision not null,
  lng                   double precision not null,
  costo                 numeric(10,2) not null default 0,
  costo_punta           numeric(10,2),
  costo_saturacion      numeric(10,2),
  sentido               text,
  grupo                 text,
  secuencia             text,
  fecha_actualizacion   timestamptz not null default now()
);

-- tarifas: esquema real desconocido hoy (sin escritor encontrado); jsonb flexible
create table public.tarifas (
  id                    uuid primary key default gen_random_uuid(),
  nombre                text,
  datos                 jsonb not null default '{}'::jsonb,
  fecha_actualizacion   timestamptz not null default now()
);

-- auditoria: log de acciones admin, insert/select unicamente
create table public.auditoria (
  id            uuid primary key default gen_random_uuid(),
  fecha         timestamptz not null default now(),
  admin_email   text,
  action        text not null,
  target        text,
  details       text
);

create index auditoria_fecha_idx on public.auditoria (fecha desc);

-- beneficios: sin uso real en codigo hoy; se mantiene como placeholder vacio
create table public.beneficios (
  id                    uuid primary key default gen_random_uuid(),
  nombre                text,
  descripcion           text,
  fecha_actualizacion   timestamptz not null default now()
);

-- NOTA: "alertas" no se crea intencionalmente -- cero escritores en todo
-- el codigo actual (solo un conteo muerto en admin_firestore_service.dart).
