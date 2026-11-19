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

namespace Inkproof.Demos.LogScales2

open Inkproof.Axis Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Demos

/-- `n * 10^e`, exactly. -/
def ofDecimal (n : Int) (e : Int) : Rat := if e < 0 then (n : Rat) / 10 ^ (-e).toNat else (n : Rat) * 10 ^ e.toNat

theorem ofDecimal_eq (n e : Int) : ofDecimal n e = if e < 0 then (n : Rat) / 10 ^ (-e).toNat else (n : Rat) * 10 ^ e.toNat := rfl

/-- The values `i * 10^m` for `m` in `-6..7` and `i` in `1..9`, then `10^8`: nine to a decade, on a linear scale all but the last decade crowd the bottom. -/
def decades : List Rat :=
  (List.range 14).flatMap (fun (k : Nat) => (List.range 9).map fun (i : Nat) => ofDecimal ((i : Int) + 1) ((k : Int) - 6)) ++ [ofDecimal 1 8]

theorem decades_length : decades.length = 127 := by simp [decades]; rfl

/-- The points `(x₀, v₀), (x₀ + 1, v₁), …` of `ys`, a value the log scale cannot place (zero or negative) being missing. -/
def points (x0 : Nat) (positive : Bool) (ys : List (Option Rat)) : Series Rat Rat :=
  Series.ofUnsorted (ys.zipIdx.toArray.map fun (y, i) =>
    (((x0 + i : Nat) : Rat), y.bind fun v => if positive && v ≤ 0 then none else some v))

theorem points_eq (x0 : Nat) (positive : Bool) (ys : List (Option Rat)) :
    points x0 positive ys = Series.ofUnsorted (ys.zipIdx.toArray.map fun (y, i) =>
      (((x0 + i : Nat) : Rat), y.bind fun v => if positive && v ≤ 0 then none else some v)) := rfl

/-- Thirteen values from `-100` to `100` through zero, ten times over in an order drawn from a fixed seed. -/
def signed : List Rat :=
  let values : List Rat := [-100, -10, -1, -1/10, -1/100, -1/1000, 0, 1/1000, 1/100, 1/10, 1, 10, 100]
  ((List.range 130).foldl (fun (acc : List Rat × StdGen) _ =>
    let (draw, g) := randNat acc.2 0 12
    (values.getD (min draw 12) 0 :: acc.1, g)) ([], mkStdGen 7)).1

theorem signed_eq : signed =
    ((List.range 130).foldl (fun (acc : List Rat × StdGen) _ =>
      let (draw, g) := randNat acc.2 0 12
      ((([-100, -10, -1, -1/10, -1/100, -1/1000, 0, 1/1000, 1/100, 1/10, 1, 10, 100] : List Rat).getD (min draw 12) 0) :: acc.1, g))
      ([], mkStdGen 7)).1 := rfl

/-- How a chart's y axis is scaled and labelled. -/
inductive Kind where
  | linear
  | log10
  | log2
deriving DecidableEq

/-- One chart of the page. -/
structure Spec where
  name : String
  width : Nat
  height : Nat
  kind : Kind
  xs : Rat × Rat
  ys : Rat × Rat
  stroke : Color
  fill : Option Color
  data : Series Rat Rat

def Spec.frame (s : Spec) : Frame := ⟨90, s.width - 20, 20, s.height - 40, s.xs, s.ys⟩

theorem Spec.frame_eq (s : Spec) : s.frame = ⟨90, s.width - 20, 20, s.height - 40, s.xs, s.ys⟩ := rfl

def floorInt (x : Float) : Int := x.floor.toInt64.toInt

theorem floorInt_eq (x : Float) : floorInt x = x.floor.toInt64.toInt := rfl

def sups : List Char := ['⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹']

/-- `2` to the power `e`, written with superscript digits. -/
def powerOfTwo (e : Int) : String :=
  "2" ++ (if e < 0 then "⁻" else "") ++ String.ofList ((toString e.natAbs).toList.map fun c => sups.getD (c.toNat - '0'.toNat) c)

theorem powerOfTwo_eq (e : Int) : powerOfTwo e =
    "2" ++ (if e < 0 then "⁻" else "") ++ String.ofList ((toString e.natAbs).toList.map fun c => sups.getD (c.toNat - '0'.toNat) c) := rfl

/-- `1e+8` for `e = 8`, as JavaScript's `toExponential` writes it. -/
def powerOfTen (e : Int) : String := "1e" ++ (if e < 0 then "" else "+") ++ toString e

theorem powerOfTen_eq (e : Int) : powerOfTen e = "1e" ++ (if e < 0 then "" else "+") ++ toString e := rfl

