# Changelog

## v0.12.0

- Web v0.15.0, and the Area Fill page takes the window's width, draws 1 pixel lines and an open circle at each point, shows the legend with each series at the cursor and a dotted cursor, and hides a series when its entry is clicked.
- The Area Fill page takes a `seed` query parameter and otherwise a random seed; the browser tests fix it.
- Scene v0.21.0.

## v0.11.0

- The candlestick page writes its dates with Core v0.15.0's `Calendar.isoDate`.
- Scene v0.20.0, and a Stacked Series page of stacked areas and stacked bars drawn by its `compileStackedAreas` and `compileStackedBars`.
- The Tooltip and legend page: the tooltip names the point nearest the pointer and the legend gives each series at the cursor and hides or shows it.
- Web v0.14.1.
- The Area Fill page fills the window, draws one pixel lines with an open circle at each point, and uses a random seed unless the URL gives `?seed=`.

## v0.10.0

- The Candlestick, Box & Whisker, Timeline / Discrete and Annotations pages, composed shapes built from Scene's rectangles, strips and markers, with notes on a zooming chart that stay at their data positions.

## v0.9.1

- Web v0.13.0: the zoom and fetch pages use its declarative buttons, scene cache and event decoding in place of their own.

## v0.9.0

- The Sync cursor, Cursor bind and Zoom fetch pages, charts that share a cursor and x range through Web's `group` and `cursor` attributes, and one that fetches the samples of its zoomed range.
- The Zoom ranger page, an overview chart whose dragged band sets the range of a larger one.
- Web v0.12.0 and Viewport v0.10.0.

## v0.8.0

- The Wheel Zoom & Drag, Pinch Zoom & Pan, Zoom variations and Zoom with reset pages, charts that the pointer zooms and pans from retained GPU buffers.
- The scatter plot, the latency heatmaps and the Heatmap / Scatter page, completing the Scatter & Bubble and Latency Heatmap pages.
- Web v0.9.1, Viewport v0.7.0 and Gpu v0.10.0.

## v0.7.0

- The Scatter & Bubble page (bubble plot only), the Sparklines page and the Sparklines (w/ floating bars) page.
- The Multi-Bars, Grouped and stacked bars and Latency Heatmap (histograms only) pages.

## v0.6.0

- Tick labels are converted with Web's `Label.ofDrawing`.
- Axes are compiled by Scene's `compilePixelAxis`, `compileLinearAxis` and `compileLogAxis`, and frames are encoded by Gpu's `frameBytes`; the clock-time axis is Scene's `compileTimeAxis`; `Axes.withTicks`, `linear`, `logarithmic`, `time`, `plane` and `Page.bytes` are gone, and `Reduce.Panel` is now `Frame`.

## v0.5.0

- The Path Gap Clip page draws a series stepped before, stepped after and as a spline through its points, with the gap left open.
- The Log Scales page, twelve servers' player counts on log and linear y axes over a clock-time x axis.

## v0.4.0

- The Axis Control page, half a million points with a red right axis and axis titles.
- The Missing Data, High-Low Bands and Path Gap Clip pages, with lines, bands and gaps over clock-time x axes.
- `Axes.withTicks` takes the axis style, and `Axes.time` draws a time axis.

## v0.3.0

- The million-point spike page and the server events page, drawn as per-column envelopes from `Pyramid.columns`, with tick labels placed by one shared helper.
- Pages convert rationals with `Rat.toFloat` from inkproof-float.

## v0.2.0

- Vertical axes lay out their labels with `layoutLabelsVertical`, so the y axis no longer needs transposed measurements.
- The Log Scales 2 page, with linear, base-10 and base-2 log y axes.
- The frame, label placement and axis builders that pages share now live in their own modules.

## v0.1.0

- The site skeleton, with the area-fill data, areas and lines generated from a fixed seed with Lean core's `StdGen`.
