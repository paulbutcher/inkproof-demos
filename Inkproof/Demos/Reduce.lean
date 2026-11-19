/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Demos.Axes

namespace Inkproof.Demos.Reduce

open Inkproof.Core Inkproof.Scene

/-- What a pyramid node holds: the lowest and highest sample of the range it covers. -/
abbrev Extent := Minimum Int × Maximum Int

def extent (v : Int) : Extent := (⟨some v⟩, ⟨some v⟩)

theorem extent_eq (v : Int) : extent v = (⟨some v⟩, ⟨some v⟩) := rfl

/-- The pyramid of the extents of `samples`. -/
def pyramid (samples : Array Int) : Pyramid Extent := Pyramid.ofMeasure 2 (by omega) extent samples

theorem pyramid_eq (samples : Array Int) : pyramid samples = Pyramid.ofMeasure 2 (by omega) extent samples := rfl

/-- The samples per tile of the pyramid's stored levels. -/
def tileSize : Nat := 1024

/-- The extent of each of `cols` equal columns of the `total` samples, cut from the pyramid. -/
def columnExtents (p : Pyramid Extent) (total cols : Nat) : Array Extent :=
  Pyramid.columns tileSize (by decide) p.branching p.levels.size (p.tile tileSize) 0 total cols

theorem columnExtents_eq (p : Pyramid Extent) (total cols : Nat) : columnExtents p total cols =
    Pyramid.columns tileSize (by decide) p.branching p.levels.size (p.tile tileSize) 0 total cols := rfl

/-- Plot rectangle of one panel. -/
structure Panel where
  left : Rat
  right : Rat
  top : Rat
  bottom : Rat

def plot (p : Panel) : Rect := ⟨p.left, p.top, p.right, p.bottom⟩

theorem plot_eq (p : Panel) : plot p = ⟨p.left, p.top, p.right, p.bottom⟩ := rfl

end Inkproof.Demos.Reduce
