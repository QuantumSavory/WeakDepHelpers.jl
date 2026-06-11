using Documenter
using WeakDepHelpers

DocMeta.setdocmeta!(WeakDepHelpers, :DocTestSetup, :(using WeakDepHelpers); recursive=true)

makedocs(;
    modules=[WeakDepHelpers],
    sitename="WeakDepHelpers.jl",
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/QuantumSavory/WeakDepHelpers.jl.git",
    push_preview=true,
)

