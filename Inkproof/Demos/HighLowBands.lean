/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Axes
import Inkproof.Demos.Lines
import Inkproof.Demos.HighLowSource

namespace Inkproof.Demos.HighLowBands

open Inkproof.Core Inkproof.Scene Inkproof.Demos.Lines Inkproof.Demos.HighLowSource

/-- Midnight UTC on each day of 2010, in Unix seconds. -/
def days : Array Rat := (Array.range 365).map fun i => (1262304000 + 86400 * i : Nat)

/-- The temperature midway between each day's low and high. -/
def means : Array Rat := ((scaled 10 lows).zip (scaled 10 highs)).map fun (a, b) => (a + b) / 2

/-- The day's low, high and mean, with the stretches that uPlot's page blanks: the mean's last day is present where the others' is not. -/
def lowSeries : Series Rat Rat := series days (withGaps ((List.range' 50 10) ++ (List.range' 100 10) ++ [364]) (scaled 10 lows))
def highSeries : Series Rat Rat := series days (withGaps ((List.range' 50 10) ++ (List.range' 200 10) ++ [364]) (scaled 10 highs))
def meanSeries : Series Rat Rat := series days ((withGaps (List.range' 300 10) means).setIfInBounds 364 (some 38))

/-- Lows and highs as thin lines, the mean dashed, the space between the mean and each of the others filled. -/
def temps : Chart :=
  let layers : List Layer :=
    [{ data := lowSeries, label := "Low", color := ⟨0, 128, 0, 255⟩ },
     { data := highSeries, label := "High", color := ⟨255, 0, 0, 255⟩ },
     { data := meanSeries, label := "Avg", color := ⟨0, 0, 255, 255⟩, halfWidth := 1, dash := some ⟨10, 10⟩ }]
  { name := "temps", width := 1920, height := 600, xs := (days.getD 0 0, days.getD 364 0), time := true, timeStyle := some Axes.numericDates,
    left := autoYAxis layers "°F", layers,
    bands := [⟨1, 2, ⟨255, 0, 0, 26⟩⟩, ⟨0, 2, ⟨0, 255, 0, 26⟩⟩] }

/-- A line falling from 5 to -4 over a flat one at -5, with the space between them filled, drawn over integer x. -/
def inverted : Chart :=
  let xs : Array Rat := (Array.range 10).map fun (i : Nat) => (i : Rat)
  let line (ys : Array Rat) (label : String) (c : Color) : Layer :=
    { data := series xs (ys.map some), label, color := c }
  let layers : List Layer :=
    [line #[5, 4, 3, 2, 1, 0, -1, -2, -3, -4] "High" ⟨255, 0, 0, 255⟩,
     line #[-5, -5, -5, -5, -5, -5, -5, -5, -5, -5] "Low" ⟨0, 0, 255, 255⟩]
  { name := "inverted", width := 1920, height := 600, xs := (0, 9), time := false,
    left := autoYAxis layers, layers, bands := [⟨1, 0, ⟨255, 0, 0, 18⟩⟩] }

/-- Two lines that cross at every sample, with the space between them filled. -/
def crossing : Chart :=
  let xs : Array Rat := (Array.range 4).map fun (i : Nat) => (i : Rat)
  let line (ys : Array Rat) (label : String) (c : Color) : Layer :=
    { data := series xs (ys.map some), label, color := c }
  let layers : List Layer :=
    [line #[10, 0, 10, 0] "High" ⟨255, 0, 0, 255⟩,
     line #[0, 10, 0, 10] "Low" ⟨0, 0, 255, 255⟩]
  { name := "crossing", width := 1920, height := 600, xs := (0, 3), time := false,
    left := autoYAxis layers, layers, bands := [⟨1, 0, ⟨255, 0, 0, 18⟩⟩] }

/-- The values of uPlot's first differing series, falling from 109 to -5. -/
def differingBase : Array Int :=
  #[109, 117, 122, 104, 105, 117, 119, 121, 117, 121, 122, 129, 119, 113, 113, 121, 108, 108, 100, 103, 113, 110, 107, 105, 99, 93, 87, 83, 91, 85, 81, 69, 76, 61, 63, 74, 76, 68, 55, 61, 48, 39, 54, 44, 37, 30, 22, 33, 29, 21, 22, 43, 47, 33, 47, 28, 29, 31, 32, 35, 37, 25, -5, -14, -7, -14, -7, -18, -18, -18, -16, -41, -22, -30, -27, -30, -47, -49, -47, -42, -55, -34, -27, -22, -23, -34, -23, -32, -36, -47, -33, -32, -18, -23, -21, -33, -39, -21, -18, -27, -5]

/-- Four series over the same x, each 100 plus the one before it plus a spread of up to 100 (a fixed hash where uPlot's is random), joined straight, stepped before, as a spline and stepped after, and filled between neighbours. -/
def differing : Chart :=
  let xs : Array Rat := (Array.range 101).map fun (i : Nat) => (i : Rat)
  let next (salt : Nat) (prev : Array Int) : Array Int :=
    prev.mapIdx fun i v => 100 + v + (((i * 37 + salt * 61) % 101 : Nat) : Int)
  let second := next 1 differingBase
  let third := next 2 second
  let fourth := next 3 third
  let vals (a : Array Int) : Array (Option Rat) := a.map fun (v : Int) => some ((v : Rat))
  let linearVals := (List.range' 22 4).foldl (fun a i => a.setIfInBounds i none) (vals differingBase)
  let layers : List Layer :=
    [{ data := series xs linearVals, label := "linear", color := ⟨0, 128, 0, 255⟩, fill := some ⟨0, 255, 0, 26⟩ },
     { data := series xs (vals second), label := "stepBefore", color := ⟨255, 0, 255, 255⟩, fill := some ⟨255, 0, 255, 13⟩, join := .stepBefore },
     { data := series xs (vals third), label := "spline", color := ⟨0, 0, 255, 255⟩, fill := some ⟨0, 0, 255, 13⟩, join := .spline 16 },
     { data := series xs (vals fourth), label := "stepAfter", color := ⟨255, 0, 0, 255⟩, fill := some ⟨255, 0, 0, 13⟩, join := .stepAfter, dash := some ⟨5, 5⟩ }]
  { name := "differing", width := 1920, height := 600, xs := (0, 100), time := false,
    left := autoYAxis layers, layers, bands := [⟨2, 3, ⟨255, 0, 0, 26⟩⟩, ⟨1, 2, ⟨255, 0, 0, 26⟩⟩, ⟨0, 1, ⟨255, 0, 0, 26⟩⟩] }

def charts : List Chart := [temps, inverted, crossing, differing]

end Inkproof.Demos.HighLowBands
