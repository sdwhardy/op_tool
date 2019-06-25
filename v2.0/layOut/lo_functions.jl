################################################################################
########################### Main layout logic ##################################
################################################################################
function lof_layoutEez(cnt)
    #cnt=lpd_fullProbSetUp()[3][1]
    ocean=eez()#build the eez in the ocean
    ocean.pccs=lof_layPccs()#add the gps of PCCs
    println("PCCs positioned at:")
    for value in ocean.pccs
        print(value.num)
        print(" - ")
        println(value.gps)
    end

    ocean.gens=lof_layGens(ocean)#add the gps of OWPPs
    println("OWPPs positioned at:")
    for value in ocean.gens
        print(value.num)
        print(" - ")
        println(value.gps)
    end
    base=lof_bseCrd(ocean)#find base coordinates
    print("Base coordinates are: ")
    println(base)
    lof_gps2cartesian(ocean.gens,base)#projects owpps onto cartesian plane
    lof_gps2cartesian(ocean.pccs,base)#projects pccs onto cartesian plane
    println("GPS coordinates projected onto cartesian plane.")
    lof_transformAxis(ocean)
    println("Axis transformed.")
    lof_osss(ocean,cnt)#add all osss within boundary
    println("OSSs positioned at:")
    for value in ocean.osss
        print(value.num)
        print(" - ")
        println(value.coord)
    end
    lof_layoutEez_arcs(ocean,cnt)
    ppf_printOcnXY(ocean)
    return ocean
end

#Mian logic for final milp set up
function lof_layoutEez_Sum(solutions,cntrl)
    ocean=lof_layoutEez_nodes(solutions,cntrl)
    ocean.oOcbls=solutions[4][length(solutions[4])].oOcbls
    ocean.oPcbls=solutions[4][length(solutions[4])].oPcbls
    ocean.oPXcbls=solutions[4][length(solutions[4])].oPXcbls
    ocean.gOcbls=solutions[4][length(solutions[4])].gOcbls
    ocean.gPcbls=solutions[4][length(solutions[4])].gPcbls
    ocean.dcCbls=solutions[4][length(solutions[4])].dcCbls
    println("Node Layout Complete!")
    println(string(length(ocean.osss))*" OSSs positioned at:")
    for value in ocean.osss
        print(value.num)
        print(" - ")
        println(value.coord)
    end
    lof_layoutEez_arcs(ocean,cntrl)
    return ocean
end

#Extracts set up solution nodes
function lof_layoutEez_nodes(sols,cnt)
    ocean=eez()
    all=eez()
    ocean.gens=deepcopy(sols[4][1].gens)
    ocean.pccs=deepcopy(sols[4][1].pccs)
    for sol in sols[1]
        lof_loadNodes(all.osss,sol.osss)
    end

    num=ocean.gens[length(ocean.gens)].num+1
    ocean.osss,num=lof_uniqueNodes(ocean.osss,all.osss,num)
    return ocean
end

#Loads the nd into nds
function lof_loadNodes(osss,nosss)
    for oss in nosss
        push!(osss,deepcopy(oss))
    end
end

#Keeps only unique nodes
function lof_uniqueNodes(ocn,nds,num)
    eyeDs=Array{String,1}()
    for nd in nds
        push!(eyeDs,nd.id)
    end
    eyeDs=unique(eyeDs)
    for eyeD in eyeDs
        for nd in nds
            if string(eyeD)==(nd.id)
                nd.num=deepcopy(num)
                push!(ocn,nd)
                num=num+1
                @goto uniqNodes
            end
        end
        @label uniqNodes
    end
    return ocn,num
end

#Main arcs creating logic for given nodes
function lof_layoutEez_arcs(ocean,cnt)
    lof_GoArcs(ocean,cnt)#add all gen to oss arcs within boundary
    print(length(ocean.gOarcs))
    println(" candidate OWPP to OSS arcs contructed.")
    lof_GpArcs(ocean)#add all gen to pcc arcs within boundary
    print(length(ocean.gParcs))
    println(" candidate OWPP to PCC arcs contructed.")
    lof_OoArcs(ocean,cnt)#add all oss to oss arcs within boundary
    print(length(ocean.oOarcs))
    println(" OSS to OSS arcs constructed.")
    lof_OpArcs(ocean,cnt)#add all oss to pcc arcs within boundary
    print(length(ocean.oParcs))
    println(" candidate OSS to PCC arcs constructed.")
    println("EEZ layout complete.")
end

