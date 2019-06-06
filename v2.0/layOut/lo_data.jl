################################################################################
################################ ARC DATA ######################################
################################################################################
#set min oss to oss arc length
function lod_mnKm()
    return 2.0
end
################################################################################
################################ NODE DATA #####################################
################################################################################
##############################
########### OSSs #############
#distance from owpp to place nearest oss on path to neighbouring owpp
function lod_rad()
    return 2
end

#fraction of distance to place oss for mid point compensation
function lod_rdFrc()
    return 0.5
end

#furthest # of owpp to add midpoint compensation
function lod_frcNum()
    return 4
end

#sets max distance upstream to connect gen to oss and which wind profiles are included at OSS
function lod_gen2Noss()
    return 2
end
##############################
########## PCCs ##############
function lod_pccGps()
    pcc=Array{Tuple,1}()
##### Belgium #####
    push!(pcc,(2.939692,51.239737))
    push!(pcc,(3.183611,51.32694))
    return pcc
end
##############################
########## Gens ##############
function lod_gensGps()
    c=Array{Tuple,1}()
    wnd=Array{String,1}()
    p=Array{Float64,1}()
##### Belgium #####
    #Norther
    push!(c,(3.015833,51.52806))
    push!(p,250.0)
    push!(wnd,"Norther")
    #Thornton
    push!(c,((2.97+2.919972)/2,(51.56+51.53997)/2))
    push!(p,250.0)
    push!(wnd,"Thornton")
    #Rentel
    push!(c,(2.939972,51.59))
    push!(p,250.0)
    push!(wnd,"Rentel")
    #Northwind
    push!(c,(2.900972,51.61897))
    push!(p,250.0)
    push!(wnd,"Northwind")
    #Seastar
    push!(c,(2.859972,51.63))
    push!(p,250.0)
    push!(wnd,"Seastar")
    #Nobelwind/Belwind
    push!(c,((2.819972+2.799972)/2,(51.664+51.67)/2))
    push!(p,250.0)
    push!(wnd,"Nobelwind")
    #Northwester
    push!(c,(2.757,51.68597))
    push!(p,250.0)
    push!(wnd,"Northwester")
    #Mermaid
    push!(c,(2.74,51.71997))
    push!(p,250.0)
    push!(wnd,"Mermaid")
    return c,p,wnd
end

################################################################################
################################ ELEC DATA #####################################
################################################################################
#set onshore transmission voltage
function lod_pccKv()
    return 220.0
end

#set offshore transmission voltage
function lod_ossKv()
    return 220.0
end

#set collector voltage
function lod_cncsKv()
    return 66.0
end
