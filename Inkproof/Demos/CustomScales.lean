/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

The sample points of the Weibull plot are those of uPlot's `custom-scales` demo, Copyright (c) 2022 Leon Sorokin, released under the MIT license.
-/
import Inkproof.Axis
import Inkproof.Core
import Inkproof.Float
import Inkproof.Scene
import Inkproof.Scale
import Inkproof.Demos.Axes
import Inkproof.Demos.Frame
import Inkproof.Demos.Lines

namespace Inkproof.Demos.CustomScales

open Inkproof.Axis Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Demos

/-- The x values: two hundred points a step of `0.4232666594038496` apart, the first of which is not drawn. -/
def times : Array Rat := (Array.range 199).map fun i => ((i + 1 : Nat) : Rat) * 4232666594038496 / 10 ^ 16

theorem times_eq : times = (Array.range 199).map fun i => ((i + 1 : Nat) : Rat) * 4232666594038496 / 10 ^ 16 := rfl

/-- The scale parameter of the fitted Weibull distribution; its shape parameter is 2. -/
def lambda : Float := 30

/-- The fitted distribution's log(-log(1 - y)) at `x`, which is linear in log x. -/
def fittedLevel (x : Float) : Float := 2 * (Float.log x - Float.log lambda)

theorem fittedLevel_eq (x : Float) : fittedLevel x = 2 * (Float.log x - Float.log lambda) := rfl

/-- How far the confidence bounds lie from the fitted level at `x`, in the same units. -/
def spread (x : Float) : Float :=
  let t := Float.log x
  Float.sqrt (9.655999041894857 - 5.226225750783621 * t + 0.768292554803369 * t * t)

theorem spread_eq (x : Float) : spread x =
    Float.sqrt (9.655999041894857 - 5.226225750783621 * Float.log x + 0.768292554803369 * Float.log x * Float.log x) := rfl

/-- The cumulative probability whose log(-log(1 - y)) is `level`. -/
def probability (level : Float) : Float := 1 - Float.exp (-(Float.exp level))

theorem probability_eq (level : Float) : probability level = 1 - Float.exp (-(Float.exp level)) := rfl

/-- The curve at each x, `shift` spreads from the fitted level. -/
def curve (shift : Float) : Array Rat :=
  times.map (Inkproof.Float.Float.onRat fun x => probability (fittedLevel x + shift * spread x))

theorem curve_eq (shift : Float) : curve shift =
    times.map (Inkproof.Float.Float.onRat fun x => probability (fittedLevel x + shift * spread x)) := rfl

def upper : Series Rat Rat := Lines.series times ((curve 1).map some)
def lower : Series Rat Rat := Lines.series times ((curve (-1)).map some)
def fitted : Series Rat Rat := Lines.series times ((curve 0).map some)

theorem upper_eq : upper = Lines.series times ((curve 1).map some) := rfl
theorem lower_eq : lower = Lines.series times ((curve (-1)).map some) := rfl
theorem fitted_eq : fitted = Lines.series times ((curve 0).map some) := rfl

/-- The observations: a time and an estimated probability of failure for each. -/
def observations : List (Rat × Rat) :=
  List.zip
    [20.55094355447392, 52.04910458236307, 34.42486200685348, 28.664408216433806, 12.355661998295018, 12.354621108036648,
     7.338589220539095, 42.54536141616317, 28.76063174314045, 33.2885123658918, 4.32658955751811, 56.15337681424405,
     40.09721423015828, 14.656700267251571, 13.43916254365193, 13.503713583641774, 18.06871208787249, 25.875375316597225,
     22.560659567093843, 17.60115602165231]
    [0.47549019607843135, 0.9166666666666667, 0.7696078431372549, 0.6225490196078431, 0.18137254901960786, 0.13235294117647062,
     0.08333333333333334, 0.8676470588235294, 0.6715686274509804, 0.7205882352941176, 0.03431372549019608, 0.9656862745098039,
     0.8186274509803921, 0.32843137254901966, 0.2303921568627451, 0.27941176470588236, 0.4264705882352941, 0.5735294117647058,
     0.5245098039215687, 0.3774509803921569]

