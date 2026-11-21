/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Browser

namespace Page.Candlestick

open Inkproof.Web.Host Inkproof.Demos

def run : IO Unit :=
  register "inkproof-chart" fun
    | "gold" => Browser.paneScene Candles.pane Candles.shapes "Gold"
      #[Browser.paneGroup Candles.pane "Candle" Candles.black #["Open", "High", "Low", "Close", "Volume"]
        (Candles.candles.map fun c => #[c.open_, c.high, c.low, c.close, c.volume])]
    | src => throw (IO.userError s!"no chart {src}")

end Page.Candlestick
