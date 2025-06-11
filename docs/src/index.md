# `HealthBase.jl`

> Common namespace for functions and interfaces in the JuliaHealth ecosystem

## Overview

`HealthBase.jl` is a foundational package for interacting with the JuliaHealth ecosystem.
It is designed to live within your global Julia environment. 
The package supports a number of workflows and provides helper functions for JuliaHealth users.

## Features

Some notable features include:

- Extensible and consistent ecosystem interfaces

- Templates for common JuliaHealth workflows

- Utilities to quickly build a research study

- Interoperability with packages across Julia community

- Lightweight and high code quality

## Limitations

`HealthBase.jl` is an interface and foundational level package that acts as a dependency for multiple JuliaHealth packages.
It is designed to be as lightweight as possible.
As a result, all provided functions that depend on other packages should live in extensions.
