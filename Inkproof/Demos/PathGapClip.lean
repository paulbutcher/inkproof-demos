/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Lines
import Inkproof.Demos.PathGapClipSource

namespace Inkproof.Demos.PathGapClip

open Inkproof.Core Inkproof.Scene Inkproof.Demos.Lines

def times : Array Rat := scaled 1 PathGapClipSource.times

/-- Samples 35 to 49 are missing from every series. -/
def hole : List Nat := List.range' 35 15

def lowSeries : Series Rat Rat := series times (withGaps hole (scaled 100000 PathGapClipSource.lows))
def highSeries : Series Rat Rat := series times (withGaps hole (scaled 100000 PathGapClipSource.highs))

/-- Low and high with the space between them filled, over an x range wider than the data by eight hours each side. -/
def zoomedOut : Chart :=
  let green : Color := ⟨0, 128, 0, 255⟩
  let layers : List Layer := [{ data := lowSeries, color := green }, { data := highSeries, color := green }]
  { name := "zoomed-out", width := 756, height := 475, xs := (1577454300 - 3600 * 8, 1577999700 + 3600 * 8), time := true,
    left := autoYAxis layers, layers, bands := [⟨1, 0, ⟨0, 255, 0, 51⟩⟩] }

/-- Low and high with a value missing from both, so the band between them has a gap, and a mean without one. -/
def bandGap : Chart :=
  let xs : Array Rat := (#[1572679693747, 1572679694747, 1572679695747, 1572679696747, 1572679697747, 1572679698746, 1572679699746] : Array Nat).map fun (t : Nat) => (t : Rat) / 1000
  let line (ys : Array (Option Rat)) (c : Color) : Layer := { data := series xs ys, color := c }
  let layers : List Layer :=
    [line #[some 9.5, some 10.5, some 11.5, none, some 13.5, some 14.5, some 15.5] ⟨255, 0, 0, 255⟩,
     line #[some 10.5, some 11.5, some 12.5, none, some 14.5, some 15.5, some 16.5] ⟨255, 0, 0, 255⟩,
     line ((#[10, 11, 12, 13, 14, 15, 16] : Array Rat).map some) ⟨0, 128, 0, 255⟩]
  { name := "band-gap", width := 800, height := 400, xs := (xs.getD 0 0, xs.getD 6 0), time := true,
    left := autoYAxis layers, layers, bands := [⟨1, 0, ⟨0, 255, 0, 51⟩⟩] }

/-- uPlot's gap pattern: runs of one and two, with missing samples between them. -/
def stepPattern : Array (Option Rat) :=
  #[none, none, none, some 1, some 1, some 1, some 1, some 1, none, none, some 2, some 2, none, some 1, none, none, none, some 1, some 1, some 1, some 1, some 2, some 2, some 2, none, none]

/-- A stepped series with a fill, a linear series 0.1 above it and a spline 0.2 above it, all with the gaps of `stepPattern`. -/
def stepped (name : String) (stepLabel : String) (stepColor linearColor : Color) (join : Join) : Chart :=
  let xs : Array Rat := (Array.range stepPattern.size).map fun (i : Nat) => (i : Rat)
  let above (d : Rat) : Array (Option Rat) := stepPattern.map (·.map (· + d))
  let orange : Color := ⟨255, 165, 0, 255⟩
  let layers : List Layer :=
    [{ data := series xs stepPattern, label := stepLabel, color := stepColor, fill := some { stepColor with a := 77 }, halfWidth := 1, join },
     { data := series xs (above (1 / 10)), label := "linear", color := linearColor, halfWidth := 1 },
     { data := series xs (above (1 / 5)), label := "spline", color := orange, halfWidth := 1, join := .spline 16 }]
  { name, width := 800, height := 400, xs := (0, (stepPattern.size - 1 : Nat)), time := false, left := autoYAxis layers, layers }

theorem stepped_name (name stepLabel : String) (c d : Color) (join : Join) : (stepped name stepLabel c d join).name = name := rfl

theorem stepped_layers (name stepLabel : String) (c d : Color) (join : Join) :
    ((stepped name stepLabel c d join).layers.map (·.join)) = [join, .straight, .spline 16] := rfl

def steppedAfter := stepped "stepped-after" "step after" ⟨0, 0, 255, 255⟩ ⟨255, 0, 0, 255⟩ .stepAfter
def steppedBefore := stepped "stepped-before" "step before" ⟨255, 0, 0, 255⟩ ⟨0, 0, 255, 255⟩ .stepBefore

def charts : List Chart := [zoomedOut, bandGap, steppedAfter, steppedBefore]

end Inkproof.Demos.PathGapClip
