/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Scale
import Inkproof.Demos.Axes
import Inkproof.Demos.Data
import Inkproof.Demos.Frame

namespace Inkproof.Demos.Stacked

open Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Demos

def xs : List Nat := List.range 30 |>.map (· + 1)

/-- The five series of uPlot's first stacked chart over `1..30`, bottom to top. -/
def levels : List (List Rat) :=
  [xs.zipIdx.map fun (_, i) => if i < 15 then ((20 + i : Nat) : Rat) else if i == 15 then 15 else if i == 16 then 14
      else if i == 24 then 20 else if i == 28 then 15 else if i == 29 then 0 else 30,
   xs.zipIdx.map fun (_, i) => if i == 24 then 20 else 10,
   xs.map fun _ => 10, xs.map fun _ => 5, xs.map fun _ => 5]

private def mkSeries (ys : List (Option Rat)) (xs : List Nat) : Series Rat Rat :=
  Series.ofUnsorted (xs.zip ys |>.toArray.map fun (x, y) => ((x : Rat), y))

def areaSeries : Array (Series Rat Rat) := levels.toArray.map fun ys => mkSeries (ys.map some) xs

/-- The first bar series of uPlot's bar chart, which the others are built from. -/
def base : List Rat :=
  [109, 117, 122, 104, 105, 117, 119, 121, 117, 121, 122, 129, 119, 113, 113, 121, 108, 108, 100, 103, 113, 110, 107, 105, 99, 93,
   87, 83, 91, 85, 81, 69, 76, 61, 63, 74, 76, 68, 55, 61, 48, 39, 54, 44, 37, 30, 22, 33, 29, 21, 22, 43, 47, 33, 47, 28, 29, 31,
   32, 35, 37, 25, -5, -14, -7, -14, -7, -18, -18, -18, -16, -41, -22, -30, -27, -30, -47, -49, -47, -42, -55, -34, -27, -22, -23,
   -34, -23, -32, -36, -47, -33, -32, -18, -23, -21, -33, -39, -21, -18, -27, -5]

private def barXs : List Nat := List.range base.length

/-- Each bar series is the one before it, raised by 100 and a random amount, as in uPlot's page, the random amounts drawn from `seed`; the first has a gap of four bars. -/
private def barLevels (seed : Nat) : List (List (Option Rat)) :=
  let first := base.map some
  let next (prev : List (Option Rat)) (seed : Nat) : List (Option Rat) :=
    (prev.zip (Data.ints seed prev.length 0 100).toList).map fun (v, r) => v.map fun v => 100 + v + (r : Rat)
  let second := next (base.map some) (3 * seed)
  let third := next second (3 * seed + 1)
  let fourth := next third (3 * seed + 2)
  [first.zipIdx.map (fun (v, i) => if 22 ≤ i && i < 26 then none else v), second, third, fourth]

def barSeries (seed : Nat) : Array (Series Rat Rat) := (barLevels seed).toArray.map (mkSeries · barXs)

theorem barSeries_eq (seed : Nat) : barSeries seed = (barLevels seed).toArray.map (mkSeries · barXs) := rfl

/-- The names uPlot gives the four bar series. -/
def barNames : List String := (List.range 4).map fun i => s!"bars {i + 1}"

theorem barNames_eq : barNames = ["bars 1", "bars 2", "bars 3", "bars 4"] := by
  decide

theorem barNames_length : barNames.length = (barSeries 0).size := by
  simp [barNames, barSeries, barLevels]

def areaFrame : Frame := Frame.sized 800 400 (1, 30) (0, 70)

def barFrame : Frame := Frame.sized 800 400 (-1, 101) (-100, 1200)

private def fills : List Color :=
  [⟨165, 55, 253, 102⟩, ⟨255, 165, 0, 102⟩, ⟨0, 0, 255, 77⟩, ⟨0, 255, 0, 77⟩, ⟨255, 0, 0, 77⟩]

private def paint (k : Nat) : Paint := ⟨k, fills.getD k ⟨0, 0, 0, 255⟩⟩

/-- The series with those `off` marks at zero, so the others stack as if they were absent. -/
def hide (off : Array Bool) (ss : Array (Series Rat Rat)) : Array (Series Rat Rat) :=
  ss.mapIdx fun i s => if off.getD i false then Series.ofUnsorted (s.points.map fun (x, _) => (x, some 0)) else s

theorem hide_eq (off : Array Bool) (ss : Array (Series Rat Rat)) : hide off ss =
    ss.mapIdx fun i s => if off.getD i false then Series.ofUnsorted (s.points.map fun (x, _) => (x, some 0)) else s := rfl

def areaChart (off : Array Bool) (f : Frame) (measure : String → Float × Float) : DisplayList :=
  axisDisplay f measure ++ compileStackedAreas paint (projection f) (hide off areaSeries)

theorem areaChart_eq (off : Array Bool) (f : Frame) (measure : String → Float × Float) :
    areaChart off f measure = axisDisplay f measure ++ compileStackedAreas paint (projection f) (hide off areaSeries) := rfl

/-- The width in pixels of a bar: 60% of the distance between adjacent x values, which are one apart. -/
def barWidth (f : Frame) : Rat := ((projection f).x 1 - (projection f).x 0) * 3 / 5

theorem barWidth_eq (f : Frame) : barWidth f = ((projection f).x 1 - (projection f).x 0) * 3 / 5 := rfl

def barChart (off : Array Bool) (seed : Nat) (f : Frame) (measure : String → Float × Float) : DisplayList :=
  axisDisplay f measure ++ compileStackedBars paint (barWidth f) (projection f) (hide off (barSeries seed))

theorem barChart_eq (off : Array Bool) (seed : Nat) (f : Frame) (measure : String → Float × Float) :
    barChart off seed f measure = axisDisplay f measure ++ compileStackedBars paint (barWidth f) (projection f) (hide off (barSeries seed)) := rfl

/-- The colour of series `k` without its transparency, as the legend shows it. -/
def colour (k : Nat) : Color := { fills.getD k ⟨0, 0, 0, 255⟩ with a := 255 }

theorem colour_eq (k : Nat) : colour k = { fills.getD k ⟨0, 0, 0, 255⟩ with a := 255 } := rfl

end Inkproof.Demos.Stacked
