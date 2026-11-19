/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
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
    [{ data := lowSeries, color := ⟨0, 128, 0, 255⟩ },
     { data := highSeries, color := ⟨255, 0, 0, 255⟩ },
     { data := meanSeries, color := ⟨0, 0, 255, 255⟩, halfWidth := 1, dash := some ⟨10, 10⟩ }]
  { name := "temps", width := 1920, height := 600, xs := (days.getD 0 0, days.getD 364 0), time := true,
    left := autoYAxis layers "°F", layers,
    bands := [⟨1, 2, ⟨255, 0, 0, 26⟩⟩, ⟨0, 2, ⟨0, 255, 0, 26⟩⟩] }

def charts : List Chart := [temps]

end Inkproof.Demos.HighLowBands
