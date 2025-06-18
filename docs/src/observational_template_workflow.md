# Observational Health Study

This workflow guide demonstrates how to initialize and run an observational health study using [HealthBase.jl](https://github.com/JuliaHealth/HealthBase.jl).\
By the end of this tutorial, you will be able to:

- Initialize a new observational health study project using `HealthBase.jl`
- Download phenotype definitions and concept sets from [OHDSI ATLAS](https://atlas-demo.ohdsi.org/) via WebAPI
- Translate OHDSI cohort definitions to SQL using `OHDSICohortExpressions.jl`
- Execute translated SQL against an [OMOP CDM v5.4](https://ohdsi.github.io/CommonDataModel/) database using `FunSQL.jl`

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

```jldoctest
using DrWatson
using HealthBase

import HealthBase:
  cohortsdir
```

Initialize a new observational health study:

```jldoctest
julia> initialize_study("sample_study", "Jenna Reps"; template = :observational)
```

This command creates a new directory called `sample_study` using the `:observational` template.
Then, it activates a new Julia environment named `sample_study`.

After initializing the study directory and Julia environment, install the remaining required packages:

```jldoctest
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

Now, load and import all necessary packages and functions:

```jldoctest
using DataFrames
using Downloads

import DBInterface:
  connect,
  execute
import DuckDB:
  DB
import FunSQL:
  reflect,
  render
import OHDSIAPI:
  download_cohort_definition,
  download_concept_set
import OHDSICohortExpressions:
  translate
```

---

## 2. Download OHDSI Cohort Definitions

[`OHDSIAPI.jl`](https://github.com/JuliaHealth/OHDSIAPI.jl) is a Julia interface to various OHDSI WebAPI services.
We can use it to access [OHDSI ATLAS](https://atlas-demo.ohdsi.org/), OHDSI's web-based tool for defining phenotypes and analyses.

Here, we can download a single cohort definition using its ATLAS ID:

```julia
cohort_path = download_cohort_definition(1793014; output_dir=cohortsdir())
```

> **Tip:** To download multiple cohort definitions with more verbose output:
>
> ```julia
> cohort_ids = [1793014, 1792956]
> download_cohort_definition(cohort_ids; progress_bar=true, verbose=true)
> ```
>
> You can also download associated concept sets:
>
> ```julia
> download_concept_set(cohort_ids; deflate=true, output_dir=cohortsdir())
> ```

---

## 3. Translate Cohort Definitions to SQL

Now, we can use [`OHDSICohortExpressions.jl`](https://github.com/JuliaHealth/OHDSICohortExpressions.jl) to convert this cohort definition into SQL.

```jldoctest
cohort_expression = cohortsdir("1793014.json")

fun_sql = translate(
    cohort_expression;
    cohort_definition_id = 1
)
```

---

## 4. Download Synthetic Database

For this guide, we will use a synthetic OMOP CDM v5.3 database from [Eunomia](https://github.com/OHDSI/EunomiaDatasets).
We will download it as follows:

```jldoctest
# TODO: Add download URL
url = ""
db_path = datadir("exp_raw", "omop_cdm.db")
Downloads.download(url, db_path)
```

---

## 5. Execute the Cohort on a Database

Create database connection and configure dialect:

```jldoctest
const CONNECTION = connect(DB, datadir("exp_raw", "omop_cdm.db"))
const SCHEMA = ""
const DIALECT = :postgresql
```

Reflect database catalog and render SQL:

```jldoctest
catalog = reflect(CONNECTION; schema=SCHEMA, dialect=DIALECT)
sql = render(catalog, fun_sql)
```

Execute cohort query and insert results into cohort table:

```jldoctest
execute(
  CONNECTION,
  """
  INSERT INTO cohort
  SELECT * FROM ($sql) AS foo;
  """
)
```

Query results into a DataFrame:

```jldoctest
df = execute(CONNECTION, "SELECT COUNT(*) FROM cohort;") |> DataFrame
```

Display DataFrame:

```jldoctest
println(df)
```

---

## Summary

This workflow demonstrates how to run an observational health study using tools from the JuliaHealth ecosystem:

- Initialize a project with a standardized structure using `HealthBase.jl`
- Download cohort and concept set definitions from [OHDSI ATLAS](https://atlas-demo.ohdsi.org/) using `OHDSIAPI.jl`
- Convert JSON cohort logic to SQL using `OHDSICohortExpressions.jl`
- Execute SQL queries on an [OMOP CDM v5.4](https://ohdsi.github.io/CommonDataModel/) database using `FunSQL.jl` and `DuckDB`

---

## Related Resources

- [OHDSI Common Data Model](https://ohdsi.github.io/CommonDataModel/)
- [ATLAS Tool (Demo)](https://atlas-demo.ohdsi.org/)
- [DrWatson.jl Documentation](https://juliadynamics.github.io/DrWatson.jl/)
- [HealthBase.jl GitHub](https://github.com/JuliaHealth/HealthBase.jl)
- [JuliaHealth GitHub](https://github.com/JuliaHealth)
