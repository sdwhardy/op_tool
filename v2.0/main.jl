using DataFrames
using CSV
using StatsPlots
using Polynomials
using SpecialFunctions
#MILP
using PowerModels
using JuMP, Gurobi
using JLD

include("layout/lo_struct.jl")#layout
include("layout/lo_data.jl")#layout
include("layout/lo_functions.jl")#layout

include("eens/eens_functions.jl")#costs

include("cost/cst_struct.jl")#costs
include("cost/cst_data.jl")#costs
include("cost/cst_functions.jl")#costs

include("milp/milp_data.jl")#milp
include("milp/milp_struct.jl")#milp
include("milp/milp_functions.jl")#milp

include("wind/wnd_struct.jl")#wind
include("wind/wnd_functions.jl")#wind

include("eqp/eqp_struct.jl")#equipment
include("eqp/eqp_data.jl")#equipment
include("eqp/eqp_functions.jl")#equipment

include("post_process/pp_2screen.jl")#post processing
include("post_process/pp_2files.jl")#post processing
include("post_process/pp_milp.jl")#post processing

solutions=lpf_buildsetUpMilp()
solution=lpf_buildFnlMilp(solutions)
#ppf_printOcnGPS(solution[1])
solution=load("v2.0/results/partial_sols/n_1.jld")
plotly()
ppf_printOcnXY(solution["asBuilt"])
#=println(solution["objective"])
wp=wndF_wndPrf(lod_gensGps()[3])
xc=cstF_xfo_ttl(750,wp,true)
xc3=cstF_xfo_ttl(250,wp,true)
println(xc.costs.ttl-2*xc3.costs.ttl)=#
