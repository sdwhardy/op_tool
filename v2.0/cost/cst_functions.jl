################################################################################
################# Main Logic functions for cost of eqp #########################
################################################################################
#Cost of HV connection between 2 OSS

function cstF_HVcbl2oss(l,S,kv,wp)#3
    os=true#offshore to offshore connection
    cb=cstF_cbl_ttl(l,S,kv,wp,os)
    cb.costs.ttl=cb.costs.ttl+(2*cstD_cfs().FC_ac)
    eqpF_puImped(l,cb)
    return cb
end

#Cost of HV connection to pcc no transformer
function cstF_HVcbl2pcc(l,S,kv,wp)#4
    os=false#offshore to onshore connection
    cb=cstF_cbl_ttl(l,S,kv,wp,os)
    cb.costs.ttl=cb.costs.ttl+(cstD_cfs().FC_ac)
    eqpF_puImped(l,cb)
    return cb
end

#HV connection to PCC including PCC transformer
function cstF_HVcbl2pccX(l,S,kv,wp)#5
    os=false#offshore to onshore connection
    cbx=cstF_cblxfo_ttl(l,S,kv,wp,os)
    cbx.costs.ttl=cbx.costs.ttl+(cstD_cfs().FC_ac)
    eqpF_sumryPu(l,kv,cbx)
    return cbx
end

#Cost of an MV connection to an offshore OSS including transformer
function cstF_MVcbl2ossX(l,S,kv,wp)#1
    os=true#offshore to offshore connection
    cbx=cstF_cblxfo_ttl(l,S,kv,wp,os)
    eqpF_sumryPu(l,kv,cbx)
    return cbx
end

#Cost of MV cbl connection direct to a PCC including pcc transformer
function cstF_MVcbl2pccX(l,S,kv,wp)#2
    os=false#offshore to onshore connection
    cbx=cstF_cblxfo_ttl(l,S,kv,wp,os)
    eqpF_sumryPu(l,kv,cbx)
    return cbx
end

#Cost of DC line from OSS to PCC
function cstF_DCcbl2pcc(l,S,wp,oss,gens,ocn)#6
    cbcn=cstF_dcCblCon_ttl(l,S,wp)
    cstF_correctDc(cbcn,oss,gens,ocn)
    rxb=eqpD_dcAdm()
    cbcn.cable.ohm=rxb[1]
    cbcn.cable.xl=rxb[2]
    cbcn.cable.yc=rxb[3]
    return cbcn
end

################################################################################
################ Support functions for Cost of HV/MVAC cable ###################
################################################################################
#Cost of optimal cable under l,S,kv,wp,os
function cstF_cbl_ttl(l,S,kv,wp,os)
    cbls_all=[]
    cbls_2use=[]
    cb=cbl()#create 1 object of type cbl_costs
    cb.costs.ttl=Inf#Initialize to very high total for comparison
    ks=cstD_cfs()#get the cost factors
    cbls_all=eqpF_cbl_opt(kv,cbls_all,l)#returns all base data available for kv cables
    cbls_2use=eqpF_cbl_sel(cbls_all,S,l)#Selects 1 to ...(adjust in data) of the cables in parallel appropriate for required capacity

    for value in cbls_2use
        value.costs.cbc=cstF_cbl_cpx(value)#capex
        value.costs.qc=cstF_cbl_q(value,os,ks)#cost of compensastion
        value.costs.rlc=cstF_acCbl_rlc(value,S,ks,wp)#cost of losses
        value.costs.cm=cstF_eqp_cm(value,ks)#corrective maintenance
        value.costs.eens=eensF_eqp_eens(value,S,ks,wp)#eens calculation
        value.costs.ttl=cstF_cbl_sum(value.costs)#totals the cable cost
        if value.costs.ttl<cb.costs.ttl
            cb=deepcopy(value)#store lowest cost option
        end
    end
    return cb#return optimal cable object
end

#CAPEX of cable
function cstF_cbl_cpx(cbl)
    cbc=cbl.length*cbl.num*cbl.cost
    return cbc
end

#AC compensation cost
function cstF_cbl_q(cbl,os,ks)
    cstD_QC(os,ks)
