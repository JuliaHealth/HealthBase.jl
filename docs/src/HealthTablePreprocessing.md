# HealthTable: Preprocessing Functions

This page documents the preprocessing and transformation functions available for `HealthTable` objects when working with OMOP CDM data. These functions are provided by the OMOP CDM extension and enable data preparation workflows for machine learning and analysis.

## One-Hot Encoding

Transform categorical variables into binary indicator columns suitable for machine learning algorithms.

```@docs
HealthBase.one_hot_encode
```

## Vocabulary Compression

Reduce the dimensionality of categorical variables by grouping infrequent levels under a common label.

```@docs
HealthBase.apply_vocabulary_compression
```

## Concept Translation

### Concept Mapping (Immutable)

Map OMOP concept IDs to human-readable concept names using the OMOP vocabulary tables, returning a new `HealthTable`.

```@docs
HealthBase.map_concepts
```

### Concept Mapping (In-Place)

In-place version of concept mapping that modifies the original `HealthTable` directly for memory efficiency.

```@docs
HealthBase.map_concepts!
```
