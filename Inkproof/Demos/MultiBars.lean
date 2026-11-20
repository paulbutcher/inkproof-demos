/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

The library benchmark figures are those of uPlot's bench/results.json, Copyright (c) 2022 Leon Sorokin, released under the MIT license.
-/
import Inkproof.Core
import Inkproof.Demos.Bars
import Inkproof.Demos.Data

namespace Inkproof.Demos.MultiBars

open Inkproof.Core Inkproof.Scene Inkproof.Demos Inkproof.Demos.Bars

/-- A library's benchmark: its size in KB, the four phases of rendering in ms, its peak and final heap in MB, and the time interacting and toggling series, in ms, where measured. -/
structure Lib where
  name : String
  size : Rat
  render : Array Rat
  heap : Rat × Rat
  interact : Option (Array Rat) := none
  toggle : Option (Array Rat) := none

def libs : Array Lib := #[
  ⟨"uPlot v1.6.24", 47.9, #[51, 2, 1, 34], (20.8, 2.9), some #[218, 360, 146, 196], some #[59, 14, 7, 62]⟩,
  ⟨"Chart.js v4.2.1", 254, #[90, 2, 1, 40], (28.6, 10), some #[1154, 46, 165, 235], some #[145, 5, 7, 47]⟩,
  ⟨"Flot v3.0.0", 494, #[105, 5, 1, 52], (40.5, 21), none, none⟩,
  ⟨"ECharts v5.4.1", 1000, #[148, 3, 1, 35], (17.3, 3.2), some #[1943, 444, 203, 208], some #[218, 12, 9, 60]⟩,
  ⟨"dygraphs v2.2.1", 132, #[163, 2, 1, 33], (88.3, 42), some #[1438, 371, 174, 268], none⟩,
  ⟨"LightningChart® v4.0.2", 1300, #[250, 2, 1, 33], (33.2, 12.6), some #[5390, 120, 128, 325], some #[1337, 42, 54, 111]⟩,
  ⟨"CanvasJS v3.7.5", 489, #[266, 4, 1, 35], (97.9, 69.3), some #[1030, 445, 90, 246], none⟩,
  ⟨"dvxCharts v5.1.0", 373, #[264, 23, 1, 62], (99.6, 60.5), some #[687, 779, 206, 197], some #[829, 188, 8, 145]⟩,
  ⟨"Highcharts v10.3.3", 413, #[416, 7, 1, 38], (97, 54.8), some #[1286, 824, 205, 242], some #[1035, 38, 19, 72]⟩,
  ⟨"Plotly.js v2.18.2", 3600, #[655, 14, 1, 40], (104, 70.2), some #[1814, 163, 25, 208], some #[681, 58, 20, 113]⟩,
  ⟨"ApexCharts v3.37.1", 503, #[694, 9, 1, 33], (175, 45.7), some #[1708, 421, 106, 207], some #[2503, 58, 5, 39]⟩,
  ⟨"ZingChart v2.9.10", 871, #[717, 7, 1, 105], (290, 195), some #[9021, 305, 41, 71], none⟩,
  ⟨"amCharts v5.3.7", 625, #[1601, 3, 3, 46], (147, 121), some #[9171, 71, 460, 167], some #[1611, 17, 35, 65]⟩]

def total (xs : Array Rat) : Rat := xs.foldl (· + ·) 0

theorem total_empty : total #[] = 0 := rfl

theorem total_eq (xs : Array Rat) : total xs = xs.toList.sum := by
  have h : ∀ (l : List Rat) (a : Rat), l.foldl (· + ·) a = a + l.sum := by
    intro l
    induction l with
    | nil => intro a; simp [Rat.add_zero]
    | cons x l ih => intro a; rw [List.foldl_cons, ih, List.sum_cons]; rw [Rat.add_assoc]
  rw [total, ← Array.foldl_toList, h, Rat.zero_add]

/-- The largest of `vs`, or zero. -/
def largest (vs : Array Rat) : Rat := vs.foldl max 0