/-- The exponents to tick, every `stride`th when there would be more than 12. -/
def exponents (lg : Float → Float) (lo hi : Float) : List Int :=
  letI : IntCast Float := ⟨Float.ofInt⟩
  letI : NatCast Float := ⟨Nat.toFloat⟩
  let stride := max 1 (((lg hi - lg lo) / 12).ceil.toUInt64.toNat)
  decadeExponents floorInt lg lo hi stride

theorem exponents_eq (lg : Float → Float) (lo hi : Float) :
    exponents lg lo hi =
      letI : IntCast Float := ⟨Float.ofInt⟩
      letI : NatCast Float := ⟨Nat.toFloat⟩
      decadeExponents floorInt lg lo hi (max 1 (((lg hi - lg lo) / 12).ceil.toUInt64.toNat)) := rfl

/-- The y axis's tick values and their labels. -/
def Spec.yTicks (s : Spec) : List Float × List String :=
  let (lo, hi) := (Rat.toFloat s.ys.1, Rat.toFloat s.ys.2)
  match s.kind with
  | .linear => let ts := linearTicks lo hi 10; (ts, tickLabels .en ts)
  | .log10 =>
    let es := exponents Float.log10 lo hi
    (es.map fun e => Float.pow 10 (Float.ofInt e), es.map powerOfTen)
  | .log2 =>
    let es := exponents Float.log2 lo hi
    (es.map fun e => Float.pow 2 (Float.ofInt e), es.map powerOfTwo)

theorem Spec.yTicks_eq (s : Spec) : s.yTicks =
    match s.kind with
    | .linear => (linearTicks (Rat.toFloat s.ys.1) (Rat.toFloat s.ys.2) 10, tickLabels .en (linearTicks (Rat.toFloat s.ys.1) (Rat.toFloat s.ys.2) 10))
    | .log10 => ((exponents Float.log10 (Rat.toFloat s.ys.1) (Rat.toFloat s.ys.2)).map (fun e => Float.pow 10 (Float.ofInt e)),
        (exponents Float.log10 (Rat.toFloat s.ys.1) (Rat.toFloat s.ys.2)).map powerOfTen)
    | .log2 => ((exponents Float.log2 (Rat.toFloat s.ys.1) (Rat.toFloat s.ys.2)).map (fun e => Float.pow 2 (Float.ofInt e)),
        (exponents Float.log2 (Rat.toFloat s.ys.1) (Rat.toFloat s.ys.2)).map powerOfTwo) := by
  unfold Spec.yTicks; cases s.kind <;> rfl

/-- Data to pixels along the y axis. -/
def Spec.yPixel (s : Spec) : Float → Float :=
  let (lo, hi, start, stop) := (Rat.toFloat s.ys.1, Rat.toFloat s.ys.2, Rat.toFloat s.frame.bottom, Rat.toFloat s.frame.top)
  match s.kind with
  | .linear => (Linear.mk lo hi start stop).map
  | .log10 => Log.map Float.log10 ⟨lo, hi, start, stop⟩
  | .log2 => Log.map Float.log2 ⟨lo, hi, start, stop⟩

theorem Spec.yPixel_eq (s : Spec) : s.yPixel =
    match s.kind with
    | .linear => (Linear.mk (Rat.toFloat s.ys.1) (Rat.toFloat s.ys.2) (Rat.toFloat s.frame.bottom) (Rat.toFloat s.frame.top)).map
    | .log10 => Log.map Float.log10 ⟨Rat.toFloat s.ys.1, Rat.toFloat s.ys.2, Rat.toFloat s.frame.bottom, Rat.toFloat s.frame.top⟩
    | .log2 => Log.map Float.log2 ⟨Rat.toFloat s.ys.1, Rat.toFloat s.ys.2, Rat.toFloat s.frame.bottom, Rat.toFloat s.frame.top⟩ := by
  unfold Spec.yPixel; cases s.kind <;> rfl

/-- Every label either axis may show: the browser measures these before the axes choose among them. -/
def Spec.labelTexts (s : Spec) : List String :=
  Axes.linearLabels (Rat.toFloat s.xs.1) (Rat.toFloat s.xs.2) ++ s.yTicks.2

theorem Spec.labelTexts_eq (s : Spec) :
    s.labelTexts = Axes.linearLabels (Rat.toFloat s.xs.1) (Rat.toFloat s.xs.2) ++ s.yTicks.2 := rfl

