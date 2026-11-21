/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import RandomSampling

namespace Inkproof.Demos.Latency

/-- The latencies of `n` skew normal draws for `seed`. -/
def draws (seed n : Nat) (ξ ω α : Float) : Array Float :=
  (RandomSampling.draws n (RandomSampling.skewNormal ξ ω α) (mkStdGen seed)).1

theorem draws_eq (seed n : Nat) (ξ ω α : Float) : draws seed n ξ ω α =
    (RandomSampling.draws n (RandomSampling.skewNormal ξ ω α) (mkStdGen seed)).1 := rfl

theorem draws_size (seed n : Nat) (ξ ω α : Float) : (draws seed n ξ ω α).size = n :=
  RandomSampling.draws_size _ _ _

end Inkproof.Demos.Latency