#Re orders the the array in num order after the milp
function lof_reOrderNodes(nds)
    dummy=Array{node,1}()
    Ids=Array{Float64,1}()
    for nd in nds
        push!(Ids,nd.num)
    end
    Ids=sort(Ids)
    for i in Ids
        for nd in nds
            if i==nd.num
                push!(dummy,nd)
            end
        end
    end
    nds=deepcopy(dummy)
    return nds
end

#re numbers Gens after placement
function lof_gensOrder(gens,ocn,num)
    lnths=Array{Float64,1}()
    ordrdGens=Array{node,1}()
    for gen in gens
        pcc_close=lof_xClosestPcc(gen,ocn.pccs)
        push!(lnths,lof_pnt2pnt_dist(gen.coord,pcc_close.coord))
    end
    for lps=1:1:length(lnths)
        push!(ordrdGens,gens[findmin(lnths)[2]])
        ordrdGens[length(ordrdGens)].num=deepcopy(num+lps)
        lnths[findmin(lnths)[2]]=Inf
    end
    gens = ordrdGens
    return gens
end

function lof_avePcc(pccs)
    avPcc=node()
    avPcc.coord.x=0
    avPcc.coord.y=0
    for pcc in pccs
        avPcc.coord.x=avPcc.coord.x+pcc.coord.x
        avPcc.coord.y=avPcc.coord.y+pcc.coord.y
    end
    avPcc.coord.x=avPcc.coord.x/length(pccs)
    avPcc.coord.y=avPcc.coord.y/length(pccs)
    return avPcc
end
################################################################################
########################### Oss layout #########################################
################################################################################
#OSS layout control logic
function lof_osss(ocn,cnt)
    cns=reverse(ocn.gens,1)
    osss=Array{node,1}()

    for i=1:length(cns)
        if cnt.xrad==true
            lof_ossXradius(i,cns,osss,cnt)#lay oss version 3
        end
        if cnt.neib1==true
            lof_oss1neibs(i,cns,osss,cnt)#lay oss version 3
        end
        if cnt.neib3==true
            lof_oss3neibs(i,cns,osss,cnt)
        end
        if cnt.xradPcc==true
            id=8
            rad=lod_rad()
            lof_ossRadPcc(i,cns,id,ocn.pccs,osss,rad,false)#lay n radius
        end
        if (i<=lod_frcNum() && cnt.xradHlf==true)
            id=9
            rad=lod_rdFrc()
            lof_ossRadPcc(i,cns,id,ocn.pccs,osss,rad,true)#lay halfway
        end
    end
    num=length(ocn.pccs)+length(ocn.gens)
    osss=lof_ossOrder(osss,ocn,num)
    lof_wndPfOss(osss,ocn)
    ocn.osss=deepcopy(osss)
end

#re numbers OSSs after placement
function lof_ossOrder(osss,ocn,num)
    lnths=Array{Float64,1}()
    ordrdOsss=Array{node,1}()
    for oss in osss
        pcc_close=lof_xClosestPcc(oss,ocn.pccs)
        push!(lnths,lof_pnt2pnt_dist(oss.coord,pcc_close.coord))
    end
    for lps=1:1:length(lnths)
        push!(ordrdOsss,osss[findmax(lnths)[2]])
        lnths[findmax(lnths)[2]]=0
    end
    ordrdOsss2=Array{node,1}()
    gens=reverse(ocn.gens,1)
    for (index,value) in enumerate(gens)
        for oss in ordrdOsss
            if value.num == oss.dwnstrm
                push!(ordrdOsss2,oss)
            end
        end
    end
    for (index,value) in enumerate(ordrdOsss2)
        value.num=deepcopy(num+index)
    end
    osss = ordrdOsss2
    return osss
end

#Sets OSS wind profiles with all OWPPs wps further from a PCC
function lof_wndPfOss(osss,ocn)
    nos=lod_gen2Noss()#sets offset on owpp away from pcc
    for i in osss
        for j in ocn.gens
            for k in ocn.pccs
                if (lof_pnt2pnt_dist(i.coord,k.coord) <= lof_pnt2pnt_dist(j.coord,k.coord)+nos)
                    push!(i.wnds,j.name)
                    push!(i.mvas,j.mva)
                    @goto wnd_stored
                else
                end
            end
            @label wnd_stored
        end
    end
