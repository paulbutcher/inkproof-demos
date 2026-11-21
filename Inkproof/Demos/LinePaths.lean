/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Scene
import Inkproof.Demos.Lines
import Inkproof.Demos.Stacked

namespace Inkproof.Demos.LinePaths

open Inkproof.Scene Inkproof.Demos.Lines

/-- The bar chart's first series with a gap of four points, as uPlot draws under each interpolation. -/
def values : Array (Option Rat) :=
  (Stacked.base.toArray.mapIdx fun i v => if 22 ≤ i && i < 26 then none else some v)

theorem values_eq : values = Stacked.base.toArray.mapIdx fun i v => if 22 ≤ i && i < 26 then none else some v := rfl

def xs : Array Rat := (Array.range Stacked.base.length).map fun (i : Nat) => (i : Rat)

/-- The same data drawn with `join`. -/
def chart (name : String) (join : Join) (color : Color) : Chart :=
  let layers : List Layer := [{ data := series xs values, color, join }]
  { name, width := 800, height := 300, xs := (0, 100), time := false, left := autoYAxis layers, layers }

theorem chart_eq (name : String) (join : Join) (color : Color) : chart name join color =
    let layers : List Layer := [{ data := series xs values, color, join }]
    { name, width := 800, height := 300, xs := (0, 100), time := false, left := autoYAxis layers, layers } := rfl

def charts : List Chart :=
  [chart "linear" .straight ⟨126, 178, 109, 255⟩, chart "spline" (.spline 16) ⟨31, 120, 193, 255⟩,
   chart "step-after" .stepAfter ⟨110, 208, 224, 255⟩, chart "step-before" .stepBefore ⟨239, 132, 60, 255⟩]

end Inkproof.Demos.LinePaths
