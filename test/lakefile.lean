/-
Copyright (c) 2026 Paul Butcher. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Lake
open Lake DSL

package «inkproof-demos-test» where
  leanOptions := #[
    ⟨`autoImplicit, false⟩,
    ⟨`relaxedAutoImplicit, false⟩,
    ⟨`warningAsError, true⟩
  ]

require «inkproof-demos» from ".."
require «inkproof-tools» from git "https://github.com/paulbutcher/inkproof-tools" @ "v0.6.0"

@[default_target]
lean_exe tests where
  root := `Main

@[test_driver]
script test do
  let driver ← IO.Process.spawn
    { cmd := "lake", args := #["exe", "inkproof-test-driver"], cwd := __dir__ }
  let code ← driver.wait
  if code != 0 then return code
  let app := __dir__ / ".." / "app"
  for dir in #[__dir__ / "..", app] do
    let install ← IO.Process.spawn
      { cmd := "npm", args := #["ci", "--no-fund", "--no-audit"], cwd := dir }
    let code ← install.wait
    if code != 0 then return code
  let data ← IO.Process.spawn { cmd := "lake", args := #["exe", "demo-data"], cwd := __dir__ / ".." }
  let code ← data.wait
  if code != 0 then return code
  for (name, cmd, args) in #[("build", "npx", #["vite", "build"]), ("browser", "node", #["--test", "browser.test.mjs"])] do
    IO.println s!"== {name}"
    let child ← IO.Process.spawn { cmd, args, cwd := app, env := #[("LASM_EDITOR", some "0")] }
    let code ← child.wait
    if code != 0 then return code
  return 0
