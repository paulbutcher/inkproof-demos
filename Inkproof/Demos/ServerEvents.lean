/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Axis
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Demos.Axes
import Inkproof.Demos.Frame
import Inkproof.Demos.Reduce

namespace Inkproof.Demos.ServerEvents

open Inkproof.Axis Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Demos Inkproof.Demos.Reduce

/-- One sample a minute for just under five weeks, the length of uPlot's server events data. -/
def total : Nat := 55550

/-- The first sample's Unix time, midnight UTC on 2020-01-01. -/
def start : Nat := 1577836800

def columns : Nat := 1060

/-- A fixed hash of the index and series, so that every visit shows the same data. -/
def hash (series i : Nat) : Nat := (i * 2654435761 + series * 40503 + 97) % 4294967296 / 4096

theorem hash_eq (series i : Nat) : hash series i = (i * 2654435761 + series * 40503 + 97) % 4294967296 / 4096 := rfl

/-- Hundredths of a percent: mostly idle, with bursts of load that last a few hundred minutes. -/
def busy (i : Nat) : Int :=
  Int.ofNat (50 + hash 1 i % 100 + if hash 5 (i / 300) % 4 == 0 then hash 2 i % 9000 else 0)

theorem busy_eq (i : Nat) :
    busy i = Int.ofNat (50 + hash 1 i % 100 + if hash 5 (i / 300) % 4 == 0 then hash 2 i % 9000 else 0) := rfl

/-- Memory in use: a slow rise and fall with a little noise. -/
def memory (i : Nat) : Int :=
  Int.ofNat (4000 + (i / 7 % 4000) + hash 3 i % 60)

theorem memory_eq (i : Nat) : memory i = Int.ofNat (4000 + (i / 7 % 4000) + hash 3 i % 60) := rfl

/-- Network traffic in hundredths of a megabyte: quiet, with rare single-sample bursts. -/
def traffic (i : Nat) : Int := Int.ofNat (if hash 4 i % 150 == 0 then 3000 + hash 6 i % 7000 else hash 7 i % 20)

theorem traffic_eq (i : Nat) :
    traffic i = Int.ofNat (if hash 4 i % 150 == 0 then 3000 + hash 6 i % 7000 else hash 7 i % 20) := rfl

def series : List (Nat → Int) := [busy, memory, traffic]

def names : List String := ["CPU", "RAM", "TCP Out"]

def values (f : Nat → Int) : Array Int := (Array.range total).map f

theorem values_size (f : Nat → Int) : (values f).size = total := by simp [values]

def extents (f : Nat → Int) : Array Extent := columnExtents (pyramid (values f)) total columns

theorem extents_eq (f : Nat → Int) : extents f = columnExtents (pyramid (values f)) total columns := rfl

/-- The highest value of a series, read from the data. -/
def highest (f : Nat → Int) : Int := (values f).foldl max 0

theorem highest_eq (f : Nat → Int) : highest f = (values f).foldl max 0 := rfl

/-- The highest value the envelope of a series reaches. -/
def drawnHighest (exts : Array Extent) : Int :=
  (extentColumns exts).foldl (fun m c => match c with | some (_, hi) => max m hi | none => m) 0

theorem drawnHighest_eq (exts : Array Extent) : drawnHighest exts =
    (extentColumns exts).foldl (fun m c => match c with | some (_, hi) => max m hi | none => m) 0 := rfl

def ys : Rat × Rat := (0, 100)

/-- The range of the traffic axis, in megabytes. -/
def rightYs : Rat × Rat := (0, 110)

def panel : Frame := ⟨60, 1120, 40, 560, (start, start + 60 * total), ys, none⟩

/-- Column index and value in hundredths of the axis's unit to pixels, for a series on the axis over `range`. -/
def projectionOn (range : Rat × Rat) : Projection Nat Int :=
  .mk (fun c => (Linear.mk 0 (columns : Rat) panel.left panel.right).map (c : Rat))
    (fun v => (Linear.mk range.1 range.2 panel.bottom panel.top).map ((v : Rat) / 100))

theorem projectionOn_x (range : Rat × Rat) (c : Nat) :
    (projectionOn range).x c = (Linear.mk 0 (columns : Rat) panel.left panel.right).map (c : Rat) := rfl

