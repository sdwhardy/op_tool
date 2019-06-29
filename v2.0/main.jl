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
optMaps=Array{eez,1}()
optObjs=Array{Float64,1}()
optIds=Array{Array{Int64,1},1}()
domains=Array{eez,1}()
solutions=(optMaps,optObjs,optIds,domains)
for i=1:17
    solution=load("v2.0/results/33kv220kv/n_"*string(i)*".jld")
    push!(optMaps,solution["asBuilt"])
    push!(domains,solution["domain"])
    push!(optObjs,solution["objective"])
end

optMapsMp=Array{eez,1}()
optObjsMp=Array{Float64,1}()
optIdsMp=Array{Array{Int64,1},1}()
domainsMp=Array{eez,1}()
solutionsMp=(optMapsMp,optObjsMp,optIdsMp,domainsMp)
for i=1:1:length(solutions)-1
    optMapsMpA=Array{eez,1}()
    optObjsMpA=Array{Float64,1}()
    optIdsMpA=Array{Array{Int64,1},1}()
    domainsMpA=Array{eez,1}()

    nID=string(i)*string(i+1)
    push!(optMapsMpA,solutions[1][i])
    push!(optMapsMpA,solutions[1][i+1])

    push!(optObjsMpA,solutions[2][i])
    push!(optObjsMpA,solutions[2][i+1])

    push!(optIdsMpA,[])
    push!(optIdsMpA,[])

    push!(domainsMpA,solutions[4][i])
    push!(domainsMpA,solutions[4][i+1])
    solutionsMpA=(optMapsMpA,optObjsMpA,optIdsMpA,domainsMpA)

    push!(solutionsMp,lpf_buildMidMilp(solutionsMpA,nID))
end

solution=lpf_buildFnlMilp(solutions)
solutions=lpf_buildsetUpMilp()
#ppf_printOcnGPS(solution[1])
<<<<<<< HEAD
solution=load("v2.0/results/33kv220kv/n_1.jld")
=======



solution=
>>>>>>> 7280fa4894d55133ede8aa629f3ff1d5759d3655
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
