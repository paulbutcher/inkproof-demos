# Parity with uPlot

Each page is compared with the uPlot demo it recreates, run locally from a clone of https://github.com/leeoniya/uPlot at commit `e995b061e9fc5476a6d862cd2fb2ebc7452ca012` (v1.6.32), in headless Chromium at the same viewport and device pixel ratio. Differences that come only from random data are not listed. A difference is `fixed` (with the pull request), `requested` (with the issue on the library that must change), `explained` (with the reason), or `open` (found, not yet resolved; none may remain when the comparison is finished).

Pages not yet compared have no section. Done: Line Paths, Area Fill, Axis Control, Stacked Series, Scatter and Bubble, Multi-Bars, Grouped Bars, Points, Missing Data, Zoom Wheel and Touch, Sparklines, Sparklines Bars, Months, Timezones and DST, Annotations, Arcsinh Scales, Box and Whisker, Candlestick, Cursor Bind, Custom Scales, Gradients, High-Low Bands, Latency Heatmap, Heatmap Cells, Log Scales, Log Scales 2, Path Gap Clip, A Million Points, Server Events, Sync Cursor, Timeline / Discrete, Tooltip and Legend, Zoom Fetch, Zoom Ranger, Zoom with Reset and Zoom Variations.

## Shared differences

- Axis lines, ticks and gridlines: uPlot's default draws no axis line, and ticks (10 long) and gridlines in the same 7% black, 2 CSS pixels wide, unless a demo sets otherwise. The site drew a black axis line, black 6 long ticks and a 1 pixel gridline. Fixed in `Axes.style`, which every page uses; a test checks that an axis draws no line and only faint two pixel ticks and gridlines.
- Series stroke width: uPlot's default is one CSS pixel. Pages set it through `Axes.strokeHalfWidth` (Axis Control and Log Scales 2 drew two pixels). Fixed; a test checks the stroke of those two pages.
- Axis `stroke` colours only the labels and title in uPlot, never the ticks. Axis Control drew red ticks; fixed.
- Legend placement, a row centred under the plot, and readouts (`Value: --` at rest): fixed; every chart's `legend` attribute names `below-center`, and a browser test checks the Area Fill legend sits below the plot, centred on it.
- Wheel, touch and drag pass-through to the page: fixed by Web 0.21.0, with no change to the pages; a browser test checks that the wheel over the Points page scrolls it, and the zoom tests that the zoom pages still zoom.
- Cursor markers (a dot on each series at the cursor, hollow markers filled under it): fixed; every chart with a `cursor` attribute adds `markers`. Charts with no `cursor` attribute draw no cursor in either version.
- Circle markers drawn as octagons: fixed by Gpu 0.19.0, with no change to the pages, which never tessellated markers themselves; they now draw as circles.
- Series without a label are named `Value` in uPlot's legend. Fixed: `Browser.seriesTraces` names a series `Value` unless its page gives a name (`Lines.Layer.label`), and a browser test checks the legends of Missing Data, Points, Axis Control, Zoom Wheel and Area Fill.
- uPlot draws the chart title inside the chart, above the plot; the pages put it in a heading above the chart. Open.

## Line Paths (`line-paths.html`)

- Data: the four charts draw the bar series of the stacked page with a gap of four points; same ranges. Matches.
- Colours and fills: strokes match; uPlot fills each area to the baseline at 10% (`stroke + "1A"`), as the site now does. Fixed; the chart definition carries the fill.
- Line widths: uPlot draws series and axes at `1 / devicePixelRatio` CSS pixels, one device pixel on any screen; the site draws one CSS pixel. A display list is in CSS pixels, so the same scene is the same size on every screen. Explained.
- Theme: uPlot's page is dark (`#2c3235` gridlines, `#c7d0d9` labels). Open.
- Axes: ticks and gridlines drawn as uPlot's; label format matches. Fixed.
- Point markers: a 5 pixel dot at each point, as uPlot's `drawStyles.points` draws. Fixed. Legend and cursor as under Shared differences.

