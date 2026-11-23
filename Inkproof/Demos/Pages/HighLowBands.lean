/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.HighLowBands

open Inkproof.Web.Host Inkproof.Demos

def run : IO Unit :=
  Browser.registerLines HighLowBands.charts

end Page.HighLowBands