end
##################################################
##### OSS at radius r on line to X neighbour #####
##################################################
#lays OSS on OWPP MV radius on line to X closest OWPP
function lof_ossXradius(i,cns,osss,cnt)
    num=0.0
    x=deepcopy(cnt.xXrad)
    x_close=lof_xClosestGens(i,cns,x)
    for j=1:length(x_close)
        osub1=node()
        osub2=node()
        osub1.upstrm=cns[i].num
        osub1.dwnstrm=x_close[j].num
        osub2.upstrm=cns[i].num
        osub2.dwnstrm=x_close[j].num
        alpha_beta=reverse([[cns[i].coord.y,x_close[j].coord.y] ones(2)]\[cns[i].coord.x,x_close[j].coord.x])#fits linear model
        osub1.coord,osub2.coord=lof_atXgen(alpha_beta,cns[i],x_close[j])
        osub1.id="3"*string(x[j])*string(cns[i].id)[2:end]*string(x_close[j].id)[2:end]
        num=num+1
        osub2.id="4"*string(x[j])*string(cns[i].id)[2:end]*string(x_close[j].id)[2:end]
        push!(osss,deepcopy(osub1))
        push!(osss,deepcopy(osub2))
        num=num+1
    end
end

#Sorts the relative position of one OWPP to another
function lof_atXgen(mb,p1,p2)
    os=lod_rad()
    xy1=xy()
    xy2=xy()
    if (p1.coord.x == p2.coord.x && p1.coord.y > p2.coord.y)
        xy1.y=p1.coord.y-os
        xy2.y=p2.coord.y+os
    elseif (p1.coord.x == p2.coord.x && p1.coord.y < p2.coord.y)
        xy1.y=p1.coord.y+os
        xy2.y=p2.coord.y-os
    elseif (p1.coord.y == p2.coord.y && p1.coord.x > p2.coord.x)
        xy1.x=p1.coord.x-os
        xy2.x=p2.coord.x+os
    elseif (p1.coord.y == p2.coord.y && p1.coord.x < p2.coord.x)
        xy1.x=p1.coord.x+os
        xy2.x=p2.coord.x-os
    elseif (p1.coord.y < p2.coord.y)
         lof_solvIntersect(xy1,xy2,p1,p2,os,mb)
    elseif (p1.coord.y > p2.coord.y)
        lof_solvIntersect(xy2,xy1,p2,p1,os,mb)
    else
        println("Caution: No OSS Xkm radius placement matched!")
    end
    return xy1,xy2
end

#finds the point on the circle of radius r around the owpp that intersects the line to a neighbouring OWPP
function lof_solvIntersect(xy1,xy2,p1,p2,os,mb)
    xy1.y=p1.coord.y+os
    xy1.x=xy1.y*mb[2]+mb[1]#mb contains the slope and y intercept
    while lof_pnt2pnt_dist(p1.coord,xy1)>2
        xy1.y=xy1.y-0.1
        xy1.x=xy1.y*mb[2]+mb[1]
    end

    xy2.y=p2.coord.y-os
    xy2.x=xy2.y*mb[2]+mb[1]
    while lof_pnt2pnt_dist(p2.coord,xy2)>2
        xy2.y=xy2.y+0.1
        xy2.x=xy2.y*mb[2]+mb[1]
    end
end

#returns the hypotenuse distance between 2 cartesian points
#minimum distance for a path is 1km
function lof_pnt2pnt_dist(pnt1,pnt2)
    hyp=sqrt((pnt2.x-pnt1.x)^2+(pnt2.y-pnt1.y)^2)
    if hyp < 1
        hyp=1
        #println("Arc distance is less than 1km, set to 1km.")
    end
    return hyp
end

#finds x closest owpp neighbours
function lof_xClosestGens(i,cns,x)
    x_close=Array{node,1}()
    for index in x
        if (i-index) >= 1
            push!(x_close,cns[i-index])
        end
    end
    return x_close
end
#=function lof_xClosestGens(i,cns,x)
    x_close=Array{node,1}()
    lnths=Array{Float64,1}()
    for j=i+1:1:length(cns)
        push!(lnths,lof_pnt2pnt_dist(cns[i].coord,cns[j].coord))
    end
    while (length(lnths) != 0 && length(x) != 0 && findmax(x)[1]>length(lnths))
        deleteat!(x,findmax(x)[2])
    end
    lp=1
    while length(x_close)<length(x) && length(lnths) != 0
        mn=findmin(lnths)
        if lp in x
            push!(x_close,cns[mn[2]+i])
        end
        lnths[mn[2]]=Inf
        lp=lp+1
    end
    return x_close
end=#
#############################################
##### OSS at centre line to X neighbour #####
#############################################
#places an OSS halfway between OWPP and X neighbour
function lof_oss1neibs(i,cns,osss,cnt)
    num=0.0
    x=deepcopy(cnt.xXneib1)
    x_close=lof_xClosestGens(i,cns,x)
    for j=1:length(x_close)
        osub=node()
        osub.upstrm=cns[i].num
        osub.dwnstrm=x_close[j].num
        osub.coord=lof_mdOss(x_close[j],cns[i])
        osub.id="5"*string(x[j])*string(cns[i].id)[2:end]*string(x_close[j].id)[2:end]
        push!(osss,deepcopy(osub))
        num=num+1
    end
