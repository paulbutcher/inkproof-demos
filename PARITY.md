# Parity with uPlot

Each page is compared with the uPlot demo it recreates, run locally from a clone of https://github.com/leeoniya/uPlot at commit `e995b061e9fc5476a6d862cd2fb2ebc7452ca012` (v1.6.32), in headless Chromium at the same viewport and device pixel ratio. Differences that come only from random data are not listed. A difference is `fixed` (with the pull request), `requested` (with the issue on the library that must change), `explained` (with the reason), or `open` (found, not yet resolved; none may remain when the comparison is finished).

Pages not yet compared have no section. Done: Line Paths, Area Fill, Axis Control, Stacked Series, Scatter and Bubble, Multi-Bars, Grouped Bars, Points, Missing Data, Zoom Wheel and Touch, Sparklines, Sparklines Bars, Months, Timezones and DST, Annotations, Arcsinh Scales, Box and Whisker, Candlestick, Cursor Bind, Custom Scales, Gradients, High-Low Bands, Latency Heatmap, Heatmap Cells, Log Scales, Log Scales 2 and Path Gap Clip.

## Shared differences

- Axis lines, ticks and gridlines: uPlot's default draws no axis line, and ticks (10 long) and gridlines in the same 7% black, 2 CSS pixels wide, unless a demo sets otherwise. The site drew a black axis line, black 6 long ticks and a 1 pixel gridline. Fixed in `Axes.style`, which every page uses; a test checks that an axis draws no line and only faint two pixel ticks and gridlines.
- Series stroke width: uPlot's default is one CSS pixel. Pages set it through `Axes.strokeHalfWidth` (Axis Control and Log Scales 2 drew two pixels). Fixed; a test checks the stroke of those two pages.
- Axis `stroke` colours only the labels and title in uPlot, never the ticks. Axis Control drew red ticks; fixed.
- Legend placement, a row centred under the plot, and readouts (`Value: --` at rest): requested, [inkproof-web#110](http://localhost:3000/tentenths/inkproof-web/issues/110).
- Wheel, touch and drag pass-through to the page: requested, [inkproof-web#113](http://localhost:3000/tentenths/inkproof-web/issues/113).
- Cursor markers (a dot on each series at the cursor, hollow markers filled under it): requested, [inkproof-web#115](http://localhost:3000/tentenths/inkproof-web/issues/115). Applies to every page whose uPlot original shows cursor points.
- Circle markers drawn as octagons: requested, [inkproof-gpu#68](http://localhost:3000/tentenths/inkproof-gpu/issues/68). Applies to every page with circle markers.
- Series without a label are named `Value` in uPlot's legend. Fixed: `Browser.seriesTraces` names a series `Value` unless its page gives a name (`Lines.Layer.label`), and a browser test checks the legends of Missing Data, Points, Axis Control, Zoom Wheel and Area Fill.
- uPlot draws the chart title inside the chart, above the plot; the pages put it in a heading above the chart. Open.

## Line Paths (`line-paths.html`)

- Data: the four charts draw the bar series of the stacked page with a gap of four points; same ranges. Matches.
- Colours and fills: strokes match; uPlot fills each area to the baseline at 10% (`stroke + "1A"`); the site draws no fill. Open.
- Line widths: uPlot draws series and axes at `1 / devicePixelRatio` CSS pixels, one device pixel on any screen; the site draws one CSS pixel. A display list is in CSS pixels, so the same scene is the same size on every screen. Explained.
- Theme: uPlot's page is dark (`#2c3235` gridlines, `#c7d0d9` labels). Open.
- Axes: ticks and gridlines drawn as uPlot's; label format matches. Fixed.
- Point markers (`drawStyles.points` shows a 5 pixel dot at each point), cursor and legend: open for the markers; legend and cursor as under Shared differences.

## Area Fill (`area-fill.html`)

- Data and ranges: three series of integers from -10 to 10 over 1..30; same ranges and axis labels at the same step once the plot is the same width. Matches.
- Colours and fills: red, green and blue strokes with fills of 10% alpha, a circle at every point. Matches.
- Line widths: one pixel. Matches.
- Axes: fixed as above.
- Legend: uPlot names the series `Value`; the page names them `Series 1` to `Series 3`. Open.
- Title: see Shared differences.

## Axis Control (`axis-control.html`)

- Data: sine over half a million points, y fixed to -50..50. Matches.
- Series width: uPlot one pixel; the page drew two. Fixed.
- Right axis: labels and title red, ticks faint; the page drew red ticks. Fixed. Its title sits 8 pixels from the labels in uPlot; open.
- Legend: `x` and `sin(x)` entries in uPlot; the page names the series `Series 1`. Open.

## Stacked Series (`stacked-series.html`)

- Stacked areas: uPlot strokes each series' top edge in its colour and draws a point at every sample; the site draws the fills only. Open.
- Stacked bars: the bar width is a fraction of the spacing, as uPlot's builder gives it (fixed in #111, issue [#108](http://localhost:3000/tentenths/inkproof-demos/issues/108)). uPlot's bars also carry a two pixel stroke in the series colour (`width: 2`); whether the site's match is not yet checked. Open.
- Legend: uPlot names the series `bars 1` to `bars 4` (and `A`, `B` on a further chart) and lists the x entry first; the page names them `Series N`. Open.
- Charts below the first two (`Stacked 2` and the bar charts' variants): not yet compared.

## Scatter and Bubble (`scatter.html`)

- Series names: uPlot's scatter series have no label, so the legend reads `Value` four times; the page now does the same. Fixed.
- Data: ten thousand points per series over 0..500, y range unpadded (`guardedRange`). Matches.
- Markers: 5 pixel circles with a fill of 10% alpha and a stroke; drawn as octagons by Gpu ([inkproof-gpu#68](http://localhost:3000/tentenths/inkproof-gpu/issues/68)). Requested.
- Bubble chart: the page draws the bubbles of `data2`; sizes and labels in the legend `GDP`, `Income 1`, `Income 2` and the region names are not yet compared. Open.

## Multi-Bars (`multi-bars.html`)

- Legend names: `Lib Size (KB)`, `Render Time (ms)`, `Peak Heap (MB)`, `Final Heap (MB)`, `Interact 10s (ms)`, `Toggle 6x (ms)` and `Random line`, the line hidden by a click as the bars are. Fixed; a browser test checks the names and that clicking the last entry redraws.
- Random line in the horizontal layout: uPlot draws it; `Bars.lineDisplay` returns none when `horizontal`. Open: the points are computed in screen coordinates from the same `along` and category centres the horizontal bars use.
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
- Wheel and touch pass-through: requested, see Shared differences.

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
- Markers: uPlot draws a small circle at every point; the site draws none. Open.
- Legend: `Value` with the cursor's readout under the plot; see Shared differences.

## Timezones and DST (`timezones-dst.html`)

- Data: a spike once a day over the range, the same twelve charts (four ranges, UTC, the zone with the change and the other zone), with the same titles. Matches.
- Ticks: uPlot labels every day as `3/29`, `3/30`; the site's step is two days and its labels read `Mar 29`. Open: the step comes from the library's tick choice for the width, and the label format from the library's date label.
- Context line: the date under the first tick of a day, as uPlot's. Matches.
- Series name: `2019` in uPlot; the site read `Value`. Fixed; a browser test checks it.
- Section headings: uPlot puts each range's heading in a pale blue band; the site's are plain. Open.

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
- Series names: `upper_ci`, `lower_ci` and `weibull_fitted` in uPlot; the site reads `Value`. Open.
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
- Series names: `Low`, `High` and `Avg` in uPlot; the site reads `Value`. Open.

## Latency Heatmap and Heatmap Cells (`latency-heatmap.html`)

- Heatmap cells: uPlot's third chart (mode 2, 45k latencies in 15 second by 2 ms cells) is the page `heatmap-cells`; it has no demo of its own. Matches in shape: oranges to red by count, over about eighty minutes.
- Raw and aggregated heatmaps: translucent red dashes, and cyan to red buckets of 10 ms; the site's buckets are 5 ms and its time ticks every ten seconds against five. Open.
- Histograms: uPlot's start at 5 with the tail to 155; the site's x axis starts at 25 and its first bar is the 25 to 30 bucket. Open.
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
- Ticks: uPlot's log axes label every power plus minor gridlines at 2 to 9 times each; the site labels powers only. The log2 labels read `2^24` in uPlot and use superscripts on the site. Open: the library's tick choice.
- Ranges: skip ticks log10 spans 1e-14 to 1e+14 in uPlot, the site 1e-12 to 1e+12; the tiny chart shows 5e-16 to 1e-12 (3e-24 in uPlot's title) against the site's 1e-15 to 1e-13. Open.
- Proper range: uPlot's third small chart carries an all-missing second series; the page says it has none. Explained.
- Markers: uPlot draws a dot at every point; the site draws none. Open: see Shared differences.

## Path Gap Clip (`path-gap-clip.html`)

- Charts: uPlot has fifteen charts; the page recreates the first two (zoom-out range with a band, and gaps in a band) and three stepped and spline variants, whose data differ from uPlot's stepped, null-fill, align and pixel-bug cases. Open: the others have no counterpart.
- Data: temperature series and the band with its gaps match.
- Theme: uPlot's charts here have a grey plot background; the site's are white. Open.
- X range of the gaps chart: uPlot's axis is in seconds since an offset; the site's is the clock time. Explained.
