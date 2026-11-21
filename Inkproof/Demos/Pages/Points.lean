/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos
import Inkproof.Demos.Browser

namespace Page.Points

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.Points

def run : IO Unit :=
  register "inkproof-chart" fun
    | "multi" => Browser.frameScene multi.width multi.height multi.frame (multiChart multi.frame)
    | "single" => Browser.frameScene single.width single.height single.frame (singleChart single.frame · true)
    | "dense" => Browser.frameScene singleDense.width singleDense.height singleDense.frame (singleChart singleDense.frame · false)
    | "sparse" => Browser.frameScene sparseFrame.width sparseFrame.height sparseFrame.frame (sparseChart sparseFrame.frame)
    | src => throw (IO.userError s!"no chart {src}")

end Page.Points