#div sets compensation to 50-50 split
    f=eqpD_freq()
    div=0.5
    A=cbl.farrad*cbl.length*cbl.num
    Q=2*pi*f*cbl.volt^2*A
    Q_oss=Q*div
    Q_pcc=Q*(1-div)
    qc=ks.Qc_oss*Q_oss+ks.Qc_pcc*Q_pcc
    return qc
end

#AC cable loss cost
function cstF_acCbl_rlc(cbl,s,ks,wp)
    eta=eqpD_xEFF()
    A=s*eta#eta is the efficiencu of a feeder transformer, s power to transmit
    B=cbl.volt*sqrt(3)
    I=A/B#cable current
    R=(cbl.length*cbl.ohm)/(cbl.num)#cable resistance
    #I^2R losses times cost factors
    #delta is related to wind profile, T_op lifetime hours and E_op cost of energy
    rlc=I^2*R*ks.T_op*ks.E_op*wp.delta
    return rlc
end

#corrective maintenance of equipment
#eq is the equipment, k are the cost factors
function cstF_eqp_cm(eq,k)
    A=(eq.num*eq.mc)
    B=(1/eq.fr)
    C=(eq.mttr*30.417*24.0)/8760.0#changes time base of mttr of equipment: mnth-hrs/yr-hrs
    cm=k.cf*(A/(B+C))
    return cm
end

#sums all cable costs and returns the total
function cstF_cbl_sum(res)
    ttl=res.rlc+res.qc+res.cbc+res.cm+res.eens
    return ttl
end

################################################################################
###################  Support functions for Transformers ########################
################################################################################
#OSS/PCC transformer cost

function cstF_xfo_ttl(S,wp,o2o)
    ks=cstD_cfs()#get the cost factors
    xfm=xfo()#create transformer object
    xfm.costs.ttl=Inf
    xfos_all=eqpD_xfo_opt()#get all available xformer sizes
    xfos_2use=eqpF_xfo_sel(xfos_all,S)#select combinations to calculate

    for value in xfos_2use
        if o2o==true
            value.costs.cpx=cstF_oss_cpx(value,ks)#capex oss
        else
            value.costs.cpx=cstF_pcc_cpx(value)#capex pcc
        end

        value.costs.tlc=cstF_xfo_tlc(value,S,ks,wp)#cost of losses
        value.costs.cm=cstF_eqp_cm(value,ks)#corrective maintenance
        value.costs.eens=eensF_eqp_eens(value,S,ks,wp)#eens calculation
        value.costs.ttl=cstF_xfo_sum(value.costs)#totals the cable cost
        #store lowest cost option
        if value.costs.ttl<xfm.costs.ttl
            xfm=deepcopy(value)
        end
    end
    return xfm
end

#OSS platform CAPEX
#excluding fixed platform cost
function cstF_oss_cpx(x,k)
    A=(1+k.dc*(x.num-2))
    B=(k.f_ct+k.p_ct)
    cpx=A*B*x.num*x.mva
    return cpx
end

#PCC transformer CAPEX
function cstF_pcc_cpx(x)
    cpx=0.02621*(x.mva*x.num)^0.7513
    return cpx
end

#xfm Losses Calculation
function cstF_xfo_tlc(xfo,S,ks,wp)
    pf=eqpD_pf()
    tlc=S*pf*(1-xfo.eta)*ks.T_op*ks.E_op*wp.delta
    return tlc
end

#sums all transformer/converter costs and returns the total
function cstF_xfo_sum(res)
    ttl=res.cpx+res.tlc+res.cm+res.eens
    return ttl
