/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.Sparklines

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.Sparklines

def run : IO Unit :=
  Browser.registerPixels fun src px => do
    let some vals := named? src | throw (IO.userError s!"no sparkline {src}")
    Browser.sidedScene px #[] [] (fun _ => []) (fun _ => chart vals) pink

end Page.Sparklines
