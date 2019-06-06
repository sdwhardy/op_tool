using DataFrames
using CSV
using StatsPlots
using Polynomials
#using Distributions
using SpecialFunctions
#MILP
using PowerModels
#using Mosek
using JuMP, Gurobi
#using MAT
using JLD

include("layout/lo_struct.jl")#layout
include("layout/lo_data.jl")#layout
include("layout/lo_functions.jl")#layout

include("eens/eens_functions.jl")#costs

include("cost/cst_struct.jl")#costs
include("cost/cst_data.jl")#costs
include("cost/cst_functions.jl")#costs


#include("milp/milp_data.jl")#milp
#include("milp/milp_struct.jl")#milp

include("wind/wnd_struct.jl")#wind
include("wind/wnd_functions.jl")#wind

include("eqp/eqp_struct.jl")#equipment
include("eqp/eqp_data.jl")#equipment
include("eqp/eqp_functions.jl")#equipment

include("post_process/pp_graphs.jl")#post processing
include("post_process/pp_files.jl")#post processing


domain=lof_layoutEez(lpd_fullProbSetUp()[3])
ppf_printOcn(domain)
wp=wndF_wndPrf(["Norther"])


#cost functions
lngth=100
mva=2000
kv=220
print("HVcbl2oss: ")
println(cstF_HVcbl2oss(lngth,mva,kv,wp).costs)#3
print("HVcbl2pcc: ")
println(cstF_HVcbl2pcc(lngth,mva,kv,wp).costs)#4
print("HVcbl2pccX: ")
println(cstF_HVcbl2pccX(lngth,mva,kv,wp).costs)#5
println(cstF_xfo_ttl(mva,wp,true).costs)

kv=66
print("MVcbl2pccX: ")
println(cstF_MVcbl2pccX(lngth,mva,kv,wp).costs)#2
print("MVcbl2ossX: ")
println(cstF_MVcbl2ossX(lngth,mva,kv,wp).costs)#1

kv=300
print("DCcbl2pcc: ")
println(cstF_DCcbl2pcc(lngth,mva,kv,wp,domain.osss[1],domain.gens).costs)#6