theorem projectionOn_y (range : Rat × Rat) (v : Int) :
    (projectionOn range).y v = (Linear.mk range.1 range.2 panel.bottom panel.top).map ((v : Rat) / 100) := rfl

/-- The ticks and labels of the percentage axis on the left. -/
def leftTicks : List Float × List String :=
  Axes.spacedTicks (Rat.toFloat ys.1) (Rat.toFloat ys.2) panel.yExtent Axes.ySpacing "%"

theorem leftTicks_eq : leftTicks =
    Axes.spacedTicks (Rat.toFloat ys.1) (Rat.toFloat ys.2) panel.yExtent Axes.ySpacing "%" := rfl

/-- The ticks and labels of the traffic axis on the right. -/
def rightTicks : List Float × List String :=
  Axes.spacedTicks (Rat.toFloat rightYs.1) (Rat.toFloat rightYs.2) panel.yExtent Axes.ySpacing " MB"

theorem rightTicks_eq : rightTicks =
    Axes.spacedTicks (Rat.toFloat rightYs.1) (Rat.toFloat rightYs.2) panel.yExtent Axes.ySpacing " MB" := rfl

/-- The time axis below the plot, the percentage axis on its left and the traffic axis, without a grid, on its right. -/
def axes (measure : String → Float × Float) (theme : Option Theme := none) : List AxisDrawing :=
  let f := { panel with theme }
  let yScale (r : Rat × Rat) : Linear Float := ⟨Rat.toFloat r.1, Rat.toFloat r.2, Rat.toFloat f.bottom, Rat.toFloat f.top⟩
  [f.spacedTimeAxis Axes.numericDates measure,
   compilePixelAxis .left (plot f) f.style measure Axes.spec.labelGap (leftTicks.1.map (yScale ys).map) leftTicks.2,
   compilePixelAxis .right (plot f) { f.style with grid := none } measure Axes.spec.labelGap (rightTicks.1.map (yScale rightYs).map) rightTicks.2]

theorem axes_eq (measure : String → Float × Float) (theme : Option Theme) : axes measure theme =
    let f := { panel with theme }
    let yScale (r : Rat × Rat) : Linear Float := ⟨Rat.toFloat r.1, Rat.toFloat r.2, Rat.toFloat f.bottom, Rat.toFloat f.top⟩
    [f.spacedTimeAxis Axes.numericDates measure,
     compilePixelAxis .left (plot f) f.style measure Axes.spec.labelGap (leftTicks.1.map (yScale ys).map) leftTicks.2,
     compilePixelAxis .right (plot f) { f.style with grid := none } measure Axes.spec.labelGap (rightTicks.1.map (yScale rightYs).map) rightTicks.2] := rfl

/-- Every label the axes may show, for the host to measure. -/
def labelTexts : Array String :=
  (panel.spacedTimeTicks Axes.numericDates).2.1.toArray ++ leftTicks.2.toArray ++ rightTicks.2.toArray

theorem labelTexts_eq : labelTexts =
    (panel.spacedTimeTicks Axes.numericDates).2.1.toArray ++ leftTicks.2.toArray ++ rightTicks.2.toArray := rfl

def colors : List Color := [⟨255, 0, 0, 255⟩, ⟨0, 0, 255, 255⟩, ⟨0, 128, 0, 255⟩]

/-- The axes, and each series as the envelope of its columns, the last on the right axis. -/
def chart (exts : List (Array Extent)) (measure : String → Float × Float) (theme : Option Theme := none) : DisplayList :=
  (axes measure theme).foldl (· ++ ·.display) #[] ++
  (colors.zip exts).zipIdx.toArray.flatMap fun ((color, e), i) =>
    compileEnvelopeOfExtents ⟨i + 1, color⟩ (projectionOn (if i == 2 then rightYs else ys)) e

theorem chart_eq (exts : List (Array Extent)) (measure : String → Float × Float) (theme : Option Theme) : chart exts measure theme =
    (axes measure theme).foldl (· ++ ·.display) #[] ++
    (colors.zip exts).zipIdx.toArray.flatMap fun ((color, e), i) =>
      compileEnvelopeOfExtents ⟨i + 1, color⟩ (projectionOn (if i == 2 then rightYs else ys)) e := rfl

end Inkproof.Demos.ServerEvents
