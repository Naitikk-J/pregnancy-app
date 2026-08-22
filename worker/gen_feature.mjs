// Generates the Play Store feature graphic (1024x500). Run from worker/:
//   node gen_feature.mjs
import sharp from 'sharp';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const outDir = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
  'assets',
  'store',
);

const W = 1024;
const H = 500;

// White heart path scaled to ~k of a 100 box, centred at (cx,cy).
function heart(k, color, cx, cy) {
  const w = 100 * k;
  const scale = w / 100;
  const tx = cx - w / 2;
  const ty = cy - (w * 0.9) / 2;
  const d =
    'M50 88 C50 88 8 60 8 33 C8 16 22 8 34 8 C43 8 48 14 50 18 ' +
    'C52 14 57 8 66 8 C78 8 92 16 92 33 C92 60 50 88 50 88 Z';
  return `<g transform="translate(${tx} ${ty}) scale(${scale})"><path d="${d}" fill="${color}"/></g>`;
}

// Multi-colour growth ring around the heart, echoing the app's hero.
function ring(cx, cy, r) {
  const segs = ['#7FC8A0', '#6FD0C0', '#F0857D', '#F4B36B', '#A99BE0'];
  const parts = [];
  const gap = 8; // degrees
  const step = 360 / segs.length;
  for (let i = 0; i < segs.length; i++) {
    const a0 = (i * step + gap / 2 - 90) * (Math.PI / 180);
    const a1 = ((i + 1) * step - gap / 2 - 90) * (Math.PI / 180);
    const x0 = cx + r * Math.cos(a0);
    const y0 = cy + r * Math.sin(a0);
    const x1 = cx + r * Math.cos(a1);
    const y1 = cy + r * Math.sin(a1);
    const large = a1 - a0 > Math.PI ? 1 : 0;
    parts.push(
      `<path d="M${x0} ${y0} A${r} ${r} 0 ${large} 1 ${x1} ${y1}" fill="none" stroke="${segs[i]}" stroke-width="14" stroke-linecap="round"/>`,
    );
  }
  return parts.join('');
}

const svg = `
<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#1B6156"/>
      <stop offset="1" stop-color="#0E3F38"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.22" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#F9D3CB" stop-opacity="0.45"/>
      <stop offset="1" stop-color="#F9D3CB" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="${W}" height="${H}" fill="url(#bg)"/>
  <circle cx="230" cy="250" r="230" fill="url(#glow)"/>

  ${ring(230, 250, 150)}
  ${heart(1.5, '#FFFFFF', 230, 250)}
  <circle cx="300" cy="180" r="16" fill="#F1857B"/>

  <text x="470" y="235" font-family="Poppins, Segoe UI, Arial, sans-serif"
        font-size="66" font-weight="700" fill="#FFFFFF">Pregnancy</text>
  <text x="470" y="305" font-family="Poppins, Segoe UI, Arial, sans-serif"
        font-size="66" font-weight="700" fill="#FFFFFF">Companion</text>
  <text x="472" y="360" font-family="Inter, Segoe UI, Arial, sans-serif"
        font-size="30" fill="#CFE8E0">Your week-by-week pregnancy guide</text>
</svg>`;

await sharp(Buffer.from(svg))
  .png()
  .toFile(path.join(outDir, 'feature_graphic.png'));
console.log('wrote', path.join(outDir, 'feature_graphic.png'));
