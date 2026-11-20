/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.ZoomPage

def main : IO Unit := Inkproof.Demos.ZoomPage.mount [("tooltip-legend", Inkproof.Demos.Linked.bindChart)]
