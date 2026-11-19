/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lake
open Lake DSL

package «inkproof-demos» where
  leanOptions := #[
    ⟨`autoImplicit, false⟩,
    ⟨`relaxedAutoImplicit, false⟩,
    ⟨`warningAsError, true⟩
  ]

require «inkproof-web» from git "https://github.com/paulbutcher/inkproof-web" @ "v0.6.1"
require «inkproof-export» from git "https://github.com/paulbutcher/inkproof-export" @ "v0.5.0"
require «inkproof-viewport» from git "https://github.com/paulbutcher/inkproof-viewport" @ "v0.6.0"
require «inkproof-scene» from git "https://github.com/paulbutcher/inkproof-scene" @ "v0.13.0"
require «inkproof-scale» from git "https://github.com/paulbutcher/inkproof-scale" @ "v0.10.0"
require «inkproof-axis» from git "https://github.com/paulbutcher/inkproof-axis" @ "v0.7.0"
require «inkproof-core» from git "https://github.com/paulbutcher/inkproof-core" @ "v0.13.0"
require «inkproof-float» from git "https://github.com/paulbutcher/inkproof-float" @ "v0.7.0"
require «inkproof-gpu» from git "https://github.com/paulbutcher/inkproof-gpu" @ "v0.7.0"

@[default_target]
lean_lib InkproofDemos where
  roots := #[`Inkproof.Demos, `Inkproof.Demos.Proofs]

@[test_driver]
script tests do
  let child ← IO.Process.spawn
    { cmd := "lake", args := #["test"], cwd := __dir__ / "test" }
  child.wait

/-- The code the pages share. It imports Lasm, so only Lasm's build compiles it. -/
lean_lib InkproofDemosBrowser where
  roots := #[`Inkproof.Demos.Browser]
