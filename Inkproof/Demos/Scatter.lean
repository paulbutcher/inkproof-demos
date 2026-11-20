/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Scale
import Inkproof.Demos.Axes
import Inkproof.Demos.Data
import Inkproof.Demos.Frame

namespace Inkproof.Demos.Scatter

open Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Demos

def red : Color := ⟨255, 0, 0, 255⟩
def green : Color := ⟨0, 128, 0, 255⟩
def blue : Color := ⟨0, 0, 255, 255⟩
def orange : Color := ⟨255, 128, 0, 255⟩

/-- A bubble: its coordinates and its size, a population. -/
structure Bubble where
  x : Rat
  y : Rat
  size : Nat

/-- Fifty bubbles with coordinates in `0..500` and sizes in `1..10000`. -/
def bubbles (seed : Nat) : Array Bubble :=
  ((Data.ints (3 * seed) 50 0 500).zip ((Data.ints (3 * seed + 1) 50 0 500).zip (Data.ints (3 * seed + 2) 50 1 10000))).map
    fun (x, y, s) => ⟨x, y, s⟩

theorem bubbles_eq (seed : Nat) : bubbles seed =
    ((Data.ints (3 * seed) 50 0 500).zip ((Data.ints (3 * seed + 1) 50 0 500).zip (Data.ints (3 * seed + 2) 50 1 10000))).map
      fun (x, y, s) => ⟨x, y, s⟩ := rfl

theorem bubbles_size (seed : Nat) : (bubbles seed).size = 50 := by
  simp [bubbles, Data.ints_size]

/-- A series of bubbles, its colour as an outline and as a fill, and whether it is plotted against the right axis. -/
structure Region where
  outline : Color
  fill : Color
  onRight : Bool
  bubbles : Array Bubble

/-- Region A is plotted against the right axis, with its y values negated. -/
def regions : List Region :=
  [⟨red, ⟨255, 179, 179, 255⟩, true, (bubbles 1).map fun b => { b with y := -b.y }⟩,
   ⟨green, ⟨179, 255, 179, 255⟩, false, bubbles 2⟩,
   ⟨blue, ⟨179, 179, 255, 255⟩, false, bubbles 3⟩,
   ⟨orange, ⟨255, 217, 179, 255⟩, false, bubbles 4⟩]

theorem regions_eq : regions =
    [⟨red, ⟨255, 179, 179, 255⟩, true, (bubbles 1).map fun b => { b with y := -b.y }⟩,
     ⟨green, ⟨179, 255, 179, 255⟩, false, bubbles 2⟩,
     ⟨blue, ⟨179, 179, 255, 255⟩, false, bubbles 3⟩,
     ⟨orange, ⟨255, 217, 179, 255⟩, false, bubbles 4⟩] := rfl

def allBubbles (onRight : Bool) : Array Bubble :=
  (regions.filter (·.onRight == onRight)).toArray.flatMap (·.bubbles)

theorem allBubbles_eq (onRight : Bool) :
    allBubbles onRight = (regions.filter (·.onRight == onRight)).toArray.flatMap (·.bubbles) := rfl

/-- The bubble chart's frame: the x range of all bubbles and the y range of those on the left axis. -/
def bubbleFrame : Frame :=
  let all := (regions.toArray.flatMap (·.bubbles))
  ⟨60, 1840, 20, 560, Data.extent (all.map (·.x)), Data.extent ((allBubbles false).map (·.y))⟩

theorem bubbleFrame_eq : bubbleFrame =
    ⟨60, 1840, 20, 560, Data.extent ((regions.toArray.flatMap (·.bubbles)).map (·.x)), Data.extent ((allBubbles false).map (·.y))⟩ := rfl

/-- The range of the right axis. -/
def rightRange : Rat × Rat := Data.extent ((allBubbles true).map (·.y))

theorem rightRange_eq : rightRange = Data.extent ((allBubbles true).map (·.y)) := rfl

/-- The radius in pixels of a bubble whose area is proportional to its size, the largest having diameter 60. -/
def radius (size maxSize : Nat) : Rat :=
  (((30 * Float.sqrt (size.toFloat / maxSize.toFloat) * 1000).round.toUInt64.toNat : Nat) : Rat) / 1000

