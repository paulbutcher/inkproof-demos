/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.AreaFill
import Inkproof.Core.Proofs.Series

namespace Inkproof.Demos.AreaFill

open Inkproof.Core

theorem series_size (seed n : Nat) : (series seed n).points.size = n := by
  have h := (Series.ofUnsorted_perm (ps := (values seed n).zipIdx.map fun (v, i) => (((i + 1 : Nat) : Rat), some ((v : Int) : Rat)))).length_eq
  simpa [series, values_size] using h

end Inkproof.Demos.AreaFill
