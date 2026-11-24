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

/-- The lowest and the highest edge of the buckets that hold the latencies. -/
def span : Int × Int :=
  let lo := samples.foldl min (samples.getD 0 0)
  let hi := samples.foldl max (samples.getD 0 0)
  (lo / bucket * bucket, (hi / bucket + 1) * bucket)

theorem span_eq : span =
    ((samples.foldl min (samples.getD 0 0)) / bucket * bucket, ((samples.foldl max (samples.getD 0 0)) / bucket + 1) * bucket) := rfl

/-- The number of buckets between the edges of `span`. -/
def buckets : Nat := max 1 ((span.2 - span.1).toNat / bucket)

theorem buckets_eq : buckets = max 1 ((span.2 - span.1).toNat / bucket) := rfl

theorem buckets_pos : 0 < buckets := Nat.lt_of_lt_of_le Nat.one_pos (Nat.le_max_left ..)

/-- The bucket each latency falls in. -/
def binning : Binning Int := Binning.ofInt span.1 span.2 buckets buckets_pos

theorem binning_eq : binning = Binning.ofInt span.1 span.2 buckets buckets_pos := rfl

/-- How many latencies each bucket holds, from the lowest. -/
def counts : Array Nat :=
  (samples.foldl (fun acc x => acc.modify (binning.col x) (Aggregate.merge · ⟨1⟩)) (Array.replicate buckets Aggregate.empty)).map Count.get

theorem counts_eq : counts =
    (samples.foldl (fun acc x => acc.modify (binning.col x) (Aggregate.merge · ⟨1⟩)) (Array.replicate buckets Aggregate.empty)).map Count.get := rfl

theorem counts_size : counts.size = buckets := by
  have h : ∀ (l : List Int) (a : Array Count),
      (l.foldl (fun acc x => acc.modify (binning.col x) (Aggregate.merge · ⟨1⟩)) a).size = a.size := by
    intro l
    induction l with
    | nil => intro a; rfl
    | cons x l ih => intro a; simp [List.foldl_cons, ih]
  unfold counts
  rw [Array.size_map, ← Array.foldl_toList, h]
  simp

/-- The chart's frame, 1800 by 600: latencies across and counts up. -/
def frame : Frame :=
  .sized 1800 600 ((span.1 : Rat), (span.2 : Rat)) (0, ((counts.foldl max 0 : Nat) : Rat) * 21 / 20)

theorem frame_eq : frame =
    .sized 1800 600 ((span.1 : Rat), (span.2 : Rat)) (0, ((counts.foldl max 0 : Nat) : Rat) * 21 / 20) := rfl

/-- The middle of each bucket, with its lower edge, its upper edge and its count. -/
def rows : Array (Rat × Array Rat) :=
  counts.zipIdx.map fun (n, i) =>
    let lo : Rat := (span.1 : Rat) + i * bucket
    (lo + (bucket : Rat) / 2, #[lo, lo + bucket, (n : Rat)])

theorem rows_eq : rows = counts.zipIdx.map fun (n, i) =>
    let lo : Rat := (span.1 : Rat) + i * bucket
    (lo + (bucket : Rat) / 2, #[lo, lo + bucket, (n : Rat)]) := rfl

/-- A bar over each bucket, inset by `gap` pixels between neighbours, with a red outline `stroke` wide. -/
def chart (gap stroke : Rat) (f : Frame) (measure : String → Float × Float) : DisplayList :=
  let p := projection f
  axisDisplay f measure ++ DisplayList.clip (plot f) (counts.zipIdx.flatMap fun (n, i) =>
    let x : Rat := (span.1 : Rat) + i * bucket
    Bars.Bar.commands ⟨⟨p.x x + gap / 2, p.y 0, p.x (x + bucket) - gap / 2, p.y n⟩, ⟨255, 153, 153, 255⟩, none, true, some ⟨255, 0, 0, 255⟩, stroke⟩)

theorem chart_eq (gap stroke : Rat) (f : Frame) (measure : String → Float × Float) :
    chart gap stroke f measure =
      axisDisplay f measure ++ DisplayList.clip (plot f) (counts.zipIdx.flatMap fun (n, i) =>
        let x : Rat := (span.1 : Rat) + i * bucket
        Bars.Bar.commands ⟨⟨(projection f).x x + gap / 2, (projection f).y 0, (projection f).x (x + bucket) - gap / 2, (projection f).y n⟩, ⟨255, 153, 153, 255⟩, none, true, some ⟨255, 0, 0, 255⟩, stroke⟩) := rfl

end Inkproof.Demos.LatencyHistogram
