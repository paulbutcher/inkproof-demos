// Copyright (c) 2026 Paul Butcher. All rights reserved.
// Released under Apache 2.0 license as described in the file LICENSE.
// Browser tests: the built site, served under /inkproof-demos/ as GitHub Pages serves it.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { chromium } from 'playwright';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';

const root = new URL('./dist/', import.meta.url).pathname;
const prefix = '/inkproof-demos/';
const types = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.wasm': 'application/wasm' };

let server, browser, base;

before(async () => {
  server = createServer(async (req, res) => {
    const url = new URL(req.url, 'http://x').pathname;
    if (!url.startsWith(prefix)) { res.writeHead(404).end(); return; }
    let path = normalize(join(root, url.slice(prefix.length)));
    if (!path.startsWith(root)) { res.writeHead(404).end(); return; }
    if (url.endsWith('/')) path = join(path, 'index.html');
    try {
      res.writeHead(200, { 'content-type': types[extname(path)] ?? 'application/octet-stream' }).end(await readFile(path));
    } catch { res.writeHead(404).end(); }
  });
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  base = `http://127.0.0.1:${server.address().port}${prefix}`;
  browser = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
});

after(async () => {
  await browser?.close();
  server?.close();
});

const open = async path => {
  const page = await browser.newPage();
  const problems = [];
  page.on('console', m => { if (['error', 'warning'].includes(m.type())) problems.push(m.text()); });
  page.on('pageerror', e => problems.push(e.message));
  page.on('requestfailed', r => problems.push(`request failed: ${r.url()}`));
  page.on('response', r => { if (r.status() >= 400) problems.push(`${r.status()} ${r.url()}`); });
  await page.addInitScript(() => {
    window.draws = [];
    addEventListener('inkproof-draw', e => window.draws.push(e.detail));
  });
  await page.goto(base + path);
  return { page, problems };
};

const colours = page => page.evaluate(() => {
  const canvas = document.querySelector('inkproof-chart').shadowRoot.querySelector('canvas');
  const { width, height } = canvas;
  const d = canvas.getContext('2d').getImageData(0, 0, width, height).data;
  const count = { red: 0, green: 0, blue: 0 };
  for (let i = 0; i < d.length; i += 4) {
    const [r, g, b] = [d[i], d[i + 1], d[i + 2]];
    if (r > 200 && g < 60 && b < 60) count.red++;
    if (r < 60 && g > 100 && g < 160 && b < 60) count.green++;
    if (r < 60 && g < 60 && b > 200) count.blue++;
  }
  return count;
});

test('every demo the index lists opens from its relative link without console errors', async () => {
  const { page, problems } = await open('');
  const links = await page.$$eval('a[href^="./"]', as => as.map(a => a.getAttribute('href')));
  assert.ok(links.length > 0);
  assert.deepEqual(problems, []);
  for (const link of links) {
    const demo = await open(link);
    await demo.page.waitForFunction(() => window.draws.length >= 1);
    assert.deepEqual(demo.problems, [], link);
    await demo.page.close();
  }
  await page.close();
});

test('area fill draws its three series', async () => {
  const { page } = await open('area-fill/');
  await page.waitForFunction(() => window.draws.length >= 1);
  const { red, green, blue } = await colours(page);
  assert.ok(red > 0 && green > 0 && blue > 0, `red ${red}, green ${green}, blue ${blue}`);
  await page.close();
});

test('points draws its four charts', async () => {
  const { page } = await open('points/');
  await page.waitForFunction(() => window.draws.length >= 4);
  const { red, green, blue } = await colours(page);
  assert.ok(red > 0 && green > 0 && blue > 0, `red ${red}, green ${green}, blue ${blue}`);
  await page.close();
});

test('the million-point page shows the spikes naive decimation loses', async () => {
  const { page, problems } = await open('million/');
  await page.waitForFunction(() => window.draws.length >= 1);
  assert.deepEqual(problems, []);
  const lost = await page.evaluate(() => {
    const canvas = document.querySelector('inkproof-chart').shadowRoot.querySelector('canvas');
    const d = canvas.getContext('2d').getImageData(0, 0, canvas.width, canvas.height).data;
    const half = (canvas.height / 2) | 0;
    const dark = (from, to) => {
      let n = 0;
      for (let i = from * canvas.width * 4; i < to * canvas.width * 4; i += 4) if (d[i] < 80 && d[i + 1] < 80 && d[i + 2] < 80) n++;
      return n;
    };
    return { naive: dark(0, half), inkproof: dark(half, canvas.height) };
  });
  assert.ok(lost.naive > 0 && lost.inkproof > lost.naive, JSON.stringify(lost));
  await page.close();
});

test('server events draws its three series as envelopes', async () => {
  const { page, problems } = await open('server-events/');
  await page.waitForFunction(() => window.draws.length >= 1);
  assert.deepEqual(problems, []);
  const { red, green, blue } = await colours(page);
  assert.ok(red > 0 && green > 0 && blue > 0, `red ${red}, green ${green}, blue ${blue}`);
  await page.close();
});
