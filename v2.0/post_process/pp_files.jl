################################################################################
######################## creates power models input file #######################
################################################################################
#main logic to write the .m file
function ppf_main2mfile(mp,s,ob)
	matfile = open("v2.0/results/tnep_map.mat","w")#open the .mat file
	ppf_header(matfile)#print top function data
	#ppf_prntBuss(matfile,mp)#prints the bus data
	#tpp_prntGens(mf,mp)#prints all generator (OWPP) data
	#tpp_prntBrns(mf,mp,ob)#prints any pre-existing branches (onshore connections)
	#tpp_prntNeBrns(mf,mp,s)#prints all candiadate branch data
	close(matfile)#close the .mat file
	mv("v2.0/results/tnep_map.mat", "v2.0/results/tnep_map.m", force=true)#change file type to .m
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
################################################################################

################################################################################################################
################################## Prints Node data ############################################################
################################################################################################################
#prints bus titles and data for pccs, concessions, oss and onshore star point
function tpp_prntBuss(mf,mp)
	println(mf, "%bus data")
	println(mf, "%bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin eyeD_bs")
	println(mf, "mpc.bus = [")
	tpp_busNode(mf,mp.pccs)#prints all pccs to the bus
	tpp_busNode(mf,mp.cnces)#prints all concessions to the bus
	tpp_busNode(mf,mp.osss)#prints all oss to the bus
	Binf=cnce()#creates an onshore connection point to connect all PCCS
	Binf.num=mp.osss[length(mp.osss)].num+1#gets the next available bus number
	Binf.mva=length(mp.cnces)*lod_cnceMva()#adds a load to the bus equal to all generation
	tpp_busInf(mf,Binf)#builds the infinite onshore bus and load
	println(mf, "];")
	println(mf, "")
end
########################################################
#builds infinite bus onshore data
function tpp_busInf(mf,n)
	print(mf,n.num,"\t")
	print(mf,1.0,"\t")
	print(mf,trunc(Int,n.mva),"\t")
	print(mf,0.0,"\t")
	print(mf,0.0,"\t")
	print(mf,1.0,"\t")
	print(mf,1.0,"\t")
	print(mf,1.0,"\t")
	print(mf,1.05,"\t")
	print(mf,lod_pccKv(),"\t")
	print(mf,1.0,"\t")
	print(mf,1.1,"\t")
	print(mf,0.9,"\t")
	print(mf,"90"*string(n.num))
	println(mf,";")
end
