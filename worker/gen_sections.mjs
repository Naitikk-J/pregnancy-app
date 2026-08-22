// Flat spot illustrations for the Week-tracker section cards. Run from worker/:
//   node gen_sections.mjs
import sharp from 'sharp';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const outDir = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
  'assets',
  'images',
);

const teal = '#14564D';
const tealDark = '#0E3F38';
const coral = '#F1857B';
const blush = '#F9D3CB';
const mint = '#7FC8A0';
const amber = '#F4B36B';
const lav = '#8E7CC3';
const skin = '#F4C7A8';
const cream = '#FBF6F1';

const S = 512;
function wrap(inner) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}" viewBox="0 0 ${S} ${S}">${inner}</svg>`;
}

// Things to avoid — a friendly "no entry" sign.
const avoid = wrap(`
  <circle cx="256" cy="256" r="150" fill="${coral}"/>
  <circle cx="256" cy="256" r="112" fill="${cream}"/>
  <rect x="150" y="238" width="212" height="36" rx="18" fill="${coral}" transform="rotate(-45 256 256)"/>
`);

// Doctor's advice — a stethoscope.
const doctor = wrap(`
  <path d="M170 120 v90 a86 86 0 0 0 172 0 v-90"
        fill="none" stroke="${teal}" stroke-width="26" stroke-linecap="round"/>
  <circle cx="170" cy="112" r="20" fill="${teal}"/>
  <circle cx="342" cy="112" r="20" fill="${teal}"/>
  <path d="M256 296 v50 a70 70 0 0 0 70 70 h20"
        fill="none" stroke="${tealDark}" stroke-width="22" stroke-linecap="round"/>
  <circle cx="366" cy="404" r="46" fill="${coral}"/>
  <circle cx="366" cy="404" r="20" fill="${cream}"/>
`);

// Nutrition — a bowl with wholesome food + a leaf.
const nutrition = wrap(`
  <path d="M110 250 a146 146 0 0 0 292 0 Z" fill="${teal}"/>
  <path d="M110 250 a146 146 0 0 0 292 0" fill="none" stroke="${tealDark}" stroke-width="10"/>
  <ellipse cx="256" cy="250" rx="150" ry="26" fill="${mint}"/>
  <circle cx="205" cy="232" r="30" fill="${coral}"/>
  <circle cx="262" cy="226" r="26" fill="${amber}"/>
  <circle cx="312" cy="234" r="26" fill="${lav}"/>
  <path d="M262 150 q40 6 44 44 q-42 -4 -44 -44 Z" fill="${mint}"/>
  <path d="M262 150 q40 6 44 44" fill="none" stroke="${tealDark}" stroke-width="6"/>
`);

// Exercise — a walking expecting mother.
const exercise = wrap(`
  <circle cx="250" cy="120" r="40" fill="${skin}"/>
  <path d="M226 96 q24 -22 52 -4 q10 8 6 24 q-18 -18 -40 -12 q-14 4 -18 -8 Z" fill="${tealDark}"/>
  <path d="M250 160 q46 8 46 70 q0 44 -20 70" fill="${coral}"/>
  <path d="M250 160 q-30 6 -30 60 q0 8 2 16" fill="none" stroke="${coral}" stroke-width="26" stroke-linecap="round"/>
  <circle cx="286" cy="220" r="30" fill="#F79A90"/>
  <path d="M244 300 l-34 70" stroke="${teal}" stroke-width="24" fill="none" stroke-linecap="round"/>
  <path d="M262 300 l34 60" stroke="${tealDark}" stroke-width="24" fill="none" stroke-linecap="round"/>
  <path d="M232 200 l-40 40" stroke="${skin}" stroke-width="20" fill="none" stroke-linecap="round"/>
`);

// Yoga — a mother seated in meditation.
const yoga = wrap(`
  <circle cx="256" cy="150" r="42" fill="${skin}"/>
  <path d="M232 126 q24 -24 52 -4 q10 8 6 24 q-18 -18 -40 -12 q-14 4 -18 -8 Z" fill="${tealDark}"/>
  <path d="M256 196 q70 6 92 96 q6 26 -10 40 h-164 q-16 -14 -10 -40 q22 -90 92 -96 Z" fill="${lav}"/>
  <ellipse cx="256" cy="360" rx="150" ry="30" fill="${mint}" opacity="0.5"/>
  <path d="M150 330 q40 -30 106 -30 q66 0 106 30" fill="none" stroke="${teal}" stroke-width="22" stroke-linecap="round"/>
  <circle cx="150" cy="330" r="16" fill="${skin}"/>
  <circle cx="362" cy="330" r="16" fill="${skin}"/>
`);

async function render(svg, name) {
  const out = path.join(outDir, name);
  await sharp(Buffer.from(svg)).png().toFile(out);
  console.log('wrote', out);
}

await render(avoid, 'sec_avoid.png');
await render(doctor, 'sec_doctor.png');
await render(nutrition, 'sec_nutrition.png');
await render(exercise, 'sec_exercise.png');
await render(yoga, 'sec_yoga.png');
console.log('done');
