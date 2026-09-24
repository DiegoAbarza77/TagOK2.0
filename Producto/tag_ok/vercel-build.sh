#!/usr/bin/env bash
# Build de la app web en Vercel. Se llama desde vercel.json (buildCommand),
# que tiene un límite de 256 caracteres, por eso vive en este script.
set -euo pipefail

# Falla con un mensaje claro si falta alguna variable, en vez de publicar un sitio roto.
: "${SUPABASE_URL:?Falta SUPABASE_URL en las Environment Variables de Vercel}"
: "${SUPABASE_ANON_KEY:?Falta SUPABASE_ANON_KEY en las Environment Variables de Vercel}"
: "${MAPBOX_ACCESS_TOKEN:?Falta MAPBOX_ACCESS_TOKEN en las Environment Variables de Vercel}"

git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter_sdk
export PATH="$PATH:$(pwd)/flutter_sdk/bin"
flutter config --enable-web --no-analytics

# La app carga el .env como asset; se genera aquí con las variables de Vercel.
printf 'SUPABASE_URL=%s\nSUPABASE_ANON_KEY=%s\nMAPBOX_ACCESS_TOKEN=%s\n' \
  "$SUPABASE_URL" "$SUPABASE_ANON_KEY" "$MAPBOX_ACCESS_TOKEN" > .env

flutter pub get
flutter build web --release
