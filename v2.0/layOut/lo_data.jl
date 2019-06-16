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
function lod_Belgium()
    return true
end
function lod_pccGps()
    pcc=Array{Tuple,1}()
    if lod_Belgium()==true
    ##### Belgium #####
        push!(pcc,(2.939692,51.239737))
        push!(pcc,(3.183611,51.32694))
    else
        ################################## India ###################################
        #Dui
        push!(pcc,(71.0,20.71))
        #Barbarkot (Ultratech)
        push!(pcc,(71.399491,20.866641))
    end
    return pcc
end
##############################
########## Gens ##############

function lod_gensGps()
    c=Array{Tuple,1}()
    wnd=Array{String,1}()
    p=Array{Float64,1}()
##### Belgium #####
    if lod_Belgium()==true
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
    else
        #A5
        push!(c,(71.375,20.53))
        push!(p,500.0)
        push!(wnd,"A5")
        #A1
        push!(c,(71.4,20.58))
        push!(p,500.0)
        push!(wnd,"A1")
        #A2
        push!(c,(71.53,20.55))
        push!(p,500.0)
        push!(wnd,"A2")
        #A3
        push!(c,(71.5,20.64))
        push!(p,500.0)
        push!(wnd,"A3")
        #A4
        push!(c,(71.435,20.53))
        push!(p,500.0)
        push!(wnd,"A4")
        #A6
        push!(c,(71.525,20.45))
        push!(p,500.0)
        push!(wnd,"A6")
        #A7
        push!(c,(71.44,20.475))
        push!(p,500.0)
        push!(wnd,"A7")
        #A8
        push!(c,(71.36,20.475))
        push!(p,500.0)
        push!(wnd,"A8")
        #A9
        push!(c,(71.27,20.475))
        push!(p,500.0)
        push!(wnd,"A9")
        #A10
        push!(c,(71.15,20.47))
        push!(p,500.0)
        push!(wnd,"A10")
        #A11
        push!(c,(71.11,20.39))
        push!(p,500.0)
        push!(wnd,"A11")
        #A12
        push!(c,(71.28,20.415))
        push!(p,500.0)
        push!(wnd,"A12")
        #A13
        push!(c,(71.25,20.365))
        push!(p,500.0)
        push!(wnd,"A13")
        #A14
        push!(c,(71.425,20.415))
        push!(p,500.0)
        push!(wnd,"A14")
        #A15
        push!(c,(71.37,20.365))
        push!(p,500.0)
        push!(wnd,"A15")
        #A16
        push!(c,(71.5,20.365))
        push!(p,500.0)
        push!(wnd,"A16")
        #A17
        push!(c,(71.5,20.32))
        push!(p,500.0)
        push!(wnd,"A17")
        #A18
        push!(c,(71.35,20.32))
        push!(p,500.0)
        push!(wnd,"A18")
        #A19
        push!(c,(71.45,20.27))
        push!(p,500.0)
        push!(wnd,"A19")
    end
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

#Grid PU mva
function lod_cnceMva()
    if lod_Belgium()==true
        mva=250.0
    else
        mva=500.0
    end
    return mva
end
