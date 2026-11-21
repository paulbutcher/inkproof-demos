/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import RandomSampling

namespace Inkproof.Demos.Data

/-- A step of the walk: the sum of twelve uniform draws in `0..1`, less six, which is close to a standard normal draw. -/
def gauss (g : StdGen) : Rat × StdGen :=
  let (sum, g) := (List.range 12).foldl (fun (acc : Nat × StdGen) _ => let (d, g) := RandomSampling.nat acc.2 0 1000; (acc.1 + d, g)) (0, g)
  (((sum : Int) - 6000 : Int) / 1000, g)

theorem gauss_eq (g : StdGen) :
    gauss g =
      let (sum, g) := (List.range 12).foldl (fun (acc : Nat × StdGen) _ => let (d, g) := RandomSampling.nat acc.2 0 1000; (acc.1 + d, g)) (0, g)
      (((sum : Int) - 6000 : Int) / 1000, g) := rfl

/-- One step from `v`: it moves by a normal draw and stays put when that would leave `lo..hi`. -/
def next (lo hi : Rat) (acc : Rat × StdGen) : Rat × StdGen :=
  let (r, g) := gauss acc.2
  let v := acc.1 + r
  (if lo ≤ v ∧ v ≤ hi then v else acc.1, g)

theorem next_eq (lo hi : Rat) (acc : Rat × StdGen) :
    next lo hi acc =
      let (r, g) := gauss acc.2
      (if lo ≤ acc.1 + r ∧ acc.1 + r ≤ hi then acc.1 + r else acc.1, g) := rfl

theorem next_within (lo hi : Rat) (acc : Rat × StdGen) (h : lo ≤ acc.1 ∧ acc.1 ≤ hi) :
    lo ≤ (next lo hi acc).1 ∧ (next lo hi acc).1 ≤ hi := by
  unfold next
  dsimp only
  split <;> simp_all

/-- `n` values of a random walk from `start`, confined to `lo..hi`, from the fixed seed `seed`; uPlot's demos draw theirs at random. -/
def walk (seed n : Nat) (start lo hi : Rat) : Array Rat :=
  (n.fold (fun _ _ (acc : Array Rat × Rat × StdGen) =>
    let (v, g) := next lo hi acc.2
    (acc.1.push v, v, g)) (#[], start, mkStdGen seed)).1

theorem walk_eq (seed n : Nat) (start lo hi : Rat) :
    walk seed n start lo hi =
      (n.fold (fun _ _ (acc : Array Rat × Rat × StdGen) =>
        let (v, g) := next lo hi acc.2
        (acc.1.push v, v, g)) (#[], start, mkStdGen seed)).1 := rfl

theorem walk_size (seed n : Nat) (start lo hi : Rat) : (walk seed n start lo hi).size = n := by
  have h : ∀ (k : Nat) (a : Array Rat × Rat × StdGen),
      (k.fold (fun _ _ (acc : Array Rat × Rat × StdGen) =>
        let (v, g) := next lo hi acc.2
        (acc.1.push v, v, g)) a).1.size = a.1.size + k := by
    intro k
    induction k with
    | zero => simp [Nat.fold]
    | succ k ih => intro a; rw [Nat.fold_succ]; simp [ih]; omega
  simp [walk, h]

/-- `n` integers in `lo..hi` from the fixed seed `seed`; uPlot's demos draw theirs at random. -/
def ints (seed n lo hi : Nat) : Array Nat :=
  (RandomSampling.nats (mkStdGen seed) n lo hi).1

theorem ints_eq (seed n lo hi : Nat) : ints seed n lo hi = (RandomSampling.nats (mkStdGen seed) n lo hi).1 := rfl

theorem ints_size (seed n lo hi : Nat) : (ints seed n lo hi).size = n := RandomSampling.nats_size _ _ _ _

/-- The smallest and the largest of `vals`, or `(0, 1)` when there are none. -/
def extent (vals : Array Rat) : Rat × Rat := (vals.min?.getD 0, vals.max?.getD 1)

theorem extent_eq (vals : Array Rat) : extent vals = (vals.min?.getD 0, vals.max?.getD 1) := rfl

theorem extent_empty : extent #[] = (0, 1) := rfl

end Inkproof.Demos.Data
