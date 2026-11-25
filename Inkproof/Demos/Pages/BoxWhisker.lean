/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.BoxWhisker

open Inkproof.Web.Host Inkproof.Demos

def run : IO Unit :=
  Browser.registerPixels fun src px => do
    let some c := Boxes.charts.find? (·.name == src) | throw (IO.userError s!"no chart {src}")
    Browser.paneScene px c.pane c.shapes c.name
      #[Browser.paneGroup c.pane "Box" Boxes.black #["Max", "Q3", "Median", "Q1", "Min"]
        (c.boxes.map fun b => #[b.max, b.q3, b.median, b.q1, b.min])] (Hover.boxItems c)

end Page.BoxWhisker
