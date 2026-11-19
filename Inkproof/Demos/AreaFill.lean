/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Scale
import Inkproof.Demos.Axes

namespace Inkproof.Demos.AreaFill

open Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Demos

/-- An integer in `-10..10` from a draw of `randNat`, clamped because core states no bound on its result. -/
def level (draw : Nat) : Int := ((min draw 20 : Nat) : Int) - 10

theorem level_bounds (draw : Nat) : -10 ≤ level draw ∧ level draw ≤ 10 := by
  unfold level
  omega

/-- One draw of the generator: the next value is appended and the generator advances. -/
def step (acc : Array Int × StdGen) : Array Int × StdGen :=
  let (draw, g) := randNat acc.2 0 20
  (acc.1.push (level draw), g)

/-- The `n` values of series `seed`: uPlot's page draws these at random, here from a fixed seed so that every visit shows the same chart. -/
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

/-- Plot rectangle and data ranges of the chart. -/
structure Frame where
  left : Rat
  right : Rat
  top : Rat
  bottom : Rat
  xs : Rat × Rat
  ys : Rat × Rat

def frame : Frame := ⟨60, 1180, 20, 560, (1, 30), (-12, 12)⟩

/-- Data to pixels: x increases rightwards and y upwards, so the y range is reversed. -/
def projection (f : Frame) : Projection Rat Rat :=
  .linear ⟨f.xs.1, f.xs.2, f.left, f.right⟩ ⟨f.ys.1, f.ys.2, f.bottom, f.top⟩

theorem projection_x (f : Frame) (x : Rat) :
    (projection f).x x = (Linear.mk f.xs.1 f.xs.2 f.left f.right).map x := rfl

theorem projection_y (f : Frame) (y : Rat) :
    (projection f).y y = (Linear.mk f.ys.1 f.ys.2 f.bottom f.top).map y := rfl

def colors : List (Color × Color) :=
  [(⟨255, 0, 0, 255⟩, ⟨255, 0, 0, 26⟩), (⟨0, 128, 0, 255⟩, ⟨0, 255, 0, 26⟩), (⟨0, 0, 255, 255⟩, ⟨0, 0, 255, 26⟩)]

def flt (r : Rat) : Float := Float.ofInt r.num / r.den.toFloat

theorem flt_eq (r : Rat) : flt r = Float.ofInt r.num / r.den.toFloat := rfl

def plot (f : Frame) : Rect := ⟨f.left, f.top, f.right, f.bottom⟩

theorem plot_eq (f : Frame) : plot f = ⟨f.left, f.top, f.right, f.bottom⟩ := rfl

/-- The bottom and left axes. -/
def axes (f : Frame) (measure : String → Float × Float) : List AxisDrawing :=
  [Axes.linear .bottom (plot f) measure (flt f.xs.1) (flt f.xs.2) (flt f.left) (flt f.right),
   Axes.linear .left (plot f) measure (flt f.ys.1) (flt f.ys.2) (flt f.bottom) (flt f.top)]

theorem axes_eq (f : Frame) (measure : String → Float × Float) :
    axes f measure =
      [Axes.linear .bottom (plot f) measure (flt f.xs.1) (flt f.xs.2) (flt f.left) (flt f.right),
       Axes.linear .left (plot f) measure (flt f.ys.1) (flt f.ys.2) (flt f.bottom) (flt f.top)] := rfl

/-- Each series filled down to zero and stroked on top, over the axes. -/
def chart (f : Frame) (measure : String → Float × Float) : DisplayList :=
  (axes f measure).foldl (· ++ ·.display) #[] ++
  colors.zipIdx.toArray.flatMap fun ((stroke, fill), i) =>
    let g := Segmented.single (series (i + 1) 30)
    compileArea ⟨0, fill⟩ 0 (projection f) g ++ compileLine ⟨⟨1, stroke⟩, 1, false⟩ (projection f) g

theorem chart_eq (f : Frame) (measure : String → Float × Float) :
    chart f measure = (axes f measure).foldl (· ++ ·.display) #[] ++
      colors.zipIdx.toArray.flatMap fun ((stroke, fill), i) =>
        compileArea ⟨0, fill⟩ 0 (projection f) (Segmented.single (series (i + 1) 30)) ++
          compileLine ⟨⟨1, stroke⟩, 1, false⟩ (projection f) (Segmented.single (series (i + 1) 30)) := rfl

end Inkproof.Demos.AreaFill