end

#Finds centre between OWPPs
function lof_mdOss(c1,c2)
    xy0=xy()
    xy0.x=(c1.coord.x+c2.coord.x)/2
    xy0.y=(c1.coord.y+c2.coord.y)/2
    return xy0
end

#####################################################
##### OSS at 1/3 and 2/3 on line to X neighbour #####
#####################################################
function lof_oss3neibs(i,cns,osss,cnt)
    num=0.0
    x=deepcopy(cnt.xXneib3)
    x_close=lof_xClosestGens(i,cns,x)
    xy0=node()
    for j=1:length(x_close)
        osub1=node()
        osub2=node()
        osub1.upstrm=cns[i].num
        osub1.dwnstrm=x_close[j].num
        osub2.upstrm=cns[i].num
        osub2.dwnstrm=x_close[j].num
        xy0.coord=lof_mdOss(x_close[j],cns[i])
        osub1.coord=lof_mdOss(xy0,cns[i])
        osub2.coord=lof_mdOss(x_close[j],xy0)
        osub1.id="6"*string(x[j])*string(cns[i].id)[2:end]*string(x_close[j].id)[2:end]
        num=num+1
        osub2.id="7"*string(x[j])*string(cns[i].id)[2:end]*string(x_close[j].id)[2:end]
        push!(osss,deepcopy(osub1))
        push!(osss,deepcopy(osub2))
        num=num+1
    end
end

#####################################################
##### OSS X km Radius on line to nearest PCC ########
#####################################################
#Places an OSS at X radius on the line towards the nearest PCC
function lof_ossRadPcc(i,cns,id,pccs,osss,rad,frac)
    num=0.0
    x=lof_xClosestPcc(cns[i],pccs)
    if frac == true
        rad=rad*lof_pnt2pnt_dist(cns[i].coord,x.coord)
    end
    osub=node()
    osub.upstrm=cns[i].num
    osub.dwnstrm=x.num
    alpha_beta=reverse([[cns[i].coord.y,x.coord.y] ones(2)]\[cns[i].coord.x,x.coord.x])#fits linear model
    osub.coord=lof_atXPcc(alpha_beta,cns[i],x,rad)
    osub.id=string(id)*string(cns[i].id)[2:end]*string(x.id)[2:end]
    push!(osss,deepcopy(osub))
    num=num+1
    return num
end

#Sorts the relative positions of the OWPP to pcc
function lof_atXPcc(mb,p1,pcc,rad)
    xy1=xy()
    if (p1.coord.x == pcc.coord.x && p1.coord.y > pcc.coord.y)
        xy1.y=p1.coord.y-rad
        xy1.x=p1.coord.x
    elseif (p1.coord.x == pcc.coord.x && p1.coord.y < pcc.coord.y)
        xy1.y=p1.coord.y+rad
        xy1.x=p1.coord.x
    elseif (p1.coord.y == pcc.coord.y && p1.coord.x > pcc.coord.x)
        xy1.x=p1.coord.x-rad
        xy1.y=p1.coord.y
    elseif (p1.coord.y == pcc.coord.y && p1.coord.x < pcc.coord.x)
        xy1.x=p1.coord.x+rad
        xy1.y=p1.coord.y
    elseif (p1.coord.y > pcc.coord.y)
         lof_solvIntersPcc(xy1,p1,rad,mb)
    elseif (p1.coord.y < pcc.coord.y)
          lof_solvIntersPcc(xy1,p1,(-1)*rad,mb)
    end
    return xy1
end

#find closest PCC
function lof_xClosestPcc(i,pc)
    x_close=node()
    lnths=Array{Float64,1}()
    for j=1:length(pc)
        push!(lnths,lof_pnt2pnt_dist(i.coord,pc[j].coord))
    end
    mn=findmin(lnths)
    x_close=pc[mn[2]]
    return x_close
end

#Finds radial point on line to nearest pcc
function lof_solvIntersPcc(xy1,p1,os,mb)
    xy1.y=p1.coord.y-os
    xy1.x=xy1.y*mb[2]+mb[1]
    while lof_pnt2pnt_dist(p1.coord,xy1)<abs(os)
        xy1.y=xy1.y-((abs(os)/os)*0.1)
        xy1.x=xy1.y*mb[2]+mb[1]
    end
end

################################################################################
################################## Arc Layout ##################################
################################################################################

