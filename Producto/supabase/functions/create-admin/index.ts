// Reemplaza el truco de la segunda instancia de FirebaseApp que usaba
// admin/lib/main.dart (_createAdminAccount) para crear un admin nuevo sin
// cerrar la sesion del admin actual. Aqui la verificacion de super_admin y
// la creacion del usuario ocurren en el servidor con la service-role key,
// que nunca se expone al cliente Flutter.

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

  // 1. Verificar que quien llama es un super_admin autenticado.
  const { data: callerData, error: callerErr } = await supabaseCaller.auth.getUser();
  if (callerErr || !callerData.user) {
    return new Response("Unauthorized", { status: 401, headers: corsHeaders });
  }

  const { data: callerAdminRow } = await supabaseAdmin
    .from("administradores")
    .select("rol")
    .eq("id", callerData.user.id)
    .maybeSingle();

  if (!callerAdminRow || callerAdminRow.rol !== "super_admin") {
    return new Response("Forbidden: requiere rol super_admin", { status: 403, headers: corsHeaders });
  }

  // 2. Leer y validar el body.
  let body: { email?: string; password?: string; rol?: string };
  try {
    body = await req.json();
  } catch {
    return new Response("Body invalido", { status: 400, headers: corsHeaders });
  }

  const { email, password, rol = "operador" } = body;
  if (!email || !password) {
    return new Response("email y password son requeridos", { status: 400, headers: corsHeaders });
  }
  if (rol !== "operador" && rol !== "super_admin") {
    return new Response("rol debe ser 'operador' o 'super_admin'", { status: 400, headers: corsHeaders });
  }

  // 3. Crear el usuario de Auth (solo posible con la service-role key).
  const { data: created, error: createErr } = await supabaseAdmin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });
  if (createErr || !created.user) {
    return new Response(createErr?.message ?? "No se pudo crear el usuario", {
      status: 400,
      headers: corsHeaders,
    });
  }

  // 4. Insertar la fila de administradores.
  const { error: insertErr } = await supabaseAdmin.from("administradores").insert({
    id: created.user.id,
    email,
    rol,
  });
  if (insertErr) {
    // Revertir la creacion del usuario de Auth si la fila no se pudo insertar,
    // para no dejar una cuenta huerfana sin fila de administradores.
    await supabaseAdmin.auth.admin.deleteUser(created.user.id);
    return new Response(insertErr.message, { status: 400, headers: corsHeaders });
  }

  return new Response(JSON.stringify({ uid: created.user.id, email, rol }), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
