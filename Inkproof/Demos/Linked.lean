/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Float.FloatValue
import Inkproof.Viewport.Proofs.Interval
import Inkproof.Demos.Data
import Inkproof.Demos.ServerEvents
import Inkproof.Demos.Zoom

namespace Inkproof.Demos.Linked

open Inkproof.Scene Inkproof.Demos

/-- Three stacked charts over the same thousand minutes, each drawing three consecutive thousand-minute stretches of one of the server events series, as uPlot's sync-cursor page does. -/
def syncCharts : List (String × Zoom.Chart) :=
  let xs : Array Rat := (Array.range 1000).map fun i => ((i : Nat) : Rat)
  let colours : List Color := [⟨255, 0, 0, 255⟩, ⟨0, 128, 0, 255⟩, ⟨0, 0, 255, 255⟩]
  ServerEvents.series.zipIdx.map fun (f, i) =>
    (s!"sync-{i}", ⟨800, 240, (List.range 3).zip colours |>.map fun (k, colour) =>
      ⟨xs, (Array.range 1000).map fun j => ((f (1000 * k + j) : Int) : Rat) / 100, colour, none⟩, none, []⟩)

/-- Two thousand minutes of the first server events series, drawn small as the overview and large as the chart that shows the selected range, as uPlot's zoom-ranger page does. -/
def rangerCharts : List (String × Zoom.Chart) :=
  let xs : Array Rat := (Array.range 2000).map fun i => ((i : Nat) : Rat)
  let line : Zoom.Line := ⟨xs, (Array.range 2000).map fun j => ((ServerEvents.busy j : Int) : Rat) / 100, ⟨0, 0, 255, 255⟩, none⟩
  [("ranger-main", ⟨800, 300, [line], none, []⟩), ("ranger-overview", ⟨800, 120, [line], none, []⟩)]

/-- The range of minutes the large chart shows when the page opens. -/
def rangerStart : Float := 600

def rangerEnd : Float := 1200

theorem rangerCharts_eq : rangerCharts =
    let xs : Array Rat := (Array.range 2000).map fun i => ((i : Nat) : Rat)
    let line : Zoom.Line := ⟨xs, (Array.range 2000).map fun j => ((ServerEvents.busy j : Int) : Rat) / 100, ⟨0, 0, 255, 255⟩, none⟩
    [("ranger-main", ⟨800, 300, [line], none, []⟩), ("ranger-overview", ⟨800, 120, [line], none, []⟩)] := rfl

/-- Three series of thirty integers in `-10..10` over `1..30`, the data of uPlot's cursor-bind page, drawn from `seed`. -/
def bindChart (seed : Nat) : Zoom.Chart :=
  let xs : Array Rat := (Array.range 30).map fun i => ((i + 1 : Nat) : Rat)
  let line (k : Nat) (colour : Color) : Zoom.Line :=
    ⟨xs, (Data.ints (3 * seed + k) 30 0 20).map fun (v : Nat) => ((v : Int) - 10 : Int), colour, none⟩
  ⟨900, 400, [line 0 ⟨255, 0, 0, 255⟩, line 1 ⟨0, 128, 0, 255⟩, line 2 ⟨0, 0, 255, 255⟩], none, []⟩

theorem bindChart_eq (seed : Nat) : bindChart seed =
    let xs : Array Rat := (Array.range 30).map fun i => ((i + 1 : Nat) : Rat)
    let line (k : Nat) (colour : Color) : Zoom.Line :=
      ⟨xs, (Data.ints (3 * seed + k) 30 0 20).map fun (v : Nat) => ((v : Int) - 10 : Int), colour, none⟩
    ⟨900, 400, [line 0 ⟨255, 0, 0, 255⟩, line 1 ⟨0, 128, 0, 255⟩, line 2 ⟨0, 0, 255, 255⟩], none, []⟩ := rfl

/-- The samples a data server holds, one byte each, so that a byte range of its file is a range of samples. -/
def samples : Nat := 5000

/-- A sample of the served series: a slow wander with fast noise, below 256. -/
def sample (i : Nat) : Nat := 20 + ServerEvents.hash 8 (i / 40) % 150 + ServerEvents.hash 9 i % 60

theorem sample_eq (i : Nat) : sample i = 20 + ServerEvents.hash 8 (i / 40) % 150 + ServerEvents.hash 9 i % 60 := rfl

