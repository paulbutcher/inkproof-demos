/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Gpu.Frame
import Inkproof.Gpu.Tessellate
import Inkproof.Gpu.Wire

namespace Inkproof.Demos.Page

open Inkproof.Scene Inkproof.Gpu

/-- The wire bytes of a fresh frame of `list` on a white `w` by `h` target: what a chart element takes as its command list. -/
def bytes (w h : Nat) (list : DisplayList) : ByteArray :=
  ByteArray.mk (encode (frame (tessellate ⟨0, 0⟩) {} true w h list ⟨255, 255, 255, 255⟩).2).toArray

theorem bytes_data (w h : Nat) (list : DisplayList) :
    (bytes w h list).data.toList =
      encode (frame (tessellate ⟨0, 0⟩) {} true w h list ⟨255, 255, 255, 255⟩).2 := rfl

end Inkproof.Demos.Page
