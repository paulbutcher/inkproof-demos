/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Axis
import Inkproof.Core
import Inkproof.Scale
import Inkproof.Scene
import Inkproof.Demos.Axes
import Inkproof.Demos.Data
import Inkproof.Demos.Frame
import Inkproof.Demos.Pane

namespace Inkproof.Demos.Timeline

open Inkproof.Axis Inkproof.Core Inkproof.Scale Inkproof.Scene Inkproof.Demos Inkproof.Demos.Pane

/-- A state held over `start` to `stop`, written `text`. -/
structure Span where
  start : Rat
  stop : Rat
  text : String
  fill : Color
  stroke : Color

/-- A device's states along the time axis. -/
structure Row where
  name : String
  spans : Array Span

/-- Rows of states against an x axis, each state a labelled bar. A centred label sits in the middle of its bar, as for samples taken at regular intervals; otherwise it starts at the bar's left edge. -/
structure Chart where
  name : String
  width : Nat := 1920
  height : Nat := 300
  xs : Rat × Rat
  time : Bool := true
  rows : Array Row
  centred : Bool := false
  theme : Option Theme := none

/-- The room left of the plot for the row names. -/
def Chart.frame (c : Chart) : Frame := ⟨90, c.width - 20, 20, c.height - 40, c.xs, (0, 1), c.theme⟩

theorem Chart.frame_eq (c : Chart) : c.frame = ⟨90, c.width - 20, 20, c.height - 40, c.xs, (0, 1), c.theme⟩ := rfl

def Chart.xMap (c : Chart) (x : Rat) : Rat := (Linear.mk c.xs.1 c.xs.2 c.frame.left c.frame.right).map x

theorem Chart.xMap_eq (c : Chart) (x : Rat) : c.xMap x = (Linear.mk c.xs.1 c.xs.2 c.frame.left c.frame.right).map x := rfl

/-- The top and bottom of row `i`'s bars: the middle 90% of its band. -/
def Chart.lane (c : Chart) (i : Nat) : Rat × Rat :=
  let band := (c.frame.bottom - c.frame.top) / c.rows.size
  (c.frame.top + band * i + band / 20, c.frame.top + band * (i + 1) - band / 20)

theorem Chart.lane_eq (c : Chart) (i : Nat) : c.lane i =
    let band := (c.frame.bottom - c.frame.top) / c.rows.size
    (c.frame.top + band * i + band / 20, c.frame.top + band * (i + 1) - band / 20) := rfl

/-- The rectangle of span `s` of row `i`. -/
def Chart.rect (c : Chart) (i : Nat) (s : Span) : Rect := ⟨c.xMap s.start, (c.lane i).1, c.xMap s.stop, (c.lane i).2⟩

theorem Chart.rect_eq (c : Chart) (i : Nat) (s : Span) : c.rect i s = ⟨c.xMap s.start, (c.lane i).1, c.xMap s.stop, (c.lane i).2⟩ := rfl

/-- The thickness of a bar's outline, drawn inside it. -/
def outline : Rat := 4

/-- A bar: its fill, then its outline. -/
def Chart.commands (c : Chart) (i : Nat) (s : Span) : DisplayList := outlined 1 s.stroke s.fill outline (c.rect i s)

theorem Chart.commands_eq (c : Chart) (i : Nat) (s : Span) : c.commands i s = outlined 1 s.stroke s.fill outline (c.rect i s) := rfl

/-- Every bar of every row, cut off at the plot's edge. -/
def Chart.shapes (c : Chart) : DisplayList :=
  DisplayList.clip (plot c.frame) (c.rows.zipIdx.flatMap fun (r, i) => r.spans.flatMap (c.commands i))

theorem Chart.shapes_eq (c : Chart) : c.shapes =
    DisplayList.clip (plot c.frame) (c.rows.zipIdx.flatMap fun (r, i) => r.spans.flatMap (c.commands i)) := rfl

/-- The text of each bar, with the pixel it is anchored on: the bar's middle or its left edge, on the middle of its lane. -/
def Chart.texts (c : Chart) : Array (String × Rat × Rat) :=
  c.rows.zipIdx.flatMap fun (r, i) => r.spans.map fun s =>
    let b := c.rect i s
    (s.text, if c.centred then (b.x0 + b.x1) / 2 else b.x0 + outline + 2, ((c.lane i).1 + (c.lane i).2) / 2)

theorem Chart.texts_eq (c : Chart) : c.texts =
    c.rows.zipIdx.flatMap fun (r, i) => r.spans.map fun s =>
      let b := c.rect i s
      (s.text, if c.centred then (b.x0 + b.x1) / 2 else b.x0 + outline + 2, ((c.lane i).1 + (c.lane i).2) / 2) := rfl

