# Changelog

## v0.25.1

- PARITY.md compares Custom Scales, Gradients, High-Low Bands, Latency Heatmap and Heatmap Cells with uPlot.
- PARITY.md compares Log Scales, Log Scales 2 and Path Gap Clip with uPlot.
- Log Scales draws each server's line across the samples it did not report, as uPlot does.

## v0.25.0

- Time-axis labels draw their context line (the year or the day) under the label.
- Cursor Bind draws at uPlot's size with its 10% fills.
- Gradients names its series as uPlot does.
- Depends on inkproof-web v0.25.1, inkproof-axis v0.14.0 and inkproof-scene v0.30.0.

## v0.24.2

- The Timezones and DST series are named 2019.
- Cursor Bind draws at uPlot's size with its 10% fills.
- Gradients names its series as uPlot does.

## v0.24.1

- Retained layers' recorded draws are kept by Web's `SceneCache.buildRetained`, not in a ref beside it.
- Depends on inkproof-web v0.25.0.

## v0.24.0

- A legend click on the Zoom Wheel and Touch and Zoom Fetch pages, and on every page that draws retained layers, replays the draws recorded for the layers drawn before, so a click costs time in the number of layers, not their commands.
- Depends on inkproof-gpu v0.22.1 and inkproof-scene v0.29.0.

## v0.23.0

- A legend click on the Points and Sync Cursor pages draws again from retained layers, uploading and tessellating nothing again.
- Axis labels, bar labels and the timeline's state text are set in Scene's shared text style, bar labels, legend and tooltip share one number format, the default axis hides its line with the optional axis parts, and pages use Web's list-of-words `interaction` and `cursor` attributes.

## v0.22.0

- A legend click on the Scatter, Log Scales, Gradients, High Low Bands, Line Paths, Missing Data and Path Gap Clip pages draws again from retained layers, uploading and tessellating nothing again.
- Depends on inkproof-gpu v0.20.0.

## v0.21.0

- The Stacked page's bars are 60% of the pixel distance between adjacent x values wide, not hairlines.

## v0.20.1

- Every page draws its strokes with Gpu v0.18.0's `strokeFrameBytes`, so thin vertical strokes such as x axis ticks have no foot.

## v0.20.0

- The calendar-time pages use Axis v0.11.0's `posixZone` for zone offsets; `CalendarTime.Zone.ofRule`, `Zone.offset` and their theorems are removed.

## v0.19.0

- Latency Heatmap's four charts have a legend that reads the column's, or the bucket's, counts at the cursor.

## v0.18.0

- Log Scales, Log Scales 2, ArcSinh Scales and Custom Scales use Float v0.8.0's `Float.onRat` in place of their own lifts; `CustomScales.asRat` and its theorem are removed.

## v0.17.0

- Every page draws at the device pixel ratio, Zoom and Fetch data strokes included.
- Every chart has a one or two sentence description above it.
- Timezones & DST page: six-day charts of hourly data in UTC, Europe/London and America/Chicago across each zone's 2019 daylight-saving changes, with offsets from Lean's POSIX zone rules.
- Months page: three years of monthly levels on an axis ticked on the first of each month.
- ArcSinh Scales page: data from a thousandth to a thousand of either sign on an arcsinh y axis, with a slider for the linear threshold.
- Custom Scales page: a Weibull plot on linear, log and log(-log(1 - y)) scales, with confidence bands, a dashed fit and the observed points.
- Timezones & DST ticks sit at each zone's local clock intervals.
- Scene v0.24.0, Gpu v0.17.0, Axis v0.9.0, Scale v0.11.0.

## v0.16.0

- Multi-Bars, Lines and Log Scales 2 use Lean's `Array.sum`, `max?`, `min?`, `Nat.toSuperscriptString` and `Rat.ofScientific` in place of their own; `MultiBars.total`, `largest`, `LogScales2.ofDecimal` and `sups` and their theorems are removed.

## v0.15.1

- Candlestick and Box Whisker have a legend that reads each chart's group of values (open, high, low, close and volume; the box's five numbers) at the cursor.
- Timeline Discrete has a legend with a row for each device that reads its state at the cursor.
- Inkproof-web v0.19.0.
- Axis Control has a legend that follows the cursor over its half million points.
- Inkproof-web v0.17.0: the legend shows a dash for a missing value, the cursor works over half a million points.
- The Grouped and stacked bars page and the line charts of Multi-Bars have a static legend that hides a series on a click.
- The Scatter Plot chart has a static legend that hides a cloud on a click.

## v0.15.0

- The first three Gradients charts change colour at once at each stop, as uPlot's do, using Scene's stepped shading.
- Sparklines with floating bars draws the area, line and bars with one paint each: a red to white to green fill, and a line and bars that are green above zero and red below.
- Every page whose uPlot demo has a live legend has one too, with an entry for each series that reads its value at the cursor and hides the series on a click.

## v0.14.1

- The site builds in a fraction of the time: every page mounts one shared Lasm program, so the Lean compiles once, not once per page.
- Gpu v0.15.0: thin vertical and horizontal strokes, such as axis ticks, end without a foot.
- The Gradients page is on the index, with horizontal, over-under, banded and fill gradients.

## v0.14.0

- Seeded draws come from lean-random-sampling v0.1.0, and the samplers written here are gone; uniform draws now have a resolution of 2^-53, so the Latency pages show different data for a seed.

## v0.13.1

- The Zoom variations page boxes on a plain drag (`drag="box"`).
- The Area Fill page redraws at the chart's size when it is resized, and puts its legend below the plot.

## v0.13.0

- The Cursor bind and Tooltip and legend pages take a `seed` query parameter and otherwise a random seed.
- The Stacked Series bar chart and the Scatter page's point clouds take a `seed` query parameter and otherwise a random seed.
- The Multi Bars page takes a `seed` query parameter and otherwise a random seed.
- The Line Paths page, one series drawn as linear, spline and stepped lines, and gradient strokes and fills for the line charts' layers.

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
