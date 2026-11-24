/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

The sparse series is the data of uPlot's points demo, Copyright (c) 2022 Leon Sorokin, released under the MIT license.
-/
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Demos.Frame
import Inkproof.Demos.Data

namespace Inkproof.Demos.Points

open Inkproof.Core Inkproof.Scene Inkproof.Demos

/-- The samples of uPlot's sparse series that are present, as sample number and value; every other sample of the 2761 is missing. -/
def sparse : Array (Nat × Nat) := #[
  (33, 60), (235, 61), (241, 60), (259, 61), (265, 60), (296, 61), (302, 60), (308, 59), (314, 60), (321, 59), 
  (345, 58), (381, 57), (540, 56), (546, 57), (552, 56), (558, 57), (570, 56), (656, 55), (705, 56), (710, 55), 
  (887, 54), (1065, 53), (1070, 54), (1119, 55), (1162, 56), (1180, 55), (1186, 56), (1198, 57), (1247, 56), 
  (1253, 57), (1296, 56), (1308, 57), (1315, 58), (1375, 57), (1394, 58), (1400, 59), (1406, 58), (1430, 57), 
  (1436, 58), (1455, 59), (1485, 60), (1497, 61), (1551, 62), (1595, 61), (1613, 60), (1644, 59), (1650, 60), 
  (1656, 59), (1662, 60), (1687, 59), (1704, 60), (1717, 59), (1723, 60), (1735, 59), (1784, 58), (1790, 59), 
  (1912, 58), (1948, 57), (1954, 58), (1960, 57), (1997, 56), (2113, 55), (2119, 56), (2125, 55), (2161, 54), 
  (2167, 53), (2186, 52), (2197, 51), (2222, 52), (2229, 54), (2235, 55), (2241, 56), (2302, 57), (2387, 58), 
  (2405, 59), (2423, 60), (2435, 61), (2459, 60), (2465, 61), (2496, 62), (2502, 61), (2508, 62), (2514, 61), 
  (2520, 62), (2539, 63), (2563, 64), (2569, 63), (2575, 64), (2581, 63), (2630, 62), (2649, 61), (2661, 62), 
  (2686, 63), (2716, 64), (2728, 63), (2741, 62)]

/-- The values of walk `seed`, `n` of them, as the points `(1, v₁), …, (n, vₙ)` with the samples listed in `missing` absent. -/
def walk (seed n : Nat) (start : Rat) (missing : List Nat := []) : Series Rat Rat :=
  Series.ofUnsorted ((Data.walk seed n start 0 100).zipIdx.map fun (v, i) =>
    (((i + 1 : Nat) : Rat), if missing.contains i then none else some v))

theorem walk_eq (seed n : Nat) (start : Rat) (missing : List Nat) :
    walk seed n start missing =
      Series.ofUnsorted ((Data.walk seed n start 0 100).zipIdx.map fun (v, i) =>
        (((i + 1 : Nat) : Rat), if missing.contains i then none else some v)) := rfl

/-- A hollow marker at each present sample: `outline` out to `r`, with white over it out to `r - 1`. -/
def rings (layer : Nat) (outline : Color) (r : Rat) (proj : Projection Rat Rat) (s : Series Rat Rat) : DisplayList :=
  s.points.flatMap fun (x, v) =>
    match v with
    | some y => compileRing ⟨layer, outline, ⟨255, 255, 255, 255⟩, r, 1⟩ ⟨proj.x x, proj.y y⟩
    | none => #[]

theorem rings_eq (layer : Nat) (outline : Color) (r : Rat) (proj : Projection Rat Rat) (s : Series Rat Rat) :
    rings layer outline r proj s = s.points.flatMap fun (x, v) =>
      match v with
      | some y => compileRing ⟨layer, outline, ⟨255, 255, 255, 255⟩, r, 1⟩ ⟨proj.x x, proj.y y⟩
      | none => #[] := rfl

def green : Color := ⟨0, 128, 0, 255⟩
def red : Color := ⟨255, 0, 0, 255⟩
def blue : Color := ⟨0, 0, 255, 255⟩
def orange : Color := ⟨255, 165, 0, 255⟩
def magenta : Color := ⟨255, 0, 255, 255⟩

/-- A chart's pixel size and its frame. -/
structure Panel where
  width : Nat
  height : Nat
  frame : Frame

/-- A `width` by `height` panel showing the data ranges `xs` and `ys`. -/
def Panel.sized (width height : Nat) (xs ys : Rat × Rat) : Panel :=
  ⟨width, height, .sized width height xs ys⟩

