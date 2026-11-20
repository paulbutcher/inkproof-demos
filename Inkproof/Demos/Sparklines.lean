/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Scale
import Inkproof.Demos.Data
import Inkproof.Demos.Frame
import Inkproof.Demos.StocksSource

namespace Inkproof.Demos.Sparklines

open Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Demos StocksSource

def width : Nat := 150
def height : Nat := 30

/-- The canvas colour behind each sparkline. -/
def pink : Color := ⟨255, 192, 203, 255⟩

/-- A stock's volumes, or its closing prices in dollars, in the order of the records. -/
def values (s : Stock) (close : Bool) : Array Rat :=
  if close then s.closeCents.map fun (c : Nat) => (c : Rat) / 100 else s.volume.map fun (v : Nat) => (v : Rat)

theorem values_eq (s : Stock) (close : Bool) :
    values s close = if close then s.closeCents.map fun (c : Nat) => (c : Rat) / 100 else s.volume.map fun (v : Nat) => (v : Rat) := rfl

/-- The `i`-th value is plotted at `x = i`. -/
def series (vals : Array Rat) : Series Rat Rat :=
  Series.ofUnsorted (vals.mapIdx fun i v => ((i : Rat), some v))

theorem series_eq (vals : Array Rat) : series vals = Series.ofUnsorted (vals.mapIdx fun i v => ((i : Rat), some v)) := rfl

/-- The whole canvas shows the x range of the records and the y range of the values padded by a tenth. -/
def frame (vals : Array Rat) : Frame :=
  let (lo, hi) := Data.extent vals
  ⟨0, width, 0, height, (0, ((vals.size - 1 : Nat) : Rat)), autoRange (1 / 10) lo hi⟩

theorem frame_eq (vals : Array Rat) : frame vals =
    ⟨0, width, 0, height, (0, ((vals.size - 1 : Nat) : Rat)), autoRange (1 / 10) (Data.extent vals).1 (Data.extent vals).2⟩ := rfl

/-- The series filled down to the bottom of the canvas and stroked on top, with no axes. -/
def chart (vals : Array Rat) : DisplayList :=
  let f := frame vals
  let g := Segmented.single (series vals)
  compileArea ⟨0, ⟨179, 229, 252, 255⟩⟩ f.ys.1 (projection f) g ++
    compileLine ⟨⟨1, ⟨3, 169, 244, 255⟩⟩, 1 / 2, false, none, .straight⟩ (projection f) g

theorem chart_eq (vals : Array Rat) : chart vals =
    compileArea ⟨0, ⟨179, 229, 252, 255⟩⟩ (frame vals).ys.1 (projection (frame vals)) (Segmented.single (series vals)) ++
      compileLine ⟨⟨1, ⟨3, 169, 244, 255⟩⟩, 1 / 2, false, none, .straight⟩ (projection (frame vals)) (Segmented.single (series vals)) := rfl

/-- The sparkline named `name`, which is a stock's symbol and either `volume` or `close`, joined by a hyphen. -/
def named? (name : String) : Option (Array Rat) :=
  match name.splitOn "-" with
  | [symbol, kind] =>
    (stocks.find? (·.symbol == symbol)).bind fun s =>
      if kind == "close" then some (values s true) else if kind == "volume" then some (values s false) else none
  | _ => none

theorem named?_eq (name : String) : named? name =
    match name.splitOn "-" with
    | [symbol, kind] =>
      (stocks.find? (·.symbol == symbol)).bind fun s =>
        if kind == "close" then some (values s true) else if kind == "volume" then some (values s false) else none
    | _ => none := rfl

end Inkproof.Demos.Sparklines
