/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lasm.UI.Mount
import Inkproof.Demos.Pages.Annotations
import Inkproof.Demos.Pages.AreaFill
import Inkproof.Demos.Pages.ArcsinhScales
import Inkproof.Demos.Pages.CustomScales
import Inkproof.Demos.Pages.AxisControl
import Inkproof.Demos.Pages.BoxWhisker
import Inkproof.Demos.Pages.CalendarTime
import Inkproof.Demos.Pages.Candlestick
import Inkproof.Demos.Pages.CursorBind
import Inkproof.Demos.Pages.Gradients
import Inkproof.Demos.Pages.GroupedBars
import Inkproof.Demos.Pages.HeatmapCells
import Inkproof.Demos.Pages.HighLowBands
import Inkproof.Demos.Pages.LatencyHeatmap
import Inkproof.Demos.Pages.LinePaths
import Inkproof.Demos.Pages.LogScales
import Inkproof.Demos.Pages.LogScales2
import Inkproof.Demos.Pages.Million
import Inkproof.Demos.Pages.MissingData
import Inkproof.Demos.Pages.MultiBars
import Inkproof.Demos.Pages.PathGapClip
import Inkproof.Demos.Pages.Points
import Inkproof.Demos.Pages.Scatter
import Inkproof.Demos.Pages.ServerEvents
import Inkproof.Demos.Pages.SparklinesBars
import Inkproof.Demos.Pages.Sparklines
import Inkproof.Demos.Pages.Stacked
import Inkproof.Demos.Pages.SyncCursor
import Inkproof.Demos.Pages.TimelineDiscrete
import Inkproof.Demos.Pages.TooltipLegend
import Inkproof.Demos.Pages.ZoomFetch
import Inkproof.Demos.Pages.ZoomRanger
import Inkproof.Demos.Pages.ZoomResetRange
import Inkproof.Demos.Pages.ZoomTouch
import Inkproof.Demos.Pages.ZoomVariations
import Inkproof.Demos.Pages.ZoomWheel

/-- Every page mounts this one program, naming itself in the mount flags, so the site compiles its Lean once. -/
def main : IO Unit := do
  match (← Lasm.UI.Mount.flags String) with
  | "annotations" => Page.Annotations.run
  | "area-fill" => Page.AreaFill.run
  | "arcsinh-scales" => Page.ArcsinhScales.run
  | "calendar-time" => Page.CalendarTime.run
  | "axis-control" => Page.AxisControl.run
  | "box-whisker" => Page.BoxWhisker.run
  | "candlestick" => Page.Candlestick.run
  | "cursor-bind" => Page.CursorBind.run
  | "custom-scales" => Page.CustomScales.run
  | "gradients" => Page.Gradients.run
  | "grouped-bars" => Page.GroupedBars.run
  | "heatmap-cells" => Page.HeatmapCells.run
  | "high-low-bands" => Page.HighLowBands.run
  | "latency-heatmap" => Page.LatencyHeatmap.run
  | "line-paths" => Page.LinePaths.run
  | "log-scales" => Page.LogScales.run
  | "log-scales2" => Page.LogScales2.run
  | "million" => Page.Million.run
  | "missing-data" => Page.MissingData.run
  | "multi-bars" => Page.MultiBars.run
  | "path-gap-clip" => Page.PathGapClip.run
  | "points" => Page.Points.run
  | "scatter" => Page.Scatter.run
  | "server-events" => Page.ServerEvents.run
  | "sparklines-bars" => Page.SparklinesBars.run
  | "sparklines" => Page.Sparklines.run
  | "stacked" => Page.Stacked.run
  | "sync-cursor" => Page.SyncCursor.run
  | "timeline-discrete" => Page.TimelineDiscrete.run
  | "tooltip-legend" => Page.TooltipLegend.run
  | "zoom-fetch" => Page.ZoomFetch.run
  | "zoom-ranger" => Page.ZoomRanger.run
  | "zoom-reset-range" => Page.ZoomResetRange.run
  | "zoom-touch" => Page.ZoomTouch.run
  | "zoom-variations" => Page.ZoomVariations.run
  | "zoom-wheel" => Page.ZoomWheel.run
  | page => throw (IO.userError s!"no page {page}")
