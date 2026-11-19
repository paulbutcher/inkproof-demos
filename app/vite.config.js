// Copyright (c) 2026 Paul Butcher. All rights reserved.
// Released under Apache 2.0 license as described in the file LICENSE.
import lasm from '@lasm/cli/vite';
import { readdirSync } from 'node:fs';

const web = new URL('./web/', import.meta.url).pathname;
const pages = ['index.html', ...readdirSync(web, { withFileTypes: true }).filter(d => d.isDirectory() && d.name !== 'public').map(d => `${d.name}/index.html`)];

export default {
  root: 'web',
  base: './',
  plugins: [lasm()],
  build: { rollupOptions: { input: pages.map(p => web + p) }, outDir: '../dist', emptyOutDir: true },
  server: { fs: { allow: ['..', '../..'] } },
};
