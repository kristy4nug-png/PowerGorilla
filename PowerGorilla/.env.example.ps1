# Phat Gorrilla optional Supabase free-tier sync settings.
# Copy to .env.ps1 locally and fill in your own free-tier Supabase values.

$env:GORILLA_SUPABASE_URL = 'https://your-project.supabase.co'
$env:GORILLA_SUPABASE_ANON_KEY = 'your-anon-key'
$env:GORILLA_SUPABASE_SERVICE_KEY = 'your-service-role-key-for-local-powershell-only'

# Ollama stays local.
$env:GORILLA_OLLAMA_URL = 'http://localhost:11434'
$env:GORILLA_EMBED_MODEL = 'nomic-embed-text'
$env:GORILLA_EXTRACT_MODEL = 'llama3.2'
