# Phat Gorrilla Architecture Visuals

This document uses GitHub-native Mermaid diagrams so the visuals render directly in Markdown on GitHub. No paid diagramming account, trial, credit card, or external SaaS is required.

## System Context

```mermaid
flowchart LR
    user["Windows operator"]
    buyer["Buyer / evaluator"]

    subgraph local["Local Windows machine"]
        dashboard["Phat Gorrilla dashboard"]
        ps["PowerShell modules and scripts"]
        schemas["JSON schemas"]
        ollama["Local Ollama models"]
        apps["Installed Windows apps"]
        state["Local data, reports, icons"]
    end

    subgraph optional["Optional free-tier services"]
        supabase["Supabase Postgres, Auth, Storage"]
        github["GitHub repo, releases, packages"]
        frontend["Expo web frontend"]
    end

    user --> dashboard
    user --> ps
    buyer --> github
    dashboard --> ps
    ps --> schemas
    ps --> ollama
    ps --> apps
    ps --> state
    ps -. optional sync .-> supabase
    frontend -. optional client .-> supabase
    github -. source and releases .-> ps

    classDef localNode fill:#eef7ff,stroke:#2f6f9f,color:#102030;
    classDef optionalNode fill:#f5f3ff,stroke:#6b5fb5,color:#201a3d;
    classDef actorNode fill:#fff8e6,stroke:#b47b00,color:#2b2000;
    class dashboard,ps,schemas,ollama,apps,state localNode;
    class supabase,github,frontend optionalNode;
    class user,buyer actorNode;
```

## Container Map

```mermaid
flowchart TB
    subgraph entry["Entry points"]
        launcher["Start-PowerGorilla.ps1"]
        setup["Setup-PowerGorilla.ps1"]
        validate["Validate-PowerGorilla.ps1"]
        frontend["frontend / Expo web"]
    end

    subgraph app["Local application layer"]
        server["Local dashboard server"]
        ui["ui/index.html, app.js, app-data"]
        core["PowerGorilla.psm1"]
        supaModule["PowerGorilla.Supabase.psm1"]
        batch["Batch-Management.psm1"]
        orchestration["App-Orchestration.psm1"]
    end

    subgraph data["Data contracts and persistence"]
        schemas["schema/*.schema.json"]
        migrations["supabase/migrations/*.sql"]
        reports["reports and processed data"]
        queue["checkpoint queue"]
    end

    subgraph external["Optional external/runtime systems"]
        supabase["Supabase free-tier project"]
        github["GitHub repo and releases"]
        ollama["Ollama local API"]
        windows["Windows apps and processes"]
    end

    launcher --> server
    setup --> core
    validate --> core
    frontend --> supabase
    server --> ui
    ui --> core
    core --> schemas
    core --> reports
    core --> supaModule
    core --> orchestration
    batch --> queue
    batch --> ollama
    batch --> supabase
    orchestration --> windows
    supaModule --> supabase
    migrations --> supabase
    github --> launcher

    classDef entryNode fill:#e9f5ee,stroke:#2f7d4f,color:#102615;
    classDef appNode fill:#eef7ff,stroke:#2f6f9f,color:#102030;
    classDef dataNode fill:#fff4e8,stroke:#b8681b,color:#2b1604;
    classDef externalNode fill:#f5f3ff,stroke:#6b5fb5,color:#201a3d;
    class launcher,setup,validate,frontend entryNode;
    class server,ui,core,supaModule,batch,orchestration appNode;
    class schemas,migrations,reports,queue dataNode;
    class supabase,github,ollama,windows externalNode;
```

## Batch Processing Flow

```mermaid
sequenceDiagram
    autonumber
    participant User as Operator
    participant PS as PowerShell batch script
    participant DB as Supabase checkpoint queue
    participant LLM as Local Ollama
    participant Schema as JSON schema validator
    participant Report as Local report/export

    User->>PS: Start batch processor
    PS->>DB: Claim next pending queue item
    DB-->>PS: Locked item payload
    PS->>Schema: Validate input contract
    Schema-->>PS: Input accepted
    PS->>LLM: Process item with strict JSON output
    LLM-->>PS: Candidate JSON result
    PS->>Schema: Validate output contract
    alt Valid output
        PS->>DB: Mark item completed
    else Invalid output
        PS->>DB: Retry or mark failed
    end
    PS->>DB: Create checkpoint every N items
    PS->>Report: Write progress and final exports
```

## Multi-App Orchestration Flow

