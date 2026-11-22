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

const open = async (path, seed = '1') => {
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
  await page.goto(base + path + (path.includes('?') || seed === null ? '' : `?seed=${seed}`));
  return { page, problems };
};

const colours = (page, index = 0) => page.evaluate(index => {
  const canvas = document.querySelectorAll('inkproof-chart')[index].shadowRoot.querySelector('canvas');
  const { width, height } = canvas;
  const d = canvas.getContext('2d').getImageData(0, 0, width, height).data;
  const count = { red: 0, green: 0, blue: 0 };
  for (let i = 0; i < d.length; i += 4) {
    const [r, g, b] = [d[i], d[i + 1], d[i + 2]];
    if ((r > 200 && g < 60 && b < 60) || (r > 200 && g < 200 && Math.abs(g - b) < 20 && g < r - 40)) count.red++;
    if (r < 60 && g > 100 && g < 160 && b < 60) count.green++;
    if ((r < 60 && g < 60 && b > 200) || (b > 200 && r < 200 && Math.abs(r - g) < 20 && r < b - 40)) count.blue++;
  }
  return count;
}, index);

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

test('area fill fills the window at a similar aspect ratio, and draws other data for another seed', async () => {
  const drawn = async (seed, viewport) => {
    const { page, problems } = await open('area-fill/', seed);
    if (viewport) await page.setViewportSize(viewport);
    await page.reload();
    await page.waitForFunction(() => window.draws.length >= 1);
    return { page, problems };
  };
  const a = await drawn('1', { width: 1400, height: 900 });
  const size = await a.page.evaluate(() => { const r = document.querySelector('inkproof-chart').getBoundingClientRect(); return [r.width, r.height]; });
  assert.equal(size[0], 1400);
  assert.ok(size[0] / size[1] > 2.5 && size[0] / size[1] < 4, `aspect ${size}`);
  const first = await a.page.evaluate(() => window.uploads.map(u => u.data).join(';'));
  const b = await drawn('2', null);
  const second = await b.page.evaluate(() => window.uploads.map(u => u.data).join(';'));
  assert.notEqual(first, second);
  await a.page.close();
  await b.page.close();
});

test('area fill makes its scene again at the new size when the window is resized, with the legend below the plot', async () => {
  const { page, problems } = await open('area-fill/', '1');
  await page.setViewportSize({ width: 1200, height: 800 });
  await page.waitForFunction(() => window.draws.length >= 1);
  const before = await page.evaluate(() => window.draws.length);
  await page.setViewportSize({ width: 700, height: 800 });
  await page.waitForFunction(n => window.draws.length > n, before);
  const { chart, canvas, legend } = await page.evaluate(() => {
    const el = document.querySelector('inkproof-chart');
    const box = e => { const r = e.getBoundingClientRect(); return { top: r.top, bottom: r.bottom, width: r.width }; };
    return { chart: box(el), canvas: box(el.shadowRoot.querySelector('canvas')), legend: box(el.shadowRoot.querySelector('.legend')) };
  });
  assert.ok(Math.abs(canvas.width - 700) <= 1, `canvas ${canvas.width}`);
  assert.ok(legend.top >= canvas.bottom - 1, `legend ${legend.top} canvas bottom ${canvas.bottom}`);
  assert.deepEqual(problems.filter(p => !p.includes('willReadFrequently')), []);
  await page.close();
});

test('area fill: the legend reads each series at the cursor and hides its series on a click', async () => {
  const { page, problems } = await open('area-fill/', '1');
  await page.waitForFunction(() => window.draws.length >= 1);
  const shadow = sel => page.evaluate(sel => [...document.querySelector('inkproof-chart').shadowRoot.querySelectorAll(sel)].map(e => e.textContent), sel);
  assert.equal((await shadow('.legend button')).length, 3);
  const last = await shadow('.legend button');
  assert.ok(last.every(r => r.includes('(last)')), last.join('|'));
  await pointerAt(page, 'chart', 'pointermove', 400, 150);
  await page.waitForFunction(() => !document.querySelector('inkproof-chart').shadowRoot.querySelector('.legend button').textContent.includes('(last)'));
  const before = await page.evaluate(() => window.draws.length);
  await page.locator('inkproof-chart button[data-series="1"]').click();
  await page.waitForFunction(n => window.draws.length > n, before);
  assert.deepEqual(problems.filter(p => !p.includes('willReadFrequently')), []);
  await page.close();
});

