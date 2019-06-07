################################################################################
######################## creates power models input file #######################
################################################################################
#main logic to write the .m file
function ppf_main2mfile(mp,s,mxObj)
	matfile = open("v2.0/results/tnep_map.mat","w")#open the .mat file
	ppf_header(matfile)#print top function data
	ppf_Buss(matfile,mp)#prints the bus data
	ppf_Gens(matfile,mp)#prints all generator (OWPP) data
	ppf_Brnchs(matfile,mp,mxObj)#prints any pre-existing branches (onshore connections)
	ppf_NeBrnchs(matfile,mp,optLout)#prints all candiadate branch data
	close(matfile)#close the .mat file
	#mv("v2.0/results/tnep_map.mat", "v2.0/results/tnep_map.m", force=true)#change file type to .m
	#close(open("v2.0/results/tnep_map.m"))
end

# file description and function headers
function ppf_header(mf)
	println(mf, "%TNEP optimizor input file")
	println(mf, "")
	println(mf, "function mpc = owpp_tnep_map")
	println(mf, "mpc.version = '2';")
	print(mf, "mpc.baseMVA = ")
	print(mf, lod_cnceMva())
	println(mf, ";")
	println(mf, "")
end

#############################################################
################## Printing Node data #######################
#############################################################

###########################
######## Buss #############
#bus printing control logic
function ppf_Buss(mf,mp)
	ppf_busHdr(mf)
	ppf_busPcc(mf,mp.pccs)#prints all pccs to the bus
	ppf_busGen(mf,mp.gens)#prints all concessions to the bus
	ppf_busOss(mf,mp.osss)#prints all oss to the bus
	ppf_busInf(mf,mp)#builds the infinite onshore bus and load
	ppf_close(mf)
end

#bus header
function ppf_busHdr(mf)
	println(mf, "%bus data")
	println(mf, "%bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin eyeD_bs")
	println(mf, "mpc.bus = [")
end

#Sets parameters for pcc bus print
function ppf_busPcc(mf,pccs)
	type1=1.0
	type2=1.0
	kv=lod_pccKv()
	load=0.0
	ppf_bus2file(mf,pccs,type1,type2,kv,load)
end

#Sets parameters for gen bus print
function ppf_busGen(mf,gens)
	type1=3.0
	type2=2.0
	kv=lod_pccKv()
	load=0.0
	ppf_bus2file(mf,gens,type1,type2,kv,load)
end

#Sets parameters for oss bus print
function ppf_busOss(mf,osss)
	type1=1.0
	type2=1.0
	kv=lod_pccKv()
	load=0.0
	ppf_bus2file(mf,osss,type1,type2,kv,load)
end

##Sets parameters for infinite bus onshore
function ppf_busInf(mf,ocn)
	type1=1.0
	type2=1.0
	kv=lod_pccKv()
	Binf=node()#creates an onshore connection point to connect all PCCS/DCLines
	Binf.num=ocn.osss[length(ocn.osss)].num+1#gets the next available bus number
	Binf.id="90"*string(Binf.num)
	load=trunc(Int,length(mp.gens)*lod_cnceMva())#adds a load to the bus equal to all generation
	ppf_bus2file(mf,[Binf],type1,type2,kv,load)
end

#Prints the buss to file
function ppf_bus2file(mf,nds,type1,type2,kv,ld)
	tp=type1
	for n in nds
		print(mf,n.num,"\t")
		print(mf,tp,"\t")
		print(mf,ld,"\t")
		print(mf,0.0,"\t")
		print(mf,0.0,"\t")
		print(mf,1.0,"\t")
		print(mf,1.0,"\t")
		print(mf,1.0,"\t")
		print(mf,1.05,"\t")
		print(mf,kv,"\t")
		print(mf,1.0,"\t")
		print(mf,1.1,"\t")
		print(mf,0.9,"\t")
		print(mf,n.id)
		println(mf,";")
		tp=type2
	end