theorem largest_empty : largest #[] = 0 := rfl

theorem le_largest (vs : Array Rat) {v : Rat} (h : v ∈ vs) : v ≤ largest vs := by
  have key : ∀ (l : List Rat) (a : Rat), a ≤ l.foldl max a ∧ ∀ v ∈ l, v ≤ l.foldl max a := by
    intro l
    induction l with
    | nil => intro a; simp
    | cons x l ih =>
      intro a
      obtain ⟨h1, h2⟩ := ih (max a x)
      refine ⟨Rat.le_trans (Std.left_le_max) h1, ?_⟩
      intro v hv
      rcases List.mem_cons.mp hv with rfl | hv
      · exact Rat.le_trans (Std.right_le_max) h1
      · exact h2 v hv
  rw [largest, ← Array.foldl_toList]
  exact (key vs.toList 0).2 v (Array.mem_toList_iff.mpr h)

theorem zero_le_largest (vs : Array Rat) : 0 ≤ largest vs := by
  rw [largest, ← Array.foldl_toList]
  generalize vs.toList = l
  suffices ∀ a : Rat, a ≤ l.foldl max a from this 0
  induction l with
  | nil => intro a; exact Rat.le_refl
  | cons x l ih => intro a; exact Rat.le_trans (Std.left_le_max) (ih _)

/-- The scale shared by the render times and the random line, which is the left axis. -/
def renderRange : Rat × Rat := (0, 4000)

/-- A line of values between 3000 and 4000, one per library, from a fixed seed: uPlot's page draws them at random. -/
def random : Array Rat := (Data.ints 7 libs.size 0 1000).map fun (v : Nat) => 3000 + (v : Rat)

theorem random_eq : random = (Data.ints 7 libs.size 0 1000).map fun (v : Nat) => 3000 + (v : Rat) := rfl

theorem random_size : random.size = libs.size := by
  simp [random, Data.ints_size]

/-- A series of the libraries' values on a scale that runs from zero to its largest value. -/
def series (fill : Color) (values : Array (Option Rat)) : Series :=
  { fill, values, range := (0, largest (values.filterMap id)) }

theorem series_range (fill : Color) (values : Array (Option Rat)) :
    (series fill values).range = (0, largest (values.filterMap id)) := rfl

/-- The six series of uPlot's page, each on its own scale except that the two heaps share one. -/
def benchmarkSeries : Array Series :=
  let heaps := libs.map (·.heap.1) ++ libs.map (·.heap.2)
  #[series ⟨51, 187, 85, 255⟩ (libs.map (some ·.size)),
    { fill := ⟨181, 111, 171, 255⟩, values := libs.map (some <| total ·.render), range := renderRange },
    { fill := ⟨187, 17, 51, 255⟩, values := libs.map (some ·.heap.1), range := (0, largest heaps) },
    { fill := ⟨247, 148, 32, 255⟩, values := libs.map (some ·.heap.2), range := (0, largest heaps) },
    series ⟨85, 138, 181, 255⟩ (libs.map (·.interact.map total)),
    series ⟨250, 213, 92, 255⟩ (libs.map (·.toggle.map total))]

