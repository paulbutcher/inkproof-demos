/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Data
import Inkproof.Demos.Pane

namespace Inkproof.Demos.Boxes

open Inkproof.Scene Inkproof.Demos Inkproof.Demos.Pane

/-- The five numbers of a box and whisker plot of one library's runs, and the runs outside the whiskers. -/
structure Box where
  name : String
  median : Rat
  q1 : Rat
  q3 : Rat
  min : Rat
  max : Rat
  outliers : Array Rat

/-- The value a fraction `p` of the way through the sorted `xs`, between neighbours linearly. -/
def quantile (xs : Array Rat) (p : Rat) : Rat :=
  let pos := p * ((xs.size : Rat) - 1)
  let i := pos.floor.toNat
  xs.getD i 0 + (pos - i) * (xs.getD (i + 1) (xs.getD i 0) - xs.getD i 0)

theorem quantile_eq (xs : Array Rat) (p : Rat) : quantile xs p =
    let pos := p * ((xs.size : Rat) - 1)
    let i := pos.floor.toNat
    xs.getD i 0 + (pos - i) * (xs.getD (i + 1) (xs.getD i 0) - xs.getD i 0) := rfl

/-- The box of `runs`: the whiskers reach the furthest runs within 1.5 interquartile ranges of the quartiles, and the rest are outliers. -/
def Box.ofRuns (name : String) (runs : Array Rat) : Box :=
  let sorted := runs.qsort (· < ·)
  let (q1, q3) := (quantile sorted (1 / 4), quantile sorted (3 / 4))
  let pad := 3 * (q3 - q1) / 2
  let inside := sorted.filter fun v => q1 - pad ≤ v && v ≤ q3 + pad
  { name, median := quantile sorted (1 / 2), q1, q3, min := inside.getD 0 q1, max := inside.getD (inside.size - 1) q3,
    outliers := sorted.filter fun v => v < q1 - pad || q3 + pad < v }

theorem Box.ofRuns_eq (name : String) (runs : Array Rat) : Box.ofRuns name runs =
    let sorted := runs.qsort (· < ·)
    let (q1, q3) := (quantile sorted (1 / 4), quantile sorted (3 / 4))
    let pad := 3 * (q3 - q1) / 2
    let inside := sorted.filter fun v => q1 - pad ≤ v && v ≤ q3 + pad
    { name, median := quantile sorted (1 / 2), q1, q3, min := inside.getD 0 q1, max := inside.getD (inside.size - 1) q3,
      outliers := sorted.filter fun v => v < q1 - pad || q3 + pad < v } := rfl

def frameworks : Array String :=
  #["vanillajs", "solid", "svelte", "vue", "preact", "inferno", "lit", "alpine", "mithril", "react", "marko", "hyperapp", "knockout",
    "riot", "stencil", "angular", "ember", "elm", "imba", "dojo", "aurelia", "backbone", "ractive", "cycle"]

/-- Twelve timings of each framework in a benchmark: a typical value per framework, noise around it, and a rare slow run. -/
def runsOf (bench : Nat) (lo hi : Nat) : Array (String × Array Rat) :=
  let base := Data.ints (500 + bench) frameworks.size lo hi
  frameworks.zipIdx.map fun (name, i) =>
    let noise := Data.ints (100 * bench + i) 12 0 100
    let b : Rat := base.getD i lo
    (name, noise.map fun (n : Nat) => b * (1 + (n : Rat) / 400 + (if n ≥ 98 then 1 / 2 else 0)))

theorem runsOf_eq (bench lo hi : Nat) : runsOf bench lo hi =
    let base := Data.ints (500 + bench) frameworks.size lo hi
    frameworks.zipIdx.map fun (name, i) =>
      let noise := Data.ints (100 * bench + i) 12 0 100
      let b : Rat := base.getD i lo
      (name, noise.map fun (n : Nat) => b * (1 + (n : Rat) / 400 + (if n ≥ 98 then 1 / 2 else 0))) := rfl

/-- The boxes of a benchmark, fastest median first. -/
def boxes (bench lo hi : Nat) : Array Box :=
  ((runsOf bench lo hi).map fun (name, runs) => Box.ofRuns name runs).qsort (·.median < ·.median)

theorem boxes_eq (bench lo hi : Nat) : boxes bench lo hi =
    ((runsOf bench lo hi).map fun (name, runs) => Box.ofRuns name runs).qsort (·.median < ·.median) := rfl

/-- A plot of `bs`, the value axis padded to hold every outlier. -/
def paneOf (bs : Array Box) : Pane :=
  let ends := bs.flatMap fun b => #[b.min, b.max] ++ b.outliers
  { width := 800, height := 400, groups := bs.map (·.name),
    left := Scale.autoRange (1 / 10) (ends.foldl min (ends.getD 0 0)) (ends.foldl max (ends.getD 0 0)), below := 100 }

