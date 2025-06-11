# \ud83d\udcca Observational Health Study Workflow

This tutorial demonstrates how to initialize and run an observational health study using [HealthBase.jl](https://github.com/JuliaHealth/HealthBase.jl) and other JuliaHealth packages. It covers how to set up your study environment, download OHDSI cohort definitions, and execute them on a local OMOP CDM database.

---

## 1. \u2705 Setup

First, make sure the required packages are available in your Julia environment:

```@jldoctest
using DrWatson
using HealthBase
```

You can install them if needed via:

```@jldoctest
import Pkg
Pkg.add(["DrWatson", "HealthBase"])
```

---

## 2. \ud83c\udfc1 Initialize a Study

To get started, initialize a new study with the `:observational` template:

```@jldoctest
initialize_study("JuliaHealth", "Emmy Noether"; template = :observational)
```

This sets up a project structure using [`DrWatson.initialize_project`](https://juliadynamics.github.io/DrWatson.jl/dev/project/) under the hood and activates the environment for immediate use.

> **Tip:** You can now begin tracking data, scripts, results, and cohort definitions in a reproducible way.

---

## 3. \ud83d\udcc5 Download OHDSI Cohort Definitions

Use the `OHDSIAPI` package to access ATLAS/WebAPI cohort definitions:

```@jldoctest
using OHDSIAPI
```

Download a single cohort definition using its ATLAS/WebAPI ID:

```@jldoctest
cohort_path = download_cohort_definition(1793014; output_dir=cohortsdir(), metadata="metadata.json")
```

Download multiple cohort definitions at once:

```@jldoctest
cohort_ids = [1793014, 1792956]
download_cohort_definition(cohort_ids; progress_bar=true, verbose=true)
```

You can also fetch associated concept sets:

```@jldoctest
download_concept_set(cohort_ids; deflate=true, output_dir=cohortsdir())
```

---

## 4. \ud83d\udd04 Translate Cohort Definitions to SQL

To convert JSON cohort definitions to SQL for execution, use:

```@jldoctest
using OHDSICohortExpressions
```

Load and translate the cohort definition:

```@jldoctest
cohort_expression = cohortsdir("1793014.json")

fun_sql = translate(
    cohort_expression;
    cohort_definition_id = 1
)
```

---

## 5. \ud83d\uddc3\ufe0f Execute the Cohort on a Database

We can now execute the SQL expression against a local or remote OMOP CDM database:

```@jldoctest
import DBInterface: connect, execute
import DuckDB: DB
import FunSQL: reflect, render
using DataFrames

const CONNECTION = connect(DB, "synthea_1M_3YR.duckdb")
const SCHEMA = "dbt_synthea_dev"
const DIALECT = :postgresql

catalog = reflect(CONNECTION; schema=SCHEMA, dialect=DIALECT)

sql = render(catalog, fun_sql)

execute(CONNECTION, """
    INSERT INTO omop.cohort
    SELECT * FROM ($sql) AS foo;
""")

df = execute(CONNECTION, "SELECT COUNT(*) FROM omop.cohort;") |> DataFrame
println(df)
```

---

## 6. \ud83e\uddea Summary

This workflow demonstrates a full observational study setup using the JuliaHealth ecosystem:

* \ud83d\udd27 Initialize a study project with `HealthBase.jl`
* \ud83e\uddec Download cohorts and concept sets from OHDSI WebAPI using `OHDSIAPI.jl`
* \ud83d\udd04 Translate definitions into executable SQL via `OHDSICohortExpressions.jl`
* \ud83d\udcc0 Execute cohort logic against an OMOP CDM with `FunSQL.jl` and `DuckDB`

The `:observational` template streamlines your study structure, making reproducible research in observational health more accessible for Julia users.

---

## \ud83d\udd17 Related Resources

* [OHDSI Cohort Definition System](https://ohdsi.github.io/CommonDataModel/)
* [ATLAS Tool](https://atlas-demo.ohdsi.org/)
* [DrWatson.jl Documentation](https://juliadynamics.github.io/DrWatson.jl/)
* [HealthBase.jl GitHub](https://github.com/JuliaHealth/HealthBase.jl)
* [JuliaHealth Ecosystem](https://github.com/JuliaHealth)

