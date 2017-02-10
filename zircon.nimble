# Package
version       = "0.1.0"
author        = "stisa"
description   = "DSL for Html"
license       = "MIT"

# Deps
requires: "nim >= 0.14.0"

task builddocs, "Build docs folder - examples and documentation":
  exec("nim doc2 -o:docs/zircon.html zircon.nim")
