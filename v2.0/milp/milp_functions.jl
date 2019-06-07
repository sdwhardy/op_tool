#Calls Power Models on the input file
function milp_main(name)
    filename="v2.0/results/"*name*".m"
    mv("v2.0/results/tnep_map.mat", filename, force=true)
    solver=GurobiSolver(Presolve=1)
    result = run_tnep(filename, DCPPowerModel, solver)
    network_data = PowerModels.parse_file(filename)
    return result, network_data
end
