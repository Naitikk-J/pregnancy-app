// Generates warm, flat, on-brand illustration PNGs for the app (hero baby,
// empty-state mom, decorative bloom). Run from worker/:  node gen_illustrations.mjs
import sharp from 'sharp';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const outDir = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
  'assets',
  'images',
);

// Brand palette
const teal = '#14564D';
const tealDark = '#0E3F38';
const coral = '#F1857B';
const blush = '#F9D3CB';
const blushLite = '#FBE6E0';
const cream = '#FBF6F1';
const lav = '#8E7CC3';
const mint = '#7FC8A0';
const skin = '#F4C7A8';
const cheek = '#F1857B';

// A cute swaddled sleeping baby — used in the hero ring centre and as the baby
// avatar. Transparent background.
const babySvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <!-- swaddle bundle -->
  <path d="M256 150
           C150 150 120 250 120 330
           C120 430 190 470 256 470
           C322 470 392 430 392 330
           C392 250 362 150 256 150 Z"
        fill="${blush}"/>
  <path d="M256 150 C150 150 120 250 120 330 C120 380 138 412 168 434
           C150 400 150 320 176 268 C202 216 232 200 256 200 Z"
        fill="${blushLite}"/>
  <!-- swaddle knot / hood -->
  <ellipse cx="256" cy="176" rx="120" ry="70" fill="${mint}"/>
  <ellipse cx="256" cy="182" rx="96" ry="56" fill="${cream}"/>
  <!-- face -->
  <circle cx="256" cy="206" r="76" fill="${skin}"/>
  <!-- little hair curl -->
  <path d="M256 132 q18 8 8 30" stroke="${tealDark}" stroke-width="10"
        fill="none" stroke-linecap="round"/>
  <!-- closed sleeping eyes -->
  <path d="M214 208 q16 16 32 0" stroke="${tealDark}" stroke-width="7"
        fill="none" stroke-linecap="round"/>
  <path d="M266 208 q16 16 32 0" stroke="${tealDark}" stroke-width="7"
        fill="none" stroke-linecap="round"/>
  <!-- cheeks -->
  <circle cx="206" cy="234" r="13" fill="${cheek}" opacity="0.55"/>
  <circle cx="306" cy="234" r="13" fill="${cheek}" opacity="0.55"/>
  <!-- smile -->
  <path d="M240 250 q16 14 32 0" stroke="${tealDark}" stroke-width="6"
        fill="none" stroke-linecap="round"/>
</svg>`;

// A pregnant mother, flat ¾ view, cradling her belly with a heart. Transparent
// background. Used in empty states and welcome surfaces.
const momSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <!-- soft ground blob -->
  <ellipse cx="256" cy="470" rx="150" ry="26" fill="${blush}" opacity="0.6"/>
  <!-- hair back -->
  <path d="M188 92 C150 120 150 210 172 260 L214 250 C196 200 200 150 214 120 Z"
        fill="${tealDark}"/>
  <!-- head -->
  <circle cx="236" cy="112" r="46" fill="${skin}"/>
  <!-- hair top -->
  <path d="M190 108 C190 66 230 54 262 66 C286 74 292 96 288 112
           C280 92 250 84 232 92 C214 100 200 104 190 108 Z" fill="${tealDark}"/>
  <!-- face hint -->
  <circle cx="252" cy="112" r="5" fill="${tealDark}"/>
  <circle cx="244" cy="126" r="8" fill="${cheek}" opacity="0.5"/>
  <!-- dress body with rounded belly -->
  <path d="M214 158
           C196 168 182 196 180 240
           C150 270 150 330 182 356
           C176 400 178 430 190 452
           L320 452
           C330 420 326 372 322 348
           C356 320 356 258 320 236
           C316 196 300 168 280 158
           C262 150 232 150 214 158 Z"
        fill="${coral}"/>
  <!-- belly highlight -->
  <circle cx="250" cy="300" r="70" fill="#F79A90"/>
  <!-- cradling arms -->
  <path d="M212 250 C186 286 188 330 214 356" stroke="${skin}"
        stroke-width="26" fill="none" stroke-linecap="round"/>
  <path d="M300 250 C326 286 322 332 292 356" stroke="${skin}"
        stroke-width="26" fill="none" stroke-linecap="round"/>
  <!-- heart on belly -->
  <path d="M250 292
           c-8 -12 -30 -10 -30 8
           c0 14 20 26 30 34
           c10 -8 30 -20 30 -34
           c0 -18 -22 -20 -30 -8 Z" fill="${cream}"/>
</svg>`;

// A soft decorative floral bloom for headers / accents. Transparent.
const bloomSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <g transform="translate(256 256)">
    ${[0, 60, 120, 180, 240, 300]
      .map(
        (a) =>
          `<ellipse cx="0" cy="-90" rx="46" ry="80" fill="${blush}" opacity="0.9" transform="rotate(${a})"/>`,
      )
      .join('')}
    <circle cx="0" cy="0" r="52" fill="${coral}"/>
    <circle cx="0" cy="0" r="30" fill="${cream}"/>
  </g>
</svg>`;

async function render(svg, name) {
  const out = path.join(outDir, name);
  await sharp(Buffer.from(svg)).png().toFile(out);
  console.log('wrote', out);
}

await render(babySvg, 'baby.png');
await render(momSvg, 'mom.png');
await render(bloomSvg, 'bloom.png');
console.log('done');
