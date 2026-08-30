import http from 'node:http';
import { createReadStream, existsSync, statSync } from 'node:fs';
import { extname, join, normalize, resolve } from 'node:path';

const requestedRoot = process.argv[2] && !/^\d+$/.test(process.argv[2]) ? process.argv[2] : '.';
const portArg = process.argv[2] && /^\d+$/.test(process.argv[2]) ? process.argv[2] : process.argv[3];
const port = Number(portArg || process.env.PORT || 5173);
const root = resolve(requestedRoot);
const mime = { '.html':'text/html; charset=utf-8', '.js':'text/javascript; charset=utf-8', '.css':'text/css; charset=utf-8', '.json':'application/json; charset=utf-8', '.webmanifest':'application/manifest+json; charset=utf-8', '.svg':'image/svg+xml', '.png':'image/png', '.jpg':'image/jpeg', '.jpeg':'image/jpeg' };

const server = http.createServer((req, res) => {
  const rawPath = decodeURIComponent((req.url || '/').split('?')[0]);
  const safePath = normalize(rawPath).replace(/^(\.\.[/\\])+/, '');
  let filePath = join(root, safePath === '/' ? 'index.html' : safePath);
  if (!filePath.startsWith(root)) { res.writeHead(403); res.end('Forbidden'); return; }
  if (!existsSync(filePath) || statSync(filePath).isDirectory()) filePath = join(root, 'index.html');
  res.setHeader('Content-Type', mime[extname(filePath)] || 'application/octet-stream');
  res.setHeader('Cache-Control', extname(filePath) === '.html' ? 'no-cache' : 'public, max-age=300');
  createReadStream(filePath).on('error', () => { res.writeHead(500); res.end('Server error'); }).pipe(res);
});

server.listen(port, '127.0.0.1', () => console.log(`BeautyLink Africa: http://localhost:${port}`));
