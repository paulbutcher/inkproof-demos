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
    window.views = [];
    addEventListener('inkproof-view', e => window.views.push(e.detail));
    window.uploads = [];
    const bufferData = WebGL2RenderingContext.prototype.bufferData;
    WebGL2RenderingContext.prototype.bufferData = function (target, data, usage) {
      window.uploads.push({ frame: window.draws.length, size: data.byteLength, data: Array.from(new Uint32Array(data.buffer, data.byteOffset, data.byteLength / 4)).join(',') });
      return bufferData.call(this, target, data, usage);
    };
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

test('the gallery B pages draw their charts', async () => {
  for (const [path, charts] of [['scatter/', 1], ['sparklines/', 20], ['sparklines-bars/', 2], ['multi-bars/', 4], ['grouped-bars/', 10], ['latency-heatmap/', 2]]) {
    const { page, problems } = await open(path);
    await page.waitForFunction(n => window.draws.length >= n, charts);
    assert.deepEqual(problems, [], path);
    await page.close();
  }
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

test('axis control draws its red series and axis', async () => {
  const { page, problems } = await open('axis-control/');
  await page.waitForFunction(() => window.draws.length >= 1);
  assert.deepEqual(problems, []);
  const { red } = await colours(page);
  assert.ok(red > 0, `red ${red}`);
  await page.close();
});

test('the time series pages draw every chart in their series colours', async () => {
  for (const [path, charts, wanted] of [['missing-data/', 2, ['red', 'blue']], ['log-scales/', 2, []], ['high-low-bands/', 1, ['red', 'blue', 'green']], ['path-gap-clip/', 2, ['green']]]) {
    const { page, problems } = await open(path);
    await page.waitForFunction(n => window.draws.length >= n, charts);
    assert.deepEqual(problems, [], path);
    const found = await colours(page);
    for (const colour of wanted) assert.ok(found[colour] > 0, `${path} ${colour}: ${JSON.stringify(found)}`);
    await page.close();
  }
});

const lastView = page => page.evaluate(() => window.views.at(-1));
const settled = async (page, count) => {
  await page.waitForFunction(n => window.views.length >= n, count);
  await page.waitForTimeout(100);
};

const openZoom = async (path, index = 0) => {
  const { page, problems } = await open(path);
  await page.waitForFunction(() => window.draws.length >= 1);
  const chart = page.locator('inkproof-chart').nth(index);
  await chart.scrollIntoViewIfNeeded();
  const box = await chart.boundingBox();
  // The plot lies 60 pixels from the left and 20 from the top of the 600 by 400 chart.
  return { page, problems, at: (x, y) => [box.x + 60 + x, box.y + 20 + y], chart };
};

const span = v => ({ x: v.xEnd - v.xStart, y: v.yEnd - v.yStart });

test('the wheel zooms about the pointer, and the key resets to the full range exactly', async () => {
  const { page, problems, at, chart } = await openZoom('zoom-wheel/');
  const [x, y] = at(100, 100);
  await page.mouse.move(x, y);
  await page.mouse.wheel(0, -300);
  await settled(page, 1);
  const zoomed = await lastView(page);
  assert.ok(span(zoomed).x < 6, JSON.stringify(zoomed));
  await page.mouse.wheel(0, 300);
  await settled(page, 2);
  const out = await lastView(page);
  assert.ok(span(out).x > span(zoomed).x);
  await chart.focus();
  await page.keyboard.press('0');
  await settled(page, 3);
  const reset = await lastView(page);
  assert.deepEqual([reset.xStart, reset.xEnd], [1, 7]);
  assert.deepEqual(problems, []);
  await page.close();
});

test('a drag pans and a shift-drag zooms to the box', async () => {
  const { page, problems, at } = await openZoom('zoom-wheel/');
  const [x, y] = at(200, 150);
  await page.mouse.move(x, y);
  await page.mouse.wheel(0, -300);
  await settled(page, 1);
  const before = await lastView(page);
  await page.mouse.move(x, y);
  await page.mouse.down();
  await page.mouse.move(x + 60, y + 30, { steps: 4 });
  await page.mouse.up();
  await settled(page, 2);
  const panned = await lastView(page);
  assert.ok(panned.xStart < before.xStart && Math.abs(span(panned).x - span(before).x) < 1e-9, JSON.stringify([before, panned]));
  assert.ok(panned.yStart > before.yStart, JSON.stringify([before, panned]));
  const [x0, y0] = at(100, 100);
  const [x1, y1] = at(200, 160);
  await page.mouse.move(x0, y0);
  await page.keyboard.down('Shift');
  await page.mouse.down();
  await page.mouse.move(x1, y1, { steps: 4 });
  await page.mouse.up();
  await page.keyboard.up('Shift');
  await settled(page, 3);
  const boxed = await lastView(page);
  assert.ok(span(boxed).x < span(panned).x && span(boxed).y < span(panned).y, JSON.stringify([panned, boxed]));
  assert.deepEqual(problems, []);
  await page.close();
});

test('a two-finger pinch zooms and one finger pans', async () => {
  const { page, at } = await openZoom('zoom-touch/');
  const touch = (type, id, [x, y]) => page.evaluate(([type, id, x, y]) => {
    document.querySelector('inkproof-chart').dispatchEvent(new PointerEvent(type, { pointerId: id, pointerType: 'touch', clientX: x, clientY: y, bubbles: true }));
  }, [type, id, x, y]);
  await touch('pointerdown', 11, at(200, 150));
  await touch('pointerdown', 12, at(300, 150));
  await touch('pointermove', 12, at(400, 150));
  await settled(page, 1);
  const zoomed = await lastView(page);
  assert.ok(span(zoomed).x < 6, JSON.stringify(zoomed));
  await touch('pointerup', 12, at(400, 150));
  await touch('pointermove', 11, at(250, 150));
  await settled(page, 2);
  const panned = await lastView(page);
  assert.ok(panned.xStart < zoomed.xStart && Math.abs(span(panned).x - span(zoomed).x) < 1e-9, JSON.stringify([zoomed, panned]));
  await page.close();
});

test('each zoom variation boxes the axes its attributes name, and not a drag under its minimum', async () => {
  const wanted = [['x', true, false], ['y', false, true], ['auto', true, false], ['xy', true, true]];
  for (const [index, [axes, changesX, changesY]] of wanted.entries()) {
    const { page, at } = await openZoom('zoom-variations/', index);
    const [x0, y0] = at(100, 100);
    await page.mouse.move(x0, y0);
    await page.keyboard.down('Shift');
    await page.mouse.down();
    await page.mouse.move(x0 + 150, y0 + 120, { steps: 4 });
    await page.mouse.up();
    await page.keyboard.up('Shift');
    await settled(page, 1);
    const v = await lastView(page);
    // The data spans 29 in x and at least 20 in y; the box covers about a third of the plot.
    assert.equal(span(v).x < 15, changesX, `${axes} x ${JSON.stringify(v)}`);
    assert.equal(span(v).y < 10, changesY, `${axes} y ${JSON.stringify(v)}`);
    await page.close();
  }
  const { page, at } = await openZoom('zoom-variations/', 8);
  const [x0, y0] = at(100, 100);
  await page.mouse.move(x0, y0);
  await page.keyboard.down('Shift');
  await page.mouse.down();
  await page.mouse.move(x0 + 6, y0 + 6, { steps: 2 });
  await page.mouse.up();
  await page.keyboard.up('Shift');
  await page.waitForTimeout(300);
  assert.equal(await page.evaluate(() => window.views.length), 0);
  await page.close();
});

test('the reset button returns a zoomed chart to its full range exactly', async () => {
  const { page, at } = await openZoom('zoom-reset-range/');
  const [x, y] = at(150, 100);
  await page.mouse.move(x, y);
  await page.mouse.wheel(0, -400);
  await settled(page, 1);
  const zoomed = await lastView(page);
  assert.ok(span(zoomed).x < 6);
  await page.click('button[data-reset]');
  await settled(page, 2);
  const reset = await lastView(page);
  assert.deepEqual([reset.xStart, reset.xEnd], [1, 7]);
  await page.close();
});

test('zooming uploads no buffer an earlier frame uploaded', async () => {
  const { page, at } = await openZoom('zoom-wheel/');
  await page.waitForTimeout(300);
  const [x, y] = at(150, 100);
  await page.mouse.move(x, y);
  for (let i = 1; i <= 6; i++) {
    await page.mouse.wheel(0, -120);
    await settled(page, i);
  }
  const uploads = await page.evaluate(() => window.uploads);
  const first = uploads.filter(u => u.frame === 0);
  const largest = Math.max(...first.map(u => u.size));
  const lines = new Set(first.filter(u => u.size === largest).map(u => u.data));
  assert.ok(lines.size >= 2, 'the first frame uploads each line');
  assert.ok(uploads.some(u => u.frame > 0), 'later frames still upload the axes');
  assert.deepEqual(uploads.filter(u => u.frame > 0 && lines.has(u.data)), []);
  await page.close();
});