theorem paneOf_eq (bs : Array Box) : paneOf bs =
    let ends := bs.flatMap fun b => #[b.min, b.max] ++ b.outliers
    { width := 800, height := 400, groups := bs.map (·.name),
      left := Scale.autoRange (1 / 10) (ends.foldl min (ends.getD 0 0)) (ends.foldl max (ends.getD 0 0)), below := 100 } := rfl

/-- The width of a box: 70% of its column, less a 2 pixel gap. -/
def boxWidth (p : Pane) : Rat := 7 * (p.categories.bandwidth - 2) / 10

theorem boxWidth_eq (p : Pane) : boxWidth p = 7 * (p.categories.bandwidth - 2) / 10 := rfl

/-- The rectangle from the first to the third quartile of box `i`. -/
def body (p : Pane) (i : Nat) (b : Box) : Rect :=
  ⟨p.centre i - boxWidth p / 2, p.row p.left b.q3, p.centre i + boxWidth p / 2, p.row p.left b.q1⟩

theorem body_eq (p : Pane) (i : Nat) (b : Box) :
    body p i b = ⟨p.centre i - boxWidth p / 2, p.row p.left b.q3, p.centre i + boxWidth p / 2, p.row p.left b.q1⟩ := rfl

/-- The 2 pixel line across box `i` at its median. -/
def medianBar (p : Pane) (i : Nat) (b : Box) : Rect :=
  let y := p.row p.left b.median
  ⟨(body p i b).x0, y - 1, (body p i b).x1, y + 1⟩

theorem medianBar_eq (p : Pane) (i : Nat) (b : Box) : medianBar p i b =
    let y := p.row p.left b.median
    ⟨(body p i b).x0, y - 1, (body p i b).x1, y + 1⟩ := rfl

def black : Color := ⟨0, 0, 0, 255⟩
def grey : Color := ⟨238, 238, 238, 255⟩

/-- A dashed whisker from the minimum to the maximum, a cap at each end, the box with its median, and a square for each outlier. -/
def commands (p : Pane) (i : Nat) (b : Box) : DisplayList :=
  let r := body p i b
  let (lo, hi) := (p.row p.left b.min, p.row p.left b.max)
  let cap (y : Rat) := line black 2 none r.x0 y r.x1 y
  line black 2 (some ⟨4, 4⟩) (p.centre i) hi (p.centre i) lo ++
  #[⟨1, black, .rect r⟩, ⟨1, grey, .rect ⟨r.x0 + 1, r.y0 + 1, r.x1 - 1, r.y1 - 1⟩⟩,
    ⟨3, black, .rect (medianBar p i b)⟩] ++ cap hi ++ cap lo ++
  b.outliers.map fun v => ⟨3, black, .marker .square ⟨p.centre i, p.row p.left v⟩ 4⟩

theorem commands_eq (p : Pane) (i : Nat) (b : Box) : commands p i b =
      let r := body p i b
    let (lo, hi) := (p.row p.left b.min, p.row p.left b.max)
    let cap (y : Rat) := line black 2 none r.x0 y r.x1 y
    line black 2 (some ⟨4, 4⟩) (p.centre i) hi (p.centre i) lo ++
    #[⟨1, black, .rect r⟩, ⟨1, grey, .rect ⟨r.x0 + 1, r.y0 + 1, r.x1 - 1, r.y1 - 1⟩⟩,
      ⟨3, black, .rect (medianBar p i b)⟩] ++ cap hi ++ cap lo ++
    b.outliers.map fun v => ⟨3, black, .marker .square ⟨p.centre i, p.row p.left v⟩ 4⟩ := rfl

/-- A benchmark's plot and the commands of its boxes. -/
structure Chart where
  name : String
  boxes : Array Box
  pane : Pane

def Chart.shapes (c : Chart) : DisplayList := c.boxes.zipIdx.flatMap fun (b, i) => commands c.pane i b

theorem Chart.shapes_eq (c : Chart) : c.shapes = c.boxes.zipIdx.flatMap fun (b, i) => commands c.pane i b := rfl

def chartOf (name : String) (bench lo hi : Nat) : Chart :=
  let bs := boxes bench lo hi
  ⟨name, bs, paneOf bs⟩

theorem chartOf_eq (name : String) (bench lo hi : Nat) : chartOf name bench lo hi =
    ⟨name, boxes bench lo hi, paneOf (boxes bench lo hi)⟩ := rfl

/-- Timings in milliseconds of three of the benchmarks of the JS framework benchmark that uPlot's page draws. -/
def charts : List Chart :=
  [chartOf "create-rows" 1 100 400, chartOf "replace-all-rows" 2 120 450, chartOf "select-row" 3 10 90]

end Inkproof.Demos.Boxes
