/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos
import InkproofTools.Test.Harness
import InkproofTools.Test.Platform

open InkproofTools.Test Inkproof.Demos Inkproof.Scene

private def areaFillTest : Except String Unit := do
  for seed in [1, 2, 3] do
    let s := AreaFill.series seed 30
    check (s.xs == (Array.range 30).map fun i => ((i + 1 : Nat) : Rat)) s!"series {seed} runs over 1..30"
    check (s.values.all fun v => v.any fun y => -10 ≤ y && y ≤ 10) s!"series {seed} stays within -10..10"
  check (AreaFill.values 1 12 == #[-8, 9, 3, 7, -3, 0, -2, 9, 3, 3, -10, -3]) "series 1 differs from the recorded values, so a platform draws other data"
  check (AreaFill.values 2 12 == #[1, 5, 5, -9, -7, 0, -9, 9, -9, 4, -6, -3]) "series 2 differs from the recorded values, so a platform draws other data"

def main (args : List String) : IO UInt32 :=
  runTests [⟨"area fill", areaFillTest⟩, platformTest (args.contains "--expect-wasm")]
