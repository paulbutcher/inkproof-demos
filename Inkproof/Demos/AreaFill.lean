/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import RandomSampling
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Scale
import Inkproof.Viewport
import Inkproof.Demos.Axes
import Inkproof.Demos.Frame

namespace Inkproof.Demos.AreaFill

open Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Viewport Inkproof.Demos

/-- The integer in `-10..10` for a draw in `0..20`. -/
def level (draw : Nat) : Int := (draw : Int) - 10

theorem level_eq (draw : Nat) : level draw = (draw : Int) - 10 := rfl

theorem level_bounds (draw : Nat) (h : draw ≤ 20) : -10 ≤ level draw ∧ level draw ≤ 10 := by
  unfold level
  omega

/-- The `n` values drawn from the generator seeded with `seed`. -/
def values (seed n : Nat) : Array Int :=
  ((RandomSampling.nats (mkStdGen seed) n 0 20).1).map level

theorem values_eq (seed n : Nat) : values seed n = ((RandomSampling.nats (mkStdGen seed) n 0 20).1).map level := rfl

theorem values_size (seed n : Nat) : (values seed n).size = n := by
  simp [values, RandomSampling.nats_size]

theorem values_bounds (seed n : Nat) : ∀ v ∈ values seed n, -10 ≤ v ∧ v ≤ 10 := by
  intro v hv
  obtain ⟨d, hd, rfl⟩ := Array.mem_map.mp hv
  exact level_bounds d (RandomSampling.nats_mem _ _ _ _ (by omega) d hd).2

/-- The `n` points `(1, v₁), …, (n, vₙ)` of series `seed`. -/
def series (seed n : Nat) : Series Rat Rat :=
  Series.ofUnsorted ((values seed n).zipIdx.map fun (v, i) => (((i + 1 : Nat) : Rat), some ((v : Int) : Rat)))

/-- The height of a chart `width` wide, about a third of it. -/
def height (width : Nat) : Nat := min 600 (max 240 (width / 3))

theorem height_eq (width : Nat) : height width = min 600 (max 240 (width / 3)) := rfl

def frame (width : Nat) : Frame := Frame.sized width (height width) (1, 30) (-12, 12)

theorem frame_eq (width : Nat) : frame width = Frame.sized width (height width) (1, 30) (-12, 12) := rfl

/-- No zoom, the home view being the whole chart. -/
def config (f : Frame) : ViewConfig Float := f.viewConfig

theorem config_eq (f : Frame) : config f = f.viewConfig := rfl

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
    compileArea ⟨0, fill⟩ 0 (projection f) g ++ compileLine ⟨⟨1, stroke⟩, Axes.strokeHalfWidth, false, none, .straight⟩ (projection f) g ++
      (s.xs.zip s.values).flatMap fun (x, y) => y.elim #[] fun y => compileRing ⟨2, stroke, f.background, 3, 1⟩ ⟨(projection f).x x, (projection f).y y⟩

theorem chart_eq (seed : Nat) (hidden : Array Bool) (f : Frame) (measure : String → Float × Float) :
    chart seed hidden f measure = axisDisplay f measure ++
      (colors.zipIdx.filter fun (_, i) => !hidden.getD i false).toArray.flatMap fun ((stroke, fill), i) =>
        let s := pageSeries seed i
        let g := Segmented.single s
        compileArea ⟨0, fill⟩ 0 (projection f) g ++ compileLine ⟨⟨1, stroke⟩, Axes.strokeHalfWidth, false, none, .straight⟩ (projection f) g ++
          (s.xs.zip s.values).flatMap fun (x, y) => y.elim #[] fun y => compileRing ⟨2, stroke, f.background, 3, 1⟩ ⟨(projection f).x x, (projection f).y y⟩ := rfl

end Inkproof.Demos.AreaFill
