## subsystem initialization

export version, Shutdown,
       ismultithreaded

function version()
    LLVM.configured || error("LLVM.jl has not been configured.")
    return libllvm_version
end

function Shutdown()
  libllvm_system || error("Cannot shutdown LLVM without exclusive access")
  API.LLVMShutdown()
end

ismultithreaded() = convert(Core.Bool, API.LLVMIsMultithreaded())

for subsystem in [:Core, :TransformUtils, :ScalarOpts, :ObjCARCOpts, :Vectorization,
                  :InstCombine, :IPO, :Instrumentation, :Analysis, :IPA, :CodeGen, :Target]
    jl_fname = Symbol(:Initialize, subsystem)
    api_fname = Symbol(:LLVM, jl_fname)
    @eval begin
        export $jl_fname
        $jl_fname(R::PassRegistry) = API.$api_fname(ref(R))
    end
end


## target initialization

for component in [:TargetInfo, :Target, :TargetMC, :AsmPrinter, :AsmParser, :Disassembler]
    jl_fname = Symbol(:Initialize, :All, component, :s)
    api_fname = Symbol(:LLVM, jl_fname)
    @eval begin
        export $jl_fname
        $jl_fname() = API.$api_fname()
    end
end

for component in [:Target, :AsmPrinter, :AsmParser, :Disassembler]
    jl_fname = Symbol(:Initialize, :Native, component)
    api_fname = Symbol(:LLVM, jl_fname)
    @eval begin
        export $jl_fname
        $jl_fname() = convert(Core.Bool, API.$api_fname()) &&
                      throw(LLVMException($"Could not initialize native $component"))
    end
end

for target in libllvm_targets,
    component in [:Target, :AsmPrinter, :AsmParser, :Disassembler, :TargetInfo, :TargetMC]
    jl_fname = Symbol(:Initialize, target, component)
    api_fname = Symbol(:LLVM, jl_fname)

    @eval begin
        export $jl_fname
        $jl_fname() = API.@apicall($(QuoteNode(api_fname)), Void, ())
    end
end
