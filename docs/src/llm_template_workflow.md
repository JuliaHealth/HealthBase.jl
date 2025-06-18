# JuliaHealth LLM RAG Assisted Study 

This workflow guide demonstrates how to initialize and configure your study using [HealthBase.jl](https://github.com/JuliaHealth/HealthBase.jl) with assistance by an LLM RAG architecture.

---

## 1. Setup and Study Initialization

First, ensure that the required packages are installed in your global Julia environment:

```julia
import Pkg
Pkg.add(
  [
    "DrWatson",
    "HealthBase"
  ]
)
```

> **Note**: The global environment is the default Julia package environment shared across projects.
> To learn more about environments, see the [Pkg documentation](https://pkgdocs.julialang.org/v1/environments/).

Then, load the packages:

```julia
using DrWatson
using HealthBase

import HealthBase:
  configdir,
  corpusdir,
  modelsdir
```

Initialize a new study:

```julia
julia> initialize_study("sample_study", "Rosalind Franklin"; template = :llm)
```

This command creates a new directory called `sample_study` using the `:llm` template.
Then, it activates a new Julia environment named `sample_study`.

After initializing the study directory and Julia environment, install the remaining required packages:

```julia
Pkg.add(
  [
    "DataFrames",
    "Downloads",
    "DBInterface",
    "DuckDB",
    "FunSQL",
    "OHDSIAPI",
    "OHDSICohortExpressions"
  ]
)
```