theorem sample_lt (i : Nat) : sample i < 256 := by
  have h1 := Nat.mod_lt (ServerEvents.hash 8 (i / 40)) (show 150 > 0 by decide)
  have h2 := Nat.mod_lt (ServerEvents.hash 9 i) (show 60 > 0 by decide)
  unfold sample
  omega

/-- The file the server holds for every `stride`th sample. -/
def file (stride : Nat) : ByteArray :=
  ⟨((Array.range (samples / stride)).map fun i => UInt8.ofNat (sample (i * stride)))⟩

theorem file_get (stride i : Nat) (h : i < (file stride).size) : (file stride).data[i]'(by simpa using h) = UInt8.ofNat (sample (i * stride)) := by
  simp [file]

theorem file_size (stride : Nat) : (file stride).size = samples / stride := by
  simp [file, ByteArray.size]

/-- The samples a file of every `stride`th sample holds, as points over the sample index. -/
def points (stride : Nat) (first : Nat) (body : ByteArray) : Array (Rat × Rat) :=
  body.data.zipIdx.map fun (b, i) => ((((first + i) * stride : Nat) : Rat), ((b.toNat : Nat) : Rat))

theorem points_get (stride first : Nat) (body : ByteArray) (i : Nat) (h : i < (points stride first body).size) :
    (points stride first body)[i] = ((((first + i) * stride : Nat) : Rat), ((body.data[i]'(by simpa [points] using h)).toNat : Rat)) := by
  simp [points]

theorem points_size (stride first : Nat) (body : ByteArray) : (points stride first body).size = body.size := by
  rw [points, Array.size_map, Array.size_zipIdx]
  rfl

/-- The samples the server returns for the visible interval `a`, padded by a tenth of it each side so a small pan still shows data, as the first sample and the count of them. -/
def window (a : Viewport.Interval Rat) : Nat × Nat :=
  let pad := a.span / 10
  let (lo, hi) := Viewport.Interval.indexRange ⟨a.start - pad, a.span + 2 * pad⟩ samples
  (lo, hi - lo)

theorem window_eq (a : Viewport.Interval Rat) : window a =
    ((Viewport.Interval.indexRange ⟨a.start - a.span / 10, a.span + 2 * (a.span / 10)⟩ samples).1,
     (Viewport.Interval.indexRange ⟨a.start - a.span / 10, a.span + 2 * (a.span / 10)⟩ samples).2 -
       (Viewport.Interval.indexRange ⟨a.start - a.span / 10, a.span + 2 * (a.span / 10)⟩ samples).1) := rfl

theorem window_bounds (a : Viewport.Interval Rat) : 0 < (window a).2 ∧ (window a).1 + (window a).2 ≤ samples := by
  have h := Viewport.Interval.indexRange_lt_le ⟨a.start - a.span / 10, a.span + 2 * (a.span / 10)⟩ samples (by decide)
  simp only [window]
  omega

/-- The window for the visible x range `[x0, x1]`, the whole file when either end is not a finite number. -/
def windowOf (x0 x1 : Float) : Nat × Nat :=
  match Inkproof.Float.Float.toRat x0, Inkproof.Float.Float.toRat x1 with
  | some a, some b => window ⟨a, b - a⟩
  | _, _ => (0, samples)

theorem windowOf_eq (x0 x1 : Float) : windowOf x0 x1 =
    match Inkproof.Float.Float.toRat x0, Inkproof.Float.Float.toRat x1 with
    | some a, some b => window ⟨a, b - a⟩
    | _, _ => (0, samples) := rfl

/-- The chart of the points fetched, over the extent of the whole series. -/
def fetched (pts : Array (Rat × Rat)) : Zoom.Chart :=
  ⟨800, 400, [⟨pts.map (·.1), pts.map (·.2), ⟨255, 0, 0, 255⟩, none⟩], some ((0, ((samples - 1 : Nat) : Rat)), (0, 256)), []⟩

theorem fetched_lines (pts : Array (Rat × Rat)) : (fetched pts).lines = [⟨pts.map (·.1), pts.map (·.2), ⟨255, 0, 0, 255⟩, none⟩] := rfl

theorem fetched_bounds (pts : Array (Rat × Rat)) : (fetched pts).ranges = ((0, ((samples - 1 : Nat) : Rat)), (0, 256)) := rfl

end Inkproof.Demos.Linked
