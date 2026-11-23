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
  compileLine ⟨⟨0, .flat ⟨128, 128, 128, 255⟩⟩, Axes.strokeHalfWidth, false, some ⟨3, 3⟩, .straight⟩ (projection frame)
    (Segmented.single (Series.ofUnsorted #[(1, some 0), (16, some 0)]))

theorem zero_eq : zero =
    compileLine ⟨⟨0, .flat ⟨128, 128, 128, 255⟩⟩, Axes.strokeHalfWidth, false, some ⟨3, 3⟩, .straight⟩ (projection frame)
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

def white : Color := ⟨255, 255, 255, 255⟩

/-- Green above zero and red below it, changing at once there. -/
def zeroSteps : Shading := (projection frame).stepsY (0, green) [(0, red)]

theorem zeroSteps_eq : zeroSteps = (projection frame).stepsY (0, green) [(0, red)] := rfl

/-- Red at the bottom of the plot, white at zero and green at the top, blended between. -/
def fillGradient : Shading := (projection frame).gradientY (15, green) [(0, white), (-25, red)]

theorem fillGradient_eq : fillGradient = (projection frame).gradientY (15, green) [(0, white), (-25, red)] := rfl

/-- The area under the line, shaded by value, and the line, green above zero and red below. -/
def lineLayer : DisplayList :=
  let g := Segmented.single series
  let p := projection frame
  compileArea ⟨1, fillGradient⟩ 0 p g ++
    compileLine ⟨⟨1, zeroSteps⟩, Axes.strokeHalfWidth, false, none, .straight⟩ p g

theorem lineLayer_eq : lineLayer =
    compileArea ⟨1, fillGradient⟩ 0 (projection frame) (Segmented.single series) ++
      compileLine ⟨⟨1, zeroSteps⟩, Axes.strokeHalfWidth, false, none, .straight⟩ (projection frame) (Segmented.single series) := rfl

/-- The bars, each green above zero and red below it. -/
def splitBars : DisplayList :=
  DisplayList.clip (plot frame) <| (lows.zip highs).zipIdx.map fun ((lo, hi), i) =>
    { bar green (((i + 1 : Nat) : Rat)) lo hi with color := zeroSteps }

theorem splitBars_eq : splitBars =
    DisplayList.clip (plot frame) ((lows.zip highs).zipIdx.map fun ((lo, hi), i) =>
      { bar green (((i + 1 : Nat) : Rat)) lo hi with color := zeroSteps }) := rfl

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