/-- The benchmark chart: grouped bars with a line over them, laid out across or down. -/
def benchmark (horizontal : Bool) : Chart :=
  { width := if horizontal then 800 else 2300, height := if horizontal then 2300 else 800, horizontal,
    groups := libs.map (·.name), series := benchmarkSeries, axis := renderRange,
    lines := #[⟨⟨128, 0, 128, 255⟩, random, renderRange⟩] }

theorem benchmark_eq (horizontal : Bool) : benchmark horizontal =
    { width := if horizontal then 800 else 2300, height := if horizontal then 2300 else 800, horizontal,
      groups := libs.map (·.name), series := benchmarkSeries, axis := renderRange,
      lines := #[⟨⟨128, 0, 128, 255⟩, random, renderRange⟩] } := rfl

theorem benchmark_groups (horizontal : Bool) : (benchmark horizontal).groups = libs.map (·.name) := rfl

def okFill : Color := ⟨127, 215, 154, 255⟩
def okOutline : Color := ⟨51, 187, 85, 255⟩
def pendingFill : Color := ⟨251, 201, 132, 255⟩
def pendingOutline : Color := ⟨247, 148, 32, 255⟩
def failedFill : Color := ⟨213, 100, 118, 255⟩
def failedOutline : Color := ⟨187, 17, 51, 255⟩

/-- The status of build `i`: 1 is pending, 2 failed and 0 a success. -/
def status (i : Nat) : Nat := if i % 12 == 0 then 1 else if i % 10 == 0 then 2 else 0

theorem status_eq (i : Nat) : status i = if i % 12 == 0 then 1 else if i % 10 == 0 then 2 else 0 := rfl

theorem status_zero : status 0 = 1 := rfl

/-- A build's fill and outline by its status. -/
def statusColors (i : Nat) : Color × Color :=
  match status i with
  | 0 => (okFill, okOutline)
  | 1 => (pendingFill, pendingOutline)
  | _ => (failedFill, failedOutline)

theorem statusColors_eq (i : Nat) : statusColors i =
    match status i with
    | 0 => (okFill, okOutline)
    | 1 => (pendingFill, pendingOutline)
    | _ => (failedFill, failedOutline) := rfl

/-- The 26 build durations, one for each letter, between -100 and 100; every third is negative. uPlot's page draws them at random. -/
def durations : Array Int :=
  (Data.ints 11 26 0 100).map fun (n : Nat) => let v : Int := n; if v % 3 == 0 then -v else v

theorem durations_eq : durations =
    (Data.ints 11 26 0 100).map fun (n : Nat) => let v : Int := n; if v % 3 == 0 then -v else v := rfl

theorem durations_size : durations.size = 26 := by
  simp [durations, Data.ints_size]

/-- The lowercase letters, `a` to `z`. -/
def letters : Array String := (List.range 26).toArray.map fun i => String.singleton (Char.ofNat ('a'.toNat + i))

theorem letters_size : letters.size = 26 := by simp [letters]

theorem letters_getElem? (i : Nat) (h : i < 26) :
    letters[i]? = some (String.singleton (Char.ofNat ('a'.toNat + i))) := by
  simp [letters, h]

/-- The builds as bars of varying colour, labelled with their durations. -/
def builds : Chart :=
  { width := 800, height := 400, groups := letters, axis := (-100, 100),
    series := #[{ fill := okFill, values := durations.map fun (d : Int) => some (d : Rat), range := (-100, 100),
                  groupColors := (List.range 26).toArray.map statusColors }] }

/-- The same builds on a numeric x axis, one bar centred on each whole number, so the first and last are cut in half at the plot's edge. -/
def numeric : Frame := .sized 800 400 (0, 25) (-100, 100)

/-- The axes, then a bar for each build between zero and its duration, 60% of a unit wide. -/
def numericChart (f : Frame) (measure : String → Float × Float) : DisplayList :=
  axisDisplay f measure ++ DisplayList.clip (plot f) (durations.toList.zipIdx.toArray.flatMap fun (d, i) =>
    let p := projection f
    let (fill, outline) := statusColors i
    Bar.commands ⟨⟨p.x ((i : Rat) - 3 / 10), p.y 0, p.x ((i : Rat) + 3 / 10), p.y (d : Rat)⟩, fill, none, 0 ≤ d, some outline, 1⟩)

theorem numericChart_eq (f : Frame) (measure : String → Float × Float) :
    numericChart f measure = axisDisplay f measure ++ DisplayList.clip (plot f) (durations.toList.zipIdx.toArray.flatMap fun (d, i) =>
      let p := projection f
      let (fill, outline) := statusColors i
      Bar.commands ⟨⟨p.x ((i : Rat) - 3 / 10), p.y 0, p.x ((i : Rat) + 3 / 10), p.y (d : Rat)⟩, fill, none, 0 ≤ d, some outline, 1⟩) := rfl

end Inkproof.Demos.MultiBars