test('area fill takes a malformed seed with a warning and draws', async () => {
  const { page, problems } = await open('area-fill/?seed=abc');
  await page.waitForFunction(() => window.draws.length >= 1);
  assert.ok(problems.some(p => p.includes('seed is not a natural number')), problems.join('|'));
  await page.close();
});

test('stacked series draws its areas and bars', async () => {
  const { page, problems } = await open('stacked/');
  await page.waitForFunction(() => window.draws.length >= 2);
  assert.deepEqual(problems, []);
  const { red, blue } = await colours(page);
  assert.ok(red > 0 && blue > 0, `red ${red}, blue ${blue}`);
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
  for (const [path, charts] of [['scatter/', 2], ['sparklines/', 20], ['sparklines-bars/', 2], ['multi-bars/', 4], ['grouped-bars/', 10], ['latency-heatmap/', 4], ['heatmap-cells/', 1]]) {
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

test('axis control: the legend follows the cursor over half a million points', async () => {
  const { page, problems } = await open('axis-control/');
  await page.waitForFunction(() => window.draws.length >= 1);
  const text = () => page.evaluate(() => document.querySelector('inkproof-chart').shadowRoot.querySelector('.legend button').textContent);
  assert.ok((await text()).includes('(last)'), await text());
  await pointerAt(page, 'chart', 'pointermove', 400, 150);
  await page.waitForFunction(() => !document.querySelector('inkproof-chart').shadowRoot.querySelector('.legend button').textContent.includes('(last)'));
  assert.deepEqual(problems.filter(p => !p.includes('willReadFrequently')), []);
  await page.close();
});

test('the time series pages draw every chart in their series colours', async () => {
  for (const [path, charts, wanted] of [['missing-data/', 2, ['red', 'blue']], ['log-scales/', 2, []], ['high-low-bands/', 1, ['red', 'blue', 'green']], ['path-gap-clip/', 2, ['green']], ['line-paths/', 4, []]]) {
    const { page, problems } = await open(path);
    await page.waitForFunction(n => window.draws.length >= n, charts);
    assert.deepEqual(problems, [], path);
    const found = await colours(page);
    for (const colour of wanted) assert.ok(found[colour] > 0, `${path} ${colour}: ${JSON.stringify(found)}`);
    await page.close();
  }
});

test('the gradient page colours each stroke along its gradient', async () => {
  const { page, problems } = await open('gradients/');
  await page.waitForFunction(() => window.draws.length >= 5);
  assert.deepEqual(problems, []);
  const horizontal = await colours(page, 0);
  assert.ok(horizontal.blue > 0, JSON.stringify(horizontal));
  const overUnder = await colours(page, 1);
  assert.ok(overUnder.red > 0, JSON.stringify(overUnder));
  const banded = await colours(page, 2);
  assert.ok(banded.red > 0 && banded.green > 0, JSON.stringify(banded));
  await page.close();
});

test('the arcsinh scale page draws again when the threshold slider moves, and says what the threshold is', async () => {
  const { page, problems } = await open('arcsinh-scales/');
  await page.waitForFunction(() => window.draws.length >= 1);
  const before = await page.evaluate(() => window.draws.length);
  await page.evaluate(() => {
    const input = document.querySelector('#linthresh');
    input.value = '2';
    input.dispatchEvent(new Event('input', { bubbles: true }));
  });
  await page.waitForFunction(n => window.draws.length > n, before);
  assert.equal(await page.evaluate(() => document.querySelector('#thresh-label').textContent), 'Linear threshold: 100');
  assert.deepEqual(problems.filter(p => !p.includes('willReadFrequently')), []);
  await page.close();
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

test('the pointer is relative to the plot: its corner reports the view start, the axis labels report nothing', async () => {
  const { page, problems, at } = await openZoom('zoom-wheel/');
  await page.evaluate(() => addEventListener('inkproof-pointer', e => (window.pointers ??= []).push(e.detail)));
  const [cx, cy] = at(1, 1);
  await page.mouse.move(cx, cy);
  await page.waitForFunction(() => window.pointers?.length);
  const corner = await page.evaluate(() => window.pointers.at(-1));
  assert.ok(Math.abs(corner.x - 1) < 0.05 * 6, `the plot's left edge is the start of the range: ${JSON.stringify(corner)}`);
  const [lx, ly] = at(-30, 100);
  await page.mouse.move(lx, ly);
  await page.waitForTimeout(200);
  await page.mouse.wheel(0, -300);
  await page.waitForTimeout(300);
  assert.equal(await page.evaluate(() => window.views.length), 0, 'a wheel over the axis labels starts no zoom');
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

test('each zoom variation boxes on a plain drag the axes its attributes name, and not a drag under its minimum', async () => {
  const wanted = [['x', true, false], ['y', false, true], ['auto', true, false], ['xy', true, true]];
  for (const [index, [axes, changesX, changesY]] of wanted.entries()) {
    const { page, at } = await openZoom('zoom-variations/', index);
    const [x0, y0] = at(100, 100);
    await page.mouse.move(x0, y0);
    await page.mouse.down();
    await page.mouse.move(x0 + 150, y0 + 120, { steps: 4 });
    await page.mouse.up();
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
  await page.mouse.down();
  await page.mouse.move(x0 + 6, y0 + 6, { steps: 2 });
  await page.mouse.up();
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

const pointerAt = (page, id, type, x, y) => page.evaluate(([id, type, x, y]) => {
  const el = document.getElementById(id);
  const rect = el.getBoundingClientRect();
  el.dispatchEvent(new PointerEvent(type, { bubbles: true, pointerId: 1, pointerType: 'mouse', isPrimary: true, buttons: type === 'pointermove' ? 0 : 1, clientX: rect.left + x, clientY: rect.top + y }));
}, [id, type, x, y]);

// The pixels of the column `x` pixels from the left of the chart's 2D layer, where the cursor is drawn.
const column = (page, id, x) => page.evaluate(([id, x]) => {
  const el = document.getElementById(id);
  const canvas = el.shadowRoot.querySelector('canvas');
  const scale = canvas.width / el.getBoundingClientRect().width;
  return [...canvas.getContext('2d').getImageData(Math.round(x * scale), 0, 1, canvas.height).data];
}, [id, x]);

// How many pixels differ between two columns.
const changed = (a, b) => { let n = 0; for (let i = 0; i < a.length; i += 4) if (a[i] !== b[i] || a[i + 1] !== b[i + 1] || a[i + 2] !== b[i + 2] || a[i + 3] !== b[i + 3]) n++; return n; };

const watchViews = page => page.evaluate(() => {
  window.seen = {};
  addEventListener('inkproof-view', e => (window.seen[e.target.id] ??= []).push(e.detail));
});

test('sync cursor: the pointer on one chart draws the cursor on the others, and an unlinked chart stops following', async () => {
  const { page, problems } = await open('sync-cursor/');
  await page.waitForFunction(() => window.draws.length >= 3);
  await page.locator('#sync-0').scrollIntoViewIfNeeded();
  const ids = ['sync-0', 'sync-1', 'sync-2'];
  const quiet = [];
  for (const id of ids) quiet.push(await column(page, id, 300));
  await pointerAt(page, 'sync-0', 'pointermove', 300, 100);
  await page.waitForTimeout(300);
  for (const [i, id] of ids.entries()) {
    const n = changed(quiet[i], await column(page, id, 300));
    assert.ok(n > 100, `${id} draws a cursor line (${n} pixels changed)`);
  }
  await pointerAt(page, 'sync-0', 'pointerleave', 300, 100);
  await page.waitForTimeout(300);
  assert.ok(changed(quiet[2], await column(page, 'sync-2', 300)) < 10, 'leaving takes the cursor away');

  await watchViews(page);
  await page.evaluate(() => { const el = document.getElementById('sync-0'); const r = el.getBoundingClientRect(); el.dispatchEvent(new WheelEvent('wheel', { bubbles: true, cancelable: true, clientX: r.left + 300, clientY: r.top + 100, deltaY: -300 })); });
  await page.waitForFunction(() => window.seen['sync-2']?.length);
  const first = await page.evaluate(() => window.seen);
  assert.deepEqual([first['sync-1'].at(-1).xStart, first['sync-2'].at(-1).xStart], [first['sync-0'].at(-1).xStart, first['sync-0'].at(-1).xStart], 'the group follows a zoom');
  await page.click('button[data-unlink]');
  await page.evaluate(() => { window.seen = {}; });
  await page.evaluate(() => { const el = document.getElementById('sync-0'); const r = el.getBoundingClientRect(); el.dispatchEvent(new WheelEvent('wheel', { bubbles: true, cancelable: true, clientX: r.left + 300, clientY: r.top + 100, deltaY: -300 })); });
  await page.waitForFunction(() => window.seen['sync-2']?.length);
  await page.waitForTimeout(200);
  const after = await page.evaluate(() => window.seen);
  assert.equal(after['sync-1'], undefined, 'the unlinked chart does not follow');
  assert.ok(after['sync-0'].length > 0 && after['sync-2'].length > 0, 'the others still do');
  assert.deepEqual(problems.filter(p => !p.includes('willReadFrequently')), []);
  await page.close();
});

test('cursor bind: the reading is the data position under the pointer', async () => {
  const { page, problems } = await open('cursor-bind/');
  await page.waitForFunction(() => window.draws.length >= 1);
  await page.evaluate(() => addEventListener('inkproof-pointer', e => (window.pointers ??= []).push(e.detail)));
  const quiet = await column(page, 'chart', 200);
  await pointerAt(page, 'chart', 'pointermove', 400, 150);
  await page.waitForFunction(() => window.pointers?.length);
  const at = await page.evaluate(() => window.pointers.at(-1));
  assert.ok(at.x > 1 && at.x < 30, JSON.stringify(at));
  const text = await page.locator('#reading').textContent();
  const [x, y] = text.match(/-?\d+(\.\d+)?/g).map(Number);
  assert.ok(Math.abs(x - at.x) < 1e-6 && Math.abs(y - at.y) < 1e-6, `${text} against ${JSON.stringify(at)}`);
  await pointerAt(page, 'chart', 'pointermove', 200, 150);
  await page.waitForFunction(t => document.getElementById('reading').textContent !== t, text);
  const moved = await page.evaluate(() => window.pointers.at(-1));
  assert.ok(moved.x < at.x, 'the reading follows the pointer');
  await page.waitForTimeout(300);
  assert.ok(changed(quiet, await column(page, 'chart', 200)) > 100, 'the element draws the cursor line');
  assert.deepEqual(problems.filter(p => !p.includes('willReadFrequently')), []);
  await page.close();
});

test('zoom fetch: zooming requests the samples of the new range and redraws', async () => {
  const { page, problems } = await open('zoom-fetch/');
  const requests = [];
  page.on('request', r => { if (r.url().endsWith('.bin')) requests.push({ url: r.url().split('/').pop(), range: r.headers().range }); });
  await page.reload();
  await page.waitForFunction(() => window.draws.length >= 2);
  assert.ok(requests.some(r => r.url === 'zoom-fetch-coarse.bin'), JSON.stringify(requests));
  const drawn = await page.evaluate(() => window.draws.length);
  const box = await page.locator('#chart').boundingBox();
  await page.mouse.move(box.x + 200, box.y + 150);
  await page.mouse.down();
  await page.mouse.move(box.x + 400, box.y + 150, { steps: 4 });
  await page.mouse.up();
  await page.waitForFunction(() => window.views.length >= 1);
  await page.waitForTimeout(500);
  const view = await lastView(page);
  const fine = requests.filter(r => r.url === 'zoom-fetch-fine.bin');
  assert.ok(fine.length > 0, JSON.stringify(requests));
  const [start, end] = fine.at(-1).range.match(/\d+/g).map(Number);
  assert.ok(start <= view.xStart && end >= view.xEnd - 1 && end - start < 4999, `${fine.at(-1).range} for ${JSON.stringify(view)}`);
  assert.ok(await page.evaluate(n => window.draws.length > n, drawn), 'the chart is drawn again');
  assert.deepEqual(problems.filter(p => !p.includes('willReadFrequently')), []);
  await page.close();
});

test('zoom ranger: dragging the overview sets the main chart range, and the overview keeps its own', async () => {
  const { page, problems } = await open('zoom-ranger/');
  await page.waitForFunction(() => window.draws.length >= 2);
  await page.evaluate(() => {
    window.seen = {};
    addEventListener('inkproof-view', e => (window.seen[e.target.id] ??= []).push(e.detail));
    addEventListener('inkproof-select', e => (window.picked ??= []).push(e.detail));
  });
  const box = await page.locator('#ranger-overview').boundingBox();
  const drag = async (x0, x1) => {
    await page.mouse.move(box.x + x0, box.y + 60);
    await page.mouse.down();
    await page.mouse.move(box.x + x1, box.y + 60, { steps: 5 });
    await page.mouse.up();
  };
  await drag(650, 750);
  await page.waitForFunction(() => window.seen['ranger-main']?.length);
  const first = await page.evaluate(() => ({ main: window.seen['ranger-main'].at(-1), band: window.picked.at(-1), overview: window.seen['ranger-overview'] }));
  assert.ok(first.main.xEnd - first.main.xStart < 1000 && first.main.xEnd - first.main.xStart > 100, JSON.stringify(first.main));
  assert.equal(first.main.xStart, first.band.xStart);
  assert.equal(first.main.xEnd, first.band.xEnd);
  assert.equal(first.overview, undefined, 'the overview keeps its range');
  await drag(700, 600);
  await page.waitForTimeout(300);
  const moved = await page.evaluate(() => window.picked.at(-1));
  assert.ok(moved.xStart < first.band.xStart && Math.abs((moved.xEnd - moved.xStart) - (first.band.xEnd - first.band.xStart)) < 1e-6, `${JSON.stringify(first.band)} moved to ${JSON.stringify(moved)}`);
  assert.deepEqual(problems.filter(p => !p.includes('willReadFrequently')), []);
  await page.close();
});

const countPixels = (page, index, wanted) => page.evaluate(([index, wanted]) => {
  const canvas = document.querySelectorAll('inkproof-chart')[index].shadowRoot.querySelector('canvas');
  const d = canvas.getContext('2d', { willReadFrequently: true }).getImageData(0, 0, canvas.width, canvas.height).data;
  const counts = wanted.map(() => 0);
  for (let i = 0; i < d.length; i += 4)
    wanted.forEach(([r, g, b, a], k) => { if (d[i] === r && d[i + 1] === g && d[i + 2] === b && d[i + 3] === a) counts[k]++; });
  return counts;
}, [index, wanted]);

test('the composed shape pages draw their shapes in their colours', async () => {
  const pages = [
    ['candlestick/', 1, [[74, 182, 80, 255], [229, 66, 69, 255], [0, 0, 0, 255]]],
    ['box-whisker/', 3, [[0, 0, 0, 255], [238, 238, 238, 255]]],
    ['timeline-discrete/', 3, [[255, 0, 0, 255], [0, 255, 0, 255], [255, 165, 0, 255], [255, 255, 0, 255], [255, 204, 204, 255]]],
  ];
  for (const [path, charts, wanted] of pages) {
    const { page, problems } = await open(path);
    await page.waitForFunction(n => window.draws.length >= n, charts);
    assert.deepEqual(problems.filter(p => !p.includes('willReadFrequently')), [], path);
    for (let i = 0; i < charts; i++) {
      const found = await countPixels(page, i, wanted);
      if (path !== 'timeline-discrete/' || i < 2) assert.ok(found.every(n => n > 0), `${path} chart ${i}: ${JSON.stringify(found)}`);
    }
    await page.close();
  }
});

test('annotations sit at the data positions they name, and stay there after a zoom', async () => {
  const { page, problems } = await open('annotations/');
  await page.waitForFunction(() => window.draws.length >= 1);
  // The plot of the 1920 pixel wide chart runs from column 60 to column 1900; the range's dashed edges are the only amber pixels that are not text.
  const band = () => page.evaluate(() => {
    const canvas = document.querySelector('inkproof-chart').shadowRoot.querySelector('canvas');
    const d = canvas.getContext('2d', { willReadFrequently: true }).getImageData(0, 0, canvas.width, canvas.height).data;
    const xs = [];
    for (let y = 100; y < 500; y += 7) for (let x = 0; x < canvas.width; x++) {
      const i = 4 * (y * canvas.width + x);
      if (d[i] === 255 && d[i + 1] === 193 && d[i + 2] === 7 && d[i + 3] === 255) xs.push(x);
    }
    return xs.length ? [Math.min(...xs), Math.max(...xs)] : null;
  });
  const column = (view, v) => 60 + (v - view.xStart) / (view.xEnd - view.xStart) * (1900 - 60);
  const near = (found, view, what) => {
    assert.ok(found, what + ': no shaded range drawn');
    assert.ok(Math.abs(found[0] - column(view, 9.3)) < 4 && Math.abs(found[1] - column(view, 18.5)) < 4, `${what}: ${JSON.stringify(found)} against ${column(view, 9.3)}, ${column(view, 18.5)}`);
  };
  near(await band(), { xStart: 1, xEnd: 30 }, 'full range');
  const chart = page.locator('inkproof-chart');
  const box = await chart.boundingBox();
  await page.mouse.move(box.x + column({ xStart: 1, xEnd: 30 }, 14), box.y + 300);
  await page.mouse.wheel(0, -300);
  await settled(page, 1);
  const zoomed = await lastView(page);
  assert.ok(zoomed.xEnd - zoomed.xStart < 25, JSON.stringify(zoomed));
  await page.waitForTimeout(200);
  near(await band(), zoomed, 'zoomed');
  assert.deepEqual(problems.filter(p => !p.includes('willReadFrequently')), []);
  await page.close();
});

test('tooltip and legend: the tooltip names the nearest point, the legend reads each series at the cursor and toggles it', async () => {
  const { page, problems } = await open('tooltip-legend/');
  await page.waitForFunction(() => window.draws.length >= 1);
  await page.evaluate(() => addEventListener('inkproof-pointer', e => (window.pointers ??= []).push(e.detail)));
  await page.evaluate(() => addEventListener('inkproof-series', e => (window.toggles ??= []).push(e.detail)));
  const shadow = (sel) => page.evaluate(sel => [...document.querySelector('inkproof-chart').shadowRoot.querySelectorAll(sel)].map(e => e.textContent), sel);
  const numbers = text => text.match(/-?\d+(\.\d+)?/g).map(Number);
  await pointerAt(page, 'chart', 'pointermove', 400, 150);
  await page.waitForFunction(() => window.pointers?.length);
  const at = await page.evaluate(() => window.pointers.at(-1));
  await page.waitForFunction(() => document.querySelector('inkproof-chart').shadowRoot.querySelector('.tip')?.textContent);
  const [tip] = await shadow('.tip');
  const [series, x, y] = [Number(tip.match(/Series (\d)/)[1]), ...numbers(tip.replace(/Series \d/, ''))];
  assert.ok(Math.abs(x - at.x) <= 0.5 + 1e-6, `tooltip names x = ${x}, the pointer is at ${at.x}`);
  const rows = await shadow('.legend button');
  assert.equal(rows.length, 3);
  const values = rows.map(r => numbers(r.replace(/Series \d/, ''))[0]);
  assert.equal(values[series - 1], y, 'the legend row of the tooltip series shows the tooltip value, which is its value at the nearest x');
  const before = await page.evaluate(() => window.draws.length);
  await page.locator('inkproof-chart button[data-series="1"]').click();
  await page.waitForFunction(() => window.toggles?.length, null, { timeout: 3000 });
  assert.deepEqual(await page.evaluate(() => window.toggles.at(-1)), { series: 1, hidden: true });
  await page.waitForFunction(n => window.draws.length > n, before);
  assert.equal(await page.evaluate(() => document.querySelector('inkproof-chart').shadowRoot.querySelector('button[data-series="1"]').getAttribute('aria-pressed')), 'false');
  for (const px of [200, 300, 400, 500, 600]) {
    await pointerAt(page, 'chart', 'pointermove', px, 150);
    await page.waitForTimeout(100);
    const [t] = await shadow('.tip');
    assert.ok(!t.startsWith('Series 2'), `a hidden series is not named: ${t}`);
  }
  assert.deepEqual(problems.filter(p => !p.includes('willReadFrequently')), []);
  await page.close();
});

// Static legends: the pages whose uPlot demo has a key without values.
for (const [path, chart] of [['grouped-bars/', 0], ['multi-bars/', 2], ['scatter/', 1]]) {
  test(`${path.slice(0, -1)}: the static legend lists the series without values and hides a series on a click`, async () => {
    const { page, problems } = await open(path);
    const rows = () => page.evaluate(i => [...document.querySelectorAll('inkproof-chart')[i].shadowRoot.querySelectorAll('.legend button')].map(b => b.textContent), chart);
    await page.waitForFunction(i => document.querySelectorAll('inkproof-chart')[i]?.shadowRoot.querySelector('.legend button'), chart);
    const names = await rows();
    assert.ok(names.length > 0);
    assert.ok(names.every(n => !n.includes(':') && !n.includes('(last)')), `no values in ${names}`);
    const before = await page.evaluate(() => window.draws.length);
    await page.evaluate(i => document.querySelectorAll('inkproof-chart')[i].shadowRoot.querySelector('.legend button').click(), chart);
    await page.waitForFunction(n => window.draws.length > n, before);
    assert.deepEqual(problems.filter(p => !p.includes('willReadFrequently')), []);
    await page.close();
  });
}

// Pages whose legend reads a group of values at each x: the number of entries of each chart, in page order.
for (const [path, counts] of Object.entries({ 'candlestick/': [5], 'box-whisker/': [5, 5, 5], 'timeline-discrete/': [3, 3, 3], 'latency-heatmap/': [3, 3, 3, 3] })) {
  test(`${path.slice(0, -1)}: each chart's legend reads its group of values at the cursor`, async () => {
    const { page, problems } = await open(path);
    const rows = () => page.evaluate(() => [...document.querySelectorAll('inkproof-chart')].map(e => [...e.shadowRoot.querySelectorAll('.legend .entry')].map(b => b.textContent)));
    await page.waitForFunction(n => [...document.querySelectorAll('inkproof-chart')].every(e => e.shadowRoot.querySelector('.legend .entry')) && document.querySelectorAll('inkproof-chart').length === n, counts.length);
    assert.deepEqual((await rows()).map(r => r.length), counts);
    assert.ok((await rows()).flat().every(t => !t.includes('NaN')), 'no entry reads NaN');
    const read = async fraction => {
      await page.evaluate(fraction => {
        const el = document.querySelector('inkproof-chart');
        const r = el.getBoundingClientRect();
        el.dispatchEvent(new PointerEvent('pointermove', { bubbles: true, pointerId: 1, pointerType: 'mouse', isPrimary: true, buttons: 0, clientX: r.left + 60 + (r.width - 80) * fraction, clientY: r.top + r.height / 2 }));
      }, fraction);
      await page.waitForFunction(() => !document.querySelector('inkproof-chart').shadowRoot.querySelector('.legend .entry')?.textContent.includes('(last)'));
      return (await rows())[0].join('|');
    };
    const [a, b] = [await read(0.2), await read(0.7)];
    assert.notEqual(a, b, 'the legend reads the group at the cursor');
    assert.deepEqual(problems.filter(p => !p.includes('willReadFrequently')), []);
    await page.close();
  });
}

// The pages whose charts carry a legend: the number of entries of each chart, in page order.
const legends = {
  'annotations/': [2], 'arcsinh-scales/': [1], 'months/': [1], 'timezones-dst/': Array(12).fill(1), 'cursor-bind/': [3], 'custom-scales/': [3, 3, 3], 'gradients/': [1, 1, 1, 2, 1], 'high-low-bands/': [3],
  'line-paths/': [1, 1, 1, 1], 'log-scales/': [12, 12], 'log-scales2/': [1, 1, 1, 1, 1, 1, 1, 1], 'missing-data/': [3, 1],
  'path-gap-clip/': [2, 3, 1, 1, 1], 'points/': [4, 1, 1, 1], 'stacked/': [5, 4], 'sync-cursor/': [3, 3, 3],
  'zoom-fetch/': [1], 'zoom-touch/': [2], 'zoom-variations/': Array(10).fill(1), 'zoom-wheel/': [2],
};

// Where the cursor reads two different values, as fractions of the plot, for the pages whose data is flat at 0.2 and 0.7.
const cursorAt = { 'timezones-dst/': [0.0833, 0.3], 'months/': [0, 0.5] };

for (const [path, counts] of Object.entries(legends)) {
  test(`${path.slice(0, -1)}: each chart has a legend entry for each series, and the values follow the cursor and hide the series`, async () => {
    const { page, problems } = await open(path);
    const rows = () => page.evaluate(() => [...document.querySelectorAll('inkproof-chart')].map(e => [...e.shadowRoot.querySelectorAll('.legend button')].map(b => b.textContent)));
    await page.waitForFunction(n => [...document.querySelectorAll('inkproof-chart')].every(e => e.shadowRoot.querySelector('.legend button')) && document.querySelectorAll('inkproof-chart').length === n, counts.length);
    assert.deepEqual((await rows()).map(r => r.length), counts);
    assert.ok((await rows()).flat().every(t => !t.includes('NaN')), 'a missing value reads as a dash');
    const before = await page.evaluate(() => window.draws.length);
    const read = async fraction => {
      await page.evaluate(fraction => {
        const el = document.querySelector('inkproof-chart');
        const r = el.getBoundingClientRect();
        el.dispatchEvent(new PointerEvent('pointermove', { bubbles: true, pointerId: 1, pointerType: 'mouse', isPrimary: true, buttons: 0, clientX: r.left + 60 + (r.width - 80) * fraction, clientY: r.top + r.height / 2 }));
      }, fraction);
      await page.waitForFunction(() => !document.querySelector('inkproof-chart').shadowRoot.querySelector('.legend button')?.textContent.includes('(last)'));
      return (await rows())[0].join('|');
    };
    const [first, second] = cursorAt[path] ?? [0.2, 0.7];
    const [a, b] = [await read(first), await read(second)];
    assert.notEqual(a, b, 'the legend reads the series at the cursor');
    await page.evaluate(() => document.querySelector('inkproof-chart').shadowRoot.querySelector('.legend button').click());
    await page.waitForFunction(n => window.draws.length > n, before);
    assert.equal(await page.evaluate(() => document.querySelector('inkproof-chart').shadowRoot.querySelector('.legend button').getAttribute('aria-pressed')), 'false');
    assert.deepEqual(problems.filter(p => !p.includes('willReadFrequently')), []);
    await page.close();
  });
}

for (const [path, chart, density] of [['scatter/?seed=1', 1, true], ['zoom-wheel/', 0, true], ['area-fill/?seed=1', 0, true], ['million/', 0, true]]) {
  test(`${path} draws its saturated pixels over the same part of its plot at device pixel ratio 2 as at 1`, async () => {
    const measure = async scale => {
      const context = await browser.newContext({ deviceScaleFactor: scale });
      const page = await context.newPage();
      await page.goto(base + path);
      await page.waitForFunction(i => document.querySelectorAll('inkproof-chart')[i]?.shadowRoot?.querySelector('canvas'), chart);
      await page.waitForTimeout(3000);
      const r = await page.evaluate(i => {
        const c = document.querySelectorAll('inkproof-chart')[i].shadowRoot.querySelector('canvas');
        const t = document.createElement('canvas'); t.width = c.width; t.height = c.height;
        const g = t.getContext('2d'); g.drawImage(c, 0, 0);
        const d = g.getImageData(0, 0, t.width, t.height).data;
        let n = 0, x1 = 0, y1 = 0;
        for (let y = 0; y < t.height; y++) for (let x = 0; x < t.width; x++) {
          const k = (y * t.width + x) * 4;
          if (Math.max(d[k], d[k + 1], d[k + 2]) - Math.min(d[k], d[k + 1], d[k + 2]) > 100) { n++; if (x > x1) x1 = x; if (y > y1) y1 = y; }
        }
        return { n: n / (t.width * t.height), x: x1 / t.width, y: y1 / t.height };
      }, chart);
      await context.close();
      return r;
    };
    const [one, two] = [await measure(1), await measure(2)];
    assert.ok(one.n > 0, 'something saturated is drawn');
    assert.ok(Math.abs(one.x - two.x) < 0.05 && Math.abs(one.y - two.y) < 0.05, `${JSON.stringify(one)} ${JSON.stringify(two)}`);
    assert.ok(!density || Math.abs(two.n / one.n - 1) < 0.35, `${JSON.stringify(one)} ${JSON.stringify(two)}`);
  });
}
