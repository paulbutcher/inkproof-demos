/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Data
import Inkproof.Demos.Zoom

namespace Inkproof.Demos.Annotations

open Inkproof.Scene Inkproof.Demos

/-- Thirty integers in `-10..10` over `1..30` in two filled series, with an earthquake at 4 and a tornado from 9.3 to 18.5, as uPlot's page has. The notes lie where their data positions put them, so they follow the chart as it zooms and pans. -/
def chart : Zoom.Chart :=
  let xs : Array Rat := (Array.range 30).map fun i => ((i + 1 : Nat) : Rat)
  let line (seed : Nat) (color fill : Color) : Zoom.Line :=
    ⟨xs, (Data.ints seed 30 0 20).map fun (v : Nat) => ((v : Int) - 10 : Int), color, some fill⟩
  ⟨1920, 600, [line 21 ⟨255, 0, 0, 255⟩ ⟨255, 0, 0, 26⟩, line 22 ⟨0, 0, 255, 255⟩ ⟨0, 0, 255, 26⟩], none,
    [⟨4, 4, "eqk_01", ⟨76, 175, 80, 255⟩, ⟨76, 175, 80, 51⟩, false⟩, ⟨9.3, 18.5, "tor_20", ⟨255, 193, 7, 255⟩, ⟨255, 193, 7, 51⟩, true⟩]⟩

end Inkproof.Demos.Annotations
