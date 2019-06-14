#Calls Power Models on the input file
function milp_main(nme)
    filename="v2.0/results/"*nme*".m"
    mv("v2.0/results/tnep_map.mat", filename, force=true)
    solver=GurobiSolver(Presolve=1)
    result = run_tnep(filename, DCPPowerModel, solver)
    network_data = PowerModels.parse_file(filename)
    return result, network_data
end

#Runs multiple set up milps to sety up final problem
function lpf_buildsetUpMilp()
    optMaps=Array{eez,1}()
    optObjs=Array{Float64,1}()
    optIds=Array{Array{Int64,1},1}()
    domains=Array{eez,1}()
    solutions=(optMaps,optObjs,optIds,domains)
    optLout,mxObj,cntrls=lpd_fullProbSetUp()
    for cntrl in cntrls
        domain=lof_layoutEez(cntrl)
        ppf_main2mfile(domain,optLout,mxObj)
        solution,nw_data=milp_main("milp")
        asBuilt,optIds=ppm_reCnstrctSol(solution,nw_data,domain)
        asBuilt.pccs=lof_reOrderNodes(asBuilt.pccs)
        asBuilt.gens=lof_reOrderNodes(asBuilt.gens)
        asBuilt.osss=lof_reOrderNodes(asBuilt.osss)
        asBuilt.angle=domain.angle
        asBuilt.offset=domain.offset
        push!(solutions[1],asBuilt)
        push!(solutions[2],solution["objective"])
        push!(solutions[3],optIds)
        push!(solutions[4],domain)
        save("v2.0/results/partial_sols/n_"*string(cntrl.xXrad[1])*".jld", "asBuilt", asBuilt,"objective",solution["objective"], "domain", domain)
    end
    return solutions
end

#Runs final problem
function lpf_buildFnlMilp(solutions)
    optLout,mxObj,cntrl=lpd_fnlProbSetUp()
    (value,index)=findmin(solutions[2])
    mxObj=ceil(Int64,value)
    optLout=solutions[3][index]
    domain=lof_layoutEez_Sum(solutions,cntrl)
    domain.angle=solutions[4][1].angle
    domain.offset=solutions[4][1].offset
    ppf_main2mfile(domain,optLout,mxObj)
    solution,nw_data=milp_main("milp")
    asBuilt,Ids=ppm_reCnstrctSol(solution,nw_data,domain)
    asBuilt.pccs=lof_reOrderNodes(asBuilt.pccs)
    asBuilt.gens=lof_reOrderNodes(asBuilt.gens)
    asBuilt.osss=lof_reOrderNodes(asBuilt.osss)
    asBuilt.angle=solutions[4][1].angle
    asBuilt.offset=solutions[4][1].offset
    save("v2.0/results/partial_sols/final.jld", "asBuilt", asBuilt,"objective",solution["objective"], "domain", domain)
    return (asBuilt,solution["objective"],Ids,domain)
end
