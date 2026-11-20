/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Bars

namespace Inkproof.Demos.GroupedBars

open Inkproof.Scene Inkproof.Demos.Bars

def green : Color := ⟨51, 187, 85, 255⟩
def purple : Color := ⟨181, 111, 171, 255⟩
def crimson : Color := ⟨187, 17, 51, 255⟩

/-- Bars of three metrics over `groups`, stacked or side by side, all against the value range `range`. -/
def make (groups : Array String) (metrics : List (Color × Array Rat)) (range : Rat × Rat)
    (stacked horizontal : Bool) : Chart :=
  { width := if horizontal then 400 else 800, height := if horizontal then 800 else 400, groups, stacked, horizontal,
    series := metrics.toArray.map fun (fill, vs) => { fill, values := vs.map some, range }, axis := range }

theorem make_groups (groups : Array String) (metrics : List (Color × Array Rat)) (range : Rat × Rat)
    (stacked horizontal : Bool) : (make groups metrics range stacked horizontal).groups = groups := rfl

def four : Array String := #["Group A", "Group B", "Group C", "Group D"]

/-- The four data sets of uPlot's page: several groups of several bars, several groups of one bar, one group of several bars and one bar. -/
def multiGroupMultiBar : List (Color × Array Rat) :=
  [(green, #[1, 2, 3, 10]), (purple, #[3, 2, 1, 10]), (crimson, #[5, 9, 3, 10])]

def multiGroupOneBar : List (Color × Array Rat) := [(green, #[1, 2, 3, 10])]

def oneGroupMultiBar : List (Color × Array Rat) := [(green, #[1]), (purple, #[3]), (crimson, #[5])]

def oneGroupOneBar : List (Color × Array Rat) := [(green, #[1])]

/-- The charts of the page in order, each with the name its element asks for. Where stacked the value range grows to the largest stack. -/
def charts : List (String × Chart) :=
  [("multi-grouped", make four multiGroupMultiBar (0, 10) false false),
   ("multi-stacked", make four multiGroupMultiBar (0, 30) true false),
   ("multi-grouped-horizontal", make four multiGroupMultiBar (0, 10) false true),
   ("multi-stacked-horizontal", make four multiGroupMultiBar (0, 30) true true),
   ("one-bar-grouped", make four multiGroupOneBar (0, 10) false false),
   ("one-bar-stacked", make four multiGroupOneBar (0, 10) true false),
   ("one-group-grouped", make #["Group A"] oneGroupMultiBar (0, 5) false false),
   ("one-group-stacked", make #["Group A"] oneGroupMultiBar (0, 9) true false),
   ("single-grouped", make #["Group A"] oneGroupOneBar (0, 2) false false),
   ("single-stacked", make #["Group A"] oneGroupOneBar (0, 2) true false)]

end Inkproof.Demos.GroupedBars
