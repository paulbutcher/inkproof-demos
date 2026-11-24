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

def charts : List Chart := [temps, inverted, crossing]

end Inkproof.Demos.HighLowBands