/-- The y scale of a chart: linear, logarithmic, or linear in `log(-log(1 - y))`. -/
inductive Kind where
  | linear
  | log
  | weibull

structure Spec where
  name : String
  xLog : Bool
  y : Kind

def width : Nat := 800
def height : Nat := 800

/-- The least and the greatest value of the three curves. -/
def extent : Rat × Rat :=
  let all := [upper, lower, fitted].flatMap fun s => s.values.toList.filterMap id
  (all.min?.getD 0, all.max?.getD 1)

theorem extent_eq : extent =
    (([upper, lower, fitted].flatMap fun s => s.values.toList.filterMap id).min?.getD 0,
     ([upper, lower, fitted].flatMap fun s => s.values.toList.filterMap id).max?.getD 1) := rfl

/-- The ranges are those of the data, or whole decades on a logarithmic scale. -/
def Spec.frame (s : Spec) : Frame :=
  let xs : Rat × Rat := if s.xLog then (1 / 10, 100) else (times.getD 0 0, times.getD (times.size - 1) 0)
  let ys : Rat × Rat := match s.y with
    | .log => (1 / 1000000, 1)
    | _ => extent
  ⟨match s.y with | .linear => 60 | _ => 80, width - 20, 20, height - 40, xs, ys⟩

theorem Spec.frame_eq (s : Spec) : s.frame =
    (let xs : Rat × Rat := if s.xLog then (1 / 10, 100) else (times.getD 0 0, times.getD (times.size - 1) 0)
     let ys : Rat × Rat := match s.y with
       | .log => (1 / 1000000, 1)
       | _ => extent
     ⟨match s.y with | .linear => 60 | _ => 80, width - 20, 20, height - 40, xs, ys⟩) := rfl

def forward (v : Float) : Float := Float.log (-Float.log (1 - v))

def backward (v : Float) : Float := probability v

theorem forward_eq (v : Float) : forward v = Float.log (-Float.log (1 - v)) := rfl
theorem backward_eq (v : Float) : backward v = probability v := rfl

def Spec.xScale (s : Spec) : Log Float :=
  ⟨Rat.toFloat s.frame.xs.1, Rat.toFloat s.frame.xs.2, Rat.toFloat s.frame.left, Rat.toFloat s.frame.right⟩

def Spec.yScale (s : Spec) : Transformed Float :=
  ⟨Rat.toFloat s.frame.ys.1, Rat.toFloat s.frame.ys.2, Rat.toFloat s.frame.bottom, Rat.toFloat s.frame.top⟩

theorem Spec.xScale_eq (s : Spec) : s.xScale =
    ⟨Rat.toFloat s.frame.xs.1, Rat.toFloat s.frame.xs.2, Rat.toFloat s.frame.left, Rat.toFloat s.frame.right⟩ := rfl

theorem Spec.yScale_eq (s : Spec) : s.yScale =
    ⟨Rat.toFloat s.frame.ys.1, Rat.toFloat s.frame.ys.2, Rat.toFloat s.frame.bottom, Rat.toFloat s.frame.top⟩ := rfl

/-- Data to pixels along the x axis. -/
def Spec.xPixel (s : Spec) : Float → Float :=
  if s.xLog then Log.map Float.log s.xScale else s.frame.xScale.map

theorem Spec.xPixel_eq (s : Spec) : s.xPixel = if s.xLog then Log.map Float.log s.xScale else s.frame.xScale.map := rfl

/-- Data to pixels along the y axis. -/
def Spec.yPixel (s : Spec) : Float → Float :=
  match s.y with
  | .linear => s.frame.yScale.map
  | .log => Log.map Float.log ⟨s.yScale.domainStart, s.yScale.domainEnd, s.yScale.rangeStart, s.yScale.rangeEnd⟩
  | .weibull => Transformed.map forward s.yScale

theorem Spec.yPixel_eq (s : Spec) : s.yPixel =
    match s.y with
    | .linear => s.frame.yScale.map
    | .log => Log.map Float.log ⟨s.yScale.domainStart, s.yScale.domainEnd, s.yScale.rangeStart, s.yScale.rangeEnd⟩
    | .weibull => Transformed.map forward s.yScale := rfl

