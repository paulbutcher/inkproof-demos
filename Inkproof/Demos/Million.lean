/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Core
import Inkproof.Scene
import Inkproof.Demos.Axes
import Inkproof.Demos.Frame
import Inkproof.Demos.Reduce

namespace Inkproof.Demos.Million

open Inkproof.Core Inkproof.Scene Inkproof.Scale Inkproof.Demos Inkproof.Demos.Reduce

/-- The number of samples in the series. -/
def total : Nat := 1000000

/-- The number of pixel columns the series is drawn into. -/
def columns : Nat := 1120

/-- The samples that hold a spike: one sample wide, far above the noise around it. -/
def spikes : Array Nat := #[4000, 83333, 175000, 266667, 358001, 450003, 541234, 633333, 724999, 816667, 908333, 999000]

/-- The noise around zero, a fixed hash of the index so that every visit shows the same data. -/
def noise (i : Nat) : Int := Int.ofNat ((i * 2654435761 + 97) % 4294967296 / 4096 % 401) - 200

def sample (i : Nat) : Int := if spikes.contains i then 1000 else noise i

theorem sample_spike {i : Nat} (h : i ∈ spikes) : sample i = 1000 := by
  simp [sample, h]

theorem noise_bounds (i : Nat) : -200 ≤ noise i ∧ noise i ≤ 200 := by
  unfold noise
  simp only [Int.ofNat_eq_natCast]
  have := Nat.mod_lt ((i * 2654435761 + 97) % 4294967296 / 4096) (by decide : 401 > 0)
  omega

def samples : Array Int := (Array.range total).map sample

theorem samples_size : samples.size = total := by simp [samples]

def pyramid : Pyramid Extent := Reduce.pyramid samples

theorem pyramid_eq : pyramid = Reduce.pyramid samples := rfl

def columnExtents (p : Pyramid Extent) : Array Extent := Reduce.columnExtents p total columns

theorem columnExtents_eq (p : Pyramid Extent) : columnExtents p = Reduce.columnExtents p total columns := rfl

/-- The sample every `total / columns` points that naive decimation keeps for column `c`. -/
def naive (c : Nat) : Int := sample (Pyramid.columnBound 0 total columns c)

theorem naive_eq (c : Nat) : naive c = sample (Pyramid.columnBound 0 total columns c) := rfl

/-- The column that holds sample `i`. -/
def columnOf (i : Nat) : Nat := i * columns / total

theorem columnOf_eq (i : Nat) : columnOf i = i * columns / total := rfl

/-- A spike is shown when the column that holds it reaches its height. -/
def spikeShown (top : Nat → Option Int) (i : Nat) : Bool :=
  match top (columnOf i) with
  | some t => sample i ≤ t
  | none => false

theorem spikeShown_eq (top : Nat → Option Int) (i : Nat) : spikeShown top i = match top (columnOf i) with
    | some t => sample i ≤ t
    | none => false := rfl

def naiveShown (i : Nat) : Bool := spikeShown (fun c => some (naive c)) i

theorem naiveShown_eq (i : Nat) : naiveShown i = spikeShown (fun c => some (naive c)) i := rfl

def inkproofShown (exts : Array Extent) (i : Nat) : Bool := spikeShown (fun c => exts[c]?.bind (·.2.get)) i

theorem inkproofShown_eq (exts : Array Extent) (i : Nat) :
    inkproofShown exts i = spikeShown (fun c => exts[c]?.bind (·.2.get)) i := rfl

def shownCount (shown : Nat → Bool) : Nat := (spikes.filter shown).size

theorem shownCount_eq (shown : Nat → Bool) : shownCount shown = (spikes.filter shown).size := rfl

def ys : Rat × Rat := (-300, 1100)

def naivePanel : Frame := ⟨60, 1180, 40, 340, (0, total), ys⟩
def inkproofPanel : Frame := ⟨60, 1180, 420, 720, (0, total), ys⟩

/-- Column index and sample value to pixels in `p`. -/
def projection (p : Frame) : Projection Nat Int :=
  .mk (fun c => (Linear.mk 0 (columns : Rat) p.left p.right).map (c : Rat))
    (fun v => (Linear.mk ys.1 ys.2 p.bottom p.top).map (v : Rat))

theorem projection_x (p : Frame) (c : Nat) :
    (projection p).x c = (Linear.mk 0 (columns : Rat) p.left p.right).map (c : Rat) := rfl

theorem projection_y (p : Frame) (v : Int) :
    (projection p).y v = (Linear.mk ys.1 ys.2 p.bottom p.top).map (v : Rat) := rfl

def ink : Color := ⟨30, 30, 30, 255⟩
def spikeColor : Color := ⟨220, 0, 0, 255⟩

/-- Each true spike, as a ring in the column that holds it. -/
def spikeMarks (p : Frame) : DisplayList :=
  compileScatter ⟨⟨2, spikeColor⟩, .circle, 6⟩ (projection p)
    (Series.ofUnsorted (spikes.map fun i => (columnOf i, some (sample i))))

theorem spikeMarks_eq (p : Frame) : spikeMarks p = compileScatter ⟨⟨2, spikeColor⟩, .circle, 6⟩ (projection p)
    (Series.ofUnsorted (spikes.map fun i => (columnOf i, some (sample i)))) := rfl

/-- The naive panel: one sample per column, joined by a line. -/
def naiveChart (measure : String → Float × Float) : DisplayList :=
  (axes naivePanel measure).foldl (· ++ ·.display) #[] ++
  compileLine ⟨⟨1, ink⟩, 1, true, none, .straight⟩ (projection naivePanel)
    (Segmented.single (Series.ofUnsorted ((Array.range columns).map fun c => (c, some (naive c))))) ++
  spikeMarks naivePanel

theorem naiveChart_eq (measure : String → Float × Float) : naiveChart measure =
    (axes naivePanel measure).foldl (· ++ ·.display) #[] ++
    compileLine ⟨⟨1, ink⟩, 1, true, none, .straight⟩ (projection naivePanel)
      (Segmented.single (Series.ofUnsorted ((Array.range columns).map fun c => (c, some (naive c))))) ++
    spikeMarks naivePanel := rfl

/-- The Inkproof panel: the lowest and highest sample of each column, as an envelope. -/
def inkproofChart (exts : Array Extent) (measure : String → Float × Float) : DisplayList :=
  (axes inkproofPanel measure).foldl (· ++ ·.display) #[] ++
  compileEnvelopeOfExtents ⟨1, ink⟩ (projection inkproofPanel) exts ++
  spikeMarks inkproofPanel

theorem inkproofChart_eq (exts : Array Extent) (measure : String → Float × Float) : inkproofChart exts measure =
    (axes inkproofPanel measure).foldl (· ++ ·.display) #[] ++
    compileEnvelopeOfExtents ⟨1, ink⟩ (projection inkproofPanel) exts ++
    spikeMarks inkproofPanel := rfl

end Inkproof.Demos.Million
