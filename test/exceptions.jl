output = """


Please load the DrWatson package to use the cohortsdir function. You can do this by running: 

using Pkg
Pkg.add("DrWatson")
using DrWatson


in your REPL or code.
"""

io = IOBuffer()
HealthBase._extension_message("DrWatson", cohortsdir, io)

@test String(take!(io)) == output