################################################
##### generator to OSS connection paths ########
################################################
#Builds an MV path from an OWPP to a OSS if within range
function lof_GoArcs(ocn,cnt)
    for (index, value) in enumerate(ocn.gens)
        if (length(cnt.xXrad) < (length(ocn.gens)-1))
            mxKm=true
            ggkm=ocn.mnGap
        else
            ggkm=Inf
        end
            for j in ocn.osss
                go_km=lof_pnt2pnt_dist(value.coord,j.coord)
                if ggkm == Inf
                    mxKm=lof_mxMvKm(go_km,value,j,ocn.gOcbls,ocn.oOcbls)
                end
                if (mxKm && go_km <= ggkm)
                    push!(ocn.gOarcs,lof_buildArc(value,j,go_km))
                else
                end
            end
    end
end
#=function lof_GoArcs(ocn,cnt)
    for (index, value) in enumerate(ocn.gens)
            if (length(cnt.xXrad) < (length(ocn.gens)-1))
                forKm=value.num-1
                bacKm=value.num+1
                mxKm=true
            else
                forKm=0
                bacKm=Inf
                mxKm=lof_mxMvKm(go_km,value,j)
            end
            for j in ocn.osss
                go_km=lof_pnt2pnt_dist(value.coord,j.coord)
                if (mxKm && j.upstrm >= forKm && j.dwnstrm <= bacKm)
                    push!(ocn.gOarcs,lof_buildArc(value,j,go_km))
                else
                end
            end
    end
end=#

#Builds owpp to OSS path
function lof_buildArc(tl,hd,km)
    a=arc()
    a.head=hd
    a.tail=tl
    a.lngth=deepcopy(km)
    return a
end

#set maximum distance to connect the gens to oss with MV cable
function lof_mxMvKm(l,gen,oss,gOcbls,oOcbls)
    S=gen.mva
    mv=gen.kv
    hv=lod_ossKv()
    mvCbl=cstF_MVcbl2ossXChk(l,S,mv,[gen.name],gOcbls).costs.ttl
    hvCbl=cstF_HVcbl2ossChk(l-1,S,hv,[gen.name],oOcbls).costs.ttl+cstF_MVcbl2ossXChk(1,S,mv,[gen.name],gOcbls).costs.ttl
    if mvCbl<=hvCbl
        answer=true
    else
        answer=false
    end
    return answer
end

function lof_divSizes(ocn)
    ocn=ocean
    div=lof_pnt2pnt_dist(ocn.gens[length(ocn.gens)].coord,ocn.gens[1].coord)/(length(ocn.gens)-1)
    div2=lof_pnt2pnt_dist(ocn.gens[2].coord,ocn.gens[1].coord)
end
################################################
##### generator to PCC connection paths ########
################################################
#generator to Pcc connection
function lof_GpArcs(ocn)
    #shoreCon=findmax(cnt.xXrad)[1]+1
    #cnct2pcc=ocn.gens[shoreCon]
    for i in ocn.gens
        #if i.num <= cnct2pcc.num
            pcc_close=lof_xClosestPcc(i,ocn.pccs)
            km=lof_pnt2pnt_dist(i.coord,pcc_close.coord)
            #mxKm=lof_mxMv2PccKm(km,i,pcc_close)
            mxKm=true
            if mxKm
                push!(ocn.gParcs,lof_buildArc(i,pcc_close,km))
            end
        #end
    end
end

#set maximum distance to connect the gens to pccs with MV cable
function lof_mxMv2PccKm(l,gen,oss)
    S=gen.mva
    mv=gen.kv
    hv=lod_ossKv()
    wp=wndF_wndPrf([gen.name])
    mvCbl=cstF_MVcbl2pccX(l,S,mv,wp).costs.ttl
    hvCbl=cstF_HVcbl2pccX(l-1,S,hv,wp).costs.ttl+cstF_MVcbl2ossX(1,S,mv,wp).costs.ttl
    if mvCbl<=hvCbl
        answer=true
    else
        answer=false
    end
    return answer
end

