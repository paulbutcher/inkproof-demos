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

/-- One series with a missing value, drawn with the given join. -/
def joined (name : String) (join : Join) : Chart :=
  let xs : Array Rat := (#[0, 1, 2, 3, 4, 5, 6, 7] : Array Nat).map fun (t : Nat) => (t : Rat)
  let ys : Array (Option Rat) := #[some 3, some 7, some 4, none, some 8, some 2, some 6, some 5]
  let layers : List Layer := [{ data := series xs ys, color := ⟨0, 0, 255, 255⟩, join }]
  { name, width := 400, height := 250, xs := (0, 7), time := false, left := autoYAxis layers, layers }

theorem joined_eq (name : String) (join : Join) : joined name join =
    let xs : Array Rat := (#[0, 1, 2, 3, 4, 5, 6, 7] : Array Nat).map fun (t : Nat) => (t : Rat)
    let ys : Array (Option Rat) := #[some 3, some 7, some 4, none, some 8, some 2, some 6, some 5]
    let layers : List Layer := [{ data := series xs ys, color := ⟨0, 0, 255, 255⟩, join }]
    { name, width := 400, height := 250, xs := (0, 7), time := false, left := autoYAxis layers, layers } := rfl

def steppedBefore := joined "stepped-before" .stepBefore
def steppedAfter := joined "stepped-after" .stepAfter
def spline := joined "spline" (.spline 16)

def charts : List Chart := [zoomedOut, bandGap, steppedBefore, steppedAfter, spline]

end Inkproof.Demos.PathGapClip