def Spec.axes (s : Spec) (measure : String → Float × Float) : List AxisDrawing :=
  let f := s.frame
  [compileLinearAxis .bottom (plot f) f.xScale Axes.spec measure Axes.style,
   compilePixelAxis .left (plot f) Axes.style measure Axes.spec.labelGap (s.yTicks.1.map s.yPixel) s.yTicks.2]

theorem Spec.axes_eq (s : Spec) (measure : String → Float × Float) :
    s.axes measure =
      [compileLinearAxis .bottom (plot s.frame) s.frame.xScale Axes.spec measure Axes.style,
       compilePixelAxis .left (plot s.frame) Axes.style measure Axes.spec.labelGap (s.yTicks.1.map s.yPixel) s.yTicks.2] := rfl

/-- Data to pixels: the y axis is the chart's own scale. -/
def Spec.projection (s : Spec) : Projection Rat Rat :=
  let f := s.frame
  ⟨(Linear.mk f.xs.1 f.xs.2 f.left f.right).map, fun v => (Inkproof.Float.Float.toRat (s.yPixel (Rat.toFloat v))).getD 0⟩

theorem Spec.projection_x (s : Spec) (x : Rat) :
    s.projection.x x = (Linear.mk s.frame.xs.1 s.frame.xs.2 s.frame.left s.frame.right).map x := rfl

theorem Spec.projection_y (s : Spec) (v : Rat) : s.projection.y v = (Inkproof.Float.Float.toRat (s.yPixel (Rat.toFloat v))).getD 0 := rfl

/-- The axes, then the series filled down to the bottom of the plot if it has a fill, and stroked. -/
def Spec.chart (s : Spec) (measure : String → Float × Float) : DisplayList :=
  let g := Segmented.single s.data
  (s.axes measure).foldl (· ++ ·.display) #[] ++
  (match s.fill with
    | some c => compileArea ⟨0, c⟩ s.ys.1 s.projection g
    | none => #[]) ++
  compileLine ⟨⟨1, s.stroke⟩, 1, false, none, .straight⟩ s.projection g

theorem Spec.chart_eq (s : Spec) (measure : String → Float × Float) :
    s.chart measure =
      (s.axes measure).foldl (· ++ ·.display) #[] ++
      (match s.fill with
        | some c => compileArea ⟨0, c⟩ s.ys.1 s.projection (Segmented.single s.data)
        | none => #[]) ++
      compileLine ⟨⟨1, s.stroke⟩, 1, false, none, .straight⟩ s.projection (Segmented.single s.data) := rfl

def magenta : Color := ⟨255, 0, 255, 255⟩
def orange : Color := ⟨255, 165, 0, 255⟩
def purple : Color := ⟨128, 0, 128, 255⟩
def blue : Color := ⟨0, 0, 255, 255⟩
def red : Color := ⟨255, 0, 0, 255⟩

private def wide (name : String) (kind : Kind) (ys : Rat × Rat) (stroke : Color) (fill : Option Color) (data : Series Rat Rat) : Spec :=
  ⟨name, 1200, 450, kind, (1, 127), ys, stroke, fill, data⟩

/-- Charts of `Log Scales 2`, in the order of the page. -/
def specs : List Spec :=
  let ys := decades.map some
  let all := points 1 false ys
  [wide "linear" .linear (0, ofDecimal 11 7) magenta none all,
   wide "log10" .log10 (ofDecimal 1 (-6), ofDecimal 1 8) orange none all,
   wide "log2" .log2 (1 / 2 ^ 20, 2 ^ 27) purple none all,
   ⟨"signed", 1200, 450, .log10, (0, 129), (ofDecimal 1 (-3), 100), blue, some ⟨0, 0, 255, 26⟩, points 0 true (signed.map some)⟩,
   ⟨"skip10", 800, 300, .log10, (0, 1), (ofDecimal 1 (-14), ofDecimal 1 14), red, none,
     points 0 false [some (ofDecimal 1 (-14)), some (ofDecimal 1 14)]⟩,
   ⟨"skip2", 800, 300, .log2, (0, 1), (1 / 2 ^ 10, 2 ^ 20), blue, none,
     points 0 false [some (1 / 2 ^ 10), some (2 ^ 20)]⟩,
   ⟨"nulls", 800, 400, .log10, (0, 2), (100, 1000), red, none,
     points 0 false [some 100, some 200, some 1000]⟩,
   ⟨"tiny", 800, 600, .log10, (0, 1), (ofDecimal 3 (-16), ofDecimal 5 (-13)), red, some ⟨255, 0, 0, 26⟩,
     points 0 false [some (ofDecimal 31992 (-20)), some (ofDecimal 49047 (-17))]⟩]

end Inkproof.Demos.LogScales2
