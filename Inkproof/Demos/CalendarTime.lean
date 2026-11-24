/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

The data are those of uPlot's `timezones-dst` and `months` demos, Copyright (c) 2022 Leon Sorokin, released under the MIT license.
-/
import RandomSampling
import Inkproof.Axis
import Inkproof.Axis.PosixZone
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Scale
import Inkproof.Demos.Axes
import Inkproof.Demos.Frame
import Inkproof.Demos.Lines
import Inkproof.Demos.Points

namespace Inkproof.Demos.CalendarTime

open Inkproof.Axis Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Demos

/-- A time zone: its name and the seconds east of UTC its clocks are at each instant. -/
structure Zone where
  name : String
  offset : Int → Int

/-- The zone a POSIX rule describes, or why the rule does not parse. -/
def zone (name rule : String) : Except String Zone :=
  match posixZone rule with
  | .ok f => .ok ⟨name, f⟩
  | .error e => .error s!"{name}: {e}"

theorem zone_eq (name rule : String) : zone name rule =
    match posixZone rule with
    | .ok f => .ok ⟨name, f⟩
    | .error e => .error s!"{name}: {e}" := rfl

def utc : Except String Zone := zone "UTC" "UTC0"
def london : Except String Zone := zone "Europe/London" "GMT0BST,M3.5.0/1,M10.5.0"
def chicago : Except String Zone := zone "America/Chicago" "CST6CDT,M3.2.0,M11.1.0"

/-- How the time axis places its ticks: at clock intervals, or on the first of every `n`th month. -/
inductive Ticks where
  | clock
  | months (n : Nat)

/-- A chart of one line over Unix times, labelled in a time zone. -/
structure Spec where
  name : String
  width : Nat
  height : Nat
  zone : Zone
  ticks : Ticks
  times : Array Rat
  values : Array Rat

/-- The ticks of this axis are about 120 pixels apart. -/
def Spec.target (s : Spec) : Nat := s.width / 120

theorem Spec.target_eq (s : Spec) : s.target = s.width / 120 := rfl

def Spec.xs (s : Spec) : Rat × Rat := (s.times.getD 0 0, s.times.getD (s.times.size - 1) 0)

theorem Spec.xs_eq (s : Spec) : s.xs = (s.times.getD 0 0, s.times.getD (s.times.size - 1) 0) := rfl

def Spec.ys (s : Spec) : Rat × Rat :=
  let vs := s.values.toList
  autoRange (1 / 10) (vs.foldl min (vs.headD 0)) (vs.foldl max (vs.headD 0))

theorem Spec.ys_eq (s : Spec) : s.ys =
    autoRange (1 / 10) (s.values.toList.foldl min (s.values.toList.headD 0)) (s.values.toList.foldl max (s.values.toList.headD 0)) := rfl

def Spec.frame (s : Spec) : Frame := Frame.sized s.width s.height s.xs s.ys

theorem Spec.frame_eq (s : Spec) : s.frame = Frame.sized s.width s.height s.xs s.ys := rfl

/-- The distance between labelled ticks that decides what a label shows: the clock step of the ticks, or a month's length for month ticks, so they read as month names. -/
def Spec.step (s : Spec) : Float :=
  match s.ticks with
  | .clock => (durationTicksAt s.zone.offset (Rat.toFloat s.xs.1) (Rat.toFloat s.xs.2) s.target).1
  | .months _ => 31 * 86400

theorem Spec.step_eq (s : Spec) : s.step =
    match s.ticks with
    | .clock => (durationTicksAt s.zone.offset (Rat.toFloat s.xs.1) (Rat.toFloat s.xs.2) s.target).1
    | .months _ => 31 * 86400 := rfl

/-- The instants of the time axis's ticks. -/
def Spec.tickTimes (s : Spec) : List Float :=
  match s.ticks with
  | .clock => (durationTicksAt s.zone.offset (Rat.toFloat s.xs.1) (Rat.toFloat s.xs.2) s.target).2
  | .months n => (monthTicks s.zone.offset n s.xs.1.floor s.xs.2.floor).map Float.ofInt

