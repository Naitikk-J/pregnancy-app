// Regenerates the app launcher icon + splash art in the teal + blush brand.
// Run from the worker/ dir (where sharp is installed):  node gen_icons.mjs
import sharp from 'sharp';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const outDir = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
  'assets',
  'icon',
);

const S = 1024;

// A soft, rounded heart path centred in a 1024 box, scaled by `k` (fraction of
// the canvas the heart spans) — used for both full-bleed and adaptive foreground.
function heart(k, color, cx = S / 2, cy = S / 2) {
  const w = S * k;
  // Heart drawn in a 0..100 viewBox then transformed to the target size.
  const scale = w / 100;
  const tx = cx - w / 2;
  const ty = cy - (w * 0.9) / 2;
  const d =
    'M50 88 C50 88 8 60 8 33 C8 16 22 8 34 8 C43 8 48 14 50 18 ' +
    'C52 14 57 8 66 8 C78 8 92 16 92 33 C92 60 50 88 50 88 Z';
  return `<g transform="translate(${tx} ${ty}) scale(${scale})"><path d="${d}" fill="${color}"/></g>`;
}

// Full-bleed launcher icon: teal gradient ground + blush glow + white heart.
const iconSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}" viewBox="0 0 ${S} ${S}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#1B6156"/>
      <stop offset="1" stop-color="#0E3F38"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.5" cy="0.46" r="0.5">
      <stop offset="0" stop-color="#F9D3CB" stop-opacity="0.55"/>
      <stop offset="1" stop-color="#F9D3CB" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="${S}" height="${S}" rx="230" fill="url(#bg)"/>
  <circle cx="${S / 2}" cy="${S * 0.46}" r="360" fill="url(#glow)"/>
  ${heart(0.52, '#FFFFFF', S / 2, S * 0.5)}
  <circle cx="${S * 0.62}" cy="${S * 0.36}" r="30" fill="#F1857B"/>
</svg>`;

// Adaptive foreground: transparent ground, smaller heart inside the 66% safe
// zone (Android crops adaptive icons heavily).
const fgSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}" viewBox="0 0 ${S} ${S}">
  ${heart(0.42, '#FFFFFF', S / 2, S / 2)}
  <circle cx="${S * 0.6}" cy="${S * 0.39}" r="24" fill="#F1857B"/>
</svg>`;

// Splash: transparent ground (native splash composits on the teal color), a
// centred white heart with a soft blush halo.
const splashSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}" viewBox="0 0 ${S} ${S}">
  <defs>
    <radialGradient id="halo" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#F9D3CB" stop-opacity="0.35"/>
      <stop offset="1" stop-color="#F9D3CB" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <circle cx="${S / 2}" cy="${S / 2}" r="330" fill="url(#halo)"/>
  ${heart(0.4, '#FFFFFF', S / 2, S / 2)}
</svg>`;

async function render(svg, name) {
  const out = path.join(outDir, name);
  await sharp(Buffer.from(svg)).png().toFile(out);
  console.log('wrote', out);
}

await render(iconSvg, 'icon.png');
await render(fgSvg, 'icon_fg.png');
await render(splashSvg, 'splash.png');
console.log('done');
