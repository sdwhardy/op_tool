using DataFrames
using CSV
using StatsPlots
using Polynomials
using SpecialFunctions
#MILP
using PowerModels
using JuMP, Gurobi
using JLD

include("cost/cst_struct.jl")#costs
include("cost/cst_data.jl")#costs
include("cost/cst_functions.jl")#costs

include("wind/wnd_struct.jl")#wind
include("wind/wnd_functions.jl")#wind

include("eqp/eqp_struct.jl")#equipment
include("eqp/eqp_data.jl")#equipment
include("eqp/eqp_functions.jl")#equipment

include("layout/lo_struct.jl")#layout
include("layout/lo_data.jl")#layout
include("layout/lo_functions.jl")#layout

include("eens/eens_functions.jl")#costs


include("milp/milp_data.jl")#milp
include("milp/milp_struct.jl")#milp
include("milp/milp_functions.jl")#milp

include("post_process/pp_2screen.jl")#post processing
include("post_process/pp_2files.jl")#post processing
include("post_process/pp_milp.jl")#post processing

solutions=lpf_buildsetUpMilp()
solution=lpf_buildFnlMilp(solutions)
#ppf_printOcnGPS(solution[1])
solution=load("v2.0/results/33kv220kv/n_1.jld")
plotly()
ppf_printOcnXY(solution["asBuilt"])
#=println(solution["objective"])
wp=wndF_wndPrf(lod_gensGps()[3])
xc=cstF_xfo_ttl(750,wp,true)
xc3=cstF_xfo_ttl(250,wp,true)
println(xc.costs.ttl-2*xc3.costs.ttl)=#
function costTst(known_cables)
    num=1
    matfile = open("v2.0/results/test.mat","w")
    for S=500:500:1000
        for l=25:1:30
            kv=220
            nmes=lod_gensGps()[3]
            eyeD=string(S)*string(l)
            for (index,value) in enumerate(known_cables)
                if (string(eyeD) == string(value[1]))
                    println(matfile,"known cable: "*eyeD)
                    println("known cable")
                    cb=value[2]
                    @goto costTest
                end
            end
            nmes=lod_gensGps()[3]
            wp=wndF_wndPrf(nmes)
            cb=cstF_HVcbl2oss(l,S,kv,wp)
            tup=deepcopy((eyeD,cb))
            push!(known_cables,tup)
            println(matfile,"Unknown cable: "*eyeD)
            @label costTest
            println(string(num)*" cost of "*string(S)*"MVA at "*string(l)*"km is "*string(cb.costs.ttl))
            num=num+1
        end
    end
    close(matfile)
    return known_cables
end
known_cs=[]
known_cs=costTst(known_cs)
