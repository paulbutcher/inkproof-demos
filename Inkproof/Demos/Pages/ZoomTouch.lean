/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.ZoomPage

namespace Page.ZoomTouch

def run : IO Unit := Inkproof.Demos.ZoomPage.mount [("zoom-touch", Inkproof.Demos.Zoom.basic)]

end Page.ZoomTouch
