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

/-- Each bar series is the one before it, raised by 100 and a random amount, as in uPlot's page but from fixed seeds; the first has a gap of four bars. -/
private def barLevels : List (List (Option Rat)) :=
  let first := base.map some
  let next (prev : List (Option Rat)) (seed : Nat) : List (Option Rat) :=
    (prev.zip (Data.ints seed prev.length 0 100).toList).map fun (v, r) => v.map fun v => 100 + v + (r : Rat)
  let second := next (base.map some) 1
  let third := next second 2
  let fourth := next third 3
  [first.zipIdx.map (fun (v, i) => if 22 ≤ i && i < 26 then none else v), second, third, fourth]

def barSeries : Array (Series Rat Rat) := barLevels.toArray.map (mkSeries · barXs)

def areaFrame : Frame := Frame.sized 800 400 (1, 30) (0, 70)

def barFrame : Frame := Frame.sized 800 400 (-1, 101) (-100, 1200)

private def fills : List Color :=
  [⟨165, 55, 253, 102⟩, ⟨255, 165, 0, 102⟩, ⟨0, 0, 255, 77⟩, ⟨0, 255, 0, 77⟩, ⟨255, 0, 0, 77⟩]

private def paint (k : Nat) : Paint := ⟨k, fills.getD k ⟨0, 0, 0, 255⟩⟩

def areaChart (f : Frame) (measure : String → Float × Float) : DisplayList :=
  axisDisplay f measure ++ compileStackedAreas paint (projection f) areaSeries

theorem areaChart_eq (f : Frame) (measure : String → Float × Float) :
    areaChart f measure = axisDisplay f measure ++ compileStackedAreas paint (projection f) areaSeries := rfl

def barChart (f : Frame) (measure : String → Float × Float) : DisplayList :=
  axisDisplay f measure ++ compileStackedBars paint (3 / 5) (projection f) barSeries

theorem barChart_eq (f : Frame) (measure : String → Float × Float) :
    barChart f measure = axisDisplay f measure ++ compileStackedBars paint (3 / 5) (projection f) barSeries := rfl

end Inkproof.Demos.Stacked