theorem radius_eq (size maxSize : Nat) :
    radius size maxSize = (((30 * Float.sqrt (size.toFloat / maxSize.toFloat) * 1000).round.toUInt64.toNat : Nat) : Rat) / 1000 := rfl

/-- The largest size of any bubble, which has the largest radius. -/
def maxSize : Nat := regions.foldl (fun m r => r.bubbles.foldl (fun m b => max m b.size) m) 1

theorem maxSize_eq : maxSize = regions.foldl (fun m r => r.bubbles.foldl (fun m b => max m b.size) m) 1 := rfl

/-- The right axis's scale from data to pixels. -/
def rightScale (f : Frame) : Linear Float :=
  ⟨Rat.toFloat rightRange.1, Rat.toFloat rightRange.2, Rat.toFloat f.bottom, Rat.toFloat f.top⟩

theorem rightScale_eq (f : Frame) :
    rightScale f = ⟨Rat.toFloat rightRange.1, Rat.toFloat rightRange.2, Rat.toFloat f.bottom, Rat.toFloat f.top⟩ := rfl

def rightStyle : AxisStyle := { Axes.style with grid := none }

theorem rightStyle_eq : rightStyle = { Axes.style with grid := none } := rfl

def bubbleAxes (f : Frame) (measure : String → Float × Float) : List AxisDrawing :=
  axes f measure ++ [compileLinearAxis .right (plot f) (rightScale f) Axes.spec measure rightStyle]

theorem bubbleAxes_eq (f : Frame) (measure : String → Float × Float) :
    bubbleAxes f measure = axes f measure ++ [compileLinearAxis .right (plot f) (rightScale f) Axes.spec measure rightStyle] := rfl

/-- Every label an axis may show, for the host to measure. -/
def labelTexts (f : Frame) : Array String :=
  texts f ++ (Axes.linearLabels (Rat.toFloat rightRange.1) (Rat.toFloat rightRange.2)).toArray

theorem labelTexts_eq (f : Frame) :
    labelTexts f = texts f ++ (Axes.linearLabels (Rat.toFloat rightRange.1) (Rat.toFloat rightRange.2)).toArray := rfl

/-- A bubble is a ring with a pale fill, or a bare disc where it is too small for a ring. -/
def bubbleDisplay (r : Region) (proj : Projection Rat Rat) : DisplayList :=
  r.bubbles.flatMap fun b =>
    let c : Pt := ⟨proj.x b.x, proj.y b.y⟩
    let rad := radius b.size maxSize
    if 1 < rad then compileRing ⟨2, r.outline, r.fill, rad, 1⟩ c else #[⟨2, r.outline, .marker .circle c rad⟩]

theorem bubbleDisplay_eq (r : Region) (proj : Projection Rat Rat) :
    bubbleDisplay r proj = r.bubbles.flatMap fun b =>
      let c : Pt := ⟨proj.x b.x, proj.y b.y⟩
      let rad := radius b.size maxSize
      if 1 < rad then compileRing ⟨2, r.outline, r.fill, rad, 1⟩ c else #[⟨2, r.outline, .marker .circle c rad⟩] := rfl

/-- The axes, then each region's bubbles against its own y axis, cut off at the plot's edge. -/
def bubbleChart (f : Frame) (measure : String → Float × Float) : DisplayList :=
  (bubbleAxes f measure).foldl (· ++ ·.display) #[] ++
    DisplayList.clip (plot f) (regions.toArray.flatMap fun r =>
      bubbleDisplay r (if r.onRight then .linear ⟨f.xs.1, f.xs.2, f.left, f.right⟩ ⟨rightRange.1, rightRange.2, f.bottom, f.top⟩ else projection f))

theorem bubbleChart_eq (f : Frame) (measure : String → Float × Float) :
    bubbleChart f measure = (bubbleAxes f measure).foldl (· ++ ·.display) #[] ++
      DisplayList.clip (plot f) (regions.toArray.flatMap fun r =>
        bubbleDisplay r (if r.onRight then .linear ⟨f.xs.1, f.xs.2, f.left, f.right⟩ ⟨rightRange.1, rightRange.2, f.bottom, f.top⟩ else projection f)) := rfl

end Inkproof.Demos.Scatter
