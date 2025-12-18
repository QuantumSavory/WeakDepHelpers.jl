# WeakDepHelpers.jl

Small utilities for Julia packages that use extensions and weak dependencies:

- `WeakDepMissingError`: an exception with a user-facing hint on what to `import`.
- `declare_struct_is_in_extension`: declare a forwarding "constructor function" for a struct/type
  implemented in an extension.
- `declare_method_is_in_extension`: declare a generic function and register a `MethodError` hint
  pointing to the required weak dependencies.

## Usage

```julia
using WeakDepHelpers

const WEAKDEP_METHOD_ERROR_HINTS = WeakDepCache()

@declare_struct_is_in_extension MyPkg FancyType :MyPkgFancyExt (:FancyDep,) "Implemented in an extension requiring FancyDep.jl."

@declare_method_is_in_extension WEAKDEP_METHOD_ERROR_HINTS fancy_function (:FancyDep,) "Implemented in an extension requiring FancyDep.jl."
```
