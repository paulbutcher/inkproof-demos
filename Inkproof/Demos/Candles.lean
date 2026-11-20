/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Core.Calendar
import Inkproof.Demos.Data
import Inkproof.Demos.GoldSource
import Inkproof.Demos.Pane

namespace Inkproof.Demos.Candles

open Inkproof.Scene Inkproof.Demos Inkproof.Demos.Pane

/-- A day's prices in dollars and the volume traded. -/
structure Candle where
  time : Nat
  open_ : Rat
  high : Rat
  low : Rat
  close : Rat
  volume : Rat

/-- The year's days, with a volume drawn at random in uPlot's page and from a fixed hash here. The source's high and low are widened to hold the open and close, which one day's record exceeds. -/
def candles : Array Candle :=
  let volumes := Data.ints 11 GoldSource.times.size 10 250
  (GoldSource.times.zipIdx.map fun (t, i) =>
    let (o, h, l, c) := ((GoldSource.opens.getD i 0 : Nat), GoldSource.highs.getD i 0, GoldSource.lows.getD i 0, GoldSource.closes.getD i 0)
    ⟨t, (o : Rat) / 100, ((max h (max o c) : Nat) : Rat) / 100, ((min l (min o c) : Nat) : Rat) / 100, (c : Rat) / 100, (volumes.getD i 0 : Nat)⟩)

theorem candles_eq : candles =
    let volumes := Data.ints 11 GoldSource.times.size 10 250
    (GoldSource.times.zipIdx.map fun (t, i) =>
      let (o, h, l, c) := ((GoldSource.opens.getD i 0 : Nat), GoldSource.highs.getD i 0, GoldSource.lows.getD i 0, GoldSource.closes.getD i 0)
      ⟨t, (o : Rat) / 100, ((max h (max o c) : Nat) : Rat) / 100, ((min l (min o c) : Nat) : Rat) / 100, (c : Rat) / 100, (volumes.getD i 0 : Nat)⟩) := rfl

/-- The prices on the left axis, and the volume on the right against a range of 0 to 2000, so the volume bars stay low. -/
def pane : Pane :=
  let prices := candles.flatMap fun c => #[c.low, c.high]
  { width := 1920, height := 600, groups := candles.map (fun c => Core.Calendar.isoDate ((c.time / 86400 : Nat) : Int)),
    left := Scale.autoRange (1 / 10) (prices.foldl min (prices.getD 0 0)) (prices.foldl max (prices.getD 0 0)),
    right := some (0, 2000), below := 80 }

theorem pane_eq : pane =
    let prices := candles.flatMap fun c => #[c.low, c.high]
    { width := 1920, height := 600, groups := candles.map (fun c => Core.Calendar.isoDate ((c.time / 86400 : Nat) : Int)),
      left := Scale.autoRange (1 / 10) (prices.foldl min (prices.getD 0 0)) (prices.foldl max (prices.getD 0 0)),
      right := some (0, 2000), below := 80 } := rfl

/-- The width of a candle's body: at most 20 pixels, with 2 between neighbours. -/
def bodyWidth : Rat := min 20 (pane.categories.bandwidth - 2)

theorem bodyWidth_eq : bodyWidth = min 20 (pane.categories.bandwidth - 2) := rfl

/-- The 2 pixel wick from the high to the low of candle `i`. -/
def wick (i : Nat) (c : Candle) : Rect :=
  ⟨pane.centre i - 1, pane.row pane.left c.high, pane.centre i + 1, pane.row pane.left c.low⟩

theorem wick_eq (i : Nat) (c : Candle) :
    wick i c = ⟨pane.centre i - 1, pane.row pane.left c.high, pane.centre i + 1, pane.row pane.left c.low⟩ := rfl

/-- The body from the open to the close of candle `i`, outline included. -/
def body (i : Nat) (c : Candle) : Rect :=
  let (a, b) := (pane.row pane.left c.open_, pane.row pane.left c.close)
  ⟨pane.centre i - bodyWidth / 2, min a b, pane.centre i + bodyWidth / 2, max a b⟩

theorem body_eq (i : Nat) (c : Candle) : body i c =
    let (a, b) := (pane.row pane.left c.open_, pane.row pane.left c.close)
    ⟨pane.centre i - bodyWidth / 2, min a b, pane.centre i + bodyWidth / 2, max a b⟩ := rfl

/-- The volume bar under candle `i`, standing on the bottom of the plot. -/
def volumeBar (i : Nat) (c : Candle) : Rect :=
  ⟨pane.centre i - bodyWidth / 2, pane.row (pane.right.getD (0, 1)) c.volume, pane.centre i + bodyWidth / 2, pane.plot.y1⟩

theorem volumeBar_eq (i : Nat) (c : Candle) : volumeBar i c =
    ⟨pane.centre i - bodyWidth / 2, pane.row (pane.right.getD (0, 1)) c.volume, pane.centre i + bodyWidth / 2, pane.plot.y1⟩ := rfl

def bearish : Color := ⟨229, 66, 69, 255⟩
def bullish : Color := ⟨74, 182, 80, 255⟩
def black : Color := ⟨0, 0, 0, 255⟩

/-- A black wick and outline, a red body where the price fell and a green one where it rose, and a volume bar in the body's colour. -/
def commands (i : Nat) (c : Candle) : DisplayList :=
  let fill := if c.close < c.open_ then bearish else bullish
  let b := body i c
  #[⟨1, black, .rect (wick i c)⟩, ⟨1, black, .rect b⟩, ⟨1, fill, .rect ⟨b.x0 + 1, b.y0 + 1, b.x1 - 1, b.y1 - 1⟩⟩,
    ⟨1, fill, .rect (volumeBar i c)⟩]

theorem commands_eq (i : Nat) (c : Candle) : commands i c =
    let fill := if c.close < c.open_ then bearish else bullish
    let b := body i c
    #[⟨1, black, .rect (wick i c)⟩, ⟨1, black, .rect b⟩, ⟨1, fill, .rect ⟨b.x0 + 1, b.y0 + 1, b.x1 - 1, b.y1 - 1⟩⟩,
      ⟨1, fill, .rect (volumeBar i c)⟩] := rfl

/-- Every candle and its volume bar. -/
def shapes : DisplayList := candles.zipIdx.flatMap fun (c, i) => commands i c

theorem shapes_eq : shapes = candles.zipIdx.flatMap fun (c, i) => commands i c := rfl

end Inkproof.Demos.Candles
