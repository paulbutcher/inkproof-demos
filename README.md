# Inkproof.Demos

Part of Inkproof. Released under the Apache 2.0 license; see `LICENSE`.

The [uPlot demos](https://leeoniya.github.io/uPlot/demos/index.html), recreated with the Inkproof libraries and published at https://paulbutcher.github.io/inkproof-demos/. An application, not a library: nothing depends on it. Each release tag is a version of the site.

## What it does

- Show the Area Fill demo, three series with filled areas and linear axes, from uPlot's page of that name: `Inkproof.Demos.AreaFill.chart`, `Inkproof.Demos.axes`, at `area-fill/`.
- Show the Points demo, four charts of random walks with markers and gaps, from uPlot's page of that name: `Inkproof.Demos.Points.multiChart`, `Points.singleChart`, `Points.sparseChart`, at `points/`.
- Show the bubble half of the Scatter & Bubble demo, 200 bubbles sized by area on two y axes, from uPlot's `scatter.html`: `Inkproof.Demos.Scatter.bubbleChart`, at `scatter/`.
- Show the Sparklines demo, ten stocks' volumes and closing prices as 150 by 30 charts sharing one WebGL context, and the Sparklines (w/ floating bars) demo, a line with floating bars either side of zero, from uPlot's `sparklines.html` and `sparklines-bars.html`: `Inkproof.Demos.Sparklines.chart`, `SparklinesBars.chartSplit`, at `sparklines/` and `sparklines-bars/`.
- Show the Multi-Bars and Grouped and stacked bars demos, bars over categories with values written at their ends, per-bar colours, separate scales per series and stacked or horizontal layouts, from uPlot's `multi-bars.html` and `bars-grouped-stacked.html`: `Inkproof.Demos.Bars.Chart`, `MultiBars.benchmark`, `GroupedBars.charts`, at `multi-bars/` and `grouped-bars/`.
- Show the histograms of the Latency Heatmap demo, latencies of a skew normal counted in 5 ms buckets, from uPlot's `latency-heatmap.html`: `Inkproof.Demos.LatencyHistogram.chart`, at `latency-heatmap/`.
- Show the Log Scales demo, twelve servers' player counts over a day on log and linear y axes with unreported samples as gaps, from uPlot's `log-scales.html`: `Inkproof.Demos.LogScales.specs`, `Spec.chart`, at `log-scales/`.
- Show the Log Scales 2 demo, the same data on linear, log10 and log2 y axes with zero and negative values as gaps, from uPlot's `log-scales2.html` (charts 1 to 4 and 7 to 10): `Inkproof.Demos.LogScales2.specs`, `Spec.chart`, at `log-scales2/`.
- Show the Axis Control demo, half a million points on a fixed y range with a red right axis and axis titles, from uPlot's `axis-control.html`: `Inkproof.Demos.AxisControl.chart`, at `axis-control/`.
- Show the Missing Data, High-Low Bands and Path Gap Clip demos, lines and bands over Unix-time x axes with gaps drawn as gaps, and stepped and spline joins, from uPlot's `missing-data.html`, `high-low-bands.html` and `path-gap-clip.html`: `Inkproof.Demos.Lines.Chart`, at `missing-data/`, `high-low-bands/` and `path-gap-clip/`.
- Show a million samples with twelve one-sample spikes drawn two ways, one sample per pixel column against the lowest and highest per column from Core's pyramid, and count the spikes each keeps: `Inkproof.Demos.Million.naiveChart`, `Million.inkproofChart`, at `million/`.
- Show three dense series of 55,550 samples as per-column envelopes, with the highest value of each in the data and as drawn: `Inkproof.Demos.ServerEvents.chart`, at `server-events/`.
- Zoom and pan a line chart with the wheel, a drag, a shift-drag box and a two-finger pinch, redrawing under each visible range from buffers uploaded once, and reset it to the full range, from uPlot's `zoom-wheel.html`, `zoom-touch.html` and `zoom-variations.html` and a reset button that uPlot's demos lack: `Inkproof.Demos.Zoom.Chart.commands`, `Zoom.Chart.config`, at `zoom-wheel/`, `zoom-touch/`, `zoom-variations/` and `zoom-reset-range/`.

## Build and run

Needs git, Node 24 and [elan](https://github.com/leanprover/elan). From the repository root, `scripts/build-site.sh` builds the whole site into `_site/`; serve that directory under `/inkproof-demos/` to see it as GitHub Pages does. `lake test` runs the native tests and the browser tests in headless Chromium.

## Credits

The demos recreate pages of [uPlot](https://github.com/leeoniya/uPlot) by Leon Sorokin (MIT license). Server events recreates the shape of uPlot's `bench/uPlot.html` data (three series over 55,550 samples) with generated values; uPlot has no demo of reduction accuracy. The Sparklines stock records are uPlot's `demos/data/*.csv`, the Multi-Bars library figures its `bench/results.json`, and the skew normal draw follows its `demos/lib/rand.js`. The zoom pages draw uPlot's wheel and touch zoom data (seven points, two series) and a fixed hash for the variations page, whose points uPlot draws at random; uPlot 1.6.32 has no zoom-reset-range page, so that one is the wheel zoom chart with a reset button. A plain drag pans, where uPlot's variations page zooms to the dragged box; the box is a shift-drag.
