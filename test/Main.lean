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

private def axesTest : Except String Unit := do
  let measure := fun (t : String) => (7.0 * t.length.toFloat, 14.0)
  let drawings := AreaFill.axes AreaFill.frame measure
  let [bottom, left] := drawings | throw "expected a bottom and a left axis"
  check (!bottom.labels.isEmpty && !left.labels.isEmpty) "both axes keep labels"
  let f := AreaFill.frame
  check (left.labels.all fun l => l.anchor.y ≥ f.top && l.anchor.y ≤ f.bottom) "left labels lie within the plot's height"
  check (bottom.labels.all fun l => l.anchor.x ≥ f.left && l.anchor.x ≤ f.right) "bottom labels lie within the plot's width"
  check (left.labels.length ≥ 5) "the left axis keeps most of its labels"

private def logScales2Test : Except String Unit := do
  let measure := fun (t : String) => (7.0 * t.length.toFloat, 14.0)
  for spec in LogScales2.specs do
    let f := spec.frame
    check (spec.data.xs.all fun x => spec.xs.1 ≤ x && x ≤ spec.xs.2) s!"{spec.name}: points lie within the x range"
    check (spec.data.values.all fun v => v.all fun y => spec.kind == .linear || (0 < y && spec.ys.1 ≤ y && y ≤ spec.ys.2)) s!"{spec.name}: a log chart holds only values its scale can place"
    let [_, left] := spec.axes measure | throw s!"{spec.name}: expected two axes"
    check (!left.labels.isEmpty) s!"{spec.name}: the y axis keeps labels"
    check (left.labels.all fun l => l.anchor.y ≥ f.top && l.anchor.y ≤ f.bottom) s!"{spec.name}: y labels lie within the plot"
  let signed := LogScales2.specs.find? (·.name == "signed") |>.map (·.data.values)
  check (signed.any fun vs => vs.any (·.isNone) && vs.any (·.isSome)) "non-positive values are gaps, not bridged or dropped wholesale"

def main (args : List String) : IO UInt32 :=
  runTests [⟨"area fill", areaFillTest⟩, ⟨"area fill axes", axesTest⟩, ⟨"log scales 2", logScales2Test⟩, platformTest (args.contains "--expect-wasm")]
