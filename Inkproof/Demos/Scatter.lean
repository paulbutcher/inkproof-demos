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
  ⟨60, 1840, 20, 560, Data.extent (all.map (·.x)), Data.extent ((allBubbles false).map (·.y)), none⟩

theorem bubbleFrame_eq : bubbleFrame =
    ⟨60, 1840, 20, 560, Data.extent ((regions.toArray.flatMap (·.bubbles)).map (·.x)), Data.extent ((allBubbles false).map (·.y)), none⟩ := rfl

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

def rightStyle (f : Frame) : AxisStyle := { f.style with grid := none }

theorem rightStyle_eq (f : Frame) : rightStyle f = { f.style with grid := none } := rfl

def bubbleAxes (f : Frame) (measure : String → Float × Float) : List AxisDrawing :=
  axes f measure ++ [compileLinearAxis .right (plot f) (rightScale f) Axes.spec measure (rightStyle f)]

theorem bubbleAxes_eq (f : Frame) (measure : String → Float × Float) :
    bubbleAxes f measure = axes f measure ++ [compileLinearAxis .right (plot f) (rightScale f) Axes.spec measure (rightStyle f)] := rfl

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

/-- The projection of a region's bubbles: against the right axis for a region on it. -/
def regionProjection (f : Frame) (r : Region) : Projection Rat Rat :=
  if r.onRight then .linear ⟨f.xs.1, f.xs.2, f.left, f.right⟩ ⟨rightRange.1, rightRange.2, f.bottom, f.top⟩ else projection f

theorem regionProjection_eq (f : Frame) (r : Region) : regionProjection f r =
    if r.onRight then .linear ⟨f.xs.1, f.xs.2, f.left, f.right⟩ ⟨rightRange.1, rightRange.2, f.bottom, f.top⟩ else projection f := rfl

/-- A region's bubbles against its own y axis, cut off at the plot's edge. -/
def regionDisplay (f : Frame) (r : Region) : DisplayList :=
  DisplayList.clip (plot f) (bubbleDisplay r (regionProjection f r))

theorem regionDisplay_eq (f : Frame) (r : Region) :
    regionDisplay f r = DisplayList.clip (plot f) (bubbleDisplay r (regionProjection f r)) := rfl

/-- The name of the region at index `i`, as its legend entry reads. -/
def regionName (i : Nat) : String := s!"Region {Char.ofNat (65 + i)}"

theorem regionName_eq (i : Nat) : regionName i = s!"Region {Char.ofNat (65 + i)}" := rfl

/-- A bubble's text for the tooltip, the country it stands for. -/
def bubbleLabel (i : Nat) : String := s!"Country {i + 1}"

theorem bubbleLabel_eq (i : Nat) : bubbleLabel i = s!"Country {i + 1}" := rfl

/-- The slope and offset of the map from the right axis's data coordinates to the left axis's, which is how the chart places a series on the right axis. -/
def toLeft (f : Frame) : Affine Float :=
  let slope := Rat.toFloat ((f.ys.2 - f.ys.1) / (rightRange.2 - rightRange.1))
  ⟨slope, Rat.toFloat f.ys.1 - slope * Rat.toFloat rightRange.1⟩

theorem toLeft_eq (f : Frame) : toLeft f =
    ⟨Rat.toFloat ((f.ys.2 - f.ys.1) / (rightRange.2 - rightRange.1)),
     Rat.toFloat f.ys.1 - Rat.toFloat ((f.ys.2 - f.ys.1) / (rightRange.2 - rightRange.1)) * Rat.toFloat rightRange.1⟩ := rfl

/-- The scatter plot's series: ten thousand points with both coordinates in `0..500`, in the colour of their markers. -/
structure Cloud where
  name : String := "Value"
  color : Color
  points : Array (Rat × Rat)

/-- Four clouds of ten thousand points each. -/
def clouds (seed : Nat) : Array Cloud :=
  #[(red, 0), (green, 1), (blue, 2), (orange, 3)].map fun (color, i) =>
    ⟨"Value", color, ((Data.ints (2 * (seed + i)) 10000 0 500).zip (Data.ints (2 * (seed + i) + 1) 10000 0 500)).map fun (x, y) => ((x : Rat), (y : Rat))⟩

theorem clouds_eq (seed : Nat) : clouds seed =
    #[(red, 0), (green, 1), (blue, 2), (orange, 3)].map fun (color, i) =>
      ⟨"Value", color, ((Data.ints (2 * (seed + i)) 10000 0 500).zip (Data.ints (2 * (seed + i) + 1) 10000 0 500)).map fun (x, y) => ((x : Rat), (y : Rat))⟩ := rfl

/-- The scatter chart's frame, 1920 by 600: the ranges of the points of `cs`. -/
def cloudsFrame (cs : Array Cloud) : Frame :=
  let all := cs.flatMap (·.points)
  ⟨60, 1900, 20, 560, Data.extent (all.map (·.1)), Data.extent (all.map (·.2)), none⟩

theorem cloudsFrame_eq (cs : Array Cloud) : cloudsFrame cs =
    let all := cs.flatMap (·.points)
    ⟨60, 1900, 20, 560, Data.extent (all.map (·.1)), Data.extent (all.map (·.2)), none⟩ := rfl

/-- The scatter chart's frame for the clouds of `seed`. -/
def scatterFrame (seed : Nat) : Frame := cloudsFrame (clouds seed)

theorem scatterFrame_eq (seed : Nat) : scatterFrame seed = cloudsFrame (clouds seed) := rfl

/-- A disc of diameter 5 at each point of `c`, cut off at the plot's edge. -/
def cloudDisplay (f : Frame) (c : Cloud) : DisplayList :=
  DisplayList.clip (plot f) (compileScatter ⟨⟨1, c.color⟩, .circle, 5 / 2⟩ (projection f) (Series.ofUnsorted (c.points.map fun (x, y) => (x, some y))))

theorem cloudDisplay_eq (f : Frame) (c : Cloud) : cloudDisplay f c =
    DisplayList.clip (plot f) (compileScatter ⟨⟨1, c.color⟩, .circle, 5 / 2⟩ (projection f) (Series.ofUnsorted (c.points.map fun (x, y) => (x, some y)))) := rfl

/-- The axes, then the cloud of each of `cs` not in `off`. -/
def cloudsChart (cs : Array Cloud) (f : Frame) (off : Array Bool) (measure : String → Float × Float) : DisplayList :=
  axisDisplay f measure ++ cs.zipIdx.flatMap fun (c, i) => if off.getD i false then #[] else cloudDisplay f c

theorem cloudsChart_eq (cs : Array Cloud) (f : Frame) (off : Array Bool) (measure : String → Float × Float) : cloudsChart cs f off measure =
    axisDisplay f measure ++ cs.zipIdx.flatMap fun (c, i) => if off.getD i false then #[] else cloudDisplay f c := rfl

/-- The scatter chart of `seed`: the axes, then a disc at each point of each cloud not in `off`. -/
def scatterChart (seed : Nat) (f : Frame) (off : Array Bool) (measure : String → Float × Float) : DisplayList :=
  cloudsChart (clouds seed) f off measure

theorem scatterChart_eq (seed : Nat) (f : Frame) (off : Array Bool) (measure : String → Float × Float) : scatterChart seed f off measure =
    cloudsChart (clouds seed) f off measure := rfl

end Inkproof.Demos.Scatter