/-- About one tick every 120 pixels along a time axis. -/
def Chart.timeTarget (c : Chart) : Nat := c.width / 120

theorem Chart.timeTarget_eq (c : Chart) : c.timeTarget = c.width / 120 := rfl

/-- The axis along the bottom, and the row names down the left. -/
def Chart.axes (c : Chart) (measure : String → Float × Float) : List AxisDrawing :=
  let f := c.frame
  let rows : Categorical String Float := ⟨c.rows.map (·.name), Rat.toFloat f.top, Rat.toFloat f.bottom⟩
  [if c.time then f.timeAxis c.timeTarget measure else compileLinearAxis .bottom (plot f) f.xScale Axes.spec measure f.style,
   compileCategoricalAxis .left (plot f) rows id c.rows.size Axes.spec.labelGap measure { f.style with grid := none }]

theorem Chart.axes_eq (c : Chart) (measure : String → Float × Float) : c.axes measure =
    let f := c.frame
    let rows : Categorical String Float := ⟨c.rows.map (·.name), Rat.toFloat f.top, Rat.toFloat f.bottom⟩
    [if c.time then f.timeAxis c.timeTarget measure else compileLinearAxis .bottom (plot f) f.xScale Axes.spec measure f.style,
     compileCategoricalAxis .left (plot f) rows id c.rows.size Axes.spec.labelGap measure { f.style with grid := none }] := rfl

/-- Every label the axes may show, for the host to measure. -/
def Chart.labelTexts (c : Chart) : Array String :=
  (if c.time then (Axes.timeTicks (Rat.toFloat c.xs.1) (Rat.toFloat c.xs.2) c.timeTarget).2
   else Axes.linearLabels (Rat.toFloat c.xs.1) (Rat.toFloat c.xs.2)).toArray ++ c.rows.map (·.name)

theorem Chart.labelTexts_eq (c : Chart) : c.labelTexts =
    (if c.time then (Axes.timeTicks (Rat.toFloat c.xs.1) (Rat.toFloat c.xs.2) c.timeTarget).2
     else Axes.linearLabels (Rat.toFloat c.xs.1) (Rat.toFloat c.xs.2)).toArray ++ c.rows.map (·.name) := rfl

/-- The chart's commands: the axes, then the bars. -/
def Chart.display (c : Chart) (measure : String → Float × Float) : DisplayList :=
  (c.axes measure).foldl (· ++ ·.display) #[] ++ c.shapes

theorem Chart.display_eq (c : Chart) (measure : String → Float × Float) : c.display measure =
    (c.axes measure).foldl (· ++ ·.display) #[] ++ c.shapes := rfl

/-- How a state is drawn: the colour of its outline and of its fill. -/
abbrev Look := Color × Color

/-- The states of a series that holds each one until the next sample, and the last until `stop`; a missing sample is a gap. -/
def holding (look : String → Look) (stop : Rat) (samples : Array (Rat × Option String)) : Array Span :=
  samples.zipIdx.filterMap fun ((t, v), i) =>
    v.map fun text => ⟨t, (samples[i + 1]?.map (·.1)).getD stop, text, (look text).2, (look text).1⟩

theorem holding_eq (look : String → Look) (stop : Rat) (samples : Array (Rat × Option String)) : holding look stop samples =
    samples.zipIdx.filterMap fun ((t, v), i) =>
      v.map fun text => ⟨t, (samples[i + 1]?.map (·.1)).getD stop, text, (look text).2, (look text).1⟩ := rfl

/-- The states of a series sampled at a regular `step`, each a bar 90% of the step wide centred on its sample. -/
def sampled (look : String → Look) (step : Rat) (samples : Array (Rat × Option String)) : Array Span :=
  samples.filterMap fun (t, v) =>
    v.map fun text => ⟨t - step * 9 / 20, t + step * 9 / 20, text, (look text).2, (look text).1⟩

theorem sampled_eq (look : String → Look) (step : Rat) (samples : Array (Rat × Option String)) : sampled look step samples =
    samples.filterMap fun (t, v) =>
      v.map fun text => ⟨t - step * 9 / 20, t + step * 9 / 20, text, (look text).2, (look text).1⟩ := rfl

/-- A colour and the same colour at the given opacity. -/
def tint (r g b a : UInt8) : Look := (⟨r, g, b, 255⟩, ⟨r, g, b, a⟩)