end
##########################################################################################
##################  Support functions for Cable and transformer in Series ################
##########################################################################################
#Cost of optimal cable under l,S,kv,wp,os considering an OSS
function cstF_cblxfo_ttl(l,S,kv,wp,os)
    cbls_all=[]
    cbls_2use=[]
    cb=cbl()#create 1 object of type cable
    xfm=xfo()#create 1 object of type transformer
    xfm=cstF_xfo_ttl(S,wp,os)#get transformer sized with no cable
    cb.costs.ttl=Inf#Initialize cable to very high total for comparison
    cb.costs.eens=Inf#Initialize cable to very high total for comparison
    ks=cstD_cfs()#get the cost factors
    cbls_all=eqpF_cbl_opt(kv,cbls_all,l)#returns all base data available for kv cables
    cbls_2use=eqpF_cbl_sel(cbls_all,S,l)#Selects 1 to 10 of the cables in parallel appropriate for reuired capacity

    # loop through all cables
    for value in cbls_2use
        value.costs.cbc=cstF_cbl_cpx(value)#capex
        value.costs.qc=cstF_cbl_q(value,os,ks)#cost of compensastion
        value.costs.rlc=cstF_acCbl_rlc(value,S,ks,wp)#cost of losses
        value.costs.cm=cstF_eqp_cm(value,ks)#corrective maintenance
        value.costs.eens=eensF_owpp_eens(xfm,value,S,ks,wp)#eens calculation
        value.costs.ttl=cstF_cbl_sum(value.costs)#totals the cable cost
        #store lowest cost option
        if value.costs.ttl<cb.costs.ttl
            cb=deepcopy(value)
        end
    end

    #Store values as an owpp object and return
    sys=owpp()
    sys.mva=S
    sys.km=l
    sys.wp=wp
    sys.cable=cb
    sys.xfm=xfm
    cstF_owpp_sum(sys)#summarizes final values
    return sys#return optimal cable and transformer
end

#summarizes owpp resulst concisely
function cstF_owpp_sum(owp)
    owp.costs.cpx=owp.xfm.costs.cpx+owp.cable.costs.cbc+owp.cable.costs.qc
    owp.costs.loss=owp.xfm.costs.tlc+owp.cable.costs.rlc
    owp.costs.opex=owp.cable.costs.eens+owp.xfm.costs.cm+owp.cable.costs.cm#don't add xfm eens already included
    owp.costs.ttl=owp.costs.cpx+owp.costs.opex+owp.costs.loss
    owp.cable.costs.eens=owp.cable.costs.eens-owp.xfm.costs.eens#adjusts cable eens to validate sum
end

################################################################################
################################## DC calculations #############################
################################################################################
function cstF_dcCblCon_ttl(l,S,wp)
    cnv=cstF_cnv_ttl(S,wp)#get converter
    cb=cbl()#create 1 object of type cbl
    cb.costs.ttl=Inf#Initialize cable to very high total for comparison
    ks=cstD_cfs()#get the cost factors
    for kv in [150,300]
        cbls_all=[]
        cbls_2use=[]
        cbls_all=eqpF_cbl_opt(kv,cbls_all,l)#returns all base data available for kv cables
        cbls_2use=eqpF_cbl_sel(cbls_all,S,l)#Selects 1 to 10 of the cables in parallel appropriate for required capacity

        # loop through all cables
        for value in cbls_2use
            value.costs.cbc=cstF_cbl_cpx(value)#capex
            value.costs.qc=0.0#cost of compensastion
            value.costs.cm=cstF_eqp_cm(value,ks)#corrective maintenance
            value.costs.rlc=cstF_HVDC_rlc(value,S,ks.T_op*ks.E_op*wp.delta)
            value.costs.eens=eensF_owpp_eens(cnv,value,S,ks,wp)#eens calculation
            value.costs.ttl=cstF_cbl_sum(value.costs)#totals the cable cost
            #store lowest cost option
            if value.costs.ttl<cb.costs.ttl
                cb=deepcopy(value)
            end
        end
    end
    #Store values as an owpp object and return
    sys=owpp()
    sys.mva=S
    sys.km=l
    sys.wp=wp
    sys.cable=cb
    cnv.costs.cpx=cnv.costs.cpx+cstF_HVDC_opc(cnv.mva,cnv.num)
    cnv.costs.cm=cnv.costs.cm+cstF_eqp_cm(cnv,ks)#corrective maintenance
    cnv.costs.tlc=cnv.costs.tlc+cstF_HVDC_tlcPcc(cb,S,ks.T_op*ks.E_op*wp.delta)
    cnv.costs.ttl=cstF_xfo_sum(cnv.costs)
    sys.xfm=cnv
    sys.cable.costs.eens=sys.cable.costs.eens+cnv.costs.eens
    cstF_owpp_sum(sys)
    return sys#return optimal cable and converter
end

