// Borra un usuario por completo: fila en public.usuarios (via cascade) y su
// cuenta de auth.users. El admin de hoy (admin/lib/main.dart) solo borraba
// el documento de Firestore y dejaba la cuenta de Firebase Auth huerfana;
// esta funcion corrige ese gap usando la service-role key server-side.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Sin esto, el navegador bloquea la llamada en el preflight (OPTIONS) antes
// de que siquiera llegue a la función -- Deno.serve no las agrega por defecto.
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405, headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response("Unauthorized", { status: 401, headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);
  const supabaseCaller = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: callerData, error: callerErr } = await supabaseCaller.auth.getUser();
  if (callerErr || !callerData.user) {
    return new Response("Unauthorized", { status: 401, headers: corsHeaders });
  }

  const { data: callerAdminRow } = await supabaseAdmin
    .from("administradores")
    .select("rol")
    .eq("id", callerData.user.id)
    .maybeSingle();

  // Borrar una cuenta (posiblemente otro administrador) es una accion
  // destructiva e irreversible; igual que create-admin, exige super_admin
  // en vez de aceptar cualquier fila de administradores.
  if (!callerAdminRow || callerAdminRow.rol !== "super_admin") {
    return new Response("Forbidden: requiere rol super_admin", { status: 403, headers: corsHeaders });
  }

  let body: { userId?: string };
  try {
    body = await req.json();
  } catch {
    return new Response("Body invalido", { status: 400, headers: corsHeaders });
  }

  if (!body.userId) {
    return new Response("userId es requerido", { status: 400, headers: corsHeaders });
  }

  // Borra la fila de public.usuarios explicitamente (por si el cascade de
  // auth.users no alcanza a correr antes de que el caller lea el resultado),
  // luego la cuenta de Auth.
  await supabaseAdmin.from("usuarios").delete().eq("id", body.userId);

  const { error: deleteErr } = await supabaseAdmin.auth.admin.deleteUser(body.userId);
  if (deleteErr) {
    return new Response(deleteErr.message, { status: 400, headers: corsHeaders });
  }

  return new Response(JSON.stringify({ deleted: body.userId }), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