end

#adds clossing chars and carriage return
function ppf_close(mf)
	println(mf, "];")
	println(mf, "")
end

###########################
######## Gens #############
#bus printing control logic
function ppf_Gens(mf,mp)
	ppf_srceHdr(mf)#Header for generator sources
	ppf_genSrce(mf,mp.gens)#Prints Source data
	ppf_close(mf)#adds termination chars
	ppf_cstHdr(mf)#Header for generator sources
	ppf_genCst(mf,mp.gens)#Prints Cost data
	ppf_close(mf)#adds termination chars
end

#bus source header
function ppf_srceHdr(mf)
	println(mf, "%generator data")
	println(mf, "%bus	Pg	Qg	Qmax	Qmin	Vg	mbase	status	Pmax	Pmin")
	println(mf, "mpc.gen = [")
end

#Prints parameters for gen Source nodes
function ppf_genSrce(mf,nds)
	for n in nds
		print(mf,n.num,"\t")#adds bus ID
		print(mf,trunc(Int,n.mva),"\t")#rounds power to integer
		print(mf,0.0,"\t")#Qg
		print(mf,0.0,"\t")#Qmax
		print(mf,0.0,"\t")#Qmin
		print(mf,1.0,"\t")#Vg
		print(mf,trunc(Int,n.mva),"\t")#mbase
		print(mf,1.0,"\t")#status
		print(mf,trunc(Int,n.mva),"\t")#Pmax
		print(mf,0.0)#Pmin
		println(mf,";")
	end
end

#bus cost header
function ppf_cstHdr(mf)
	println(mf, "%generator cost data")
	println(mf, "mpc.gencost = [")
end

#Prints parameters for gen Cost nodes
function ppf_genCst(mf,gens)
	for i=1:length(gens)
		println(mf, "2	 0.0	 0.0	 0	   0	   0	   0;")#Adds 0 cost function for each generator
	end
end

###########################
######## Branches #########
#existing branch printing control logic
function ppf_Brnchs(mf,mp,mxObj)
	ppf_brnHdr(mf)
	ppf_onShrBrnches(mf,mp,mxObj)
	ppf_close(mf)
end

#Header for existing branches
function ppf_brnHdr(mf)
	println(mf, "%branch data")
	println(mf, "%fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle	status	angmin	angmax objmax")
	println(mf, "mpc.branch = [")
end

#Printing Onshore Infinite branches
function ppf_onShrBrnches(mf,mp,mxObj)
	mva=0.0
	tn=length(mp.pccs)+length(mp.gens)+length(mp.osss)+1
	rxb=eqpD_dcAdm()
	for i in mp.gens
		mva=mva+i.mva
	end
	for i in mp.pccs
		print(mf,i.num,"\t")
		print(mf,tn,"\t")
		print(mf,rxb[1],"\t")
		print(mf,rxb[2],"\t")
		print(mf,rxb[3],"\t")
		print(mf,mva,"\t")
		print(mf,mva,"\t")
		print(mf,mva,"\t")
		print(mf,0.0,"\t")
		print(mf,0.0,"\t")
		print(mf,1.0,"\t")
		print(mf,-30.0,"\t")
		print(mf,30.0,"\t")
		print(mf,Float64(mxObj))
		println(mf,";")
	end
end

################################################################################
########################## Candidate Branches ##################################
################################################################################
#Control logic for printing candidate lines
function ppf_NeBrnchs(mf,mp,optLout)
	ppf_HdrNeBrnch(mf)
	ppf_gpBrnch(mf,mp.gParcs,optLout)
	ppf_goBrnch(mf,mp.gOarcs,optLout)
	ppf_ooBrnch(mf,mp.oOarcs,optLout)
	ppf_opBrnch(mf,mp.oParcs,optLout)
	println(mf, "];")
end

