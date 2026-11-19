# Inkproof.Demos

Part of Inkproof. Released under the Apache 2.0 license; see `LICENSE`.

The [uPlot demos](https://leeoniya.github.io/uPlot/demos/index.html), recreated with the Inkproof libraries and published at https://paulbutcher.github.io/inkproof-demos/. An application, not a library: nothing depends on it. Each release tag is a version of the site.

## What it does

- Show the Area Fill demo, three series with filled areas, from uPlot's page of that name: `Inkproof.Demos.AreaFill.chart`, at `area-fill/`.
- Turn a display list into the command list a chart element draws: `Inkproof.Demos.Page.bytes`.

## Build and run

Needs git, Node 24 and [elan](https://github.com/leanprover/elan). From the repository root, `scripts/build-site.sh` builds the whole site into `_site/`; serve that directory under `/inkproof-demos/` to see it as GitHub Pages does. `lake test` runs the native tests and the browser tests in headless Chromium.

## Credits

The demos recreate pages of [uPlot](https://github.com/leeoniya/uPlot) by Leon Sorokin (MIT license).
