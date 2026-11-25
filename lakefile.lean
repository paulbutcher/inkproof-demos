/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lake
open Lake DSL

package «inkproof-demos» where
  leanOptions := #[
    ⟨`autoImplicit, false⟩,
    ⟨`relaxedAutoImplicit, false⟩,
    ⟨`warningAsError, true⟩
  ]

require «inkproof-web» from git "https://github.com/paulbutcher/inkproof-web" @ "v0.25.2"
require «inkproof-export» from git "https://github.com/paulbutcher/inkproof-export" @ "v0.5.0"
require «inkproof-viewport» from git "https://github.com/paulbutcher/inkproof-viewport" @ "v0.10.0"
require «inkproof-scene» from git "https://github.com/paulbutcher/inkproof-scene" @ "v0.30.0"
require «inkproof-scale» from git "https://github.com/paulbutcher/inkproof-scale" @ "v0.11.0"
require «inkproof-axis» from git "https://github.com/paulbutcher/inkproof-axis" @ "v0.16.0"
require «inkproof-core» from git "https://github.com/paulbutcher/inkproof-core" @ "v0.15.0"
require «inkproof-float» from git "https://github.com/paulbutcher/inkproof-float" @ "v0.8.0"
require «inkproof-gpu» from git "https://github.com/paulbutcher/inkproof-gpu" @ "v0.24.1"
require «lean-random-sampling» from git "https://github.com/paulbutcher/lean-random-sampling" @ "v0.1.0"

@[default_target]
lean_lib InkproofDemos where
  roots := #[`Inkproof.Demos, `Inkproof.Demos.Proofs]

/-- Writes the data files that pages fetch, into `app/web/public/data/`. -/
lean_exe «demo-data» where
  root := `Inkproof.Demos.DataFiles

@[test_driver]
script tests do
  let child ← IO.Process.spawn
    { cmd := "lake", args := #["test"], cwd := __dir__ / "test" }
  child.wait

/-- The code the pages share. It imports Lasm, so only Lasm's build compiles it. -/
lean_lib InkproofDemosBrowser where
  roots := #[`Inkproof.Demos.Browser, `Inkproof.Demos.ZoomPage, `Inkproof.Demos.FetchPage,
    `Inkproof.Demos.Pages.Annotations,
    `Inkproof.Demos.Pages.AreaFill,
    `Inkproof.Demos.Pages.ArcsinhScales,
    `Inkproof.Demos.Pages.CustomScales,
    `Inkproof.Demos.Pages.AxisControl,
    `Inkproof.Demos.Pages.BoxWhisker,
    `Inkproof.Demos.Pages.CalendarTime,
    `Inkproof.Demos.Pages.Candlestick,
    `Inkproof.Demos.Pages.CursorBind,
    `Inkproof.Demos.Pages.Gradients,
    `Inkproof.Demos.Pages.GroupedBars,
    `Inkproof.Demos.Pages.HeatmapCells,
    `Inkproof.Demos.Pages.HighLowBands,
    `Inkproof.Demos.Pages.LatencyHeatmap,
    `Inkproof.Demos.Pages.LinePaths,
    `Inkproof.Demos.Pages.LogScales,
    `Inkproof.Demos.Pages.LogScales2,
    `Inkproof.Demos.Pages.Million,
    `Inkproof.Demos.Pages.MissingData,
    `Inkproof.Demos.Pages.MultiBars,
    `Inkproof.Demos.Pages.PathGapClip,
    `Inkproof.Demos.Pages.Points,
    `Inkproof.Demos.Pages.Scatter,
    `Inkproof.Demos.Pages.ServerEvents,
    `Inkproof.Demos.Pages.SparklinesBars,
    `Inkproof.Demos.Pages.Sparklines,
    `Inkproof.Demos.Pages.Stacked,
    `Inkproof.Demos.Pages.SyncCursor,
    `Inkproof.Demos.Pages.TimelineDiscrete,
    `Inkproof.Demos.Pages.TooltipLegend,
    `Inkproof.Demos.Pages.ZoomFetch,
    `Inkproof.Demos.Pages.ZoomRanger,
    `Inkproof.Demos.Pages.ZoomResetRange,
    `Inkproof.Demos.Pages.ZoomTouch,
    `Inkproof.Demos.Pages.ZoomVariations,
    `Inkproof.Demos.Pages.ZoomWheel]
