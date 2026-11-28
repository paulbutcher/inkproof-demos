/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Scale
import Inkproof.Demos.Bars
import Inkproof.Demos.Data
import Inkproof.Demos.Frame
import Inkproof.Demos.Latency

namespace Inkproof.Demos.LatencyHistogram

open Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Demos

/-- Latencies are counted in buckets this wide, in milliseconds. -/
def bucket : Nat := 5

/-- No latency is recorded below this, in milliseconds. -/
def floor : Int := 5

/-- A hundred columns of between 200 and 500 latencies each, in whole milliseconds and none below `floor`. -/
def columns : Array (Array Int) :=
  (List.range 100).toArray.map fun i =>
    let n := (Data.ints (1000 + i) 1 200 500)[0]?.getD 200
    (Latency.draws (2000 + i) n 30 30 3).map fun v => max floor (Int.ofNat v.floor.toUInt64.toNat)

theorem columns_eq : columns =
    (List.range 100).toArray.map fun i =>
      let n := (Data.ints (1000 + i) 1 200 500)[0]?.getD 200
      (Latency.draws (2000 + i) n 30 30 3).map fun v => max floor (Int.ofNat v.floor.toUInt64.toNat) := rfl

/-- Every latency, over every column. -/
def samples : Array Int := columns.flatten

theorem samples_eq : samples = columns.flatten := rfl

/-- The lower edge of the bucket `size` wide, its edges at multiples of `size` past `offset`, that holds `v`. -/
def edge (size : Nat) (offset v : Int) : Int := (v - offset) / size * size + offset

theorem edge_eq (size : Nat) (offset v : Int) : edge size offset v = (v - offset) / size * size + offset := rfl

/-- The lowest and the highest edge of the buckets that hold the latencies. -/
def span (size : Nat := bucket) (offset : Int := 0) : Int × Int :=
  let lo := samples.foldl min (samples.getD 0 0)
  let hi := samples.foldl max (samples.getD 0 0)
  (edge size offset lo, edge size offset hi + size)

theorem span_eq (size : Nat) (offset : Int) : span size offset =
    (edge size offset (samples.foldl min (samples.getD 0 0)), edge size offset (samples.foldl max (samples.getD 0 0)) + size) := rfl

/-- The number of buckets between the edges of `span`. -/
def buckets (size : Nat := bucket) (offset : Int := 0) : Nat := max 1 (((span size offset).2 - (span size offset).1).toNat / size)

theorem buckets_eq (size : Nat) (offset : Int) : buckets size offset = max 1 (((span size offset).2 - (span size offset).1).toNat / size) := rfl

theorem buckets_pos (size : Nat) (offset : Int) : 0 < buckets size offset := Nat.lt_of_lt_of_le Nat.one_pos (Nat.le_max_left ..)

/-- The bucket each latency falls in. -/
def binning (size : Nat := bucket) (offset : Int := 0) : Binning Int :=
  Binning.ofInt (span size offset).1 (span size offset).2 (buckets size offset) (buckets_pos size offset)

theorem binning_eq (size : Nat) (offset : Int) : binning size offset =
    Binning.ofInt (span size offset).1 (span size offset).2 (buckets size offset) (buckets_pos size offset) := rfl

/-- How many latencies each bucket holds, from the lowest. -/
def counts (size : Nat := bucket) (offset : Int := 0) : Array Nat :=
  let b := binning size offset
  (samples.foldl (fun acc x => acc.modify (b.col x) (Aggregate.merge · ⟨1⟩))
    (Array.replicate (buckets size offset) Aggregate.empty)).map Count.get

theorem counts_eq (size : Nat) (offset : Int) : counts size offset =
    let b := binning size offset
    (samples.foldl (fun acc x => acc.modify (b.col x) (Aggregate.merge · ⟨1⟩))
      (Array.replicate (buckets size offset) Aggregate.empty)).map Count.get := rfl

theorem counts_size (size : Nat) (offset : Int) : (counts size offset).size = buckets size offset := by
  have h : ∀ (l : List Int) (a : Array Count),
      (l.foldl (fun acc x => acc.modify ((binning size offset).col x) (Aggregate.merge · ⟨1⟩)) a).size = a.size := by
    intro l
    induction l with
    | nil => intro a; rfl
    | cons x l ih => intro a; simp [List.foldl_cons, ih]
  unfold counts
  rw [Array.size_map, ← Array.foldl_toList, h]
  simp

/-- The chart's frame, 1800 by 600: latencies across and counts up. -/
def frame (size : Nat := bucket) (offset : Int := 0) : Frame :=
  .sized 1800 600 (((span size offset).1 : Rat), ((span size offset).2 : Rat)) (0, (((counts size offset).foldl max 0 : Nat) : Rat) * 21 / 20)

theorem frame_eq (size : Nat) (offset : Int) : frame size offset =
    .sized 1800 600 (((span size offset).1 : Rat), ((span size offset).2 : Rat)) (0, (((counts size offset).foldl max 0 : Nat) : Rat) * 21 / 20) := rfl

/-- The middle of each bucket, with its lower edge, its upper edge and its count. -/
def rows (size : Nat := bucket) (offset : Int := 0) : Array (Rat × Array Rat) :=
  (counts size offset).zipIdx.map fun (n, i) =>
    let lo : Rat := ((span size offset).1 : Rat) + i * size
    (lo + (size : Rat) / 2, #[lo, lo + size, (n : Rat)])

theorem rows_eq (size : Nat) (offset : Int) : rows size offset = (counts size offset).zipIdx.map fun (n, i) =>
    let lo : Rat := ((span size offset).1 : Rat) + i * size
    (lo + (size : Rat) / 2, #[lo, lo + size, (n : Rat)]) := rfl

/-- A bar over each bucket, inset by `gap` pixels between neighbours, with a red outline `stroke` wide. -/
def chart (gap stroke : Rat) (f : Frame) (measure : String → Float × Float) (size : Nat := bucket) (offset : Int := 0) : DisplayList :=
  let p := projection f
  axisDisplay f measure ++ DisplayList.clip (plot f) ((counts size offset).zipIdx.flatMap fun (n, i) =>
    let x : Rat := ((span size offset).1 : Rat) + i * size
    Bars.Bar.commands ⟨⟨p.x x + gap / 2, p.y 0, p.x (x + size) - gap / 2, p.y n⟩, ⟨255, 153, 153, 255⟩, none, true, some ⟨255, 0, 0, 255⟩, stroke, none⟩)

theorem chart_eq (gap stroke : Rat) (f : Frame) (measure : String → Float × Float) (size : Nat) (offset : Int) :
    chart gap stroke f measure size offset =
      axisDisplay f measure ++ DisplayList.clip (plot f) ((counts size offset).zipIdx.flatMap fun (n, i) =>
        let x : Rat := ((span size offset).1 : Rat) + i * size
        Bars.Bar.commands ⟨⟨(projection f).x x + gap / 2, (projection f).y 0, (projection f).x (x + size) - gap / 2, (projection f).y n⟩, ⟨255, 153, 153, 255⟩, none, true, some ⟨255, 0, 0, 255⟩, stroke, none⟩) := rfl

end Inkproof.Demos.LatencyHistogram