#Removes AC OSS cost if DC is used
function cstF_correctDc(cbcn,oss,gens,ocn)
    #makes all oss to gen distances
    genDists=Array{Float64,1}()
    mvConects=Array{Int64,1}()
    for value in gens
        push!(genDists,lof_pnt2pnt_dist(value.coord,oss.coord))
    end

    for (index, value) in enumerate(genDists)
        answer=cstF_mvConnect(value,gens[index],oss,ocn)
        if answer==true
            push!(mvConects,index)
        end
    end

    for value in mvConects
        S=gens[value].mva
        wp=wndF_wndPrf([gens[value].name])
        oppc=cstF_xfo_ttl(S,wp,true).costs.cpx
        xfm=cstF_xfo_ttl(S,wp,false).costs.cpx
        cbcn.costs.ttl=cbcn.costs.ttl-oppc+xfm
    end
    cbcn.costs.ttl=cbcn.costs.ttl-(cstD_cfs().FC_ac*(length(gens)-length(mvConects)))
end

function cstF_mvConnect(l,gen,oss,ocn)
    S=gen.mva
    mv=gen.kv
    hv=lod_ossKv()
    mvCbl=cstF_MVcbl2pccXChk(l,S,mv,[gen.name],ocn.gPcbls).costs.ttl
    hvCbl=cstF_HVcbl2ossChk(l-1,S,hv,[gen.name],ocn.oOcbls).costs.ttl+cstF_MVcbl2ossXChk(1,S,mv,[gen.name],ocn.gOcbls).costs.ttl-cstD_cfs().FC_ac
    if mvCbl<=hvCbl
        answer=true
    else
        answer=false
    end
    return answer
end
################################################################################
################################# DC Cable Costs ###############################
################################################################################
#DC RLC Calculation
function cstF_HVDC_rlc(cbl,mva,cst_fct)
    A=mva*eqpD_invEta()*eqpD_recEta()
    B=cbl.volt
    I=A/B
    R=(cbl.length*cbl.ohm)/(cbl.num)
    rlc=I^2*R*cst_fct*0.5
    return rlc
end

################################################################################
################################ Converter Costs ###############################
################################################################################
#OSS converter cost
function cstF_cnv_ttl(S,wp)
    ks=cstD_cfs()#get the cost factors
    cnvrt=xfo()#create converter object
    cnvrt.costs.ttl=Inf
    cnvs_2use=eqpF_cnv_sel(S)#select combinations to calculate

    for value in cnvs_2use
        value.costs.tlc=cstF_HVDC_tlcOSS(S,value.eta,ks.T_op*ks.E_op*wp.delta)
        value.costs.cm=cstF_eqp_cm(value,ks)
        value.costs.cpx=cstF_HVDC_oppc(value.mva,value.num,ks)#capex oss
        value.costs.tlc=cstF_xfo_tlc(value,S,ks,wp)#cost of losses
        value.costs.cm=cstF_eqp_cm(value,ks)#corrective maintenance
        value.costs.eens=eensF_eqp_eens(value,S,ks,wp)#eens calculation
        value.costs.ttl=cstF_xfo_sum(value.costs)
        #store lowest cost option
        if (value.costs.ttl<cnvrt.costs.ttl)
            cnvrt=deepcopy(value)

        end
    end
    return cnvrt
end

#OSS hvdc tlc
function cstF_HVDC_tlcOSS(mva,eta,cst_fct)
    tlc_oss=mva*(1-eta)*cst_fct
    return tlc_oss
end

#OPPC HVDC
function cstF_HVDC_oppc(mva,num,k)
    A=(1+k.dc*(num-2))
    oppc=k.FC_dc+A*k.c_ct*num*mva
    return oppc
end

#OPC HVDC
function cstF_HVDC_opc(mva,num)
    opc=0.08148*(mva*num)
    return opc
end

function cstF_HVDC_tlcPcc(cbl,mva,cst_fct)
    #PCC tlc calculation
    A=mva*eqpD_recEta()
    B=(cbl.volt)
    I=(A/B)
    R=0.5*(cbl.ohm*cbl.length)/cbl.num
    D=A-I^2*R
    tlc_pcc=D*(1-eqpD_invEta())*cst_fct
    return tlc_pcc
end