theorem tint_eq (r g b a : UInt8) : tint r g b a = (⟨r, g, b, 255⟩, ⟨r, g, b, a⟩) := rfl

/-- The states of uPlot's first two charts: red, green, blue and cyan for the first device, red, orange and yellow for the others. -/
def deviceLook (device : Nat) (state : String) : Look :=
  match device, state with
  | _, "0" => tint 255 0 0 51
  | 0, "1" => tint 0 255 0 51
  | 0, "2" => tint 0 0 255 51
  | 0, "3" => tint 0 255 255 51
  | _, "4" => tint 255 165 0 102
  | _, _ => tint 255 255 0 77

theorem deviceLook_zero (device : Nat) : deviceLook device "0" = tint 255 0 0 51 := by
  unfold deviceLook; split <;> first | rfl | contradiction

/-- An hour in seconds. -/
def hour : Rat := 3600

/-- Midnight, 1 January 2026, in Unix time. -/
def now : Rat := 1767225600

/-- Three devices' states at irregular moments over about a day: the times grow by between 30 and 120 minutes, and the states are those of uPlot's page. -/
def spans : Chart :=
  let states : List (Nat × List (Option String)) :=
    [(0, [some "0", some "1", some "2", some "0", some "3"]), (1, [some "4", some "5", some "4", some "5"]),
     (2, [some "4", none, some "4", none, some "4", none, some "4"])]
  let samples (seed : Nat) (vals : List (Option String)) : Array (Rat × Option String) :=
    let gaps := Data.ints seed vals.length 30 120
    let times := (gaps.foldl (fun (acc : Rat × List Rat) (g : Nat) => (acc.1 + 60 * (g : Rat), acc.2 ++ [acc.1 + 60 * (g : Rat)])) (now - 6 * hour, [])).2
    (times.zip vals).toArray
  let rows := states.map fun (d, vals) =>
    (samples (20 + d) vals, d)
  let end_ : Rat := (rows.map fun (ss, _) => (ss.getD (ss.size - 1) (now, none)).1).foldl max now + hour
  { name := "spans", xs := (now - 6 * hour, end_),
    rows := (rows.zip ["Device A", "Device B", "Device C"]).toArray.map fun ((ss, d), name) =>
      ⟨name, holding (deviceLook d) end_ ss⟩ }

/-- Thirty hourly samples of three devices that hold one state, with the odd change and gap, as uPlot's second chart has. -/
def periodic : Chart :=
  let times : Array Rat := (Array.range 30).map fun i => now - ((30 - i : Nat) : Rat) * hour
  let series (state : String) (changes : List (Nat × Option String)) : Array (Rat × Option String) :=
    (times.zipIdx.map fun (t, i) => (t, (changes.lookup i).getD (some state)))
  let rows : List (Nat × String × List (Nat × Option String)) :=
    [(0, "1", [(7, none), (25, some "3")]), (1, "4", [(13, some "0")]), (2, "5", [(15, some "0"), (18, some "0"), (19, none)])]
  { name := "periodic", xs := (now - 30 * hour - hour / 2, now - hour + hour / 2), centred := true,
    rows := (rows.zip ["Device A", "Device B", "Device C"]).toArray.map fun ((d, state, changes), name) =>
      ⟨name, sampled (deviceLook d) hour (series state changes)⟩ }

/-- Letters, a flag and a state that comes and goes against a plain numeric axis, as uPlot's third chart has. -/
def letters : Chart :=
  let look : String → Look
    | "a" => tint 255 0 0 51 | "b" => tint 0 255 0 51 | "c" => tint 0 0 255 51 | "d" => tint 0 255 255 51
    | "e" => tint 255 0 255 51 | "true" => tint 0 255 0 51 | _ => tint 255 0 0 51
  let row (name : String) (times : List Rat) (vals : List (Option String)) : Row :=
    ⟨name, holding look 260 (times.zip vals).toArray⟩
  { name := "letters", xs := (0, 260), time := false,
    rows := #[row "Series 1" [0, 18, 37, 55, 74, 92, 111, 129, 148, 166, 185, 203, 222, 240]
        [some "a", some "a", some "b", some "b", some "b", some "b", some "c", some "a", some "a", some "d", some "d", some "d", some "d", some "d"],
      row "Series 2" [0, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192, 208, 224, 240]
        [none, none, some "e", some "e", some "e", none, none, some "e", none, none, some "e", none, some "e", some "e", some "e", some "e"],
      row "Series 3" [0, 48, 96, 144, 192, 240] [some "true", none, some "false", none, some "true", some "false"]] }

def charts : List Chart := [spans, periodic, letters]

end Inkproof.Demos.Timeline