## Area Fill (`area-fill.html`)

- Data and ranges: three series of integers from -10 to 10 over 1..30; same ranges and axis labels at the same step once the plot is the same width. Matches.
- Colours and fills: red, green and blue strokes with fills of 10% alpha, a circle at every point. Matches.
- Line widths: one pixel. Matches.
- Axes: fixed as above.
- Legend: uPlot names the series `Value`; the page does too. Fixed with the shared series names; a browser test checks the legend.
- Title: see Shared differences.

## Axis Control (`axis-control.html`)

- Data: sine over half a million points, y fixed to -50..50. Matches.
- Series width: uPlot one pixel; the page drew two. Fixed.
- Right axis: labels and title red, ticks faint; the page drew red ticks. Fixed. Its title sits 8 pixels from the labels in uPlot; open.
- Legend: the page names its series `sin(x)` as uPlot does; the x entry and readouts are under Shared differences. Fixed; a browser test checks the name.

## Stacked Series (`stacked-series.html`)

- Stacked areas: uPlot strokes each series' top edge in its colour and draws a point at every sample; the site draws the fills only. Open.
- Stacked bars: the bar width is a fraction of the spacing, as uPlot's builder gives it (fixed in #111, issue [#108](http://localhost:3000/tentenths/inkproof-demos/issues/108)). uPlot's bars also carry a two pixel stroke in the series colour (`width: 2`); whether the site's match is not yet checked. Open.
- Legend: uPlot names the series `bars 1` to `bars 4` (and `A`, `B` on a further chart) and lists the x entry first; the page names the bars `bars 1` to `bars 4`; the x entry is under Shared differences. Fixed.
- Charts below the first two (`Stacked 2` and the bar charts' variants): not yet compared.

## Scatter and Bubble (`scatter.html`)

- Series names: uPlot's scatter series have no label, so the legend reads `Value` four times; the page now does the same. Fixed.
- Data: ten thousand points per series over 0..500, y range unpadded (`guardedRange`). Matches.
- Markers: 5 pixel circles with a fill of 10% alpha and a stroke; drawn as circles. Fixed.
- Bubble chart: the page draws the bubbles of `data2`; sizes and labels in the legend `GDP`, `Income 1`, `Income 2` and the region names are not yet compared. Open.

## Multi-Bars (`multi-bars.html`)

- Legend names: `Lib Size (KB)`, `Render Time (ms)`, `Peak Heap (MB)`, `Final Heap (MB)`, `Interact 10s (ms)`, `Toggle 6x (ms)` and `Random line`, the line hidden by a click as the bars are. Fixed; a browser test checks the names and that clicking the last entry redraws.
- Random line in the horizontal layout: uPlot draws it; `Bars.lineDisplay` returns none when `horizontal`. Fixed: the points are computed in screen coordinates from the same `along` and category centres the horizontal bars use.
- Numbers on the bars: `Browser.barLabels` writes 10 pixel sans-serif; uPlot fits the size to each bar. Open.
- Line width: two pixels, as uPlot. Matches.

## Grouped Bars (`bars-grouped-stacked.html`)

- Legend names: `Metric 1` to `Metric 3`. Fixed (same browser test).
- Horizontal exception: the grouped and stacked horizontal charts draw no lines because they have none. Matches.
- Numbers on each bar are too small, and stacked segments carry no numbers of their own, only a total on the top bar. Open.

## Points (`points.html`)

- Series: green line, red line with a 10% fill and markers at every sample, blue markers over a 10% fill, orange line with a marker only where the samples around it are missing. Matches.
- Line width: one pixel; the page drew two. Fixed; the parity test checks both charts.
- Legend: four series named `Value`. Fixed.
- Markers: circles drawn as octagons, as under Shared differences.

## Missing Data (`missing-data.html`)

- Series: `CPU`, `RAM` and `TCP Out`, strokes red, blue and green with 5% fills, nulls left as gaps. Matches.
- Legend: the names were `Series N`; fixed. The second chart's single series is `Value`.

## Zoom Wheel and Zoom Touch (`zoom-wheel.html`, `zoom-touch.html`)

- Legend: the series are `One` and `Two`; the pages named them `Series N`. Fixed (`Zoom.legendNames`). The other zoom pages leave their series unnamed and read `Value`.
- Wheel and touch pass-through: fixed, see Shared differences.

## Sparklines (`sparklines.html`)

- Data and drawing: ten stocks, volume and close, 150 by 30 pixels on a pink canvas, a blue line over a light blue fill, no axes, cursor or legend. Side by side the twenty sparklines match in shape and extent. Matches.
- The page adds a link and a sentence above the table. Explained: the site's pages say what they show.

## Sparklines Bars (`sparklines-bars.html`)

- Data: sixteen points, a line with a gradient fill and floating bars of five either side. Same ranges (`-25` to `15`, the bar highs do not widen the range) and the same dashed line at zero. Matches.
- Colours: green above zero and red below, bars split at zero in the first chart and one colour per bar in the second. Matches.
- Headings: the site adds a title and a sentence for each chart. Explained.

## Months (`months.html`)

- Data: one value per month start from 2017 to 2019, random but for the first. Ticks fall on month starts, labelled with month names. Matches.
- Year line: the year under the first January tick, as uPlot's. Matches.
- Markers: a hollow circle at every point, as uPlot's. Fixed.
- Legend: `Value` with the cursor's readout under the plot; see Shared differences.

## Timezones and DST (`timezones-dst.html`)

- Data: a spike once a day over the range, the same twelve charts (four ranges, UTC, the zone with the change and the other zone), with the same titles. Matches.
- Ticks: uPlot labels every day as `3/29`, `3/30`; the site's step is two days and its labels read `Mar 29`. Open: the step comes from the library's tick choice for the width, and the label format from the library's date label.
- Context line: the date under the first tick of a day, as uPlot's. Matches.
- Series name: `2019` in uPlot; the site read `Value`. Fixed; a browser test checks it.
- Section headings: uPlot centres each range's heading in a pale blue band (`#E1F5FE`, 25 pixels of padding); the site's do the same. Fixed.

## Annotations (`annotations.html`)

- Data: thirty integers from -10 to 10 over 1..30 in two filled series, red and blue with 10% fills. Matches.
- Notes: an earthquake line at 4 and a tornado band from 9.3 to 18.5, dashed two pixel borders in green and amber over a 20% fill, labelled `eqk_01` on the bottom edge and `tor_20` on the top. Matches in position and colour; they follow zoom and pan as uPlot's do.
- Note labels: uPlot's carry a description as a tooltip and fill with a solid border on hover; the site's do not. Open.

## Arcsinh Scales (`arcsinh-scales.html`)

- Data: the same 109 values, a thousandth to a thousand either side of zero, and the same slider from 0.001 to 1000 in decades. Matches.
- Scale and fill: arcsinh y axis, blue line over a 10% fill. Matches.
- Ticks: uPlot places them at the arcsinh scale's own steps; the site puts them at powers of ten and zero. Open.

## Box and Whisker (`box-whisker.html`)

- Data: uPlot draws recorded benchmark timings of its frameworks from `data/results.json`; the site generates twelve runs for each of twenty-four frameworks. Open: the shapes agree, the numbers do not.
- Drawing: boxes of the middle half with a median bar, dashed whiskers within one and a half interquartile ranges, and squares for the runs beyond. Matches.
- Hover: uPlot highlights the column and shows the legend as a tooltip with every statistic; the site's cursor is a line. Open.

## Candlestick (`candlestick-ohlc.html`)

- Data: the gold year's open, high, low and close, evenly spaced days, volume on a right scale of 0 to 2000; the volumes are random in uPlot and a fixed hash here. Matches.
- Colours: `#e54245` for falls and `#4ab650` for rises. Matches.
- Hover: as for Box and Whisker. Open.

## Cursor Bind (`cursor-bind.html`)

- Data: three series of thirty integers over 1..30. Matches.
- Size and fills: uPlot is 1920 by 600 with 10% fills (red, bright green, blue); the page was 900 by 400 with no fills. Fixed; the chart is `Linked.cursorBindChart`, with a theorem for its fills.
- Ctrl-drag annotation: no counterpart, as the page says. Explained: it is a prompt for text that uPlot's demo discards.

## Custom Scales (`custom-scales.html`)

- Data: the same fitted curve, bounds and twenty observations in the same three charts (linear, both logarithmic, and a Weibull y axis). The curves match.
- Series names: `upper_ci`, `lower_ci` and `weibull_fitted` in uPlot; the site reads `Value`. Fixed.
- X range: uPlot's logarithmic x axis starts at the first sample, about 0.4; the site's starts at 0.1. Open.
- Ticks: uPlot labels the linear y axis every 0.05 and the logarithmic ones at 1, 0.5, 0.2, 0.1 and so on; the site labels every 0.1 and at decades with six decimals. Open: the library's tick choice.
- Chart titles inside the chart: see Shared differences.

## Gradients (`gradients.html`)

- Data and colours: the same five charts with the same strokes and fills, the same switch points and the same fill stops. Matches.
- Series names: `Trends`, `Over/Under`, `Tank 1 (red = high pressure)`, `Tank 2 (red = low pressure)` and `Tank 1`; the site read `Value`. Fixed; a browser test checks them.
- Banded: uPlot's third chart has a symmetric logarithmic y axis from -100 to 100 and three colours by band; the site's is linear from -30 to 30. Open.
- Markers: uPlot draws a hollow circle at every point; the site draws none. Open.
- X ticks of the fills: uPlot labels `0`, `0.5`, `1`; the site `0.0`, `0.5`, `1.0`. Open: the library's number label.

## High-Low Bands (`high-low-bands.html`)

- Only the first of uPlot's twelve charts is recreated: the year of daily lows, highs and means. The others (differing paths, bars, inverted bands, the unaligned and thin bar cases, the minute-resolution temperatures) have no counterpart. Open.
- Temperatures: the same shape, bands and gaps, with a dashed blue mean. Matches.
- Ticks: uPlot labels every twenty days as `1/11`; the site `Jan 11`. Open: the library's date label.
- Series names: `Low`, `High` and `Avg` in uPlot; the site reads `Value`. Fixed.

## Latency Heatmap and Heatmap Cells (`latency-heatmap.html`)

- Heatmap cells: uPlot's third chart (mode 2, 45k latencies in 15 second by 2 ms cells) is the page `heatmap-cells`; it has no demo of its own. Matches in shape: oranges to red by count, over about eighty minutes.
- Raw and aggregated heatmaps: translucent red dashes, and cyan to red buckets of 10 ms; the site's buckets are 5 ms and its time ticks every ten seconds against five. Open.
- Histograms: uPlot floors latencies at 5 (`yMin`), as the site now does, so the first bar is the 5 to 10 bucket. Fixed.
- Bucket sliders: uPlot has size and offset above the histograms; the site has none. Open.
- Legends read `Time`, `Value`; the site's name its columns. Explained.

## Log Scales (`log-scales.html`)

- Data: the same twelve servers and samples, a log and a linear chart at 1600 by 600. Matches.
- Gaps: uPlot sets `spanGaps`, so a server's line carries on across samples it did not report (Hypixel's drop to 53 thousand is drawn); the site broke the line there. Fixed; a native test checks that no layer has a missing sample.
- Y ticks: uPlot's log axis labels 1, 2, 5, 10 and so on with minor gridlines, and the linear one every 5,000 to 120,000; the site labels decades and every 10,000 to 110,000. Open: the library's tick choice.
- X ticks: uPlot labels every hour (`3am`, context `7/17/20`); the site every two hours (`04:00`, context `Jul 17`). Open: the library's time labels.
- Legend: see Shared differences; the chart title is inside the chart in uPlot (see Shared differences).

