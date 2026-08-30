import { cpSync, existsSync, mkdirSync, rmSync } from 'node:fs';

const files = ['index.html', 'assets', 'config.js', 'manifest.webmanifest', 'sw.js'];
rmSync('dist', { recursive: true, force: true });
mkdirSync('dist', { recursive: true });
for (const file of files) {
  if (!existsSync(file)) throw new Error(`Fichier requis absent: ${file}`);
  cpSync(file, `dist/${file}`, { recursive: true });
}
console.log('Build terminé: dist/');
