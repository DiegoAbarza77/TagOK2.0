// Reemplaza la llamada directa a la API de Gemini desde el navegador
// (audit_screen.dart) por una llamada de servidor, para que GEMINI_API_KEY
// nunca viaje al cliente ni quede expuesta en el build web.
//
// El cliente sigue armando el prompt (no es secreto) y sigue parseando la
// respuesta JSON como antes; lo único que cambia es el transporte.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Sin esto, el navegador bloquea la llamada en el preflight (OPTIONS) antes
// de que siquiera llegue a la función -- Deno.serve no las agrega por defecto.
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const GEMINI_MODEL = "gemini-2.5-flash";

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

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const geminiApiKey = Deno.env.get("GEMINI_API_KEY");

  if (!supabaseUrl || !anonKey || !geminiApiKey) {
    // Devolver un error con headers CORS en vez de dejar que Deno.env.get(...)!
    // lance una excepción no capturada (esa respuesta de error no lleva
    // corsHeaders y el navegador vuelve a ver un "Failed to fetch" genérico).
    return new Response("Faltan variables de entorno en el servidor", {
      status: 500,
      headers: corsHeaders,
    });
  }

  // Cualquier usuario autenticado de la app puede usar su propia auditoría
  // con IA; no requiere rol de administrador.
  const supabaseCaller = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: callerData, error: callerErr } = await supabaseCaller.auth.getUser();
  if (callerErr || !callerData.user) {
    return new Response("Unauthorized", { status: 401, headers: corsHeaders });
  }

  let body: { prompt?: string };
  try {
    body = await req.json();
  } catch {
    return new Response("Body invalido", { status: 400, headers: corsHeaders });
  }

  if (!body.prompt) {
    return new Response("prompt es requerido", { status: 400, headers: corsHeaders });
  }

  const geminiResponse = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${geminiApiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: body.prompt }] }],
        generationConfig: { responseMimeType: "application/json" },
      }),
    },
  );

  if (!geminiResponse.ok) {
    const errorText = await geminiResponse.text();
    return new Response(`Error de Gemini: ${errorText}`, { status: 502, headers: corsHeaders });
  }

  const geminiResult = await geminiResponse.json();
  const text = geminiResult?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

  if (!text) {
    // Gemini respondió 200 pero sin contenido (p. ej. bloqueado por el
    // filtro de seguridad) -- devolver un error explícito en vez de un
    // 200 con texto vacío, que el cliente intentaría parsear como JSON
    // y fallaría con un mensaje confuso de "Unexpected end of input".
    const blockReason = geminiResult?.promptFeedback?.blockReason ?? "sin contenido";
    return new Response(`Gemini no devolvió una respuesta utilizable (${blockReason})`, {
      status: 502,
      headers: corsHeaders,
    });
  }

  return new Response(JSON.stringify({ text }), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
