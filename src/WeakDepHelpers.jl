module WeakDepHelpers

using JuliaSyntaxHighlighting: highlight
using StyledStrings: @styled_str

const WeakDepCache = Dict{Function, Tuple{Vararg{Symbol}}}

export WeakDepMissingError,
    WeakDepCache,
    register_method_error_hint,
    register_weakdep_cache,
    @declare_struct_is_in_extension,
    @declare_method_is_in_extension

struct WeakDepMissingError <: Exception
    name::Symbol
    deps::Tuple{Vararg{Symbol}}
end

function Base.showerror(io::IO, e::WeakDepMissingError)
    hl_name = highlight(string(e.name))
    hl_deps = highlight(join(string.(e.deps), ", "))
    hl_import_deps = highlight(string("import ", join(e.deps, ", ")))
    print(io, styled"{info:`$(hl_name)` depends on the package(s) `$(hl_deps)` but you have not installed or imported them yet. Immediately after an `$(hl_import_deps)`, `$(hl_name)` will be available.}")
end

function register_method_error_hint(cache::WeakDepCache, f::Function, deps::Tuple{Vararg{Symbol}})
    cache[f] = deps
    return f
end

function method_error_hint_callback(cache::WeakDepCache, io, exc, argtypes, kwargs)
    deps = get(cache, exc.f, nothing)
    if deps !== nothing
        print(io, styled"\n{bold:{info:HINT: }}")
        showerror(io, WeakDepMissingError(nameof(exc.f), deps))
    end
    return nothing
end

function _extract_symbol(ex)
    if ex isa Symbol
        return ex
    elseif ex isa QuoteNode && ex.value isa Symbol
        return ex.value
    elseif ex isa Expr && ex.head == :quote && length(ex.args) == 1 && ex.args[1] isa Symbol
        return ex.args[1]
    end
    return nothing
end



"""
    register_weakdep_cache(cache::Dict{Function,Tuple{Vararg{Symbol}}})

Register the error hint cache for MethodError (in __init__()).
"""
function register_weakdep_cache(cache::Dict{Function,Tuple{Vararg{Symbol}}})
    if isdefined(Base.Experimental, :register_error_hint)
        Base.Experimental.register_error_hint(MethodError) do io, exc, argtypes, kwargs
            method_error_hint_callback(cache,io,exc,argtypes,kwargs)
        end
    end
end

"""
    @declare_struct_is_in_extension parent_mod struct_name extension_name deps [docstring]

Declare a forwarding "constructor function" named `struct_name` in the calling module that
dispatches to `Base.get_extension(parent_mod, extension_name).struct_name(...)` if the extension is
loaded, and otherwise throws `WeakDepMissingError(struct_name, deps)`.
"""
macro declare_struct_is_in_extension(args...)
    length(args) in (4, 5) || error("Usage: @declare_struct_is_in_extension parent_mod struct_name extension_name deps [docstring]")
    parent_mod, struct_name, extension_name, deps = args[1:4]
    docstring = length(args) == 5 ? args[5] : nothing

    struct_sym = _extract_symbol(struct_name)
    struct_sym === nothing && error("`struct_name` must be an identifier or Symbol literal")

    ext_arg = extension_name isa Symbol ? QuoteNode(extension_name) : esc(extension_name)

    struct_id = esc(struct_sym)
    parent_ex = esc(parent_mod)
    deps_ex = esc(deps)

    forward_def = :(function $struct_id(args...; kwargs...)
        ext = Base.get_extension($parent_ex, $ext_arg)
        if isnothing(ext)
            throw(WeakDepMissingError($(QuoteNode(struct_sym)), $deps_ex))
        end
        return getfield(ext, $(QuoteNode(struct_sym)))(args...; kwargs...)
    end)

    if docstring === nothing
        return forward_def
    end

    doc_attach = esc(:(@doc $docstring $struct_sym))
    return Expr(:block, forward_def, doc_attach)
end

"""
    @declare_method_is_in_extension cache function_name deps [docstring]

Declare an unimplemented generic function named `function_name` in the calling module and register an
error hint in `cache` so that a `MethodError` will display an extension/weakdep loading hint via
`method_error_hint_callback(cache, ...)`.
"""
macro declare_method_is_in_extension(args...)
    length(args) in (3, 4) || error("Usage: @declare_method_is_in_extension cache function_name deps [docstring]")
    cache, function_name, deps = args[1:3]
    docstring = length(args) == 4 ? args[4] : nothing

    fn_sym = _extract_symbol(function_name)
    fn_sym === nothing && error("`function_name` must be an identifier or Symbol literal")

    fn_id = esc(fn_sym)
    cache_ex = esc(cache)
    deps_ex = esc(deps)

    fn_def = :(function $fn_id end)
    reg = :($cache_ex[$fn_id] = $deps_ex)

    if docstring === nothing
        return Expr(:block, fn_def, reg)
    end

    doc_attach = esc(:(@doc $docstring $fn_sym))
    return Expr(:block, fn_def, doc_attach, reg)
end

end # module WeakDepHelpers
