/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.ZoomPage
import Inkproof.Demos.Browser

def main : IO Unit := do
  let seed ← Inkproof.Demos.Browser.seed
  Inkproof.Demos.ZoomPage.mount [("cursor-bind", Inkproof.Demos.Linked.bindChart seed)]
