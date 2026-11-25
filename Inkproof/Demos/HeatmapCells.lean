/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Scene
import Inkproof.Scale
import Inkproof.Demos.Lines
import Inkproof.Demos.Frame
import Inkproof.Demos.Latency

namespace Inkproof.Demos.HeatmapCells

open Inkproof.Scene Inkproof.Scale Inkproof.Demos Inkproof.Demos.Lines

/-- The number of latency samples, one every tenth of a second. -/
def samples : Nat := 45000

/-- The Unix time of the first sample, in tenths of a second. -/
def start : Nat := 16427113200

/-- Samples are counted in cells 15 seconds wide, that is 150 tenths, and 2 ms tall. -/
def xBin : Nat := 150
def yBin : Nat := 2

/-- The latency of each sample, in milliseconds. -/
def latencies : Array Float := Latency.draws 5 samples 30 50 3

/-- The index of the 15 second cell of sample `i`. -/
def xIndex (i : Nat) : Nat := (start + i) / xBin

theorem xIndex_eq (i : Nat) : xIndex i = (start + i) / xBin := rfl

/-- The index of the 2 ms cell of a latency; cells below zero have negative indices. -/
def yIndex (v : Float) : Int := (v / yBin.toFloat).floor.toInt64.toInt

theorem yIndex_eq (v : Float) : yIndex v = (v / yBin.toFloat).floor.toInt64.toInt := rfl

theorem xIndex_mono {i j : Nat} (h : i ≤ j) : xIndex i ≤ xIndex j := by
  unfold xIndex
  exact Nat.div_le_div_right (by omega)

/-- The lowest and highest cell indices that hold a latency. -/
def yRange : Int × Int :=
  let is := latencies.map yIndex
  (is.foldl min (is.getD 0 0), is.foldl max (is.getD 0 0))

theorem yRange_eq : yRange =
    ((latencies.map yIndex).foldl min ((latencies.map yIndex).getD 0 0),
     (latencies.map yIndex).foldl max ((latencies.map yIndex).getD 0 0)) := rfl

def xFirst : Nat := xIndex 0
def xCount : Nat := xIndex (samples - 1) - xFirst + 1
def yCount : Nat := (yRange.2 - yRange.1 + 1).toNat

/-- How many samples fall in each cell, column by column, lowest cell first. -/
def counts : Array Nat :=
  let init := Array.replicate (xCount * yCount) 0
  (latencies.zipIdx.foldl (fun (acc : Array Nat) (v, i) =>
    acc.modify ((xIndex i - xFirst) * yCount + (yIndex v - yRange.1).toNat) (· + 1)) init)

theorem counts_eq : counts =
    latencies.zipIdx.foldl (fun (acc : Array Nat) (v, i) =>
      acc.modify ((xIndex i - xFirst) * yCount + (yIndex v - yRange.1).toNat) (· + 1))
      (Array.replicate (xCount * yCount) 0) := rfl

/-- The grey of the least busy cell to the dark purple of the busiest: the palette runs from pale to saturated. -/
def palette : Array Color := #[
  ⟨255, 240, 222, 255⟩, ⟨255, 224, 188, 255⟩, ⟨255, 209, 153, 255⟩, ⟨254, 193, 115, 255⟩, ⟨252, 176, 69, 255⟩,
  ⟨255, 154, 61, 255⟩, ⟨255, 131, 53, 255⟩, ⟨255, 106, 45, 255⟩, ⟨255, 76, 37, 255⟩, ⟨253, 29, 29, 255⟩,
  ⟨228, 53, 80, 255⟩, ⟨202, 63, 111, 255⟩, ⟨178, 67, 136, 255⟩, ⟨154, 65, 159, 255⟩, ⟨131, 58, 180, 255⟩]

/-- The index in `palette` of a cell holding `count` samples, between those of the least and the most busy cell. -/
def paletteIndex (least most count : Nat) : Nat :=
  if most ≤ least then 0 else min (palette.size - 1) (palette.size * (count - least) / (most - least))

theorem paletteIndex_eq (least most count : Nat) : paletteIndex least most count =
    if most ≤ least then 0 else min (palette.size - 1) (palette.size * (count - least) / (most - least)) := rfl

theorem paletteIndex_lt (least most count : Nat) : paletteIndex least most count < palette.size := by
  unfold paletteIndex
  split
  · decide
  · exact Nat.lt_of_le_of_lt (Nat.min_le_left _ _) (by decide)

/-- The cells that hold a sample: each centred on its start, 15 seconds wide and 2 ms tall, valued by its count. -/
def cells : Array (Cell Rat Rat Nat) :=
  counts.zipIdx.filterMap fun (n, i) =>
    if n == 0 then none else
      let x : Rat := (((xFirst + i / yCount : Nat) : Rat)) * 15
      let y : Rat := (((yRange.1 + (i % yCount : Nat)) * yBin : Int) : Rat)
      some ⟨x - 15 / 2, x + 15 / 2, y - 1, y + 1, some n⟩

theorem cells_eq : cells =
    counts.zipIdx.filterMap fun (n, i) =>
      if n == 0 then none else
        let x : Rat := (((xFirst + i / yCount : Nat) : Rat)) * 15
        let y : Rat := (((yRange.1 + (i % yCount : Nat)) * yBin : Int) : Rat)
        some ⟨x - 15 / 2, x + 15 / 2, y - 1, y + 1, some n⟩ := rfl

/-- The chart's frame: the range of cell starts in seconds, and the range of latencies padded. -/
def chart : Lines.Chart :=
  { name := "heatmap-cells", width := 1800, height := 600,
    xs := ((xFirst * 15 : Nat), ((xFirst + xCount - 1) * 15 : Nat)), time := true,
    left := { range := autoRange (1 / 10) ((yRange.1 * yBin : Int) : Rat) ((yRange.2 * yBin : Int) : Rat) }, layers := [] }

/-- The axes, then the cells coloured by how many samples each holds. -/
def display (measure : String → Float × Float) (theme : Option Theme := none) : DisplayList :=
  let most := counts.foldl max 0
  let least := (counts.filter (· > 0)).foldl min most
  { chart with theme }.display measure ++
    DisplayList.clip (plot chart.frame) (compileHeatmap 1 (fun n => palette.getD (paletteIndex least most n) ⟨0, 0, 0, 255⟩) ⟨chart.xScale.map, (chart.yScale chart.left).map⟩ cells)

theorem display_eq (measure : String → Float × Float) (theme : Option Theme) : display measure theme =
    let most := counts.foldl max 0
    let least := (counts.filter (· > 0)).foldl min most
    { chart with theme }.display measure ++
      DisplayList.clip (plot chart.frame) (compileHeatmap 1 (fun n => palette.getD (paletteIndex least most n) ⟨0, 0, 0, 255⟩) ⟨chart.xScale.map, (chart.yScale chart.left).map⟩ cells) := rfl

end Inkproof.Demos.HeatmapCells