theorem Spec.tickTimes_eq (s : Spec) : s.tickTimes =
    match s.ticks with
    | .clock => (durationTicksAt s.zone.offset (Rat.toFloat s.xs.1) (Rat.toFloat s.xs.2) s.target).2
    | .months n => (monthTicks s.zone.offset n s.xs.1.floor s.xs.2.floor).map Float.ofInt := rfl

/-- The labels of the ticks, as the zone's clocks read at each. -/
def Spec.tickLabels (s : Spec) : List String :=
  timeTickLabelsAt s.zone.offset Axes.months s.step s.tickTimes

theorem Spec.tickLabels_eq (s : Spec) : s.tickLabels = timeTickLabelsAt s.zone.offset Axes.months s.step s.tickTimes := rfl

/-- Every label an axis may show: the browser measures these before the axes choose among them. -/
def Spec.labelTexts (s : Spec) : List String :=
  s.tickLabels ++ Axes.linearLabels (Rat.toFloat s.ys.1) (Rat.toFloat s.ys.2)

theorem Spec.labelTexts_eq (s : Spec) : s.labelTexts =
    s.tickLabels ++ Axes.linearLabels (Rat.toFloat s.ys.1) (Rat.toFloat s.ys.2) := rfl

/-- The year or day each tick begins, for a second line under its label. -/
def Spec.tickContexts (s : Spec) : List (Option String) :=
  timeTickContextsAt s.zone.offset Axes.months s.step s.tickTimes

theorem Spec.tickContexts_eq (s : Spec) : s.tickContexts = timeTickContextsAt s.zone.offset Axes.months s.step s.tickTimes := rfl

def Spec.axes (s : Spec) (measure : String → Float × Float) : List AxisDrawing :=
  let f := s.frame
  [compilePixelAxis .bottom (plot f) Axes.style measure Axes.spec.labelGap (s.tickTimes.map f.xScale.map) s.tickLabels s.tickContexts,
   compileLinearAxis .left (plot f) f.yScale Axes.spec measure Axes.style]

theorem Spec.axes_eq (s : Spec) (measure : String → Float × Float) : s.axes measure =
    [compilePixelAxis .bottom (plot s.frame) Axes.style measure Axes.spec.labelGap (s.tickTimes.map s.frame.xScale.map) s.tickLabels s.tickContexts,
     compileLinearAxis .left (plot s.frame) s.frame.yScale Axes.spec measure Axes.style] := rfl

def Spec.data (s : Spec) : Core.Series Rat Rat :=
  Lines.series s.times (s.values.map some)

theorem Spec.data_eq (s : Spec) : s.data = Lines.series s.times (s.values.map some) := rfl

def red : Color := ⟨255, 0, 0, 255⟩

