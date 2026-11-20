# Inkproof.Demos design

## Layout

- Each demo is a page under `app/web/<demo>/` (an `index.html`, a Lean `Main.lean` that Lasm builds, and a two-line `main.js` that mounts it) plus a native module `Inkproof/Demos/<Demo>.lean` that holds its data and compiles it to a display list. Native modules do not import Lasm, so they are built and tested with `lake`; the page only registers the chart element with the command list.
- `app/vite.config.js` makes every directory under `app/web/` a page, with `base: './'` so the site works from `/inkproof-demos/`. `scripts/build-site.sh` builds the native library, installs the pinned npm packages and writes `_site/`.
- The browser side has no third-party runtime code: the npm packages are Lasm and Vite (build time) and the two Web ships (the generated GPU interpreter and the custom-element shim), taken from the pinned `inkproof-web` package.

## Data

uPlot's demos draw random data; these use a fixed hash so each visit shows the same chart.

## Zooming charts

A zoom page draws its lines once, in data coordinates, and `Zoom.Chart.commands` draws them under each visible range with Gpu's `viewTile`, so a frame after the first uploads only the axes, which are in pixels and follow the range. Zoom and pan state is Web's `Nav`: the page listens for `inkproof-view`, builds the scene for that range and gives it to `Host.setScene`, which keeps the state. Each chart numbers its buffers from its own range, since every chart draws on one WebGL context, and starts again when the context is lost.

## Composed shapes

Candles, boxes and timeline bars are rectangles, strips and markers placed in pixels from a pane's scales (`Pane`), a category at a time, so their properties (a body spans open to close, a box's quartiles lie in order) are tested on the shapes themselves. A pixel takes the colour of the last command that covers it and translucent colours are not blended, so a shaded range that must show the data through it is drawn under the data, in data coordinates, while its dashed edges and label box are drawn in pixels over it.
