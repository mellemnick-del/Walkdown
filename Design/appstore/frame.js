// Frames raw simulator screenshots into App Store marketing images:
// a headline on the Reassured dusk sky, with the screenshot below as a rounded device.
// Usage: node frame.js <rawDir> <outDir>
// rawDir holds iphone/ and ipad/ folders of NN-name.png files.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const captions = {
  '01-home': ['Know where you stand.', 'Your score and next steps, the moment you open it.'],
  '02-walk': ['Audit one control at a time.', 'Big, clear buttons built for the field.'],
  '03-workspace': ['CMMC, HIPAA, PCI, SOC 2, NIST.', 'Every control scored as you go.'],
  '04-tasks': ['Every gap becomes a plan.', 'Prioritized fixes with owners and due dates.'],
  '05-locker': ['Evidence, locked and ready.', 'Expiration reminders and Face ID protection.'],
  '06-report': ['Reports clients actually read.', 'Executive summary, score by area, and findings.'],
  '07-guide': ['Plain-English guides.', "Who needs it, how it's assessed, where to start."],
  '08-home-dark': ['Calm, day or night.', 'Everything stays on your device.'],
};

const devices = {
  iphone: { width: 1320, height: 2868, shotWidth: 1010, radius: 120, top: 600, title: 104, sub: 50, pad: 110 },
  ipad: { width: 2064, height: 2752, shotWidth: 1560, radius: 70, top: 640, title: 118, sub: 56, pad: 160 },
};

function page(device, imgPath, [title, sub]) {
  const d = devices[device];
  const img = fs.readFileSync(imgPath).toString('base64');
  return `<!doctype html><html><head><meta charset="utf-8"><style>
    html, body { margin: 0; width: ${d.width}px; height: ${d.height}px; overflow: hidden; }
    body {
      background:
        radial-gradient(ellipse 70% 30% at 50% 100%, rgba(255,217,138,.45), transparent 70%),
        linear-gradient(180deg, #0F2C5C 0%, #163E6E 30%, #245F7F 68%, #C98A4B 100%);
      font-family: 'Inter', sans-serif; color: white; position: relative;
    }
    .text { position: absolute; top: ${d.pad}px; left: ${d.pad}px; right: ${d.pad}px; text-align: center; }
    h1 { font-family: 'Bitstream Charter', serif; font-weight: 700; font-size: ${d.title}px;
         line-height: 1.08; margin: 0 0 ${Math.round(d.sub * 0.6)}px; letter-spacing: -1px; text-wrap: balance; }
    p { font-size: ${d.sub}px; line-height: 1.3; margin: 0; color: rgba(255,255,255,.82); font-weight: 500; text-wrap: balance; }
    .sun { position: absolute; left: 50%; top: ${d.top - 120}px; width: ${d.shotWidth * 0.9}px; height: 300px;
           transform: translateX(-50%); background: radial-gradient(ellipse at center, rgba(255,217,138,.35), transparent 70%); }
    .device { position: absolute; left: 50%; top: ${d.top}px; width: ${d.shotWidth}px; transform: translateX(-50%);
              border-radius: ${d.radius}px; overflow: hidden;
              box-shadow: 0 40px 90px rgba(4,10,25,.55), 0 0 0 ${Math.round(d.shotWidth * 0.018)}px rgba(10,23,48,.92); }
    .device img { display: block; width: 100%; }
  </style></head><body>
    <div class="text"><h1>${title}</h1><p>${sub}</p></div>
    <div class="sun"></div>
    <div class="device"><img src="data:image/png;base64,${img}"></div>
  </body></html>`;
}

(async () => {
  const [, , rawDir, outDir] = process.argv;
  const browser = await chromium.launch();
  for (const device of Object.keys(devices)) {
    const d = devices[device];
    const dir = path.join(rawDir, device);
    if (!fs.existsSync(dir)) continue;
    fs.mkdirSync(path.join(outDir, device), { recursive: true });
    const p = await browser.newPage({ viewport: { width: d.width, height: d.height } });
    for (const file of fs.readdirSync(dir).sort()) {
      const key = path.basename(file, '.png');
      if (!captions[key]) continue;
      await p.setContent(page(device, path.join(dir, file), captions[key]), { waitUntil: 'load' });
      await p.screenshot({ path: path.join(outDir, device, file) });
    }
    await p.close();
  }
  await browser.close();
})();
