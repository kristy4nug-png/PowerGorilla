# Free-Tier Launch Plan

Phat Gorrilla can be launched as a professional GitHub project without taking on paid tools or services during the proof stage. The core message is: local-first Windows automation, optional free-tier sync, schema-validated workflows, and safe dry-run operations.

## Non-Negotiable Guardrails

- No paid APIs.
- No trials that require a payment card.
- No design or hosting service that blocks useful work behind billing.
- Logins and free accounts are fine when they do not require card or bank details.
- Local dashboard must work without Supabase, Vercel, Expo hosting, or any external account.
- Optional cloud pieces must be removable without breaking the core product.

## Recommended Free Stack

| Area | Use | Notes |
|---|---|---|
| Source and public trust | GitHub Free | Public repo, issues, releases, README, Mermaid diagrams, Actions quota |
| Architecture visuals | Mermaid in Markdown | No extra account and renders directly in GitHub |
| Polished diagram export | diagrams.net or Structurizr Lite | Use only when you need PNG/SVG assets |
| UI/product polish | Figma Starter or Canva Free | Account login is fine; skip trials, Pro prompts, and anything asking for card details |
| Backend demo | Supabase Free | Keep as optional sync/demo layer, not core runtime |
| Static docs/demo page | Cloudflare Pages or GitHub Pages | Use public docs and screenshots, not secrets |
| Local AI | Ollama | Keeps processing local and avoids API usage cost |
| Frontend preview | Expo web local build | Deploy only if the demo needs a web surface |
| Frontend speed checks | Lighthouse, Playwright, and browser dev tools | Free local quality gates before release |

## Frontend Performance Posture

- Use Supabase as a fast read-only demo plane, not the source of unvalidated data.
- Keep Ollama and JSON schema validation local; push only clean records to Supabase.
- Apply `supabase/migrations/004_frontend_performance.sql` for UI-specific indexes and category views.
- Cache public Supabase reads in the Expo app; use forced refresh only on pull-to-refresh.
- Keep the deployed frontend static where possible, preferably Cloudflare Pages for CDN-style delivery.

## GitHub-Ready Checklist

1. Confirm secrets are not tracked.
   - Keep `.env`, `.env.local`, Supabase service keys, and personal tokens out of Git.
   - Ship only `.env.example` or `.env.example.ps1`.

2. Stabilize the repo history before release.
   - The current workspace has many deletes, moves, and modifications.
   - Make one deliberate consolidation commit before marketing the project.

3. Make the README buyer-facing.
   - First paragraph: what it does, who it is for, why local-first matters.
   - Add a 5-minute quickstart.
   - Link to `docs/ARCHITECTURE_VISUALS.md`.
   - Show the free-tier policy up front.

4. Create a release package.
   - Tag releases as `v0.1.0`, `v0.2.0`, etc.
   - Attach a zip of `PowerGorilla`.
   - Include checksums and install notes.

5. Add trust documents.
   - `SECURITY.md` for responsible disclosure and secret handling.
   - `LICENSE` with the intended commercial posture.
   - `CHANGELOG.md` so buyers can see progress.

6. Keep paid value separate.
   - Public repo: community core, docs, examples, safe local runtime.
   - Paid packages: templates, integration packs, setup service, priority support, advanced workflow bundles.

## Packaging Strategy

| Package | Contents | Price posture |
|---|---|---|
| Community Core | Local dashboard, PowerShell module, docs, schemas, free-tier setup | Free/public |
| Pro Workflow Pack | Curated automation recipes, polished setup scripts, extra dashboards | Paid add-on later |
| Team Integration Pack | GitHub/Supabase templates, deployment guidance, onboarding docs | Paid add-on later |
| Support Package | Installation, configuration, workflow design, troubleshooting | Paid service later |

Important: selling anything will eventually require a payment processor, tax setup, or marketplace onboarding. You can still launch the repo, gather interest, publish releases, and build credibility before touching bank details.

## Architecture Visual Plan

Use `ARCHITECTURE_VISUALS.md` as the main visual asset. It already covers:

- System context
- Container map
- Batch processing sequence
- Multi-app orchestration flow
- Free-tier boundary
- Sellable package shape

For a more polished visual pack, export selected diagrams from Mermaid or diagrams.net as PNG/SVG and store them under:

```text
PowerGorilla/docs/assets/
```

Suggested filenames:

```text
architecture-system-context.svg
architecture-container-map.svg
batch-processing-sequence.svg
free-tier-boundary.svg
sellable-package-shape.svg
```

## First Launch Milestone

Target `v0.1.0-public-preview`:

- Local dashboard launches successfully.
- Validation script produces a clean report.
- README explains setup in under 5 minutes.
- Architecture visuals render on GitHub.
- Supabase setup is clearly marked optional.
- GitHub release contains a packaged zip.
- No tracked secrets or machine-specific private data.

## Positioning

Phat Gorrilla is not just another wrapper app. The defensible idea is the combination of:

- Local-first Windows command centre.
- Deterministic PowerShell orchestration.
- Optional free-tier cloud sync.
- Strict JSON schema contracts.
- Checkpointed long-running local AI processing.
- Safe-mode computer care and app inventory.

That is the story to sell: practical local automation with enough architecture discipline that a buyer can trust it.
