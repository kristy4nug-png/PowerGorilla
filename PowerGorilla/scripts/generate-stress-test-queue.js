const fs = require('fs');
const path = require('path');

// 100% Free-tier, open-source, and local-first desktop apps from your inventory
const apps = [
  'Audacity', 
  'Blender', 
  '7-Zip', 
  'VLC Media Player', 
  'GIMP', 
  'Inkscape', 
  'Notepad++', 
  'Visual Studio Code', 
  'Everything', 
  'WinSCP'
];

const combinations = [];

// Helper to get random unique subset of size count
function getRandomApps(count) {
  const shuffled = [...apps].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, count);
}

// Generate 100 unique, policy-compliant prompts
for (let i = 1; i <= 100; i++) {
  const appCount = Math.floor(Math.random() * 3) + 2; // Random size: 2, 3, or 4 apps
  const selected = getRandomApps(appCount);
  
  const workflowName = `Automated Local ${selected.join(' & ')} Workflow`;
  const promptText = `Design a highly resilient, local-first Windows command center plan that integrates these exact applications to complete a combined user task: ${selected.join(', ')}. Keep the task fully open-source, local-first, and free. Enforce costAllowed as true. Output the step-by-step PowerShell plan.`;

  combinations.push({
    item_id: `stress_test_item_${String(i).padStart(3, '0')}`,
    batch_id: 'batch_stress_test_100',
    sequence_number: i,
    item_type: 'workflow',
    status: 'pending',
    input_data: {
      workflowName: workflowName,
      prompt_text: promptText,
      appNames: selected,
      combinationSize: appCount,
      model: 'llama3.2:1b'
    }
  });
}

const outPath = path.join(__dirname, '..', 'data', 'queue', 'batch_stress_test_100.queue.json');
const outDir = path.dirname(outPath);

if (!fs.existsSync(outDir)) {
  fs.mkdirSync(outDir, { recursive: true });
}

fs.writeFileSync(outPath, JSON.stringify(combinations, null, 2), 'utf8');
console.log(`Generated 100 stress-test prompts successfully at: ${outPath}`);