#Header for candidate branches
function ppf_HdrNeBrnch(mf)
	println(mf, "%candidate branch data")
	println(mf, "%column_names%	f_bus	t_bus	eyeD_brch	br_r	br_x	br_b	rate_a	rate_b	rate_c	tap	shift	br_status	angmin	angmax	mva	construction_cost	branch_tnep_start")
	println(mf, "mpc.ne_branch = [")
end

###########################
####### Gen to PCC ########
#OWPP to PCC candidate branches
function ppf_gpBrnch(mf,gParcs,optLout)
	for path in gParcs
		wp=wndF_wndPrf([path.tail.name])
		link=cstF_MVcbl2pccX(path.lngth,path.tail.mva,path.tail.kv,wp)
		ppf_ifUnderSized(link.cable,path.tail.mva,path.tail.kv,path.lngth)
		if link.cable.num != 0
			ppf_candiBrnch(mf,link,path,optLout)
		else
			println("No suitable "*string(path.tail.kv)*"Kv, "*string(path.tail.mva)*"MVA cable for "*string(trunc(Int,path.lngth))*"Km. -removing")
		end
	end
end

###########################
####### Gen to OSS ########
#OWPP to OSS candidate branches
function ppf_goBrnch(mf,gOarcs,optLout)
	for path in gOarcs
		wp=wndF_wndPrf([path.tail.name])
		link=cstF_MVcbl2ossX(path.lngth,path.tail.mva,path.tail.kv,wp)
		ppf_ifUnderSized(link.cable,path.tail.mva,path.tail.kv,path.lngth)
		if link.cable.num != 0
			ppf_candiBrnch(mf,link,path,optLout)
		else
			println("No suitable "*string(path.tail.kv)*"Kv, "*string(path.tail.mva)*"MVA cable for "*string(trunc(Int,path.lngth))*"Km. -removing")
		end
	end
end

###########################
####### OSS to OSS ########
#OWPP to OSS candidate branches
function ppf_ooBrnch(mf,oOarcs,optLout)
	link=owpp()
	for path in oOarcs
		#Adds half sized cable
		wp=wndF_wndPrf([path.tail.wnds[1]])
		cable=cstF_HVcbl2oss(path.lngth,path.tail.mvas[1]/2,lod_ossKv(),wp)
		ppf_ifUnderSized(cable,path.tail.mvas[1]/2,lod_ossKv(),path.lngth)
		link.cable=cable
		link.costs.ttl=cable.costs.ttl
		if link.cable.num != 0
			ppf_candiBrnch(mf,link,path,optLout)
		else
			println("No suitable "*string(lod_ossKv())*"Kv, "*string(path.tail.mvas[1]/2)*"MVA cable for "*string(trunc(Int,path.lngth))*"Km. -removing")
		end

		#Adds power levels for each attached owpp
		mva=0.0
		mvas=Array{Float64,1}()
		ka=Array{String,1}()
		for j=1:length(path.tail.mvas)
			mva=mva+path.tail.mvas[j]
			push!(ka,path.tail.wnds[j])
			wp=wndF_wndPrf(ka)
			cable=cstF_HVcbl2oss(path.lngth,mva,lod_ossKv(),wp)
			ppf_ifUnderSized(cable,mva,lod_ossKv(),path.lngth)
			link.cable=cable
			link.costs.ttl=cable.costs.ttl
			if link.cable.num != 0
				ppf_candiBrnch(mf,link,path,optLout)
			else
				println("No suitable "*string(lod_ossKv())*"Kv, "*string(mva)*"MVA cable for "*string(trunc(Int,path.lngth))*"Km. -removing")
			end
		end
	end
end

