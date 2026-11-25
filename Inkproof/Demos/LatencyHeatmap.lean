/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Scene
import Inkproof.Scale
import Inkproof.Demos.Lines
import Inkproof.Demos.Frame
import Inkproof.Demos.Latency
import Inkproof.Demos.Data

namespace Inkproof.Demos.LatencyHeatmap

open Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Demos Inkproof.Demos.Lines

/-- The Unix time of the first column, in seconds. -/
def start : Nat := 1642711320

/-- A hundred columns, one a second, of between 200 and 500 latencies each, in tenths of a millisecond, none below 5 ms. -/
def columns : Array (Array Nat) :=
  (List.range 100).toArray.map fun i =>
    let n := (Data.ints (3000 + i) 1 200 500)[0]?.getD 200
    ((Latency.draws (4000 + i) n 30 30 3).map fun v => max 50 (v * 10).floor.toUInt64.toNat).qsort (· < ·)

theorem columns_eq : columns =
    (List.range 100).toArray.map fun i =>
      let n := (Data.ints (3000 + i) 1 200 500)[0]?.getD 200
      ((Latency.draws (4000 + i) n 30 30 3).map fun v => max 50 (v * 10).floor.toUInt64.toNat).qsort (· < ·) := rfl

/-- The lowest and the highest latency in any column, in milliseconds, rounded outwards. -/
def yBounds : Nat × Nat :=
  let all := columns.flatten
  (all.foldl min (all.getD 0 0) / 10, (all.foldl max 0 + 9) / 10)

theorem yBounds_eq : yBounds =
    ((columns.flatten.foldl min (columns.flatten.getD 0 0)) / 10, ((columns.flatten.foldl max 0) + 9) / 10) := rfl

/-- The frame of both charts: seconds across, latencies up. -/
def chart : Lines.Chart :=
  { name := "latency-heatmap", width := 1800, height := 600,
    xs := ((start : Rat), ((start + columns.size - 1 : Nat) : Rat)), time := true,
    left := { range := autoRange (1 / 10) (yBounds.1 : Rat) (yBounds.2 : Rat) }, layers := [] }

theorem chart_eq : chart =
    { name := "latency-heatmap", width := 1800, height := 600,
      xs := ((start : Rat), ((start + columns.size - 1 : Nat) : Rat)), time := true,
      left := { range := autoRange (1 / 10) (yBounds.1 : Rat) (yBounds.2 : Rat) }, layers := [] } := rfl

/-- How many seconds and how many milliseconds one pixel spans. -/
def secondsPerPixel : Rat := (chart.xs.2 - chart.xs.1) / (chart.frame.right - chart.frame.left)
def millisPerPixel : Rat := (chart.left.range.2 - chart.left.range.1) / (chart.frame.bottom - chart.frame.top)

theorem secondsPerPixel_eq : secondsPerPixel = (chart.xs.2 - chart.xs.1) / (chart.frame.right - chart.frame.left) := rfl

theorem millisPerPixel_eq : millisPerPixel =
    (chart.left.range.2 - chart.left.range.1) / (chart.frame.bottom - chart.frame.top) := rfl

/-- The cell of a column's latency band `[lo, hi)` in milliseconds: ten pixels wide, from four pixels left of the column's second. -/
def cell {α : Type} (column : Nat) (lo hi : Rat) (value : α) : Cell Rat Rat α :=
  let t : Rat := ((start + column : Nat) : Rat)
  ⟨t - 4 * secondsPerPixel, t + 6 * secondsPerPixel, lo, hi, some value⟩

theorem cell_eq {α : Type} (column : Nat) (lo hi : Rat) (value : α) : cell column lo hi value =
    ⟨((start + column : Nat) : Rat) - 4 * secondsPerPixel, ((start + column : Nat) : Rat) + 6 * secondsPerPixel, lo, hi, some value⟩ := rfl

/-- One cell, a pixel tall, for every latency. -/
def sampleCells : Array (Cell Rat Rat Unit) :=
  columns.zipIdx.flatMap fun (col, i) =>
    col.map fun (v : Nat) => cell i ((v : Rat) / 10) ((v : Rat) / 10 + millisPerPixel) ()

theorem sampleCells_eq : sampleCells =
    columns.zipIdx.flatMap fun (col, i) => col.map fun (v : Nat) => cell i ((v : Rat) / 10) ((v : Rat) / 10 + millisPerPixel) () := rfl

/-- Latencies are counted in buckets this wide, in milliseconds. -/
def bucket : Nat := 5

