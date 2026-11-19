# Changelog

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