/-- The axes, then the line unless the legend has hidden it, with a ring at each sample on the months chart, where samples are far enough apart to show. -/
def Spec.chart (off : Array Bool) (s : Spec) (measure : String → Float × Float) : DisplayList :=
  (s.axes measure).foldl (· ++ ·.display) #[] ++
    (if off.getD 0 false then #[]
     else compileLine ⟨⟨1, red⟩, Axes.strokeHalfWidth, false, none, .straight⟩ (projection s.frame) (Segmented.single s.data) ++
       (if s.name == "months" then Points.rings 1 red (5 / 2) (projection s.frame) s.data else #[]))

theorem Spec.chart_eq (off : Array Bool) (s : Spec) (measure : String → Float × Float) : s.chart off measure =
    (s.axes measure).foldl (· ++ ·.display) #[] ++
      (if off.getD 0 false then #[]
       else compileLine ⟨⟨1, red⟩, Axes.strokeHalfWidth, false, none, .straight⟩ (projection s.frame) (Segmented.single s.data) ++
         (if s.name == "months" then Points.rings 1 red (5 / 2) (projection s.frame) s.data else #[])) := rfl

/-- 2019-01-01T00:00:00Z. -/
def start2019 : Int := 1546300800

/-- Hourly instants through 2019, with a peak at the start of each UTC day. -/
def hours : Array Rat := (Array.range (365 * 24)).map fun (h : Nat) => ((start2019 + 3600 * (h : Int) : Int) : Rat)

theorem hours_eq : hours = (Array.range (365 * 24)).map fun (h : Nat) => ((start2019 + 3600 * (h : Int) : Int) : Rat) := rfl

theorem hours_size : hours.size = 365 * 24 := by simp [hours]

/-- The six days of data from `from`, an instant on the hourly grid. -/
def sliceFrom (from_ : Int) : Array Rat × Array Rat :=
  let i := ((from_ - start2019) / 3600).toNat
  ((hours.extract i (i + 144)), (Array.range 144).map fun k => if (i + k) % 24 == 0 then 1 else 1 / 2)

theorem sliceFrom_times (from_ : Int) : (sliceFrom from_).1 =
    hours.extract (((from_ - start2019) / 3600).toNat) (((from_ - start2019) / 3600).toNat + 144) := rfl

theorem sliceFrom_values (from_ : Int) : (sliceFrom from_).2 =
    (Array.range 144).map fun k => if (((from_ - start2019) / 3600).toNat + k) % 24 == 0 then 1 else 1 / 2 := rfl

theorem sliceFrom_size (from_ : Int) (h : ((from_ - start2019) / 3600).toNat + 144 ≤ 365 * 24) :
    (sliceFrom from_).1.size = 144 := by
  simp [sliceFrom, hours_size]
  omega

/-- The four ranges of the page: the instant each starts, and and whether it is London (rather than Chicago) whose clocks change in it. -/
def ranges : List (String × String × Int × Bool) :=
  [("London's 2019 \"spring forward\" time range", "london-spring", 1553774400, true),
   ("London's 2019 \"fall back\" time range", "london-fall", 1571918400, true),
   ("Chicago's 2019 \"spring forward\" time range", "chicago-spring", 1551960000, false),
   ("Chicago's 2019 \"fall back\" time range", "chicago-fall", 1572523200, false)]

/-- Each range in UTC, in the zone whose clocks change in it, and in the zone whose clocks do not. -/
def dstSpecs : Except String (List Spec) := do
  let (u, l, c) := (← utc, ← london, ← chicago)
  pure <| ranges.flatMap fun (_, key, from_, londonChanges) =>
    let (times, values) := sliceFrom from_
    let (changing, steady) := if londonChanges then (l, c) else (c, l)
    [u, changing, steady].map fun z =>
      { name := s!"{key}-{z.name}", width := 600, height := 300, zone := z, ticks := .clock, times, values }

theorem dstSpecs_eq : dstSpecs = (do
    let (u, l, c) := (← utc, ← london, ← chicago)
    pure <| ranges.flatMap fun (_, key, from_, londonChanges) =>
      let (times, values) := sliceFrom from_
      let (changing, steady) := if londonChanges then (l, c) else (c, l)
      [u, changing, steady].map fun z =>
        { name := s!"{key}-{z.name}", width := 600, height := 300, zone := z, ticks := .clock, times, values : Spec }) := rfl

/-- The month starts of 2017 to 2019, with a random level each and a first of 5. -/
def monthSpec (seed : Nat) : Except String Spec := do
  let times := ((List.range 36).map fun (k : Nat) => ((86400 * monthStartDay (2017 * 12 + (k : Int)) : Int) : Rat)).toArray
  let draws := (RandomSampling.nats (mkStdGen seed) 36 0 10).1
  pure { name := "months", width := 1920, height := 600, zone := ← utc, ticks := .months 1, times,
         values := (draws.map fun (v : Nat) => (v : Rat)).mapIdx fun i v => if i == 0 then 5 else v }

theorem monthSpec_eq (seed : Nat) : monthSpec seed = (do
    let times := ((List.range 36).map fun (k : Nat) => ((86400 * monthStartDay (2017 * 12 + (k : Int)) : Int) : Rat)).toArray
    let draws := (RandomSampling.nats (mkStdGen seed) 36 0 10).1
    pure { name := "months", width := 1920, height := 600, zone := ← utc, ticks := .months 1, times,
           values := (draws.map fun (v : Nat) => (v : Rat)).mapIdx fun i v => if i == 0 then 5 else v : Spec }) := rfl

end Inkproof.Demos.CalendarTime
