/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Demos.Axes
import Inkproof.Demos.Frame
import Inkproof.Demos.Frame
import Inkproof.Demos.Reduce

namespace Inkproof.Demos.ServerEvents

open Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Demos Inkproof.Demos.Reduce

/-- One sample a minute for just under five weeks, the length of uPlot's server events data. -/
def total : Nat := 55550

def columns : Nat := 1120

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

/-- Network traffic as a share of capacity: quiet, with rare single-sample bursts. -/
def traffic (i : Nat) : Int := Int.ofNat (if hash 4 i % 150 == 0 then 3000 + hash 6 i % 7000 else hash 7 i % 20)

theorem traffic_eq (i : Nat) :
    traffic i = Int.ofNat (if hash 4 i % 150 == 0 then 3000 + hash 6 i % 7000 else hash 7 i % 20) := rfl

def series : List (Nat → Int) := [busy, memory, traffic]

def names : List String := ["Busy", "Memory used", "Traffic"]

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

def panel : Frame := ⟨60, 1180, 40, 560, (0, total), ys⟩

/-- Column index and value in hundredths of a percent to pixels. -/
def projection : Projection Nat Int :=
  .mk (fun c => (Linear.mk 0 (columns : Rat) panel.left panel.right).map (c : Rat))
    (fun v => (Linear.mk ys.1 ys.2 panel.bottom panel.top).map ((v : Rat) / 100))

theorem projection_x (c : Nat) :
    projection.x c = (Linear.mk 0 (columns : Rat) panel.left panel.right).map (c : Rat) := rfl

theorem projection_y (v : Int) :
    projection.y v = (Linear.mk ys.1 ys.2 panel.bottom panel.top).map ((v : Rat) / 100) := rfl

def colors : List Color := [⟨255, 0, 0, 255⟩, ⟨0, 128, 0, 255⟩, ⟨0, 0, 255, 255⟩]

/-- The axes, and each series as the envelope of its columns. -/
def chart (exts : List (Array Extent)) (measure : String → Float × Float) : DisplayList :=
  (Demos.axes panel measure).foldl (· ++ ·.display) #[] ++
  (colors.zip exts).zipIdx.toArray.flatMap fun ((color, e), i) =>
    compileEnvelopeOfExtents ⟨i + 1, color⟩ projection e

theorem chart_eq (exts : List (Array Extent)) (measure : String → Float × Float) : chart exts measure =
    (Demos.axes panel measure).foldl (· ++ ·.display) #[] ++
    (colors.zip exts).zipIdx.toArray.flatMap fun ((color, e), i) =>
      compileEnvelopeOfExtents ⟨i + 1, color⟩ projection e := rfl

end Inkproof.Demos.ServerEvents
