# Observational Health Study

This tutorial demonstrates how to initialize and run an observational health study using [HealthBase.jl](https://github.com/JuliaHealth/HealthBase.jl).
It also shows how other JuliaHealth packages integrate into this workflow.
It covers how to set up your study environment.
It walks through downloading OHDSI cohort definitions from ATLAS.
It explains how to execute them on a local OMOP CDM database.

---

## Learning Objectives

By the end of this tutorial, you will be able to:

* Initialize a new observational health study project using `HealthBase.jl`
* Download phenotype definitions and concept sets from OHDSI ATLAS via WebAPI
* Translate OHDSI cohort definitions to SQL using `OHDSICohortExpressions.jl`
* Execute translated SQL against an OMOP CDM database using `FunSQL.jl`

---

## 1. Setup and Study Initialization

First, ensure that the required packages are installed in your global Julia environment:

```@jldoctest
import Pkg
Pkg.add(["DrWatson", "HealthBase"])
```

> **Note**: The global environment is the default Julia package environment shared across projects.
> To learn more about environments, see the [Pkg documentation](https://pkgdocs.julialang.org/v1/environments/).

Then, load the packages:

```@jldoctest
using DrWatson
using HealthBase
```

Initialize a new observational health study:

```@jldoctest
initialize_study("JuliaHealth", "Emmy Noether"; template = :observational)
```

This command creates a new directory called `JuliaHealth`.
It sets up a DrWatson-compatible project using the `:observational` template.
It activates a new Julia environment named `JuliaHealth`.

After initializing the study, you should install the rest of the required packages in the new environment:

```@jldoctest
import Pkg
Pkg.add(["OHDSIAPI", "OHDSICohortExpressions", "DuckDB", "DBInterface", "FunSQL", "DataFrames"])
```

Once the study is initialized and packages are installed, load all the necessary packages for this tutorial:

```@jldoctest
using OHDSIAPI
using OHDSICohortExpressions
using DuckDB
using DBInterface
using FunSQL
using DataFrames
```

---

## 2. Download OHDSI Cohort Definitions

[`OHDSIAPI.jl`](https://github.com/JuliaHealth/OHDSIAPI.jl) is a Julia interface to various OHDSI WebAPI services.
It is maintained as part of the JuliaHealth ecosystem.

Use it to access ATLAS, OHDSI's web-based tool for defining phenotypes and analyses.

Download a single cohort definition using its ATLAS ID:

```@jldoctest
cohort_path = download_cohort_definition(1793014; output_dir=cohortsdir(), metadata="metadata.json")
```

> **Tip:** To download multiple cohort definitions with more verbose output:
>
> ```@jldoctest
> cohort_ids = [1793014, 1792956]
> download_cohort_definition(cohort_ids; progress_bar=true, verbose=true)
> ```
>
> You can also download associated concept sets:
>
> ```@jldoctest
> download_concept_set(cohort_ids; deflate=true, output_dir=cohortsdir())
> ```

---

## 3. Translate Cohort Definitions to SQL

Use [`OHDSICohortExpressions.jl`](https://github.com/JuliaHealth/OHDSICohortExpressions.jl) to convert OHDSI JSON cohort definitions into SQL.

First, load and translate the cohort expression:

```@jldoctest
cohort_expression = cohortsdir("1793014.json")

fun_sql = translate(
    cohort_expression;
    cohort_definition_id = 1
)
```

---

## 4. Execute the Cohort on a Database

You can now execute the translated SQL on an OMOP CDM-compliant database using `DuckDB` and `FunSQL`:

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

## Summary

This workflow demonstrates how to run an observational health study using tools from the JuliaHealth ecosystem:

* Initialize a project with a standardized structure using `HealthBase.jl`
* Download cohort and concept set definitions from OHDSI ATLAS using `OHDSIAPI.jl`
* Convert JSON cohort logic to SQL using `OHDSICohortExpressions.jl`
* Execute SQL queries on an OMOP CDM database using `FunSQL.jl` and `DuckDB`

---

## Related Resources

* [OHDSI Common Data Model](https://ohdsi.github.io/CommonDataModel/)
* [ATLAS Tool (Demo)](https://atlas-demo.ohdsi.org/)
* [DrWatson.jl Documentation](https://juliadynamics.github.io/DrWatson.jl/)
* [HealthBase.jl GitHub](https://github.com/JuliaHealth/HealthBase.jl)
* [JuliaHealth GitHub](https://github.com/JuliaHealth)
