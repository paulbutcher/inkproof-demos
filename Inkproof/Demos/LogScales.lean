/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Axis
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Scale
import Inkproof.Demos.Axes
import Inkproof.Demos.Frame
import Inkproof.Demos.Lines
import Inkproof.Demos.LogScales2
import Inkproof.Demos.LogScalesSource

namespace Inkproof.Demos.LogScales

open Inkproof.Axis Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Demos Inkproof.Demos.Lines

def colour (rgb : Nat) : Color := ⟨(rgb / 65536 % 256).toUInt8, (rgb / 256 % 256).toUInt8, (rgb % 256).toUInt8, 255⟩

theorem colour_eq (rgb : Nat) : colour rgb = ⟨(rgb / 65536 % 256).toUInt8, (rgb / 256 % 256).toUInt8, (rgb % 256).toUInt8, 255⟩ := rfl

def times : Array Rat := scaled 1 LogScalesSource.times

/-- One layer per server; the samples a server did not report are missing, not bridged. -/
def layers : List Layer :=
  LogScalesSource.players.toList.zip LogScalesSource.servers |>.map fun (ys, _, rgb) =>
    { data := series times (ys.map fun (y : Int) => if y == 0 then none else some (y : Rat)), color := colour rgb }

/-- The largest sample of any server. -/
def peak : Nat := LogScalesSource.players.foldl (fun m ys => ys.foldl (fun m y => max m y.toNat) m) 1

theorem peak_eq : peak = LogScalesSource.players.foldl (fun m ys => ys.foldl (fun m y => max m y.toNat) m) 1 := rfl

/-- The smallest power of ten that is at least `n`. -/
def decadeAbove (n : Nat) : Nat := 10 ^ (if n ≤ 1 then 0 else (toString (n - 1)).length)

theorem decadeAbove_eq (n : Nat) : decadeAbove n = 10 ^ (if n ≤ 1 then 0 else (toString (n - 1)).length) := rfl

/-- One chart of the page: whether its y axis is logarithmic. -/
structure Spec where
  name : String
  log : Bool

def width : Nat := 1600
def height : Nat := 600

/-- The y range: whole decades on a log scale, as `autoRange` pads the data on a linear one. -/
def Spec.ys (s : Spec) : Rat × Rat :=
  if s.log then (1, (decadeAbove peak : Rat))
  else autoRange (1 / 10 : Rat) 1 (peak : Rat)

theorem Spec.ys_eq (s : Spec) : s.ys =
    if s.log then (1, (decadeAbove peak : Rat)) else autoRange (1 / 10 : Rat) 1 (peak : Rat) := rfl

def Spec.frame (s : Spec) : Frame := ⟨80, width - 20, 20, height - 40, (times.getD 0 0, times.getD (times.size - 1) 0), s.ys⟩

theorem Spec.frame_eq (s : Spec) :
    s.frame = ⟨80, width - 20, 20, height - 40, (times.getD 0 0, times.getD (times.size - 1) 0), s.ys⟩ := rfl

/-- The y axis's tick values and their labels. -/
def Spec.yTicks (s : Spec) : List Float × List String :=
  let (lo, hi) := (Rat.toFloat s.ys.1, Rat.toFloat s.ys.2)
  let ts := if s.log then logTicks lo hi 10 else linearTicks lo hi 10
  (ts, tickLabels .en ts)

theorem Spec.yTicks_eq (s : Spec) : s.yTicks =
    let ts := if s.log then logTicks (Rat.toFloat s.ys.1) (Rat.toFloat s.ys.2) 10 else linearTicks (Rat.toFloat s.ys.1) (Rat.toFloat s.ys.2) 10
    (ts, tickLabels .en ts) := rfl

/-- Data to pixels along the y axis. -/
def Spec.yPixel (s : Spec) : Float → Float :=
  let (lo, hi, start, stop) := (Rat.toFloat s.ys.1, Rat.toFloat s.ys.2, Rat.toFloat s.frame.bottom, Rat.toFloat s.frame.top)
  if s.log then Log.map Float.log10 ⟨lo, hi, start, stop⟩ else (Linear.mk lo hi start stop).map

theorem Spec.yPixel_eq (s : Spec) : s.yPixel =
    if s.log then Log.map Float.log10 ⟨Rat.toFloat s.ys.1, Rat.toFloat s.ys.2, Rat.toFloat s.frame.bottom, Rat.toFloat s.frame.top⟩
    else (Linear.mk (Rat.toFloat s.ys.1) (Rat.toFloat s.ys.2) (Rat.toFloat s.frame.bottom) (Rat.toFloat s.frame.top)).map := rfl

/-- About one tick every 120 pixels along the time axis. -/
def timeTarget : Nat := width / 120

/-- Every label either axis may show: the browser measures these before the axes choose among them. -/
def Spec.labelTexts (s : Spec) : List String :=
  (Axes.timeTicks (Rat.toFloat s.frame.xs.1) (Rat.toFloat s.frame.xs.2) timeTarget).2 ++ s.yTicks.2

theorem Spec.labelTexts_eq (s : Spec) : s.labelTexts =
    (Axes.timeTicks (Rat.toFloat s.frame.xs.1) (Rat.toFloat s.frame.xs.2) timeTarget).2 ++ s.yTicks.2 := rfl

def Spec.axes (s : Spec) (measure : String → Float × Float) : List AxisDrawing :=
  let f := s.frame
  [Axes.time .bottom (plot f) measure timeTarget (Rat.toFloat f.xs.1) (Rat.toFloat f.xs.2) (Rat.toFloat f.left) (Rat.toFloat f.right),
   Axes.withTicks .left (plot f) measure s.yPixel s.yTicks.1 s.yTicks.2]

theorem Spec.axes_eq (s : Spec) (measure : String → Float × Float) : s.axes measure =
    [Axes.time .bottom (plot s.frame) measure timeTarget (Rat.toFloat s.frame.xs.1) (Rat.toFloat s.frame.xs.2) (Rat.toFloat s.frame.left) (Rat.toFloat s.frame.right),
     Axes.withTicks .left (plot s.frame) measure s.yPixel s.yTicks.1 s.yTicks.2] := rfl

/-- Data to pixels: the y axis is the chart's own scale. -/
def Spec.projection (s : Spec) : Projection Rat Rat :=
  let f := s.frame
  ⟨(Linear.mk f.xs.1 f.xs.2 f.left f.right).map, fun v => Axes.plane (s.yPixel (Rat.toFloat v))⟩

theorem Spec.projection_y (s : Spec) (v : Rat) : s.projection.y v = Axes.plane (s.yPixel (Rat.toFloat v)) := rfl

/-- The axes, then every server's line. -/
def Spec.chart (s : Spec) (measure : String → Float × Float) : DisplayList :=
  (s.axes measure).foldl (· ++ ·.display) #[] ++
    layers.foldl (fun out l => out ++ compileLine ⟨⟨1, l.color⟩, 1 / 2, false, none, .straight⟩ s.projection (Segmented.single l.data)) #[]

theorem Spec.chart_eq (s : Spec) (measure : String → Float × Float) : s.chart measure =
    (s.axes measure).foldl (· ++ ·.display) #[] ++
      layers.foldl (fun out l => out ++ compileLine ⟨⟨1, l.color⟩, 1 / 2, false, none, .straight⟩ s.projection (Segmented.single l.data)) #[] := rfl

def specs : List Spec := [⟨"log", true⟩, ⟨"linear", false⟩]

end Inkproof.Demos.LogScales