###########################
####### OSS to PCC ########
#OSS to PCC candidate branches
function ppf_opBrnch(mf,oParcs,optLout)
	link=owpp()
	for path in oParcs
		#Adds a partially sized cable
		wp=wndF_wndPrf([path.tail.wnds[1]])
		if lod_ossKv() == lod_pccKv()
			cable=cstF_HVcbl2pcc(path.lngth,path.tail.mvas[1]/2,lod_ossKv(),wp)
			link.cable=cable
		else
			link=cstF_HVcbl2pccX(path.lngth,path.tail.mvas[1]/2,lod_ossKv(),wp)
		end
		ppf_ifUnderSized(link.cable,path.tail.mvas[1]/2,lod_ossKv(),path.lngth)
		link.costs.ttl=cable.costs.ttl
		if link.cable.num != 0
			ppf_candiBrnch(mf,link,path,optLout)
		else
			println("No suitable "*string(lod_ossKv())*"Kv, "*string(path.tail.mvas[1]/2)*"MVA cable for "*string(trunc(Int,path.lngth))*"Km. -removing")
		end

		#Add cables as multiples of attached generators
		mva=0.0
		ka=Array{String,1}()
		for j=1:length(path.tail.mvas)
			mva=mva+path.tail.mvas[j]
			push!(ka,path.tail.wnds[j])
			wp=wndF_wndPrf(ka)
			if lod_ossKv() == lod_pccKv()
				cable=cstF_HVcbl2pcc(path.lngth,mva,lod_ossKv(),wp)
				link.cable=cable
			else
				link=cstF_HVcbl2pccX(path.lngth,mva,lod_ossKv(),wp)
			end
			ppf_ifUnderSized(link.cable,mva,lod_ossKv(),path.lngth)
			link.costs.ttl=cable.costs.ttl
			if link.cable.num != 0
				ppf_candiBrnch(mf,link,path,optLout)
			else
				println("No suitable "*string(lod_ossKv())*"Kv, "*string(mva)*"MVA cable for "*string(trunc(Int,path.lngth))*"Km. -removing")
			end
		end
	end
end

###########################################
###### Candidate Support Functions ########
#Slightly undersized cables are allowed to be overloaded
function ppf_ifUnderSized(cable,mva,kv,lngth)
	if (cable.mva*cable.num)<mva
		cable.mva=mva/cable.num
		println("Undersized cable selected for "*string(kv)*"kV, "*string(mva)*"MVA "*string(trunc(Int,lngth))*"Km link.")
	end
end

#Printing of candidate branch central loop
function ppf_candiBrnch(mf,link,path,optLout)
	println(link.cable.mva)
	ppf_neBrnch(mf,link,path)
	cst=link.costs.ttl
	print(mf,cst,"\t")
	strt=ppf_neBuild(link,path,optLout)
	print(mf,Float64(strt))
	println(mf,";")
end

#set the start bit
function ppf_neBuild(link,path,optLout)
	strt=0.0
	eyeD=string(trunc(Int,link.cable.num*link.cable.mva))*string(path.tail.id)*string(path.head.id)
	for i=1:1:length(optLout)
		if string(eyeD) == string(optLout[i])
			strt=1.0
			deleteat!(optLout,i)
			@goto end_neBuild
		end
	end
	@label end_neBuild
	return strt
end

#Prints candidate branch
function ppf_neBrnch(mf,link,path)
	id=string(trunc(Int,link.cable.mva*link.cable.num))*string(path.tail.id)*string(path.head.id)
	print(mf,path.tail.num,"\t")
	print(mf,path.head.num,"\t")
	print(mf,id,"\t")
	print(mf,link.cable.ohm,"\t")
	print(mf,link.cable.xl,"\t")
	print(mf,link.cable.yc,"\t")
	print(mf,trunc(Int,link.cable.mva*link.cable.num),"\t")
	print(mf,trunc(Int,link.cable.mva*link.cable.num),"\t")
	print(mf,trunc(Int,link.cable.mva*link.cable.num),"\t")
	print(mf,0.0,"\t")
	print(mf,0.0,"\t")
	print(mf,1.0,"\t")
	print(mf,-30.0,"\t")
	print(mf,30.0,"\t")
	print(mf,trunc(Int,link.cable.mva*link.cable.num),"\t")
end
