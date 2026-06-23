using Test
using WeakDepHelpers

@testset "WeakDepMissingError" begin
    err = WeakDepMissingError(:FancyType, (:FancyDep,))
    msg = sprint(showerror, err)

    @test occursin("FancyType", msg)
    @test occursin("FancyDep", msg)
    @test occursin("import FancyDep", msg)
end

@testset "plain-text fallback message" begin
    err = WeakDepMissingError(:fancy_method, (:FancyDepA, :FancyDepB))
    msg = sprint(showerror, err)
    @test occursin("fancy_method", msg)
    @test occursin("FancyDepA, FancyDepB", msg)
    @test occursin("import FancyDepA, FancyDepB", msg)
    @test occursin("depends on the package(s)", msg)
    @test occursin("will be available", msg)
end

@testset "register_method_error_hint" begin
    cache = WeakDepCache()

    local f
    function f end

    @test register_method_error_hint(cache, f, (:FancyDep,)) === f
    @test cache[f] == (:FancyDep,)
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