/-- The data value at a pixel along the y axis of a Weibull chart. -/
def Spec.yValue (s : Spec) : Float → Float := Transformed.unmap forward backward s.yScale

theorem Spec.yValue_eq (s : Spec) : s.yValue = Transformed.unmap forward backward s.yScale := rfl

/-- The probabilities the Weibull axis is labelled at. -/
def weibullTicks : List Float :=
  [0.00001, 0.0001, 0.001, 0.01, 0.1, 0.2, 0.3, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 0.99, 0.999, 0.9999, 0.99999, 0.999999]

/-- Each tick written in exponential notation. -/
def weibullLabels : List String :=
  ["1e-5", "1e-4", "1e-3", "1e-2", "1e-1", "2e-1", "3e-1", "5e-1", "6e-1", "7e-1", "8e-1", "9e-1", "9.5e-1", "9.9e-1",
   "9.99e-1", "9.999e-1", "9.9999e-1", "9.99999e-1"]

def Spec.xLabels (s : Spec) : List String :=
  if s.xLog then tickLabels Axes.spec.locale (logTicks (Rat.toFloat s.frame.xs.1) (Rat.toFloat s.frame.xs.2) Axes.spec.target)
  else Axes.linearLabels (Rat.toFloat s.frame.xs.1) (Rat.toFloat s.frame.xs.2)

theorem Spec.xLabels_eq (s : Spec) : s.xLabels =
    if s.xLog then tickLabels Axes.spec.locale (logTicks (Rat.toFloat s.frame.xs.1) (Rat.toFloat s.frame.xs.2) Axes.spec.target)
    else Axes.linearLabels (Rat.toFloat s.frame.xs.1) (Rat.toFloat s.frame.xs.2) := rfl

def Spec.yLabels (s : Spec) : List String :=
  match s.y with
  | .linear => Axes.linearLabels (Rat.toFloat s.frame.ys.1) (Rat.toFloat s.frame.ys.2)
  | .log => tickLabels Axes.spec.locale (logTicks (Rat.toFloat s.frame.ys.1) (Rat.toFloat s.frame.ys.2) Axes.spec.target)
  | .weibull => weibullLabels

theorem Spec.yLabels_eq (s : Spec) : s.yLabels =
    match s.y with
    | .linear => Axes.linearLabels (Rat.toFloat s.frame.ys.1) (Rat.toFloat s.frame.ys.2)
    | .log => tickLabels Axes.spec.locale (logTicks (Rat.toFloat s.frame.ys.1) (Rat.toFloat s.frame.ys.2) Axes.spec.target)
    | .weibull => weibullLabels := rfl

/-- Every label the axes may show. -/
def Spec.labelTexts (s : Spec) : List String := s.xLabels ++ s.yLabels

theorem Spec.labelTexts_eq (s : Spec) : s.labelTexts = s.xLabels ++ s.yLabels := rfl

def Spec.axes (s : Spec) (measure : String → Float × Float) : List AxisDrawing :=
  let f := s.frame
  [if s.xLog then compileLogAxis .bottom (plot f) s.xScale Axes.spec measure Axes.style
   else compileLinearAxis .bottom (plot f) f.xScale Axes.spec measure Axes.style,
   match s.y with
   | .linear => compileLinearAxis .left (plot f) f.yScale Axes.spec measure Axes.style
   | .log => compileLogAxis .left (plot f) ⟨s.yScale.domainStart, s.yScale.domainEnd, s.yScale.rangeStart, s.yScale.rangeEnd⟩ Axes.spec measure Axes.style
   | .weibull => compilePixelAxis .left (plot f) Axes.style measure Axes.spec.labelGap (weibullTicks.map s.yPixel) weibullLabels]