theorem Panel.sized_eq (width height : Nat) (xs ys : Rat × Rat) :
    Panel.sized width height xs ys = ⟨width, height, .sized width height xs ys⟩ := rfl

/-- The four series of the first chart: 200 samples each, the fourth with six missing. -/
def multi : Panel := .sized 1920 600 (1, 200) (30, 80)

def seriesA : Series Rat Rat := walk 1 200 50
def seriesB : Series Rat Rat := walk 2 200 50
def seriesC : Series Rat Rat := walk 3 200 50
def seriesD : Series Rat Rat := walk 4 200 75 [1, 100, 102, 130, 133, 198]

/-- The shapes of each of the four series of the first chart, in series order; the legend hides a series by leaving its shapes out. -/
def multiParts (f : Frame) : Array DisplayList :=
  let proj := projection f
  let line (c : Color) (s : Series Rat Rat) := compileLine ⟨⟨2, c⟩, Axes.strokeHalfWidth, false, none, .straight⟩ proj (Segmented.single s)
  #[line green seriesA,
    compileArea ⟨0, .flat ⟨255, 0, 0, 26⟩⟩ f.ys.1 proj (Segmented.single seriesB) ++ line red seriesB ++
      compileScatter ⟨⟨3, red⟩, .circle, 5/2⟩ proj seriesB,
    rings 3 blue (5/2) proj seriesC,
    line orange seriesD ++ compileIsolated ⟨⟨3, orange⟩, .circle, 5/2⟩ proj (Segmented.single seriesD)]

theorem multiParts_eq (f : Frame) :
    multiParts f =
      #[compileLine ⟨⟨2, green⟩, Axes.strokeHalfWidth, false, none, .straight⟩ (projection f) (Segmented.single seriesA),
        compileArea ⟨0, .flat ⟨255, 0, 0, 26⟩⟩ f.ys.1 (projection f) (Segmented.single seriesB) ++
          compileLine ⟨⟨2, red⟩, Axes.strokeHalfWidth, false, none, .straight⟩ (projection f) (Segmented.single seriesB) ++
          compileScatter ⟨⟨3, red⟩, .circle, 5/2⟩ (projection f) seriesB,
        rings 3 blue (5/2) (projection f) seriesC,
        compileLine ⟨⟨2, orange⟩, Axes.strokeHalfWidth, false, none, .straight⟩ (projection f) (Segmented.single seriesD) ++
          compileIsolated ⟨⟨3, orange⟩, .circle, 5/2⟩ (projection f) (Segmented.single seriesD)] := rfl

/-- A walk of 180 samples, drawn with a marker at every sample. -/
def single : Panel := .sized 1920 300 (1, 180) (40, 65)

/-- The same walk over an x range that squeezes it into a third of the width, where markers would overlap; the page turns them off by hand, as `singleChart`'s `markers` argument. -/
def singleDense : Panel := .sized 1920 300 (-400, 180) (40, 65)

def singleSeries : Series Rat Rat := walk 5 180 50

/-- The walk's line, with a ring at each sample if `markers`. -/
def singleParts (markers : Bool) (f : Frame) : Array DisplayList :=
  #[compileLine ⟨⟨2, green⟩, Axes.strokeHalfWidth, false, none, .straight⟩ (projection f) (Segmented.single singleSeries) ++
    if markers then rings 3 green (5/2) (projection f) singleSeries else #[]]

theorem singleParts_eq (markers : Bool) (f : Frame) :
    singleParts markers f =
      #[compileLine ⟨⟨2, green⟩, Axes.strokeHalfWidth, false, none, .straight⟩ (projection f) (Segmented.single singleSeries) ++
        if markers then rings 3 green (5/2) (projection f) singleSeries else #[]] := rfl

/-- The sparse series: 96 samples among 2761, each drawn as a marker because the samples around it are missing. -/
def sparseFrame : Panel := .sized 1200 300 (1, 2761) (50, 65)

def sparseSeries : Series Rat Rat :=
  Series.ofUnsorted (sparse.map fun (i, v) => ((i : Rat), some (v : Rat)))

def sparseParts (f : Frame) : Array DisplayList :=
  #[compileScatter ⟨⟨3, magenta⟩, .circle, 5/2⟩ (projection f) sparseSeries]

theorem sparseParts_eq (f : Frame) :
    sparseParts f = #[compileScatter ⟨⟨3, magenta⟩, .circle, 5/2⟩ (projection f) sparseSeries] := rfl

end Inkproof.Demos.Points
