(function () {
  'use strict';

  const fallbackState = {
    generatedAt: new Date().toISOString(),
    safety: {
      mode: 'Strict Safe Mode',
      destructiveActionsEnabled: false,
      dangerousButtonsPreviewOnly: true,
      credentialsStored: false,
      costPolicy: 'Local-first; no paid subscriptions; free-tier only when a cloud service is unavoidable.',
      paidOrTrialBlocked: true,
      localFirst: true
    },
    datasets: [],
    apps: [],
    integrations: [],
    signIn: [],
    favourites: [],
    stats: {
      apps: 0,
      installedApps: 0,
      missingApps: 0,
      costAllowedApps: 0,
      blockedPaidApps: 0,
      workflows: 0,
      twoApp: 0,
      threeApp: 0,
      fourApp: 0,
      iconsExtracted: 0
    }
  };

  const state = window.POWER_GORILLA_STATE || fallbackState;
  const byId = (id) => document.getElementById(id);
  const safe = (value) => String(value == null ? '' : value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');

  let combinationSize = 2;
  let selectedApps = [];
  let activeWorkflow = null;

  function setProgress(label, value) {
    byId('progressLabel').textContent = label;
    byId('progressBar').style.width = `${Math.max(0, Math.min(100, value))}%`;
  }

  function iconUrl(appOrName) {
    const app = typeof appOrName === 'string' ? findApp(appOrName) : appOrName;
    if (!app || !app.IconUrl) return '../data/icons/fallback-app.svg';
    return app.IconUrl;
  }

  function normalized(value) {
    return String(value || '').toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
  }

  function findApp(name) {
    const target = normalized(name);
    return state.apps.find((app) => normalized(app.Name) === target)
      || state.apps.find((app) => normalized(app.Name).includes(target) || target.includes(normalized(app.Name)));
  }

  function isPaidBlocked(app) {
    if (!app) return false;
    if (app.CostAllowed === false) return true;
    const text = normalized(`${app.Name} ${app.Category} ${app.LicenceMode} ${app.Source} ${app.SignInMode}`);
    const explicitlyFree = app.IsOpenSource || app.IsFreeOrFreeTier || /open source|free|free tier|built in/.test(text);
    return !explicitlyFree && /paid|trial|subscription|commercial|premium|pro plan|enterprise plan/.test(text);
  }

  function badge(label, type) {
    return `<span class="badge ${type || ''}">${safe(label)}</span>`;
  }

  function appBadges(app) {
    const items = [];
    if (app.Installed) items.push(badge(app.Status || 'Installed', 'ok'));
    else items.push(badge(app.Status || 'Missing', 'warn'));
    if (isPaidBlocked(app)) items.push(badge('Blocked paid', 'risk'));
    if (app.IsOpenSource) items.push(badge('Open-source', 'ok'));
    else if (app.IsFreeOrFreeTier) items.push(badge('Free/free-tier', 'ok'));
    if (String(app.LocalMode || '').includes('Local mode available')) items.push(badge('Local', 'info'));
    if (typeof app.Confidence !== 'undefined') {
      const confType = app.ConfidenceLabel === 'Real' ? 'ok' : app.ConfidenceLabel === 'Likely' ? 'info' : app.ConfidenceLabel === 'Possible' ? 'warn' : 'risk';
      items.push(badge(`${app.Confidence}% ${app.ConfidenceLabel}`, confType));
    }
    return items.join('');
  }

  function workflowBadges(workflow) {
    const riskType = workflow.RiskLevel === 'Low' ? 'ok' : workflow.RiskLevel === 'Medium' ? 'warn' : 'risk';
    return [
      badge(`${workflow.CombinationSize}-app`, 'info'),
      badge(workflow.Difficulty || 'Unknown', workflow.Difficulty === 'Easy' ? 'ok' : ''),
      badge(workflow.RiskLevel || 'Low', riskType),
      badge(workflow.AutomationReadiness || 'Partial', String(workflow.AutomationReadiness || '').includes('ready') ? 'ok' : 'warn'),
      badge(workflow.FreeOpenSourceStatus || 'Unknown', 'info')
    ].join('');
  }

  function renderMetrics() {
    const metrics = [
      ['Apps', state.stats.apps],
      ['Installed', state.stats.installedApps],
      ['Workflows', state.stats.workflows],
      ['Allowed free/local', state.stats.costAllowedApps || state.stats.apps || 0]
    ];
    byId('metricGrid').innerHTML = metrics.map(([label, value]) => (
      `<article class="metric"><span>${safe(label)}</span><strong>${Number(value || 0).toLocaleString()}</strong></article>`
    )).join('');
    byId('stateStamp').textContent = `Generated ${new Date(state.generatedAt).toLocaleString()}`;
    byId('safeMode').textContent = state.safety.mode || 'Strict Safe Mode';
  }

  function filteredApps() {
    const query = normalized(byId('appSearch').value);
    const category = byId('categoryFilter').value;
    const installedOnly = byId('installedOnly').checked;
    const openSourceOnly = byId('openSourceOnly').checked;
    const freeOnly = byId('freeOnly').checked;
    const localOnly = byId('localOnly').checked;

    return state.apps.filter((app) => {
      if (query && !normalized(app.Name).includes(query)) return false;
      if (isPaidBlocked(app)) return false;
      if (category && app.Category !== category) return false;
      if (installedOnly && !app.Installed) return false;
      if (openSourceOnly && !app.IsOpenSource) return false;
      if (freeOnly && !(app.IsFreeOrFreeTier || app.IsOpenSource)) return false;
      if (localOnly && !String(app.LocalMode || '').includes('Local mode available')) return false;
      return true;
    }).slice(0, 480);
  }

  function renderCategories() {
    const categories = [...new Set(state.apps.map((app) => app.Category || 'Unknown'))].sort();
    byId('categoryFilter').innerHTML = '<option value="">All categories</option>' + categories.map((category) => (
      `<option value="${safe(category)}">${safe(category)}</option>`
    )).join('');
  }

  function renderAppGrid() {
    const selectedNames = selectedApps.map((app) => normalized(app.Name));
    byId('appGrid').innerHTML = filteredApps().map((app) => {
      const isSelected = selectedNames.includes(normalized(app.Name));
      return `<button class="appTile ${isSelected ? 'selected' : ''}" type="button" draggable="true" data-app="${safe(app.Name)}">
        <img class="appIcon" src="${safe(iconUrl(app))}" alt="">
        <span class="appName">${safe(app.Name)}</span>
        <span class="muted">${safe(app.Category || 'Unknown')}</span>
        <span class="badgeRow">${appBadges(app)}</span>
      </button>`;
    }).join('');

    document.querySelectorAll('.appTile').forEach((tile) => {
      tile.addEventListener('click', () => toggleApp(tile.dataset.app));
      tile.addEventListener('dragstart', (event) => {
        event.dataTransfer.setData('text/plain', tile.dataset.app);
      });
    });
  }

  function toggleApp(name) {
    const app = findApp(name);
    if (!app) return;
    const exists = selectedApps.some((item) => normalized(item.Name) === normalized(app.Name));
    if (exists) selectedApps = selectedApps.filter((item) => normalized(item.Name) !== normalized(app.Name));
    else {
      if (selectedApps.length >= combinationSize) selectedApps.shift();
      selectedApps.push(app);
    }
    updateBuilder();
  }

  function renderSlots() {
    const slots = [];
    for (let index = 0; index < 4; index += 1) {
      const enabled = index < combinationSize;
      const app = selectedApps[index];
      slots.push(`<div class="slot ${app ? 'filled' : ''}" data-slot="${index}" ${enabled ? '' : 'aria-disabled="true"'}>
        ${app ? `<div><img src="${safe(iconUrl(app))}" alt=""><strong>${safe(app.Name)}</strong><br><span class="muted">${safe(app.Status || '')}</span></div>` : `<span>${enabled ? `Slot ${index + 1}` : 'Optional'}</span>`}
      </div>`);
    }
    byId('slotCanvas').innerHTML = slots.join('');
    document.querySelectorAll('.slot').forEach((slot) => {
      slot.addEventListener('dragover', (event) => event.preventDefault());
      slot.addEventListener('drop', (event) => {
        event.preventDefault();
        const name = event.dataTransfer.getData('text/plain');
        const app = findApp(name);
        const index = Number(slot.dataset.slot);
        if (!app || index >= combinationSize) return;
        selectedApps = selectedApps.filter((item) => normalized(item.Name) !== normalized(app.Name));
        selectedApps[index] = app;
        selectedApps = selectedApps.filter(Boolean).slice(0, combinationSize);
        updateBuilder();
      });
    });
  }

  function workflowsForSelection() {
    const names = selectedApps.map((app) => normalized(app.Name));
    const query = normalized(byId('workflowSearch').value);
    const type = byId('workflowTypeFilter').value;

    return state.integrations.filter((workflow) => {
      if (Number(workflow.CombinationSize) !== combinationSize) return false;
      const workflowNames = (workflow.AppNames || []).map(normalized);
      if (names.length && !names.every((name) => workflowNames.includes(name))) return false;
      const haystack = normalized(`${workflow.WorkflowName} ${workflow.Description} ${workflow.Category} ${(workflow.AppNames || []).join(' ')}`);
      if (query && !haystack.includes(query)) return false;
      if (type === 'fix' && !haystack.includes('fix') && !haystack.includes('repair') && !haystack.includes('diagnos')) return false;
      if (type === 'update' && !haystack.includes('update')) return false;
      if (type === 'creative' && !haystack.includes('creative') && !haystack.includes('media') && !haystack.includes('image')) return false;
      if (type === 'automation' && !String(workflow.AutomationReadiness || '').toLowerCase().includes('ready')) return false;
      if (type === 'powerful' && Number(workflow.RankScore || 0) < 80) return false;
      if (type === 'easy' && workflow.Difficulty !== 'Easy') return false;
      return true;
    }).sort((a, b) => Number(b.RankScore || 0) - Number(a.RankScore || 0));
  }

  function workflowIcons(workflow) {
    return (workflow.AppNames || []).map((name, index) => (
      `${index ? '<span class="plus">+</span>' : ''}<img src="${safe(iconUrl(name))}" alt="${safe(name)}">`
    )).join('') + '<span class="equals">=</span>';
  }

  function workflowCard(workflow) {
    return `<article class="workflowCard" data-workflow="${safe(workflow.Id)}">
      <div class="workflowIcons">${workflowIcons(workflow)}</div>
      <h4>${safe(workflow.WorkflowName)}</h4>
      <p>${safe(workflow.Description)}</p>
      <div class="workflowMeta">${workflowBadges(workflow)}</div>
      <p class="muted">${safe(workflow.SignInRequirement || 'No sign-in needed where known')}</p>
      <div class="actionStrip">
        <button class="btn primary small" data-action="preview" data-workflow="${safe(workflow.Id)}" type="button">Preview Plan</button>
        <button class="btn secondary small" data-action="export" data-workflow="${safe(workflow.Id)}" type="button">Export Plan</button>
        <button class="btn secondary small" data-action="favourite" data-workflow="${safe(workflow.Id)}" type="button">Favourite</button>
        <button class="btn secondary small" data-action="launch" data-workflow="${safe(workflow.Id)}" type="button">Launch Apps</button>
      </div>
    </article>`;
  }

  function renderEquation() {
    const parts = selectedApps.map((app, index) => (
      `${index ? '<span class="plus">+</span>' : ''}<span class="equationItem"><img src="${safe(iconUrl(app))}" alt="">${safe(app.Name)}</span>`
    ));
    const result = activeWorkflow ? safe(activeWorkflow.WorkflowName) : 'Select apps';
    byId('equationPreview').innerHTML = `${parts.join('')}<span class="equals">=</span><strong>${result}</strong>`;
  }

  function renderIntegrations() {
    const matches = workflowsForSelection();
    activeWorkflow = matches[0] || null;
    byId('bestMatch').innerHTML = activeWorkflow ? workflowCard(activeWorkflow) : '<p class="muted">No matching workflow in the current dashboard index.</p>';
    byId('integrationCards').innerHTML = matches.slice(0, 80).map(workflowCard).join('');
    renderEquation();
    wireWorkflowButtons();
  }

  function renderSuggestions() {
    const selectedNames = selectedApps.map((app) => normalized(app.Name));
    const scores = new Map();
    state.integrations.forEach((workflow) => {
      const workflowNames = (workflow.AppNames || []).map(normalized);
      if (!selectedNames.length) return;
      if (!selectedNames.every((name) => workflowNames.includes(name))) return;
      (workflow.AppNames || []).forEach((name) => {
        const key = normalized(name);
        if (selectedNames.includes(key)) return;
        const app = findApp(name) || { Name: name, IconUrl: '../data/icons/fallback-app.svg', Installed: false };
        if (isPaidBlocked(app)) return;
        const current = scores.get(key) || { app, score: 0, count: 0 };
        current.score += Number(workflow.RankScore || 0);
        if (app.Installed) current.score += 25;
        if (app.IsOpenSource) current.score += 10;
        if (app.IsFreeOrFreeTier) current.score += 8;
        current.count += 1;
        scores.set(key, current);
      });
    });
    const suggestions = [...scores.values()].sort((a, b) => b.score - a.score).slice(0, 8);
    byId('suggestionGrid').innerHTML = suggestions.length ? suggestions.map(({ app, count }) => (
      `<button class="suggestion" type="button" data-app="${safe(app.Name)}">
        <img src="${safe(iconUrl(app))}" alt="">
        <span>${safe(app.Name)}<br><small class="muted">${count} matching workflows</small></span>
        ${app.Installed ? badge('Installed', 'ok') : badge('Candidate', 'warn')}
      </button>`
    )).join('') : '<p class="muted">Suggestions appear after selecting an app.</p>';
    document.querySelectorAll('.suggestion').forEach((button) => {
      button.addEventListener('click', () => toggleApp(button.dataset.app));
    });
  }

  function renderWorkflowSuggestions() {
    const suggestions = state.suggestions && state.suggestions.length ? state.suggestions : state.integrations.slice(0, 12);
    byId('workflowSuggestionGrid').innerHTML = suggestions.length ? suggestions.map(workflowCard).join('') : '<p class="muted">No workflow suggestions available. Refresh dashboard state to import integration templates.</p>';
    wireWorkflowButtons();
  }

  function updateBuilder() {
    setProgress('Updating visual builder', 55);
    renderSlots();
    renderAppGrid();
    renderIntegrations();
    renderSuggestions();
    setProgress('Ready', 100);
    setTimeout(() => setProgress('Ready', 0), 500);
  }

  function findWorkflow(id) {
    return state.integrations.find((workflow) => workflow.Id === id) || activeWorkflow;
  }

  function showDialog(title, body) {
    byId('dialogTitle').textContent = title;
    byId('dialogBody').textContent = typeof body === 'string' ? body : JSON.stringify(body, null, 2);
    byId('planDialog').showModal();
  }

  function planText(workflow) {
    if (!workflow) return 'No workflow selected.';
    const lines = Array.isArray(workflow.PowerShellPlan) ? workflow.PowerShellPlan : [];
    return [
      `Workflow: ${workflow.WorkflowName}`,
      `Apps: ${(workflow.AppNames || []).join(' + ')}`,
      `Risk: ${workflow.RiskLevel}`,
      `Sign-in: ${workflow.SignInRequirement}`,
      '',
      ...lines
    ].join('\n');
  }

  async function postJson(url, payload) {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
    if (!response.ok) throw new Error(`Request failed: ${response.status}`);
    return response.json();
  }

  async function saveFavourite(workflow) {
    if (!workflow) return;
    const payload = {
      id: workflow.Id,
      apps: workflow.AppNames || [],
      icons: (workflow.AppNames || []).map(iconUrl),
      workflowDescription: workflow.Description,
      actionPlan: workflow.PowerShellPlan || [],
      tags: [workflow.Category, workflow.RiskLevel, workflow.AutomationReadiness].filter(Boolean)
    };
    try {
      const result = await postJson('/api/favourites', payload);
      showDialog('Favourite Saved', result);
    } catch (error) {
      const local = JSON.parse(localStorage.getItem('powerGorillaFavourites') || '[]');
      local.push({ ...payload, dateSaved: new Date().toISOString(), localOnly: true });
      localStorage.setItem('powerGorillaFavourites', JSON.stringify(local));
      showDialog('Favourite Saved Locally', 'The local server was not available, so this browser saved a local copy.');
    }
  }

  async function exportPlan(workflow) {
    if (!workflow) return;
    const payload = {
      exportedAt: new Date().toISOString(),
      workflow,
      safety: state.safety
    };
    try {
      const result = await postJson('/api/export-plan', payload);
      showDialog('Plan Exported', result);
    } catch (error) {
      const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `PowerGorilla-Plan-${workflow.Id}.json`;
      link.click();
      URL.revokeObjectURL(url);
    }
  }

  function previewLaunch(workflow) {
    if (!workflow) return;
    showDialog('Launch Apps Preview', [
      'No apps were launched.',
      'Phase 1 only previews this action.',
      '',
      `Apps: ${(workflow.AppNames || []).join(', ')}`,
      'Future confirmed execution will use PowerShell validation and a confirmation gate.'
    ].join('\n'));
  }

  function wireWorkflowButtons() {
    document.querySelectorAll('[data-action][data-workflow]').forEach((button) => {
      button.addEventListener('click', () => {
        const workflow = findWorkflow(button.dataset.workflow);
        if (button.dataset.action === 'preview') showDialog('PowerShell Preview Plan', planText(workflow));
        if (button.dataset.action === 'export') exportPlan(workflow);
        if (button.dataset.action === 'favourite') saveFavourite(workflow);
        if (button.dataset.action === 'launch') previewLaunch(workflow);
      });
    });
  }

  function renderGoalResults() {
    const goal = normalized(byId('goalSelect').value);
    const words = goal.split(' ').filter(Boolean);
    const matches = state.integrations.filter((workflow) => {
      const haystack = normalized(`${workflow.WorkflowName} ${workflow.Description} ${workflow.Category} ${(workflow.AppNames || []).join(' ')}`);
      return words.some((word) => haystack.includes(word));
    }).sort((a, b) => Number(b.RankScore || 0) - Number(a.RankScore || 0)).slice(0, 12);
    byId('goalResults').innerHTML = matches.map(workflowCard).join('') || '<p class="muted">No matching goal workflows in the current dashboard index.</p>';
    wireWorkflowButtons();
  }

  function renderSignIn() {
    const rows = state.signIn.slice(0, 300).map((row) => (
      `<tr><td>${safe(row.AppName)}</td><td>${safe(row.Status)}</td><td>${safe(row.SignInMode)}</td><td>${safe(row.LocalMode)}</td><td>${safe(row.Notes)}</td></tr>`
    )).join('');
    byId('signinTable').innerHTML = `<table><thead><tr><th>App</th><th>Status</th><th>Sign-In</th><th>Local Mode</th><th>Notes</th></tr></thead><tbody>${rows}</tbody></table>`;
  }

  function renderRiskAndSettings() {
    byId('riskPanel').innerHTML = [
      ['Destructive actions', state.safety.destructiveActionsEnabled ? 'Enabled' : 'Disabled', 'ok'],
      ['Dangerous UI actions', state.safety.dangerousButtonsPreviewOnly ? 'Preview only' : 'Needs review', 'ok'],
      ['Credential storage', state.safety.credentialsStored ? 'Review needed' : 'None', 'ok'],
      ['Cost policy', state.safety.paidOrTrialBlocked ? 'No paid or trials' : 'Needs review', 'ok'],
      ['Dataset files', `${state.datasets.filter((item) => item.Exists).length} present`, 'info']
    ].map(([title, value, type]) => `<article class="workflowCard"><h4>${safe(title)}</h4><div class="workflowMeta">${badge(value, type)}</div></article>`).join('');

    byId('settingsPanel').innerHTML = `<pre>${safe(JSON.stringify(state.safety, null, 2))}</pre>`;
    byId('reportsPanel').innerHTML = `<p>Reports: PowerGorilla/reports</p><p>Logs: PowerGorilla/logs</p><p>Favourites: PowerGorilla/data/processed/favourites.json</p>`;
    byId('updaterPanel').innerHTML = '<p>Scan-only controls are available. No update command runs directly from the dashboard.</p>';
    byId('fixerPanel').innerHTML = '<p>Diagnostic previews are available. Cleanup and repair execution remain gated.</p>';
  }

  function exportJson(name, data) {
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = name;
    link.click();
    URL.revokeObjectURL(url);
  }

  function wireControls() {
    ['appSearch', 'categoryFilter', 'installedOnly', 'openSourceOnly', 'freeOnly', 'localOnly'].forEach((id) => {
      byId(id).addEventListener('input', renderAppGrid);
      byId(id).addEventListener('change', renderAppGrid);
    });
    ['workflowSearch', 'workflowTypeFilter'].forEach((id) => {
      byId(id).addEventListener('input', renderIntegrations);
      byId(id).addEventListener('change', renderIntegrations);
    });
    document.querySelectorAll('.segmented button').forEach((button) => {
      button.addEventListener('click', () => {
        combinationSize = Number(button.dataset.size);
        document.querySelectorAll('.segmented button').forEach((item) => item.classList.remove('active'));
        button.classList.add('active');
        selectedApps = selectedApps.slice(0, combinationSize);
        updateBuilder();
      });
    });
    byId('clearSelectionBtn').addEventListener('click', () => {
      selectedApps = [];
      updateBuilder();
    });
    byId('previewPlanBtn').addEventListener('click', () => showDialog('PowerShell Preview Plan', planText(activeWorkflow)));
    byId('exportPlanBtn').addEventListener('click', () => exportPlan(activeWorkflow));
    byId('favouriteBtn').addEventListener('click', () => saveFavourite(activeWorkflow));
    byId('launchPreviewBtn').addEventListener('click', () => previewLaunch(activeWorkflow));
    byId('generatePlanBtn').addEventListener('click', () => showDialog('Generated PowerShell Plan', planText(activeWorkflow)));
    byId('goalBtn').addEventListener('click', renderGoalResults);
    byId('exportStateBtn').addEventListener('click', () => exportJson('PowerGorilla-State.json', state));
    byId('exportInventoryBtn').addEventListener('click', () => exportJson('PowerGorilla-Inventory.json', state.apps));
    byId('exportSigninBtn').addEventListener('click', () => exportJson('PowerGorilla-SignIn-Report.json', state.signIn));
    byId('refreshBtn').addEventListener('click', () => {
      setProgress('Refresh requested', 100);
      showDialog('Refresh Data', 'Run .\\scripts\\Setup-PowerGorilla.ps1 or .\\scripts\\Validate-PowerGorilla.ps1 to refresh the PowerShell-generated dashboard state.');
    });
    document.querySelectorAll('[data-preview-command]').forEach((button) => {
      button.addEventListener('click', () => {
        showDialog('Command Preview', {
          command: button.dataset.previewCommand,
          mode: 'Dry-run preview',
          destructive: false,
          note: 'No system-changing action was triggered from the dashboard.'
        });
      });
    });
  }

  function boot() {
    setProgress('Loading dashboard state', 22);
    renderMetrics();
    renderCategories();
    renderAppGrid();
    renderSlots();
    renderIntegrations();
    renderSuggestions();
    renderWorkflowSuggestions();
    renderGoalResults();
    renderSignIn();
    renderRiskAndSettings();
    wireControls();
    setProgress('Ready', 100);
    setTimeout(() => setProgress('Ready', 0), 600);
  }

  boot();
})();
