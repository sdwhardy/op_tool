#Calls Power Models on the input file
function milp_main(nme,time)
    filename="v2.0/results/"*nme*".m"
    mv("v2.0/results/tnep_map.mat", filename, force=true)
    solver=GurobiSolver(Presolve=1, TimeLimit=time)
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
        if length(solutions[1]) != 0
            domain.oOcbls=solutions[4][length(solutions[4])].oOcbls
            domain.oPcbls=solutions[4][length(solutions[4])].oPcbls
            domain.oPXcbls=solutions[4][length(solutions[4])].oPXcbls
            domain.gOcbls=solutions[4][length(solutions[4])].gOcbls
            domain.gPcbls=solutions[4][length(solutions[4])].gPcbls
            domain.dcCbls=solutions[4][length(solutions[4])].dcCbls
        else
            solut=load("v2.0/results/partial_sols/n_1.jld")["domain"]
            domain.oOcbls=solut.oOcbls
            domain.oPcbls=solut.oPcbls
            domain.oPXcbls=solut.oPXcbls
            domain.gOcbls=solut.gOcbls
            domain.gPcbls=solut.gPcbls
            domain.dcCbls=solut.dcCbls
        end
        ppf_main2mfile(domain,optLout,mxObj,cntrl)
        solution,nw_data=milp_main("milp",2000)
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
        save("v2.0/results/partial_sols/n_"*string(cntrl.xXrad[1])*".jld", "asBuilt", asBuilt,"objective",solution["objective"],"optIds",optIds,"domain", domain)
    end
    return solutions
end

#Runs final problem
function lpf_buildFnlMilp(solutions)
    optLout,mxObj,cntrl=lpd_fnlProbSetUp()
    (value,index)=findmin(solutions[2])
    mxObj=ceil(Int64,value)
    #optLout=solutions[3][index]

    mxObj=ceil(Int64,value+5)
    optLout=solutionsPair[3][index]

    domain=lof_layoutEez_Sum(solutions,cntrl)
    domain.angle=solutions[4][1].angle
    domain.offset=solutions[4][1].offset
    ppf_main2mfile(domain,optLout,mxObj,cntrl)
    solution,nw_data=milp_main("milp",70000)
    asBuilt,Ids=ppm_reCnstrctSol(solution,nw_data,domain)
    asBuilt.pccs=lof_reOrderNodes(asBuilt.pccs)
    asBuilt.gens=lof_reOrderNodes(asBuilt.gens)
    asBuilt.osss=lof_reOrderNodes(asBuilt.osss)
    asBuilt.angle=solutions[4][1].angle
    asBuilt.offset=solutions[4][1].offset
    save("v2.0/results/partial_sols/final.jld", "asBuilt", asBuilt,"objective",solution["objective"],"optIds",Ids, "domain",domain, "solve_time",solution["solve_time"], "continuous_obj",solution["objective_lb"])
    return (asBuilt,solution["objective"],Ids,domain)
end

#=function lpf_buildMidMilp(solutions,nID)
    optLout,mxObj,cntrl=lpd_fnlProbSetUp()
    (value,index)=findmin(solutions[2])
    mxObj=ceil(Int64,value)
    #optLout=solutions[3][index]
    optLout=[]
    domain=lof_layoutEez_Sum(solutions,cntrl)
    domain.angle=solutions[4][1].angle
    domain.offset=solutions[4][1].offset
    ppf_main2mfile(domain,optLout,mxObj,cntrl)
    solution,nw_data=milp_main("milp",20000)
    asBuilt,Ids=ppm_reCnstrctSol(solution,nw_data,domain)
    asBuilt.pccs=lof_reOrderNodes(asBuilt.pccs)
    asBuilt.gens=lof_reOrderNodes(asBuilt.gens)
    asBuilt.osss=lof_reOrderNodes(asBuilt.osss)
    asBuilt.angle=solutions[4][1].angle
    asBuilt.offset=solutions[4][1].offset
    save("v2.0/results/mid_sols/mid"*nID*".jld", "asBuilt", asBuilt,"objective",solution["objective"],"optIds",optIds, "domain",domain, "solve_time",solution["solve_time"], "continuous_obj",solution["objective_lb"])
    return (asBuilt,solution["objective"],Ids,domain)
end=#


function lpf_buildMidMilp(solutions)
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

        if length(solutionsMp[1]) != 0
            solutionsPair[4][length(solutionsPair[4])].oOcbls=solutionsMp[4][length(solutionsMp[4])].oOcbls
            solutionsPair[4][length(solutionsPair[4])].oPcbls=solutionsMp[4][length(solutionsMp[4])].oPcbls
            solutionsPair[4][length(solutionsPair[4])].oPXcbls=solutionsMp[4][length(solutionsMp[4])].oPXcbls
            solutionsPair[4][length(solutionsPair[4])].gOcbls=solutionsMp[4][length(solutionsMp[4])].gOcbls
            solutionsPair[4][length(solutionsPair[4])].gPcbls=solutionsMp[4][length(solutionsMp[4])].gPcbls
            solutionsPair[4][length(solutionsPair[4])].dcCbls=solutionsMp[4][length(solutionsMp[4])].dcCbls
        else
            solut=load("v2.0/results/cables/cables.jld")["domain"]
            solutionsPair[4][length(solutionsPair[4])].oOcbls=solut.oOcbls
            solutionsPair[4][length(solutionsPair[4])].oPcbls=solut.oPcbls
            solutionsPair[4][length(solutionsPair[4])].oPXcbls=solut.oPXcbls
            solutionsPair[4][length(solutionsPair[4])].gOcbls=solut.gOcbls
            solutionsPair[4][length(solutionsPair[4])].gPcbls=solut.gPcbls
            solutionsPair[4][length(solutionsPair[4])].dcCbls=solut.dcCbls
            #=solutionsPair[4][length(solutionsPair[4])].oOcbls=solutions[4][length(solutions[4])].oOcbls
            solutionsPair[4][length(solutionsPair[4])].oPcbls=solutions[4][length(solutions[4])].oPcbls
            solutionsPair[4][length(solutionsPair[4])].oPXcbls=solutions[4][length(solutions[4])].oPXcbls
            solutionsPair[4][length(solutionsPair[4])].gOcbls=solutions[4][length(solutions[4])].gOcbls
            solutionsPair[4][length(solutionsPair[4])].gPcbls=solutions[4][length(solutions[4])].gPcbls
            solutionsPair[4][length(solutionsPair[4])].dcCbls=solutions[4][length(solutions[4])].dcCbls=#
        end

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
        save("v2.0/results/mid_sols2/mid"*nID*".jld", "asBuilt", asBuilt,"objective",solution["objective"],"optIds",Ids, "domain",domain, "solve_time",solution["solve_time"], "continuous_obj",solution["objective_lb"])
        push!(solutionsMp[1],deepcopy(asBuilt))
        push!(solutionsMp[2],solution["objective"])
        push!(solutionsMp[3],Ids)
        push!(solutionsMp[4],domain)
    end
    return solutionsMp
end

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
