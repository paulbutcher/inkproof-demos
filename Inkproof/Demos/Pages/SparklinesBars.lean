/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.SparklinesBars

open Inkproof.Web.Host Inkproof.Demos Inkproof.Demos.SparklinesBars

def run : IO Unit :=
  Browser.registerPixels fun src px => match src with
    | "split" => Browser.sidedScene px #[] [] (fun _ => []) (fun _ => chartSplit) background
    | "colored" => Browser.sidedScene px #[] [] (fun _ => []) (fun _ => chartColored) background
    | src => throw (IO.userError s!"no chart {src}")

end Page.SparklinesBars
