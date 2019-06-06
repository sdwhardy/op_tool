#=
In this file all input cost data is set
=#

#Sets the exchange rate
#original input data is in 2008 British Pounds
function cstD_xchg()
    return 1.16
end

#Sets Cost factor for cable compensation
#bin is a binary variable that which is true if a cable connects 2 OSS and false if from OSS to PCC
#ks is a set of cost factors set within this file
function cstD_QC(bin,ks)
    p2e=cstD_xchg()
    #offshore(OSS) to onshore(PCC) connection
    ks.Qc_oss=0.025*p2e#M£/MVAr
    ks.Qc_pcc=0.015*p2e#M£/MVAr
    #offshore(OSS) to offshore(OSS) connection
    if bin == true
        ks.Qc_pcc=ks.Qc_oss
    end
    return nothing
end

#Sets values of all cost factors discribed below
#the structure of object ks is described in file cst_structure.jl
function cstD_cfs()
    ks=cstS_ks()#create an instance of object ks
    p2e=cstD_xchg()#get the exchange rate
    ks.FC_ac=5*p2e#fixed AC cost
    ks.FC_dc=25.0*p2e#fixed DC cost
    ks.dc=0.2#penalization factor for different than 2 xfrms
    ks.f_ct=0.02*p2e#generating plant variable cost
    ks.p_ct=0.025*p2e#substructure variable cost
    ks.c_ct=0.11*p2e#hvdc converter variable cost
    cstD_QC(true,ks)#Q cost onshore/offfshore (see cstD_QC(bin,ks))
    ks.life=25.0#lifetime of wind farm
    ks.T_op=365*24*ks.life#Operational lifetime in hours
    ks.E_op=50.0*10^(-6)*p2e#Energy price £/Wh
    ks.cf=10#Capitalization factor
    return ks
end
