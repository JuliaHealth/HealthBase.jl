```@meta
CurrentModule = HealthBase
```

# API

```@index
```

```@autodocs
Modules = [HealthBase]
Filter = t -> !(t in [HealthBase.HealthTable,
                     Base.getproperty(Tables, :columns),
                     Base.getproperty(Tables, :rows),
                     Base.getproperty(Tables, :schema),
                     Base.getproperty(Tables, :istable),
                     Base.getproperty(Tables, :rowaccess),
                     Base.getproperty(Tables, :columnaccess),
                     Base.getproperty(Tables, :materializer)])
```
