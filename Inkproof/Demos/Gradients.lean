/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Scene
import Inkproof.Demos.Lines

namespace Inkproof.Demos.Gradients

open Inkproof.Scene Inkproof.Demos.Lines

private def line (xs ys : Array Rat) (color : Color) : Layer :=
  { data := series xs (ys.map some), color, halfWidth := 2, rings := some (5 / 2) }

private def chart (name : String) (xs : Array Rat) (layers : List Layer) : Chart :=
  { name, width := 800, height := 400, xs := (xs.getD 0 0, xs.getD (xs.size - 1) 0), time := false, spaced := true, left := autoYAxis layers, layers }

private def red : Color := ⟨255, 0, 0, 255⟩
private def orange : Color := ⟨255, 165, 0, 255⟩
private def blue : Color := ⟨0, 0, 255, 255⟩
private def green : Color := ⟨0, 128, 0, 255⟩

private def trendX : Array Rat := #[20, 30, 40, 50, 60]

/-- A stroke whose colour changes at once along x. -/
def horizontal : Chart :=
  chart "horizontal" trendX
    [{ line trendX #[20, 10, 25, 50, 30] red with label := "Trends", strokeGradient := some ⟨.x, (0, red), [(30, orange), (50, blue)], true⟩ }]

/-- A stroke that is blue below zero and red above it, with no blend between. -/
def overUnder : Chart :=
  chart "over-under" trendX
    [{ line trendX #[-5, 10, -2, -30, 30] blue with label := "Over/Under", strokeGradient := some ⟨.y, (-100, blue), [(0, red)], true⟩ }]

/-- A stroke with three colour bands in y, each one colour. -/
def banded : Chart :=
  chart "banded" trendX
    [{ line trendX #[-5, 10, -2, -30, 30] blue with label := "Over/Under", strokeGradient := some ⟨.y, (-100, blue), [(-10, red), (0, green)], true⟩ }]

private def tankX : Array Rat := #[0, 1, 2, 3, 4, 5]
private def tank1 : Array Rat := #[10, 20, 30, 40, 50, 60]
private def tank2 : Array Rat := #[1, 3, 5, 8, 15, 20]

/-- Two fills whose colours follow the value, one red when high and one red when low. -/
def fills : Chart :=
  chart "fills" tankX
    [{ line tankX tank1 ⟨0, 255, 0, 255⟩ with label := "Tank 1 (red = high pressure)", fillGradient := some ⟨.y, (30, green), [(50, orange), (60, red)], false⟩ },
     { line tankX tank2 ⟨255, 0, 255, 255⟩ with label := "Tank 2 (red = low pressure)", fillGradient := some ⟨.y, (0, red), [(10, orange), (20, green)], false⟩ }]

/-- A fill whose stops are the lowest, middle and highest value of the data. -/
def relative : Chart :=
  let lo := tank1.foldl min (tank1.getD 0 0)
  let hi := tank1.foldl max (tank1.getD 0 0)
  chart "relative" tankX
    [{ line tankX tank1 ⟨0, 255, 0, 255⟩ with label := "Tank 1", fillGradient := some ⟨.y, (lo, green), [((lo + hi) / 2, orange), (hi, red)], false⟩ }]

def charts : List Chart := [horizontal, overUnder, banded, fills, relative]

end Inkproof.Demos.Gradients
