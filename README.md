# Inkproof.Demos

Part of Inkproof. Released under the Apache 2.0 license; see `LICENSE`.

The [uPlot demos](https://leeoniya.github.io/uPlot/demos/index.html), recreated with the Inkproof libraries and published at https://paulbutcher.github.io/inkproof-demos/. An application, not a library: nothing depends on it. Each release tag is a version of the site.

## What it does

- Show the Area Fill demo, three series with filled areas and linear axes, from uPlot's page of that name: `Inkproof.Demos.AreaFill.chart`, `Inkproof.Demos.axes`, at `area-fill/`.
- Show the Points demo, four charts of random walks with markers and gaps, from uPlot's page of that name: `Inkproof.Demos.Points.multiChart`, `Points.singleChart`, `Points.sparseChart`, at `points/`.
- Show the Log Scales demo, twelve servers' player counts over a day on log and linear y axes with unreported samples as gaps, from uPlot's `log-scales.html`: `Inkproof.Demos.LogScales.specs`, `Spec.chart`, at `log-scales/`.
- Show the Log Scales 2 demo, the same data on linear, log10 and log2 y axes with zero and negative values as gaps, from uPlot's `log-scales2.html` (charts 1 to 4 and 7 to 10): `Inkproof.Demos.LogScales2.specs`, `Spec.chart`, at `log-scales2/`.
- Show the Axis Control demo, half a million points on a fixed y range with a red right axis and axis titles, from uPlot's `axis-control.html`: `Inkproof.Demos.AxisControl.chart`, at `axis-control/`.
- Show the Missing Data, High-Low Bands and Path Gap Clip demos, lines and bands over Unix-time x axes with gaps drawn as gaps, and stepped and spline joins, from uPlot's `missing-data.html`, `high-low-bands.html` and `path-gap-clip.html`: `Inkproof.Demos.Lines.Chart`, at `missing-data/`, `high-low-bands/` and `path-gap-clip/`.
- Show a million samples with twelve one-sample spikes drawn two ways, one sample per pixel column against the lowest and highest per column from Core's pyramid, and count the spikes each keeps: `Inkproof.Demos.Million.naiveChart`, `Million.inkproofChart`, at `million/`.
- Show three dense series of 55,550 samples as per-column envelopes, with the highest value of each in the data and as drawn: `Inkproof.Demos.ServerEvents.chart`, at `server-events/`.

## Build and run

Needs git, Node 24 and [elan](https://github.com/leanprover/elan). From the repository root, `scripts/build-site.sh` builds the whole site into `_site/`; serve that directory under `/inkproof-demos/` to see it as GitHub Pages does. `lake test` runs the native tests and the browser tests in headless Chromium.

## Credits

The demos recreate pages of [uPlot](https://github.com/leeoniya/uPlot) by Leon Sorokin (MIT license). Server events recreates the shape of uPlot's `bench/uPlot.html` data (three series over 55,550 samples) with generated values; uPlot has no demo of reduction accuracy.
