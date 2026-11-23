/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.MissingData

open Inkproof.Web.Host Inkproof.Demos

def run : IO Unit :=
  Browser.registerLines MissingData.charts

end Page.MissingData
