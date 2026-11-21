/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.ZoomPage
import Inkproof.Demos.Annotations

namespace Page.Annotations

def run : IO Unit := Inkproof.Demos.ZoomPage.mount [("annotations", Inkproof.Demos.Annotations.chart)]

end Page.Annotations
