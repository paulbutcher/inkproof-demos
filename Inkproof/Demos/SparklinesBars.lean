/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Demos.Frame

namespace Inkproof.Demos.SparklinesBars

open Inkproof.Core Inkproof.Scene Inkproof.Demos

def width : Nat := 800
def height : Nat := 400

/-- The line's values at `x = 1, …, 16`. -/
def ys : Array Int := #[5, -5, 0, 1, 5, 9, 10, 15, 5, -10, -15, -20, -20, -5, 0, 5]

theorem ys_size : ys.size = 16 := rfl

/-- The bars float between five below the line and five above it. -/
def lows : Array Int := ys.map (· - 5)
def highs : Array Int := ys.map (· + 5)

theorem lows_eq : lows = ys.map (· - 5) := rfl

theorem highs_eq : highs = ys.map (· + 5) := rfl

/-- The whole canvas shows the data's extent on both axes. -/
def frame : Frame := ⟨0, width, 0, height, (1, 16), (-25, 15)⟩

theorem frame_eq : frame = ⟨0, width, 0, height, (1, 16), (-25, 15)⟩ := rfl

def green : Color := ⟨0, 128, 0, 255⟩
def red : Color := ⟨255, 0, 0, 255⟩

def series : Series Rat Rat :=
  Series.ofUnsorted (ys.mapIdx fun i v => (((i + 1 : Nat) : Rat), some ((v : Int) : Rat)))

theorem series_eq : series = Series.ofUnsorted (ys.mapIdx fun i v => (((i + 1 : Nat) : Rat), some ((v : Int) : Rat))) := rfl

/-- The dashed line at zero, over the whole width. -/
def zero : DisplayList :=
  compileLine ⟨⟨0, .flat ⟨128, 128, 128, 255⟩⟩, 1 / 2, false, some ⟨3, 3⟩, .straight⟩ (projection frame)
    (Segmented.single (Series.ofUnsorted #[(1, some 0), (16, some 0)]))

theorem zero_eq : zero =
    compileLine ⟨⟨0, .flat ⟨128, 128, 128, 255⟩⟩, 1 / 2, false, some ⟨3, 3⟩, .straight⟩ (projection frame)
      (Segmented.single (Series.ofUnsorted #[(1, some 0), (16, some 0)])) := rfl

/-- The bar of the point at `x`, 60% of the space between points wide. -/
def bar (color : Color) (x : Rat) (lo hi : Int) : Command :=
  let p := projection frame
  let w := (p.x 2 - p.x 1) * 3 / 10
  ⟨2, color, .rect ⟨p.x x - w, p.y (lo : Rat), p.x x + w, p.y (hi : Rat)⟩⟩

theorem bar_eq (color : Color) (x : Rat) (lo hi : Int) :
    bar color x lo hi = ⟨2, color, .rect ⟨(projection frame).x x - ((projection frame).x 2 - (projection frame).x 1) * 3 / 10,
      (projection frame).y (lo : Rat), (projection frame).x x + ((projection frame).x 2 - (projection frame).x 1) * 3 / 10,
      (projection frame).y (hi : Rat)⟩⟩ := rfl

/-- The part of a display list above and below the line at zero, in the colours `up` and `down`. -/
def split (up down : Color) (dl : DisplayList) : DisplayList :=
  let z := (projection frame).y 0
  DisplayList.clip ⟨0, 0, width, z⟩ (dl.map fun c => { c with color := up }) ++
    DisplayList.clip ⟨0, z, width, height⟩ (dl.map fun c => { c with color := down })

theorem split_eq (up down : Color) (dl : DisplayList) :
    split up down dl =
      DisplayList.clip ⟨0, 0, width, (projection frame).y 0⟩ (dl.map fun c => { c with color := up }) ++
        DisplayList.clip ⟨0, (projection frame).y 0, width, height⟩ (dl.map fun c => { c with color := down }) := rfl

/-- The line and the area under it, green above zero and red below, clipped to the plot. -/
def lineLayer : DisplayList :=
  let g := Segmented.single series
  let p := projection frame
  split ⟨0, 128, 0, 90⟩ ⟨255, 0, 0, 90⟩ (compileArea ⟨1, .flat ⟨0, 0, 0, 0⟩⟩ 0 p g) ++
    split green red (compileLine ⟨⟨1, .flat ⟨0, 0, 0, 0⟩⟩, 1 / 2, false, none, .straight⟩ p g)

theorem lineLayer_eq : lineLayer =
    split ⟨0, 128, 0, 90⟩ ⟨255, 0, 0, 90⟩ (compileArea ⟨1, .flat ⟨0, 0, 0, 0⟩⟩ 0 (projection frame) (Segmented.single series)) ++
      split green red (compileLine ⟨⟨1, .flat ⟨0, 0, 0, 0⟩⟩, 1 / 2, false, none, .straight⟩ (projection frame) (Segmented.single series)) := rfl

/-- The bars, each green above zero and red below it. -/
def splitBars : DisplayList :=
  DisplayList.clip (plot frame) <| split green red <| (lows.zip highs).zipIdx.map fun ((lo, hi), i) =>
    bar green (((i + 1 : Nat) : Rat)) lo hi

theorem splitBars_eq : splitBars =
    DisplayList.clip (plot frame) (split green red ((lows.zip highs).zipIdx.map fun ((lo, hi), i) =>
      bar green (((i + 1 : Nat) : Rat)) lo hi)) := rfl

/-- The bars, each red when it reaches below zero and green otherwise. -/
def coloredBars : DisplayList :=
  DisplayList.clip (plot frame) <| (lows.zip highs).zipIdx.map fun ((lo, hi), i) =>
    bar (if lo < 0 || hi < 0 then red else green) (((i + 1 : Nat) : Rat)) lo hi

theorem coloredBars_eq : coloredBars =
    DisplayList.clip (plot frame) ((lows.zip highs).zipIdx.map fun ((lo, hi), i) =>
      bar (if lo < 0 || hi < 0 then red else green) (((i + 1 : Nat) : Rat)) lo hi) := rfl

def chartSplit : DisplayList := zero ++ lineLayer ++ splitBars

theorem chartSplit_eq : chartSplit = zero ++ lineLayer ++ splitBars := rfl

def chartColored : DisplayList := zero ++ lineLayer ++ coloredBars

theorem chartColored_eq : chartColored = zero ++ lineLayer ++ coloredBars := rfl

end Inkproof.Demos.SparklinesBars