theorem Spec.axes_eq (s : Spec) (measure : String → Float × Float) : s.axes measure =
    (let f := s.frame
     [if s.xLog then compileLogAxis .bottom (plot f) s.xScale Axes.spec measure Axes.style
      else compileLinearAxis .bottom (plot f) f.xScale Axes.spec measure Axes.style,
      match s.y with
      | .linear => compileLinearAxis .left (plot f) f.yScale Axes.spec measure Axes.style
      | .log => compileLogAxis .left (plot f) ⟨s.yScale.domainStart, s.yScale.domainEnd, s.yScale.rangeStart, s.yScale.rangeEnd⟩ Axes.spec measure Axes.style
      | .weibull => compilePixelAxis .left (plot f) Axes.style measure Axes.spec.labelGap (weibullTicks.map s.yPixel) weibullLabels]) := rfl

def Spec.px (s : Spec) (v : Rat) : Rat := Inkproof.Float.Float.onRat s.xPixel v
def Spec.py (s : Spec) (v : Rat) : Rat := Inkproof.Float.Float.onRat s.yPixel v

theorem Spec.px_eq (s : Spec) (v : Rat) : s.px v = Inkproof.Float.Float.onRat s.xPixel v := rfl
theorem Spec.py_eq (s : Spec) (v : Rat) : s.py v = Inkproof.Float.Float.onRat s.yPixel v := rfl

/-- Data to pixels along both axes. -/
def Spec.projection (s : Spec) : Projection Rat Rat := ⟨s.px, s.py⟩

theorem Spec.projection_eq (s : Spec) : s.projection = ⟨s.px, s.py⟩ := rfl

def blue : Color := ⟨0, 0, 255, 255⟩
def green : Color := ⟨0, 128, 0, 255⟩
def orange : Color := ⟨255, 165, 0, 255⟩
def black : Color := ⟨0, 0, 0, 255⟩
def band : Color := ⟨255, 165, 0, 48⟩

/-- The series as the legend lists them, with their colours. -/
def layers : List (Color × Series Rat Rat) := [(blue, upper), (green, lower), (orange, fitted)]

/-- The names uPlot gives the three series. -/
def names : List String := ["upper_ci", "lower_ci", "weibull_fitted"]

theorem names_length : names.length = layers.length := rfl

/-- The space between the bounds, unless the legend has hidden either, as the fitted curve dashed over it, and a square at each observation. -/
def Spec.chart (s : Spec) (off : Array Bool) (measure : String → Float × Float) : DisplayList :=
  let shown (i : Nat) := !off.getD i false
  (s.axes measure).foldl (· ++ ·.display) #[] ++
    (if shown 0 && shown 1 then
       compileEnvelope ⟨0, .flat band⟩ ⟨fun i => s.px (times.getD i 0), s.py⟩
         (upper.values.zip lower.values |>.map fun (a, z) => do pure (← a, ← z))
     else #[]) ++
    (if shown 2 then
       compileLine ⟨⟨1, .flat orange⟩, 1, false, some ⟨10, 5⟩, .straight⟩ s.projection (Segmented.single fitted)
     else #[]) ++
    (observations.toArray.map fun (x, y) => ⟨3, black, .rect ⟨s.px x, s.py y, s.px x + 5, s.py y + 5⟩⟩)

theorem Spec.chart_eq (s : Spec) (off : Array Bool) (measure : String → Float × Float) : s.chart off measure =
    (let shown (i : Nat) := !off.getD i false
     (s.axes measure).foldl (· ++ ·.display) #[] ++
       (if shown 0 && shown 1 then
          compileEnvelope ⟨0, .flat band⟩ ⟨fun i => s.px (times.getD i 0), s.py⟩
            (upper.values.zip lower.values |>.map fun (a, z) => do pure (← a, ← z))
        else #[]) ++
       (if shown 2 then
          compileLine ⟨⟨1, .flat orange⟩, 1, false, some ⟨10, 5⟩, .straight⟩ s.projection (Segmented.single fitted)
        else #[]) ++
       (observations.toArray.map fun (x, y) => ⟨3, black, .rect ⟨s.px x, s.py y, s.px x + 5, s.py y + 5⟩⟩)) := rfl

def specs : List Spec := [⟨"linear", false, .linear⟩, ⟨"log", true, .log⟩, ⟨"weibull", true, .weibull⟩]

end Inkproof.Demos.CustomScales