```mermaid
flowchart LR
    intent["User intent"]
    plan["Deterministic action plan"]
    ready1["App 1 readiness check"]
    action1["Run App 1 action"]
    validate1["Validate App 1 output"]
    ready2["App 2 readiness check"]
    action2["Run App 2 action"]
    validate2["Validate App 2 output"]
    result["Final local result"]
    fallback["Retry, fallback, skip, or abort"]

    intent --> plan --> ready1 --> action1 --> validate1 --> ready2 --> action2 --> validate2 --> result
    ready1 -. failure .-> fallback
    action1 -. failure .-> fallback
    validate1 -. failure .-> fallback
    ready2 -. failure .-> fallback
    action2 -. failure .-> fallback
    validate2 -. failure .-> fallback
    fallback --> result

    classDef mainNode fill:#eef7ff,stroke:#2f6f9f,color:#102030;
    classDef guardNode fill:#fff4e8,stroke:#b8681b,color:#2b1604;
    classDef finalNode fill:#e9f5ee,stroke:#2f7d4f,color:#102615;
    class intent,plan,action1,action2 mainNode;
    class ready1,validate1,ready2,validate2,fallback guardNode;
    class result finalNode;
```

## Free-Tier Boundary

```mermaid
flowchart TB
    subgraph required["Required for core product"]
        win["Windows"]
        powershell["PowerShell"]
        browser["Local browser"]
        files["Local files"]
    end

    subgraph free["Allowed free/no-card support layer"]
        github["GitHub public repo"]
        mermaid["Mermaid in GitHub Markdown"]
        diagrams["diagrams.net desktop or web"]
        excalidraw["Excalidraw local/web"]
        structurizr["Structurizr Lite local"]
        cloudflare["Cloudflare Pages optional docs"]
    end

    subgraph optional["Optional app integrations"]
        supabase["Supabase free project"]
        expo["Expo web frontend"]
        vercel["Vercel or Netlify free deploy"]
    end

    subgraph blocked["Avoid for this launch rule"]
        paidApi["Paid APIs"]
        trials["Free trials that require cards"]
        proDesign["Paid design tools"]
        forcedUpgrade["Services that block work without billing"]
    end

    powershell --> github
    github --> mermaid
    mermaid --> supabase
    supabase -. must remain removable .-> powershell
    paidApi -. not part of launch path .-> powershell
    trials -. not part of launch path .-> powershell

    classDef requiredNode fill:#e9f5ee,stroke:#2f7d4f,color:#102615;
    classDef freeNode fill:#eef7ff,stroke:#2f6f9f,color:#102030;
    classDef optionalNode fill:#f5f3ff,stroke:#6b5fb5,color:#201a3d;
    classDef blockedNode fill:#fff0f0,stroke:#b33a3a,color:#3d0808;
    class win,powershell,browser,files requiredNode;
    class github,mermaid,diagrams,excalidraw,structurizr,cloudflare freeNode;
    class supabase,expo,vercel optionalNode;
    class paidApi,trials,proDesign,forcedUpgrade blockedNode;
```

## Sellable Package Shape

```mermaid
flowchart LR
    repo["Public GitHub repo"]
    core["Community core"]
    docs["Architecture docs and visuals"]
    release["GitHub release artifacts"]
    package["Installable package bundle"]
    paid["Paid add-on packages"]
    support["Support / setup / integration service"]
    buyers["Buyers"]

    repo --> core
    repo --> docs
    core --> release
    release --> package
    package --> buyers
    paid --> buyers
    support --> buyers

    docs -. builds trust .-> buyers
    core -. proves value .-> buyers
    paid -. keeps commercial IP separate .-> repo

    classDef publicNode fill:#e9f5ee,stroke:#2f7d4f,color:#102615;
    classDef assetNode fill:#eef7ff,stroke:#2f6f9f,color:#102030;
    classDef commercialNode fill:#fff4e8,stroke:#b8681b,color:#2b1604;
    classDef buyerNode fill:#f5f3ff,stroke:#6b5fb5,color:#201a3d;
    class repo,core,docs publicNode;
    class release,package assetNode;
    class paid,support commercialNode;
    class buyers buyerNode;
```

## No-Card Visual Tool Stack

| Need | Primary tool | Why it fits |
|---|---|---|
| GitHub README architecture visuals | Mermaid code blocks | Renders in GitHub Markdown and stays version controlled |
| Polished export diagrams | diagrams.net | Free diagramming with local files and SVG/PNG export |
| Hand-drawn concept maps | Excalidraw | Free/open-source visual sketching |
| C4-style architecture modelling | Structurizr Lite | Free/open-source local authoring for system/context/container diagrams |
| Public docs site | GitHub Pages or Cloudflare Pages | Free hosting path for documentation and launch pages |

## Visual Rule

Use Mermaid for the source of truth. Export a polished PNG/SVG only when you need a marketplace image, a README banner, or a social preview. That keeps the real architecture editable in Git and avoids locking the project into any paid design service.
