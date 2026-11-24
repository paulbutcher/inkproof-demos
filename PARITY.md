# Parity with uPlot

Each page is compared with the uPlot demo it recreates, run locally from a clone of https://github.com/leeoniya/uPlot at commit `e995b061e9fc5476a6d862cd2fb2ebc7452ca012` (v1.6.32), in headless Chromium at the same viewport and device pixel ratio. Differences that come only from random data are not listed. A difference is `fixed` (with the pull request), `requested` (with the issue on the library that must change), `explained` (with the reason), or `open` (found, not yet resolved; none may remain when the comparison is finished).

Pages not yet compared have no section. Done: Line Paths, Area Fill, Axis Control, Stacked Series, Scatter and Bubble, Multi-Bars, Grouped Bars, Points, Missing Data, Zoom Wheel and Touch, Sparklines, Sparklines Bars, Months, Timezones and DST.

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
- Year line: uPlot writes the year under the first January tick; the site does not. Requested, [inkproof-axis#52](http://localhost:3000/tentenths/inkproof-axis/issues/52).
- Markers: uPlot draws a small circle at every point; the site draws none. Open.
- Legend: `Value` with the cursor's readout under the plot; see Shared differences.

## Timezones and DST (`timezones-dst.html`)

- Data: a spike once a day over the range, the same twelve charts (four ranges, UTC, the zone with the change and the other zone), with the same titles. Matches.
- Ticks: uPlot labels every day as `3/29`, `3/30`; the site's step is two days and its labels read `Mar 29`. Open: the step comes from the library's tick choice for the width, and the label format from the library's date label.
- Year line: uPlot writes the year under the first tick. Requested, [inkproof-axis#52](http://localhost:3000/tentenths/inkproof-axis/issues/52).
- Series name: `2019` in uPlot; the site read `Value`. Fixed; a browser test checks it.
- Section headings: uPlot puts each range's heading in a pale blue band; the site's are plain. Open.
