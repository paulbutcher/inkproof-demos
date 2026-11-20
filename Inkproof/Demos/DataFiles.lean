/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Inkproof.Demos.Linked

/-- Writes the files the zoom-fetch page asks its "server" for, under `app/web/public/data/` of the directory it runs in. -/
def main : IO Unit := do
  let dir : System.FilePath := "app/web/public/data"
  IO.FS.createDirAll dir
  for (name, stride) in [("zoom-fetch-coarse.bin", 20), ("zoom-fetch-fine.bin", 1)] do
    IO.FS.writeBinFile (dir / name) (Inkproof.Demos.Linked.file stride)