##########################################
##### OSS to OSS connection paths ########
##########################################
#OSS to OSS connection
#=function lof_OoArcs(ocn,cnt)
    mnKm=lod_mnKm()#minimum connection distance
    gens=reverse(ocn.gens,1)
    if (length(cnt.xXrad) < length(gens)-1)#apply for setup milps only
        println(ocn.mnGap)
        mnggGapf=ocn.mnGap/2
        mnggGapb=ocn.mnGap/4
        jump=cnt.xXrad[1]
        for (genfrmI, genfrm) in enumerate(gens[1:length(gens)-(jump+1)])
            gen1_pcc=lof_xClosestPcc(genfrm,ocn.pccs)
            gokm_mx=lof_pnt2pnt_dist(genfrm.coord,gen1_pcc.coord)
            gen2_pcc=lof_xClosestPcc(gens[genfrmI+1],ocn.pccs)
            gokm_mn=lof_pnt2pnt_dist(gens[genfrmI+1].coord,gen2_pcc.coord)
            #gokm_mx=gokm+mnggGapf#upper bound for distance to PCC for from oss
            #gokm_mn=gokm-mnggGapb#lower bound for distance to PCC for from oss
            println("goGap: "*string(gokm_mn)*" - "*string(gokm_mx))

            gentoc=gens[genfrmI+jump]
            gentof=gens[genfrmI+jump+1]
            gen3_pcc=lof_xClosestPcc(gentoc,ocn.pccs)
            gen4_pcc=lof_xClosestPcc(gentof,ocn.pccs)
            go2km_mx=lof_pnt2pnt_dist(gentoc.coord,gen3_pcc.coord)
            go2km_mn=lof_pnt2pnt_dist(gentof.coord,gen4_pcc.coord)
            #go2km_mx=ggkm1+ggkm2#upper bound for distance to oss for from oss
            #go2km_mn=ggkm1#lower bound for distance to oss for from oss
            println("ggGap: "*string(go2km_mn)*" - "*string(go2km_mx))
            for (ossfrmI, ossfrm) in enumerate(ocn.osss)
                oss1_pcc=lof_xClosestPcc(ossfrm,ocn.pccs)
                opkm1=lof_pnt2pnt_dist(ossfrm.coord,oss1_pcc.coord)
                if opkm1 >= gokm_mn && opkm1 <= gokm_mx
                    for (osstoI, ossto) in enumerate(ocn.osss[ossfrmI:length(ocn.osss)])
                        oss2_pcc=lof_xClosestPcc(ossto,ocn.pccs)
                        opkm2=lof_pnt2pnt_dist(ossto.coord,oss2_pcc.coord)
                        ookm=lof_pnt2pnt_dist(ossfrm.coord,ossto.coord)
                        if ((opkm2 <= go2km_mx) && (opkm2 >= go2km_mn) && (ookm >= mnKm))
                            push!(ocn.oOarcs,lof_buildArc(ossfrm,ossto,ookm))
                        end
                    end
                end
            end
        end
    else
    end
end=#
function lof_OoArcs(ocn,cnt)
    ossCon=findmax(cnt.xXrad)[1]
    mnKm=lod_mnKm()

    for (index0, value0) in enumerate(ocn.osss)
        if (length(cnt.xXrad) < length(ocn.gens)-1)
            forKm=value0.upstrm-1
            bacKm=value0.dwnstrm-1
        else
            forKm=0
            bacKm=Inf
            upKm=value0.dwnstrm
        end

        for j=(index0+1):length(ocn.osss)
                km=lof_pnt2pnt_dist(value0.coord,ocn.osss[j].coord)
                if mnKm <= km && ocn.osss[j].upstrm >= forKm && ocn.osss[j].dwnstrm <= bacKm
                    push!(ocn.oOarcs,lof_buildArc(value0,ocn.osss[j],km))
                else
                end
        end
    end
end
#=function lof_OoArcs(ocn,cnt)
    ossCon=findmax(cnt.xXrad)[1]
    #makes all gen to pcc distances
    genDists=Array{Float64,1}()
    for value in ocn.gens
        cls_pcc=lof_xClosestPcc(value,ocn.pccs)
        push!(genDists,lof_pnt2pnt_dist(value.coord,cls_pcc.coord))
    end

    for i=1:length(ocn.osss)
        mnKm=lod_mnKm()
        #find the furthest owpp closer to pcc that oss
        cls_pcc=lof_xClosestPcc(ocn.osss[i],ocn.pccs)
        ossDist=lof_pnt2pnt_dist(ocn.osss[i].coord,cls_pcc.coord)
        rank=0
        for (index,value) in enumerate(genDists)
            if value<ossDist
                rank=rank+1
            end
        end
        rank=rank-ossCon
        #Set max connection distance
        if rank>=1
            mxkm=lof_pnt2pnt_dist(ocn.osss[i].coord,ocn.gens[rank].coord)
            mnKm=lof_pnt2pnt_dist(ocn.osss[i].coord,ocn.gens[rank+1].coord)
        else
            mxkm=Inf
        end

        for j=(i+1):length(ocn.osss)
                km=lof_pnt2pnt_dist(ocn.osss[i].coord,ocn.osss[j].coord)
                if mnKm <= km && km <= mxkm
                    push!(ocn.oOarcs,lof_buildArc(ocn.osss[i],ocn.osss[j],km))
                else
                end
        end
    end
end=#

