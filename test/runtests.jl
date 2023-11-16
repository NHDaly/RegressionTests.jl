using RegressionTests
using Test
using Aqua
using Pkg

@testset "RegressionTests.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(RegressionTests, deps_compat=false)
    end

    @testset "Example usage" begin
        regression_tests_path = dirname(dirname(@__FILE__))
        package = Pkg.project().path
        cd(joinpath(dirname(@__FILE__), "TestPackage")) do
            backup = tempname()
            src_file = joinpath("src", "TestPackage.jl")
            cp(src_file, backup)
            try
                Pkg.activate("bench")
                Pkg.add(path=regression_tests_path)
                run(`git init`)
                run(`git add .`)
                run(`git commit -m "Initial content"`)
                old_src = read(src_file, String)
                new_src = replace(old_src, "my_sum(x) = sum(x)" => "my_sum(x) = sum(Float64.(x))")
                write(src_file, new_src)
                runbenchmarks(project = ".")
                # run(`git add $src_file`)
                # run(`git commit -m "Introduce regression"`)
                # runbenchmarks(project = ".")
                # TODO: handle this case well
            finally
                Pkg.activate(package)
                rm(joinpath("bench", "Project.toml"), force=true)
                if basename(pwd()) == "TestPackage" # Just double checking before we delete the git repo...
                    rm(".git", recursive=true, force=true)
                else
                    println("Woah!! Something strange happened")
                end
                cp(backup, src_file, force=true)
            end
        end
    end

    # @testset "Regression tests" begin
    #     using RegressionTests
    #     runbenchmarks()
    # end
end
