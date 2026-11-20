/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

The skew normal draw follows uPlot's demos/lib/rand.js, Copyright (c) 2022 Leon Sorokin, released under the MIT license.
-/
import Inkproof.Core
import Inkproof.Demos.Data

namespace Inkproof.Demos.Latency

open Inkproof.Core

/-- A uniform draw strictly between 0 and 1. -/
def uniform (g : StdGen) : Float × StdGen :=
  let (d, g) := Data.draw g 1000000
  ((d.toFloat + 1) / 1000002, g)

theorem uniform_eq (g : StdGen) : uniform g = (((Data.draw g 1000000).1.toFloat + 1) / 1000002, (Data.draw g 1000000).2) := rfl

/-- A draw from the skew normal distribution with location `ξ`, scale `ω` and shape `α`, by the Box-Muller transform. -/
def skewNormal (ξ ω α : Float) (g : StdGen) : Float × StdGen :=
  let (a, g) := uniform g
  let (b, g) := uniform g
  let r := Float.sqrt (-2 * Float.log a)
  let θ := 2 * 3.141592653589793 * b
  let u0 := r * Float.cos θ
  let v := r * Float.sin θ
  let δ := α / Float.sqrt (1 + α * α)
  let u1 := δ * u0 + Float.sqrt (1 - δ * δ) * v
  (ξ + ω * (if u0 ≥ 0 then u1 else -u1), g)

theorem skewNormal_eq (ξ ω α : Float) (g : StdGen) : skewNormal ξ ω α g =
    let (a, g) := uniform g
    let (b, g) := uniform g
    let r := Float.sqrt (-2 * Float.log a)
    let θ := 2 * 3.141592653589793 * b
    let u0 := r * Float.cos θ
    let v := r * Float.sin θ
    let δ := α / Float.sqrt (1 + α * α)
    let u1 := δ * u0 + Float.sqrt (1 - δ * δ) * v
    (ξ + ω * (if u0 ≥ 0 then u1 else -u1), g) := rfl

theorem skewNormal_snd (ξ ω α : Float) (g : StdGen) : (skewNormal ξ ω α g).2 = (uniform (uniform g).2).2 := rfl

/-- The latency `n` draws give, as floats: the first of the draws for `seed`. -/
def draws (seed n : Nat) (ξ ω α : Float) : Array Float :=
  ((List.range n).foldl (fun (acc : Array Float × StdGen) _ =>
    let (v, g) := skewNormal ξ ω α acc.2
    (acc.1.push v, g)) (#[], mkStdGen seed)).1

theorem draws_eq (seed n : Nat) (ξ ω α : Float) : draws seed n ξ ω α =
    ((List.range n).foldl (fun (acc : Array Float × StdGen) _ =>
      let (v, g) := skewNormal ξ ω α acc.2
      (acc.1.push v, g)) (#[], mkStdGen seed)).1 := rfl

theorem draws_size (seed n : Nat) (ξ ω α : Float) : (draws seed n ξ ω α).size = n := by
  have h : ∀ (l : List Nat) (a : Array Float × StdGen),
      (l.foldl (fun (acc : Array Float × StdGen) _ =>
        let (v, g) := skewNormal ξ ω α acc.2
        (acc.1.push v, g)) a).1.size = a.1.size + l.length := by
    intro l
    induction l with
    | nil => intro a; simp
    | cons x l ih => intro a; simp only [List.foldl_cons, List.length_cons]; rw [ih]; simp; omega
  simp [draws, h]

end Inkproof.Demos.Latency
