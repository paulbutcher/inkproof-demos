/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Web.Item
import Inkproof.Demos.Bars
import Inkproof.Demos.Boxes
import Inkproof.Demos.Candles
import Inkproof.Demos.Timeline
import Inkproof.Demos.Zoom

namespace Inkproof.Demos.Hover

open Inkproof.Scene Inkproof.Scale Inkproof.Demos

/-- The item of the pixel rectangle `r` of the plot of `f`, in the data coordinates of `f`. -/
def item (f : Frame) (r : Rect) (description : Option String := none) (series : Option Nat := none) : Web.Item :=
  let x := (Linear.mk f.left f.right f.xs.1 f.xs.2).map
  let y := (Linear.mk f.bottom f.top f.ys.1 f.ys.2).map
  { x0 := Rat.toFloat (x r.x0), x1 := Rat.toFloat (x r.x1), y0 := Rat.toFloat (y r.y0), y1 := Rat.toFloat (y r.y1), description, series }

theorem item_eq (f : Frame) (r : Rect) (description : Option String) (series : Option Nat) : item f r description series =
    { x0 := Rat.toFloat ((Linear.mk f.left f.right f.xs.1 f.xs.2).map r.x0), x1 := Rat.toFloat ((Linear.mk f.left f.right f.xs.1 f.xs.2).map r.x1),
      y0 := Rat.toFloat ((Linear.mk f.bottom f.top f.ys.1 f.ys.2).map r.y0), y1 := Rat.toFloat ((Linear.mk f.bottom f.top f.ys.1 f.ys.2).map r.y1),
      description, series } := rfl

/-- A value as the pages write it. -/
def number (v : Rat) : String := (Axes.numbers.format (Rat.toFloat v)).getD ""

theorem number_eq (v : Rat) : number v = (Axes.numbers.format (Rat.toFloat v)).getD "" := rfl

/-- The frame whose data coordinates are the chart's pixels, with y negated so it still grows upwards, for charts whose shapes are in pixels. -/
def plane (p : Rect) (theme : Option Theme := none) : Frame := ⟨p.x0, p.x1, p.y0, p.y1, (p.x0, p.x1), (-p.y1, -p.y0), theme⟩

theorem plane_eq (p : Rect) (theme : Option Theme) : plane p theme = ⟨p.x0, p.x1, p.y0, p.y1, (p.x0, p.x1), (-p.y1, -p.y0), theme⟩ := rfl

/-- The column of each box, which describes the box's statistics. -/
def boxItems (c : Boxes.Chart) : Array Web.Item :=
  c.boxes.zipIdx.map fun (b, i) =>
    item c.pane.frame (c.pane.column i)
      (some s!"{b.name}\nMax: {number b.max}\nQ3: {number b.q3}\nMedian: {number b.median}\nQ1: {number b.q1}\nMin: {number b.min}")

theorem boxItems_eq (c : Boxes.Chart) : boxItems c = c.boxes.zipIdx.map fun (b, i) =>
    item c.pane.frame (c.pane.column i)
      (some s!"{b.name}\nMax: {number b.max}\nQ3: {number b.q3}\nMedian: {number b.median}\nQ1: {number b.q1}\nMin: {number b.min}") := rfl

/-- The column of each candle, which describes the day's prices and volume. -/
def candleItems : Array Web.Item :=
  Candles.candles.zipIdx.map fun (c, i) =>
    item Candles.pane.frame (Candles.pane.column i)
      (some s!"{Candles.pane.groups.getD i ""}\nOpen: {number c.open_}\nHigh: {number c.high}\nLow: {number c.low}\nClose: {number c.close}\nVolume: {number c.volume}")

theorem candleItems_eq : candleItems = Candles.candles.zipIdx.map fun (c, i) =>
    item Candles.pane.frame (Candles.pane.column i)
      (some s!"{Candles.pane.groups.getD i ""}\nOpen: {number c.open_}\nHigh: {number c.high}\nLow: {number c.low}\nClose: {number c.close}\nVolume: {number c.volume}") := rfl

/-- Each bar of a chart that stands for data, naming its group, its series and its value. -/
def barItems (c : Bars.Chart) : Array Web.Item :=
  c.bars.filterMap fun b => b.source.map fun (g, s, v) =>
    item (plane c.plot c.theme) b.rect
      (some s!"{c.groups.getD g ""}\n{(c.series[s]?.map (·.name)).getD ""}: {number v}") (some s)

theorem barItems_eq (c : Bars.Chart) : barItems c = c.bars.filterMap fun b => b.source.map fun (g, s, v) =>
    item (plane c.plot c.theme) b.rect
      (some s!"{c.groups.getD g ""}\n{(c.series[s]?.map (·.name)).getD ""}: {number v}") (some s) := rfl

/-- Each state of a timeline, naming its row. -/
def spanItems (c : Timeline.Chart) : Array Web.Item :=
  c.rows.zipIdx.flatMap fun (r, i) =>
    r.spans.map fun s => item c.frame (c.rect i s) (some s!"{r.name}: {s.text}") (some i)

theorem spanItems_eq (c : Timeline.Chart) : spanItems c = c.rows.zipIdx.flatMap fun (r, i) =>
    r.spans.map fun s => item c.frame (c.rect i s) (some s!"{r.name}: {s.text}") (some i) := rfl

/-- The label box of each note of `c` in view in `f`, with what the note says. -/
def markItems (c : Zoom.Chart) (f : Frame) (measure : String → Float × Float) : Array Web.Item :=
  (c.marks.filter fun m => Zoom.Mark.shown f m && f.left ≤ (Zoom.Mark.columns f m).1 && (Zoom.Mark.columns f m).1 ≤ f.right).toArray.filterMap fun m =>
    (Zoom.Mark.box f measure m).map fun b => item f b (some m.description)

theorem markItems_eq (c : Zoom.Chart) (f : Frame) (measure : String → Float × Float) : markItems c f measure =
    (c.marks.filter fun m => Zoom.Mark.shown f m && f.left ≤ (Zoom.Mark.columns f m).1 && (Zoom.Mark.columns f m).1 ≤ f.right).toArray.filterMap fun m =>
      (Zoom.Mark.box f measure m).map fun b => item f b (some m.description) := rfl

end Inkproof.Demos.Hover
