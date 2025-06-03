function _extension_message(pkg, fn, io)
    print(io, "\n\nPlease load the ")
    printstyled(io, "$pkg", color = :green, bold = true)
    print(io, " package to use ")
    printstyled(io, "$fn", color = :magenta)
    print(io, ". ")

    println(io, "You can do this by running: \n")

    printstyled(io, "using Pkg\n", color = :light_blue, bold = true)
    printstyled(io, "Pkg.add(\"$pkg\")\n", color = :light_blue, bold = true)
    printstyled(io, "using $pkg\n", color = :light_blue, bold = true)

    println(io, "\n\nin your REPL or code.")
end