##########################################
##### OSS to PCC connection paths ########
##########################################
#OSS to PCC connection
function lof_OpArcs(ocn,cnt)
    ops=Array{arc,1}()
    for oss in ocn.osss
        pcc_close=lof_xClosestPcc(oss,ocn.pccs)
        op=arc()
        op.head=pcc_close
        op.tail=oss
        op.lngth=lof_pnt2pnt_dist(oss.coord,pcc_close.coord)
        push!(ops,op)
    end
    ocn.oParcs=ops
end
#=function lof_OpArcs(ocn,cnt)
    shoreCon=findmax(cnt.xXrad)[1]+1
    cnct2pcc=ocn.gens[shoreCon]
    for i in ocn.osss
        if i.dwnstrm <= cnct2pcc.num
            pcc_close=lof_xClosestPcc(i,ocn.pccs)
            km=lof_pnt2pnt_dist(i.coord,pcc_close.coord)
            push!(ocn.oParcs,lof_buildArc(i,pcc_close,km))
        end
    end
end=#

################################################################################
############################ GPS to cartesian transform ########################
################################################################################
#sets the gps coords that used as reference coords
function lof_bseCrd(ocean)
    base=gps()
    #for india (type layouts)
    if ocean.gens[length(ocean.gens)].gps.lat < ocean.pccs[length(ocean.pccs)].gps.lat
        base.lat=ocean.gens[length(ocean.gens)].gps.lat#base lat
        base.lng=ocean.gens[length(ocean.gens)].gps.lng#base long
    #for belgium (type layouts)
    elseif ocean.pccs[length(ocean.pccs)].gps.lat < ocean.gens[length(ocean.gens)].gps.lat
        base.lat=ocean.pccs[length(ocean.pccs)].gps.lat#base lat
        base.lng=ocean.pccs[length(ocean.pccs)].gps.lng#base long
    else
        error("No proper base coordinates system established!")
    end
    return base
end

#calculates lengths based on latitude
#as lattitude changes number of km should be updated
function lof_gps2cartesian(location,base)
    lnthLT=111#number of km in 1 degree of longitude at equator
    for value in location
        value.coord.x=lof_deg2lgth(value.gps.lng-base.lng,lof_lg1deg(value.gps.lat,lnthLT))
        value.coord.y=lof_deg2lgth(value.gps.lat-base.lat,lnthLT)
    end
end

#rotates and slides cartesian axis
function lof_transformAxis(ocn)
    offset=lof_rotateAxis(ocn)
    lof_slideAxis(ocn,offset)
    num=length(ocn.pccs)
    ocn.gens=lof_gensOrder(ocn.gens,ocn,num)
    ocn.mnGap=lof_mnGap(ocn.gens)
end

#finds angle to rotate and applies to owpps and pccs
#rotates axis to align n-s with y
function lof_rotateAxis(ocn)
    theta=atan((ocn.pccs[length(ocn.pccs)].coord.x-ocn.gens[length(ocn.gens)].coord.x)/(ocn.gens[length(ocn.gens)].coord.y-ocn.pccs[length(ocn.pccs)].coord.y))
    ocn.angle=theta
    offset=0.0
    offset=lof_rotateGroup(ocn.gens,theta,offset)
    offset=lof_rotateGroup(ocn.pccs,theta,offset)
    ocn.offset=offset
    return offset
end

#loops through to apply rotations for a specified group
function lof_rotateGroup(locations,theta,os)
    for value in locations
        xy=lof_rotatePnt(value.coord.x,value.coord.y,theta)
        value.coord.x=xy[1]
        value.coord.y=xy[2]
        if value.coord.x<os
            os=value.coord.x
        end
    end
    return os
end

#applies rotational matrix individual coordinates
function lof_rotatePnt(x,y,theta)
    co_od=[x y]
    rotated=co_od*[cos(theta) -1*sin(theta);sin(theta) cos(theta)]
    return rotated
end

#translates the entire region by specified offset
#sets unique IDs for owpps and pccs
function lof_slideAxis(ocn,os)
    for value in ocn.gens
        value.coord.x=value.coord.x-os
        value.id="1"*string(value.num)
    end
    for value in ocn.pccs
        value.coord.x=value.coord.x-os
        value.id="2"*string(value.num)
    end
end

#changes angle to an arc length
function lof_deg2lgth(d,dPl)
    return d*dPl
end

#calculates length of 1 deg of longitude at given lattitude
function lof_lg1deg(lat,lngth)
    return cos(lof_d2r(lat))*lngth
end

#finds minimum distance between any 2 owpp
function lof_mnGap(gens)
    lnths=Array{Float64,1}()
    for gen0 in gens
        for gen1 in gens
            if gen0.id != gen1.id
                push!(lnths,lof_pnt2pnt_dist(gen0.coord,gen1.coord))
            end
        end
    end
    mnGp=findmin(lnths)[1]
    return mnGp