## Log Scales 2 (`log-scales2.html`)

- Data: the same 127 values, in the linear, log10 and log2 charts, and the same signed, skip ticks and tiny cases. Matches.
- Inverted log scale: uPlot's fourth chart (two series on opposed log axes over time) has no counterpart. Open.
- Ticks: uPlot's log axes label every power plus minor gridlines at 2 to 9 times each; the site labels powers only, as `10^8` and `2^24`; the minor gridlines are drawn, fainter than the major ones.
- Ranges: skip ticks log10 spans 1e-14 to 1e+14 in uPlot, the site 1e-12 to 1e+12; the tiny chart shows 5e-16 to 1e-12 (3e-24 in uPlot's title) against the site's 1e-15 to 1e-13. Open.
- Proper range: uPlot's third small chart carries an all-missing second series; the page says it has none. Explained.
- Markers: uPlot draws a dot at every point; the site draws none. Open: see Shared differences.

## Path Gap Clip (`path-gap-clip.html`)

- Charts: uPlot has fifteen charts; the page recreates the first two (zoom-out range with a band, and gaps in a band) and three stepped and spline variants, whose data differ from uPlot's stepped, null-fill, align and pixel-bug cases. Open: the others have no counterpart.
- Data: temperature series and the band with its gaps match.
- Theme: uPlot's charts here have a grey plot background; the site's are white. Open.
- X range of the gaps chart: uPlot's axis is in seconds since an offset; the site's is the clock time. Explained.

## A Million Points (`million.html`)

- No uPlot demo of this name: the nearest is `bench/uPlot-10M.html` (two million points in one chart, forty thousand by fifty series in another, random data, no spikes). The page recreates what uPlot's decimation claims, not its data: a million samples with twelve one sample spikes, drawn naively and as lowest and highest of each pixel column. Explained.
- Legend, cursor and focus (`prox: 30`) of the benchmark: none on the page. Open.

## Server Events (`server-events.html`)

- Data: uPlot's `bench/data.json` holds 55,550 one minute samples of CPU, RAM and TCP out (`bench/uPlot.html`); the site generates the same count of CPU, memory and traffic samples from a hash, as the page does not ship uPlot's file. Explained.
- Axes: uPlot draws CPU and RAM on a `%` axis on the left and TCP out on its own `MB` axis on the right, without a grid; the site draws all three on one 0 to 100 axis. Open.
- Series: red CPU, blue RAM, green TCP out at one device pixel; the site's are red, green and blue (Busy, Memory used, Traffic) at one CSS pixel. Open.
- Time axis: uPlot's x is time; the site's is the sample index. Open.
- Legend and cursor readouts (`CPU`, `RAM`, `TCP Out` with `%` and `MB` values): the site has none. Open: see Shared differences.

## Sync Cursor (`sync-cursor.html`)

- Data: uPlot cuts three thousand-sample stretches out of the same real data into three charts (CPU, RAM, TCP, each with three series); the site draws three stretches of its own generated series, the same shape. Explained.
- Sizes: 1920 by 400 for CPU and 940 by 400 for the others; the site's are 800 by 240. Open.
- Syncing: uPlot syncs only the cursor, with a lock on click and focus of the series nearest it; the site also links the x range, a superset. Explained.
- Toggles: uPlot has buttons to disable syncing and the mouse up and down sync; the site has one button that unlinks the middle chart. Open.
- Mis-matched series order: uPlot's second pair of charts matches series by label across charts; no counterpart. Open.
- Axis labels: `%` and ` MB` suffixes in uPlot; the site's are plain. Open.

## Timeline / Discrete (`timeline-discrete.html`)

- Data: the states of the first three charts (devices A to C, states 0 to 5, the periodic and lettered series) are uPlot's; the irregular times are drawn from a fixed seed rather than at random. Matches.
- Charts: uPlot's fourth, `Merged same consecutive states`, has no counterpart. Open.
- Colours: states use the red, green, blue, cyan, orange and yellow strokes with the same fill alphas; bars have a four pixel inside outline. Matches.
- Hover: uPlot highlights the bar under the cursor and shows its state in the legend; the page has a cursor only. Open.
- Axes: uPlot's labels sit 15 pixels from a 70 pixel wide gutter; the site's gutter is 90. Explained.
- Chart title inside the chart, drop shadow and padding: see Shared differences.

## Tooltip and Legend (`tooltip-legend.html`)

- Page stands in for uPlot's `tooltips-closest.html` and legend pages; the data are those of Cursor Bind, not the benchmark results uPlot's tooltips draw (a series per cache state with commit hashes). Explained.
- Tooltip: uPlot shows the value and commit in a box beside the nearest point, with its border in the series colour; the page names the series and values of the nearest point. Matches in kind.
- Focus: uPlot dims series other than the one nearest the cursor (`alpha: 0.3`, `prox: 5`); the page does not. Open: [inkproof-web#110](http://localhost:3000/tentenths/inkproof-web/issues/110) concerns the legend.
- Legend: see Shared differences.

## Zoom Fetch (`zoom-fetch.html`)

- Data: uPlot draws one red series of four points (3 to 6) after a zoom and the full nine points of four series at the start; the site serves 5000 one byte samples from a file, a coarse one (one in twenty) for the full range and a fine one for a zoomed range, a red line. Explained: the demo is about fetching, which the site does for real.
- Zoom: uPlot's x drag zooms on release and fetches then; the site's wheel, drag and keys all fetch again for the range shown, and discard an answer that a later request has overtaken. Matches in kind.
- Reset: uPlot's double click restores the full data; the site's key resets to the full range and fetches the coarse file. Open: no double click.
- Axis: uPlot's x is plain numbers; so is the site's. Matches.

## Zoom Ranger (`zoom-ranger.html`)

- Data: uPlot draws one hundred points of sin(x) over 0 to 2π; the site draws two thousand minutes of the server events busy series. Explained.
- Layout: uPlot's 100 pixel overview is above the 400 pixel zoomed chart, both 800 wide; the site's are 120 and 300 high, in the same order. Explained.
- Selection: the overview opens with a band over 1 to 4.5 and the zoomed chart shows that range; the site's opens with 600 to 1200. Dragging in the overview sets the other's range and the overview keeps its own, as uPlot's does. Matches.
- Overview cursor: uPlot hides its points and its y drag; the site's overview drags in x only. Matches.
- Grips and y selection (`zoom-ranger-grips.html`, `zoom-ranger-xy.html`): no counterpart. Open.
- Legend and cursor sync (`key: "moo"`): the zoomed chart's legend is `x` and `sin(x)` in uPlot; the site has none for the overview and the unnamed `Value` for the other. Open: see Shared differences.

## Zoom with Reset (`zoom-reset-range`)

- No uPlot demo of this name: its pages have only the double click of Zoom Fetch. The page recreates the zoom pages' series with a button that returns the chart to its full range exactly. Explained.

## Zoom Variations (`zoom-variations.html`)

- Data: thirty points over -10 to 10 in purple, 600 by 400; the values are drawn from a fixed hash rather than at random. Matches.
- Charts: uPlot's are the five drag variants and the same five with `dist: 10`, titled by variant; the site has ten with the titles in captions, and a drag shorter than 10 pixels does nothing. Matches.
- Variants: X only, Y only, adaptive (the longer axis) and omni (both) match. uPlot's adaptive plus omni (`uni: 50`) has no mode of its own, so the site repeats the adaptive chart. Open.
- Layout: uPlot shows the charts inline, the site one to a row. Explained.
