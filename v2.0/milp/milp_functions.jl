#Calls Power Models on the input file
#nme="milp"
#time=20000
function milp_main(nme,time)
    filename="v2.0/results/"*nme*".m"
    mv("v2.0/results/tnep_map.mat", filename, force=true)
    solver=GurobiSolver(Presolve=1, TimeLimit=time)
    result = run_tnep(filename, DCPPowerModel, solver)
    network_data = PowerModels.parse_file(filename)
    return result, network_data
end

#######################################
###### Runs initial milp problem ######
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
        domain=ppf_savedCbls(domain)
        ppf_main2mfile(domain,optLout,mxObj,cntrl)
        solution,nw_data=milp_main("milp",2000)
        asBuilt,optIds=ppm_reCnstrctSol(solution,nw_data,domain)
        asBuilt.pccs=lof_reOrderNodes(asBuilt.pccs)
        asBuilt.gens=lof_reOrderNodes(asBuilt.gens)
        asBuilt.osss=lof_reOrderNodes(asBuilt.osss)
        asBuilt.angle=domain.angle
        asBuilt.offset=domain.offset
        domain=ppf_saveResults(domain,asBuilt,solution,optIds,"setUp")
        push!(solutions[1],asBuilt)
        push!(solutions[2],solution["objective"])
        push!(solutions[3],optIds)
        push!(solutions[4],domain)
    end
    return solutions
end

###################################
###### Runs mid milp problem ######
function lpf_buildMidMilp(solutions,round)
    optMapsMp=Array{eez,1}()
    optObjsMp=Array{Float64,1}()
    optIdsMp=Array{Array{Int64,1},1}()
    domainsMp=Array{eez,1}()
    solutionsMp=(optMapsMp,optObjsMp,optIdsMp,domainsMp)
    optLout,mxObj,cntrl=lpd_fnlProbSetUp()
    for i=1:2:length(solutions[1])-1
        nID=string(i)*string(i+1)
        solutionsPair=lpf_extrctPair(i,solutions)
        (value,index)=findmin(solutionsPair[2])
        mxObj=ceil(Int64,value+5)
        optLout=solutionsPair[3][index]
        solutionsPair[4][length(solutionsPair[4])]=ppf_savedCbls(solutionsPair[4][length(solutionsPair[4])])
        domain=lof_layoutEez_Sum(solutionsPair,cntrl)
        domain.angle=solutionsPair[4][1].angle
        domain.offset=solutionsPair[4][1].offset
        ppf_main2mfile(domain,optLout,mxObj,cntrl)
        solution,nw_data=milp_main("milp",2000)
        asBuilt,Ids=ppm_reCnstrctSol(solution,nw_data,domain)
        asBuilt.pccs=lof_reOrderNodes(asBuilt.pccs)
        asBuilt.gens=lof_reOrderNodes(asBuilt.gens)
        asBuilt.osss=lof_reOrderNodes(asBuilt.osss)
        asBuilt.angle=solutionsPair[4][1].angle
        asBuilt.offset=solutionsPair[4][1].offset
        domain=ppf_saveResults(domain,asBuilt,solution,optIds,"mid"*string(round))
        push!(solutions[1],asBuilt)
        push!(solutions[2],solution["objective"])
        push!(solutions[3],optIds)
        push!(solutions[4],domain)
    end
    return solutionsMp
end

#sets the 2 consecutive domains to be combined
function lpf_extrctPair(i,solutions)
    optMapsPair=Array{eez,1}()
    optObjsPair=Array{Float64,1}()
    optIdsPair=Array{Array{Int64,1},1}()
    domainsPair=Array{eez,1}()

    push!(optMapsPair,solutions[1][i])
    push!(optMapsPair,solutions[1][i+1])

    push!(optObjsPair,solutions[2][i])
    push!(optObjsPair,solutions[2][i+1])

    push!(optIdsPair,solutions[3][i])
    push!(optIdsPair,solutions[3][i+1])

    push!(domainsPair,solutions[4][i])
    push!(domainsPair,solutions[4][i+1])

    return (optMapsPair,optObjsPair,optIdsPair,domainsPair)
end

################################
###### Runs final problem ######
function lpf_buildFnlMilp(solutions)
    optLout,mxObj,cntrl=lpd_fnlProbSetUp()
    (value,index)=findmin(solutions[2])
    mxObj=ceil(Int64,value)
    mxObj=ceil(Int64,value+5)
    optLout=solutions[3][index]
    solutions[4][length(solutions[4])]=ppf_savedCbls(solutions[4][length(solutions[4])])
    domain=lof_layoutEez_Sum(solutions,cntrl)
    domain.angle=solutions[4][1].angle
    domain.offset=solutions[4][1].offset
    ppf_main2mfile(domain,optLout,mxObj,cntrl)
    solution,nw_data=milp_main("milp",25000)
    asBuilt,Ids=ppm_reCnstrctSol(solution,nw_data,domain)
    asBuilt.pccs=lof_reOrderNodes(asBuilt.pccs)
    asBuilt.gens=lof_reOrderNodes(asBuilt.gens)
    asBuilt.osss=lof_reOrderNodes(asBuilt.osss)
    asBuilt.angle=solutions[4][1].angle
    asBuilt.offset=solutions[4][1].offset
    domain=ppf_saveResults(domain,asBuilt,solution,Ids,"final")
    return (asBuilt,solution["objective"],Ids,domain)
end
