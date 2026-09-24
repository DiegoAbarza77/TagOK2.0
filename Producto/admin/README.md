# TAG OK Admin

Panel web de administración para el ecosistema TAG OK. Usa el mismo proyecto de **Supabase** que la app de los usuarios (`../tag_ok`), así que los cambios se reflejan en tiempo real en la app (Supabase Realtime).

## Secciones

| Sección | Qué hace | `super_admin` | `operador` |
| :------ | :------- | :-----------: | :--------: |
| Dashboard | KPIs, viajes recientes, costos por autopista | ✅ | ✅ |
| Usuarios | Consulta, edición de presupuesto/nombre, reseteo de contraseña, eliminación | ✅ | — |
| Pórticos | Alta, baja y modificación de tarifa base/punta/saturación por pórtico | ✅ | ✅ |
| Tarifas | Tarifas y viajes de usuarios | ✅ | ✅ |
| Reportes | Métricas agregadas y costos por concesionaria | ✅ | ✅ |
| Auditoría | Bitácora inmutable de cada acción administrativa | ✅ | — |
| Admins | Gestión de roles; crear/eliminar administradores | ✅ | — |

> ⏳ Pendiente (Fase 2): backoffice de **Beneficios** (crear, editar y activar/desactivar). La tabla `beneficios` y sus políticas RLS ya existen.

## Datos y seguridad

Tablas que usa el panel: `usuarios`, `vehiculos`, `trips`, `porticos`, `tarifas`, `auditoria`, `administradores`.

- El acceso está controlado por **Row Level Security** en Postgres (`../supabase/migrations/`), no solo en el cliente.
- Crear y eliminar administradores/usuarios pasa por las Edge Functions `create-admin` y `delete-user`, que verifican el rol de quien llama en el servidor. La *service-role key* nunca llega al navegador.

## Configuración

Crea `admin/.env` (no se versiona) con:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key
```

Sin estos valores el panel no arranca. `../setup.bat` genera la plantilla vacía si no existe.

## Arranque local

```bash
cd Producto/admin
flutter pub get
flutter run -d chrome
```
