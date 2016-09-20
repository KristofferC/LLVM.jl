## subsystem initialization

export Shutdown,
       ismultithreaded

function _define_subsystem_init(subsystem::Symbol)
       jl_fname = Symbol(:Initialize, subsystem)
       api_fname = Symbol(:LLVM, jl_fname)
       @eval begin
              export $jl_fname
              $jl_fname(R::PassRegistry) = API.$api_fname(ref(R))
       end
end

for subsystem in [:Core, :TransformUtils, :ScalarOpts, :ObjCARCOpts, :Vectorization,
                  :InstCombine, :IPO, :Instrumentation, :Analysis, :IPA, :CodeGen, :Target]
    _define_subsystem_init(subsystem)
end

Shutdown() = API.LLVMShutdown()

ismultithreaded() = BoolFromLLVM(API.LLVMIsMultithreaded())


## target initialization

for component in [:TargetInfo, :Target, :TargetMC, :AsmPrinter, :AsmParser, :Disassembler]
    jl_fname = Symbol(:Initialize, :All, component, :s)
    api_fname = Symbol(:LLVM, jl_fname)
    @eval begin
        export $jl_fname
        $jl_fname() = API.$api_fname
    end
end

for component in [:Target, :AsmPrinter, :AsmParser, :Disassembler]
    jl_fname = Symbol(:Initialize, :Native, component)
    api_fname = Symbol(:LLVM, jl_fname)
    @eval begin
        export $jl_fname
        $jl_fname() = BoolFromLLVM(API.$api_fname()) &&
                      throw(LLVMException($"Could not initialize native $component"))
    end
end

for target in API.llvm_targets,
    component in [:Target, :AsmPrinter, :AsmParser, :Disassembler, :TargetInfo, :TargetMC]
    jl_fname = Symbol(:Initialize, target, component)
    api_fname = Symbol(:LLVM, jl_fname)

    @eval begin
        export $jl_fname
        $jl_fname() = ccall(($(QuoteNode(api_fname)),API.libllvm), Void, ())
    end
end
