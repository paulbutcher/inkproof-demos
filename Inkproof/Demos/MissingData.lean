/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Lines
import Inkproof.Demos.MissingDataSource

namespace Inkproof.Demos.MissingData

open Inkproof.Core Inkproof.Scene Inkproof.Demos Inkproof.Demos.Lines Inkproof.Demos.MissingDataSource

def times : Array Rat := scaled 1 MissingDataSource.times

/-- CPU and memory use as percentages, and bytes sent as megabytes, with the samples that uPlot's page blanks. -/
def cpuSeries : Series Rat Rat := series times (withGaps [35, 36, 37, 38, 39, 40] (scaled 100 cpu))
def ramSeries : Series Rat Rat := series times (withGaps [79, 80, 91, 125, 126, 127] (scaled 100 ram))
def tcpSeries : Series Rat Rat := series times (scaled 100 tcp |>.map some)

/-- The chart of the three series, the first two against the left axis in percent and the third against the right in megabytes. -/
def usage : Chart :=
  let layers : List Layer :=
    [{ label := "CPU", data := cpuSeries, color := ⟨255, 0, 0, 255⟩, fill := some ⟨255, 0, 0, 13⟩ },
     { label := "RAM", data := ramSeries, color := ⟨0, 0, 255, 255⟩, fill := some ⟨0, 0, 255, 13⟩ },
     { label := "TCP Out", data := tcpSeries, color := ⟨0, 255, 0, 255⟩, fill := some ⟨0, 255, 0, 13⟩, onRight := true }]
  { name := "usage", width := 1920, height := 600, xs := (times.getD 0 0, times.getD 199 0), time := true,
    left := autoYAxis (layers.take 2) "%", right := some { autoYAxis (layers.drop 2) " MB" with grid := false },
    layers }

/-- Two runs of samples eight apart in time, drawn as two lines because the gap between them exceeds one. -/
def gaps : Chart :=
  let layers : List Layer :=
    [{ data := series #[0, 1, 2, 3, 25, 26, 27, 28] ((#[0, 1, 2, 3, 4, 5, 6, 7] : Array Rat).map some), color := ⟨255, 0, 0, 255⟩,
       maxStep := some 1 }]
  { name := "gaps", width := 1920, height := 600, xs := (0, 28), time := false, left := autoYAxis layers, layers }

def charts : List Chart := [usage, gaps]

end Inkproof.Demos.MissingData
