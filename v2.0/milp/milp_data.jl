#=Set up all OSS options to be included into large MILP
#must include all OSS in smaller problems
function lpd_fullProbSetUp()
    solmin=Array{Int64,1}()
    objmin=10000
    cntrls=control()
    cntrls.xrad=true
    cntrls.neib1=false
    cntrls.neib3=false
    cntrls.xradPcc=false
    cntrls.xradHlf=false
    cntrls.xXrad=cntrls.xXrad=[1]
    cntrls.xXneib1=cntrls.xXrad
    cntrls.xXneib3=cntrls.xXrad
    return solmin, objmin, cntrls
end=#
