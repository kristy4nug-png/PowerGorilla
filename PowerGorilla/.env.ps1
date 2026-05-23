# .env.ps1 — PowerShell Gorilla local secrets
# DO NOT commit this file to Git (already in .gitignore)
#
# Fill in your values from:
#   Supabase Dashboard → Your Project → Settings → API

$env:GORILLA_SUPABASE_URL         = 'https://YOUR_PROJECT_REF.supabase.co'
$env:GORILLA_SUPABASE_SERVICE_KEY = 'YOUR_SERVICE_ROLE_KEY_HERE'
$env:GORILLA_SUPABASE_ANON_KEY    = 'YOUR_ANON_PUBLIC_KEY_HERE'

# Ollama (leave as-is if running locally on default port)
$env:GORILLA_OLLAMA_URL           = 'http://localhost:11434'
$env:GORILLA_EMBED_MODEL          = 'nomic-embed-text'   # for pgvector embeddings
$env:GORILLA_EXTRACT_MODEL        = 'llama3.2'           # for CSV extraction
