# Inkproof.Demos design

## Layout

- Each demo is a page under `app/web/<demo>/` (an `index.html`, a Lean `Main.lean` that Lasm builds, and a two-line `main.js` that mounts it) plus a native module `Inkproof/Demos/<Demo>.lean` that holds its data and compiles it to a display list. Native modules do not import Lasm, so they are built and tested with `lake`; the page only registers the chart element with the command list.
- `app/vite.config.js` makes every directory under `app/web/` a page, with `base: './'` so the site works from `/inkproof-demos/`. `scripts/build-site.sh` builds the native library, installs the pinned npm packages and writes `_site/`.
- The browser side has no third-party runtime code: the npm packages are Lasm and Vite (build time) and the two Web ships (the generated GPU interpreter and the custom-element shim), taken from the pinned `inkproof-web` package.

## Data

uPlot's demos draw random data; these use a fixed hash so each visit shows the same chart.
