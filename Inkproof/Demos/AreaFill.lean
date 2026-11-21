/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Scale
import Inkproof.Viewport
import Inkproof.Demos.Axes
import Inkproof.Demos.Frame

namespace Inkproof.Demos.AreaFill

open Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Viewport Inkproof.Demos

/-- An integer in `-10..10` from a draw of `randNat`, clamped because core states no bound on its result. -/
def level (draw : Nat) : Int := ((min draw 20 : Nat) : Int) - 10

theorem level_bounds (draw : Nat) : -10 ≤ level draw ∧ level draw ≤ 10 := by
  unfold level
  omega

/-- One draw of the generator: the next value is appended and the generator advances. -/
def step (acc : Array Int × StdGen) : Array Int × StdGen :=
  let (draw, g) := randNat acc.2 0 20
  (acc.1.push (level draw), g)

/-- The `n` values drawn from the generator seeded with `seed`. -/
def values (seed n : Nat) : Array Int :=
  (n.fold (fun _ _ acc => step acc) (#[], mkStdGen seed)).1

theorem step_size (acc : Array Int × StdGen) : (step acc).1.size = acc.1.size + 1 := by simp [step]

theorem values_size (seed n : Nat) : (values seed n).size = n := by
  have h : ∀ (k : Nat) (a : Array Int × StdGen),
      (k.fold (fun _ _ acc => step acc) a).1.size = a.1.size + k := by
    intro k
    induction k with
    | zero => simp [Nat.fold]
    | succ k ih => intro a; rw [Nat.fold_succ]; show (step _).1.size = _; rw [step_size, ih a]; omega
  simp [values, h]

/-- The `n` points `(1, v₁), …, (n, vₙ)` of series `seed`. -/
def series (seed n : Nat) : Series Rat Rat :=
  Series.ofUnsorted ((values seed n).zipIdx.map fun (v, i) => (((i + 1 : Nat) : Rat), some ((v : Int) : Rat)))

/-- The height of a chart `width` wide, about a third of it. -/
def height (width : Nat) : Nat := min 600 (max 240 (width / 3))

theorem height_eq (width : Nat) : height width = min 600 (max 240 (width / 3)) := rfl

def frame (width : Nat) : Frame := Frame.sized width (height width) (1, 30) (-12, 12)

theorem frame_eq (width : Nat) : frame width = Frame.sized width (height width) (1, 30) (-12, 12) := rfl

/-- No zoom, the home view being the whole chart. -/
def config (f : Frame) : ViewConfig Float :=
  let axis (length : Rat) (r : Rat × Rat) : Interval.Config Float :=
    let span := Rat.toFloat (r.2 - r.1)
    ⟨Rat.toFloat length, span, span, ⟨Rat.toFloat r.1, span⟩, 5 / 4, 1 / 10⟩
  ⟨axis (f.right - f.left) f.xs, axis (f.bottom - f.top) f.ys⟩

theorem config_eq (f : Frame) : config f =
    let axis (length : Rat) (r : Rat × Rat) : Interval.Config Float :=
      let span := Rat.toFloat (r.2 - r.1)
      ⟨Rat.toFloat length, span, span, ⟨Rat.toFloat r.1, span⟩, 5 / 4, 1 / 10⟩
    ⟨axis (f.right - f.left) f.xs, axis (f.bottom - f.top) f.ys⟩ := rfl

def colors : List (Color × Color) :=
  [(⟨255, 0, 0, 255⟩, ⟨255, 0, 0, 26⟩), (⟨0, 128, 0, 255⟩, ⟨0, 255, 0, 26⟩), (⟨0, 0, 255, 255⟩, ⟨0, 0, 255, 26⟩)]

/-- Series `i` of a page seeded with `seed`. -/
def pageSeries (seed i : Nat) : Series Rat Rat := series (seed + i) 30

theorem pageSeries_eq (seed i : Nat) : pageSeries seed i = series (seed + i) 30 := rfl

/-- Each series not in `hidden` filled down to zero, stroked on top with a one pixel line and marked with an open circle at each point, over the axes. -/
def chart (seed : Nat) (hidden : Array Bool) (f : Frame) (measure : String → Float × Float) : DisplayList :=
  axisDisplay f measure ++
  (colors.zipIdx.filter fun (_, i) => !hidden.getD i false).toArray.flatMap fun ((stroke, fill), i) =>
    let s := pageSeries seed i
    let g := Segmented.single s
    compileArea ⟨0, fill⟩ 0 (projection f) g ++ compileLine ⟨⟨1, stroke⟩, 1/2, false, none, .straight⟩ (projection f) g ++
      (s.xs.zip s.values).flatMap fun (x, y) => y.elim #[] fun y => compileRing ⟨2, stroke, background, 3, 1⟩ ⟨(projection f).x x, (projection f).y y⟩

theorem chart_eq (seed : Nat) (hidden : Array Bool) (f : Frame) (measure : String → Float × Float) :
    chart seed hidden f measure = axisDisplay f measure ++
      (colors.zipIdx.filter fun (_, i) => !hidden.getD i false).toArray.flatMap fun ((stroke, fill), i) =>
        let s := pageSeries seed i
        let g := Segmented.single s
        compileArea ⟨0, fill⟩ 0 (projection f) g ++ compileLine ⟨⟨1, stroke⟩, 1/2, false, none, .straight⟩ (projection f) g ++
          (s.xs.zip s.values).flatMap fun (x, y) => y.elim #[] fun y => compileRing ⟨2, stroke, background, 3, 1⟩ ⟨(projection f).x x, (projection f).y y⟩ := rfl

end Inkproof.Demos.AreaFill
