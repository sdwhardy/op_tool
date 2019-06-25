################################################################################
################################ Mapping args ##################################
################################################################################
#Set up all OSS options to be included into large MILP
#must include all OSS in smaller problems
function lpd_fullProbSetUp()
    solmin=Array{Int64,1}()
    objmin=10000
    cntrls=Array{control,1}()
    cntrl=control()
<<<<<<< HEAD
    neibs=[[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18]]
=======
    neibs=[[2],[3],[4],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18]]
>>>>>>> 7280fa4894d55133ede8aa629f3ff1d5759d3655
    for neib in neibs
        cntrl=control()
        cntrl.xrad=true
        cntrl.neib1=true
        cntrl.neib3=true
        cntrl.xradPcc=false
        cntrl.xradHlf=false
        cntrl.xXrad=cntrl.xXrad=neib
        cntrl.xXneib1=cntrl.xXrad
        cntrl.xXneib3=cntrl.xXrad
        push!(cntrls,cntrl)
    end
    return solmin, objmin, cntrls
end

#Final milp setup
function lpd_fnlProbSetUp()
    solmin=Array{Int64,1}()
    objmin=10000
    cntrls=control()
    cntrls.xrad=false
    cntrls.neib1=false
    cntrls.neib3=false
    cntrls.xradPcc=true
    cntrls.xradHlf=true
    cntrls.xXrad=cntrls.xXrad=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18]
    #cntrls.xXrad=cntrls.xXrad=[1]
    cntrls.xXneib1=cntrls.xXrad
    cntrls.xXneib3=cntrls.xXrad
    return solmin, objmin, cntrls
end
