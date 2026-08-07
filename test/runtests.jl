using Test
using WeakDepHelpers

@testset "WeakDepMissingError" begin
    err = WeakDepMissingError(:FancyType, (:FancyDep,))
    expected = "`FancyType` depends on the package(s) `FancyDep` but you have not installed or imported them yet. Immediately after an `import FancyDep`, `FancyType` will be available."

    @test sprint(showerror, err) == expected
    @test sprint(showerror, err; context=:color => true) == expected
end

@testset "register_method_error_hint" begin
    cache = WeakDepCache()

    local f
    function f end

    @test register_method_error_hint(cache, f, (:FancyDep,)) === f
    @test cache[f] == (:FancyDep,)
end

@testset "registered method error hint" begin
    cache = WeakDepCache()
    function needs_dep end
    register_method_error_hint(cache, needs_dep, (:SomeDep,))
    register_weakdep_cache(cache)

    err = try
        needs_dep()
    catch err
        err
    end

    @test err isa MethodError
    @test occursin("\nHINT: `needs_dep` depends on the package(s) `SomeDep`", sprint(showerror, err))
end

module MethodFixture
using WeakDepHelpers

const CACHE = WeakDepCache()

@declare_method_is_in_extension CACHE fancy_method (:FancyDep,) "Implemented by FancyDep."
end

@testset "@declare_method_is_in_extension" begin
    @test isdefined(MethodFixture, :fancy_method)
    @test haskey(MethodFixture.CACHE, MethodFixture.fancy_method)
    @test MethodFixture.CACHE[MethodFixture.fancy_method] == (:FancyDep,)
    @test_throws MethodError MethodFixture.fancy_method()
    @test occursin("Implemented by FancyDep", sprint(show, @doc MethodFixture.fancy_method))
end

module StructFixture
using WeakDepHelpers

@declare_struct_is_in_extension(
    WeakDepHelpers,
    FancyType,
    :MissingExt,
    (:FancyDep,),
    "Implemented by FancyDep.",
)
end

@testset "@declare_struct_is_in_extension" begin
    @test isdefined(StructFixture, :FancyType)

    err = try
        StructFixture.FancyType()
    catch err
        err
    end

    @test err isa WeakDepMissingError
    @test err.name == :FancyType
    @test err.deps == (:FancyDep,)
    @test occursin("Implemented by FancyDep", sprint(show, @doc StructFixture.FancyType))
end
