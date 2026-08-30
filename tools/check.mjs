import { readFileSync, existsSync } from 'node:fs';
import { spawnSync } from 'node:child_process';

const required = ['index.html','assets/app.css','assets/app.js','config.js','manifest.webmanifest','sw.js','README.md'];
const missing = required.filter(file => !existsSync(file));
if (missing.length) throw new Error(`Fichiers absents: ${missing.join(', ')}`);

const html = readFileSync('index.html','utf8');
const js = readFileSync('assets/app.js','utf8');
for (const marker of ['dashboard','feed','experts','shop','carecart','passport','messages','professional','seller','admin']) {
  if (!html.includes(`id="${marker}"`)) throw new Error(`Vue absente: ${marker}`);
}
const ids = new Set([...html.matchAll(/id="([^"]+)"/g)].map(match => match[1]));
const refs = [...js.matchAll(/getElementById\(['"]([^'"]+)/g)].map(match => match[1]);
const missingIds = [...new Set(refs.filter(id => !ids.has(id)))];
if (missingIds.length) throw new Error(`Références DOM absentes: ${missingIds.join(', ')}`);

const syntax = spawnSync(process.execPath, ['--check','assets/app.js'], { encoding:'utf8' });
if (syntax.status !== 0) throw new Error(syntax.stderr || 'Erreur de syntaxe JavaScript');
JSON.parse(readFileSync('manifest.webmanifest','utf8'));
console.log(`Checks OK: ${ids.size} identifiants DOM, ${refs.length} références JS, manifeste valide.`);
