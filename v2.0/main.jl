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
for i=1:9
    solution=load("v2.0/results/mid_sols/mid"*string(i)*".jld")
    push!(optMaps,solution["asBuilt"])
    push!(domains,solution["domain"])
    push!(optObjs,solution["objective"])
    push!(optIds,solution["optIds"])
end
solutions=(optMaps,optObjs,optIds,domains)
solutionsMp=lpf_buildMidMilp(solutions)

mid9=load("v2.0/results/mid_sols/mid9.jld")
deleteat!(solutionsMp[4],1)
solutionsMp[3][5]=[0]
push!(solutionsMp[1],solutionsMp[1][1])
push!(solutionsMp[4],solutionsMp[4][1])
push!(solutionsMp[2],solutionsMp[2][1])
push!(solutionsMp[3],solutionsMp[3][1])

solutions=lpf_buildsetUpMilp()
solution=lpf_buildFnlMilp(solutionsMp)
q=load("v2.0/results/mid_sols2/mid12.jld")
# For loading results


#ppf_printOcnGPS(solution[1])
plotly()
ppf_printOcnXY(solutions[4][4])


####################################################### OLd stuff
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
    aBuilt,objct,eYeds,domn=lpf_buildMidMilp(solutionsMpA,nID)
    push!(solutionsMp[1],deepcopy(aBuilt))
    push!(solutionsMp[2],deepcopy(objct))
    push!(solutionsMp[3],deepcopy(eYeds))
    push!(solutionsMp[4],deepcopy(domn))
end




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