end
################################################################################
############################ Cartesian to GPS transform ########################
################################################################################
#finds original gps corordinates from untransformed cartesian
function lof_cartesian2gps(location,base)
    lnthLT=111#number of km in 1 degree of longitude at equator
    for value in location
        value.gps.lat=lof_lgth2deg(value.coord.y,lnthLT)+base.lat
        lnthLG=lof_lg1deg(value.gps.lat,lnthLT)
        value.gps.lng=lof_lgth2deg(value.coord.x,lnthLG)+base.lng
    end
end

#changes arc length to angle
function lof_lgth2deg(d,dPl)
    return d/dPl
end

#performs inverse transforms on cartesian coordinates
function lof_unXformAxis(ocn)
    os=ocn.offset
    lof_unSlideAxis(ocn,os)
    lof_unRotateAxis(ocn)
end

#translates the oss by specified offset
function lof_unSlideAxis(ocn,os)
    for value in ocn.osss
        value.coord.x=value.coord.x+os
    end
    for value in ocn.gens
        value.coord.x=value.coord.x+os
    end
    for value in ocn.pccs
        value.coord.x=value.coord.x+os
    end
end

#inverse rotation of oss
function lof_unRotateAxis(ocn)
    rads=(-1)*ocn.angle
    offset=lof_rotateGroup(ocn.osss,rads,0.0)
    offset=lof_rotateGroup(ocn.gens,rads,0.0)
    offset=lof_rotateGroup(ocn.pccs,rads,0.0)
end
##############################################################################
############################ laying PCC nodes ################################
##############################################################################
#Places the pccs
function lof_layPccs()
    pccs=lod_pccGps()
    location=Array{node,1}()
    for (index, value) in enumerate(pccs)
        shore=node()
        shore.gps.lng=value[1]
        shore.gps.lat=value[2]
        shore.kv=lod_pccKv()
        shore.num=index
        push!(location,deepcopy(shore))
    end
    return location
end
##############################################################################
############################ laying OWPP nodes ################################
##############################################################################
function lof_layGens(ocn)
    num=length(ocn.pccs)
    gpss,mvas,wnds=lod_gensGps()
    locations=Array{node,1}()
    for i=1:length(gpss)
        concession=node()
        concession.gps.lng=gpss[i][1]#set longitude
        concession.gps.lat=gpss[i][2]#set latittude
        concession.mva=mvas[i]#set concession power
        concession.name=wnds[i]#set wind profile name
        concession.kv=lod_cncsKv()#set collector kv
        concession.num=num+i
        push!(locations,deepcopy(concession))
    end
#sorts the owpps into closest to furthest from PCCs
    locations=lof_srtNear2Far(ocn.pccs,locations)
    return locations
end

#sorts the owpps from closest to furthest
function lof_srtNear2Far(pccs,gens)
    #creates a tuple of distances and gen/pcc numbers
    ds=Array{Tuple,1}()
    for gn in gens
        bsf=lof_gps2gps_dist(gn.gps,pccs[1].gps)
        gnn=gn.num
        pcn=pccs[1].num
        for pc in pccs
            if lof_gps2gps_dist(gn.gps,pc.gps)<bsf
                bsf=lof_gps2gps_dist(gn.gps,pc.gps)
                gnn=deepcopy(gn.num)
                pcn=deepcopy(pc.num)
            end
        end
        push!(ds,(bsf,gnn,pcn))
    end

    #sorts tuple by the length entry
    lnths = [x[1] for x in ds]
    ordrd=Array{Tuple,1}()
    for i=1:length(ds)
        ind=findmin(lnths)[2]
        lnths[ind]=Inf
        push!(ordrd,deepcopy(ds[ind]))
    end

    #sorts gens in same order as lengths
    ogens=Array{node,1}()
    for o in ordrd
        for gn in gens
            if gn.num == o[2]
                push!(ogens,gn)
            end
        end
    end

    #re-numbers each owpp
    for i=1:length(ogens)
        ogens[i].num=deepcopy(i+length(pccs))
    end
    return ogens
end

################################################################################
########################### General purpose ####################################
################################################################################
#Change radians to degrees
function lof_r2d(rad)
    return rad*180/pi
end

#Change degrees to radians
function lof_d2r(deg)
    return deg*pi/180
end

#returns the hypotenuse distance between 2 sets of gps coords
function lof_gps2gps_dist(pnt1,pnt2)
    hyp=sqrt((pnt2.lng-pnt1.lng)^2+(pnt2.lat-pnt1.lat)^2)
    return hyp
end
