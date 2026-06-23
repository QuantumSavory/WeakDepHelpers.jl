module WeakDepHelpersStyledStringsExt
 
using WeakDepHelpers: WeakDepMissingError
using JuliaSyntaxHighlighting: highlight
using StyledStrings: @styled_str
 
function styled_showerror(io::IO, e::WeakDepMissingError)
    hl_name = highlight(string(e.name))
    hl_deps = highlight(join(string.(e.deps), ", "))
    hl_import_deps = highlight(string("import ", join(e.deps, ", ")))
    print(io, styled"{info:`$(hl_name)` depends on the package(s) `$(hl_deps)` but you have not installed or imported them yet. Immediately after an `$(hl_import_deps)`, `$(hl_name)` will be available.}")
    return nothing
end
 
function styled_hint_prefix(io::IO)
    print(io, styled"\n{bold:{info:HINT: }}")
    return nothing
end
 
end # module WeakDepHelpersStyledStringsExt