/-- The buckets of a sorted column that hold latencies, from the lowest, each with its count. -/
def bucketCounts (col : Array Nat) : Array (Nat × Nat) :=
  col.foldl (fun (acc : Array (Nat × Nat)) v =>
    let b := v / (10 * bucket)
    match acc.back? with
    | some (b', n) => if b' == b then acc.pop.push (b, n + 1) else acc.push (b, 1)
    | none => #[(b, 1)]) #[]

theorem bucketCounts_eq (col : Array Nat) : bucketCounts col =
    col.foldl (fun (acc : Array (Nat × Nat)) v =>
      let b := v / (10 * bucket)
      match acc.back? with
      | some (b', n) => if b' == b then acc.pop.push (b, n + 1) else acc.push (b, 1)
      | none => #[(b, 1)]) #[] := rfl

/-- The cells of the buckets that hold latencies, valued by their count and the largest count in their column. -/
def bucketCells : Array (Cell Rat Rat (Nat × Nat)) :=
  columns.zipIdx.flatMap fun (col, i) =>
    let counts := bucketCounts col
    let most := counts.foldl (fun m (_, n) => max m n) 1
    counts.map fun (b, n) => cell i ((b * bucket : Nat) : Rat) (((b + 1) * bucket : Nat) : Rat) (n, most)

theorem bucketCells_eq : bucketCells =
    columns.zipIdx.flatMap fun (col, i) =>
      let counts := bucketCounts col
      let most := counts.foldl (fun m (_, n) => max m n) 1
      counts.map fun (b, n) => cell i ((b * bucket : Nat) : Rat) (((b + 1) * bucket : Nat) : Rat) (n, most) := rfl

/-- The second of each column. -/
def seconds : Array Rat := (Array.range columns.size).map fun i => ((start + i : Nat) : Rat)

theorem seconds_eq : seconds = (Array.range columns.size).map fun i => ((start + i : Nat) : Rat) := rfl

/-- What the legend reads of each column of latencies: how many there are, the lowest and the highest in milliseconds. -/
def sampleRows : Array (Array Rat) :=
  columns.map fun col => #[(col.size : Rat), ((col.getD 0 0 : Nat) : Rat) / 10, ((col.back?.getD 0 : Nat) : Rat) / 10]

theorem sampleRows_eq : sampleRows =
    columns.map fun col => #[(col.size : Rat), ((col.getD 0 0 : Nat) : Rat) / 10, ((col.back?.getD 0 : Nat) : Rat) / 10] := rfl

/-- What the legend reads of each column of buckets: how many hold latencies, the lower edge of the fullest in milliseconds, and its count. -/
def bucketRows : Array (Array Rat) :=
  columns.map fun col =>
    let counts := bucketCounts col
    let top := counts.foldl (fun (m : Nat × Nat) c => if c.2 > m.2 then c else m) (0, 0)
    #[(counts.size : Rat), ((top.1 * bucket : Nat) : Rat), (top.2 : Rat)]

theorem bucketRows_eq : bucketRows =
    columns.map fun col =>
      let counts := bucketCounts col
      let top := counts.foldl (fun (m : Nat × Nat) c => if c.2 > m.2 then c else m) (0, 0)
      #[(counts.size : Rat), ((top.1 * bucket : Nat) : Rat), (top.2 : Rat)] := rfl

/-- Translucent red, so that overlapping latencies darken. -/
def sampleColor : Color := ⟨255, 0, 0, 102⟩

/-- Hue runs from cyan, for a column's rarest latencies, to red, for its most common. -/
def countColor (c : Nat × Nat) : Color :=
  Color.ofHsl (180 + 180 * (c.1 : Rat) / c.2) (4 / 5) (1 / 2)

theorem countColor_eq (c : Nat × Nat) : countColor c = Color.ofHsl (180 + 180 * (c.1 : Rat) / c.2) (4 / 5) (1 / 2) := rfl

/-- The axes, then every latency as a small translucent rectangle. -/
def samplesDisplay (measure : String → Float × Float) (theme : Option Theme := none) : DisplayList :=
  { chart with theme }.display measure ++
    DisplayList.clip (plot chart.frame) (compileHeatmap 1 (fun _ => sampleColor) ⟨chart.xScale.map, (chart.yScale chart.left).map⟩ sampleCells)

theorem samplesDisplay_eq (measure : String → Float × Float) (theme : Option Theme) : samplesDisplay measure theme =
    { chart with theme }.display measure ++
      DisplayList.clip (plot chart.frame) (compileHeatmap 1 (fun _ => sampleColor) ⟨chart.xScale.map, (chart.yScale chart.left).map⟩ sampleCells) := rfl

/-- The axes, then a cell for each bucket of each column, coloured by its count. -/
def bucketsDisplay (measure : String → Float × Float) (theme : Option Theme := none) : DisplayList :=
  { chart with theme }.display measure ++
    DisplayList.clip (plot chart.frame) (compileHeatmap 1 countColor ⟨chart.xScale.map, (chart.yScale chart.left).map⟩ bucketCells)

theorem bucketsDisplay_eq (measure : String → Float × Float) (theme : Option Theme) : bucketsDisplay measure theme =
    { chart with theme }.display measure ++
      DisplayList.clip (plot chart.frame) (compileHeatmap 1 countColor ⟨chart.xScale.map, (chart.yScale chart.left).map⟩ bucketCells) := rfl

end Inkproof.Demos.LatencyHeatmap
