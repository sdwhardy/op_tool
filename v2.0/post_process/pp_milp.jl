function ppm_reCnstrctSol(res,nt,ocn)
    bIds,Ids=ppm_xtrctBrchIds(res,nt)
	oIds=ppm_xtrctOssIds(bIds,nt)
	asBuilt=ppm_buildNodes(oIds,ocn)
	ppm_buildArcs(oIds,asBuilt)
    return asBuilt,Ids
end

#Finds all built branches
function ppm_xtrctBrchIds(r,n)
        sol=Array{Tuple,1}()
		Ids=Array{Int64,1}()
		for (b, branch) in r["solution"]["ne_branch"]
		        if isapprox(branch["built"], 1.0, atol = 0.01) == 1
                        push!(sol,(n["ne_branch"]["$b"]["mva"],n["ne_branch"]["$b"]["f_bus"],n["ne_branch"]["$b"]["t_bus"]))
						push!(Ids,(n["ne_branch"]["$b"]["eyeD_brch"]))
                end
        end
	return sol,Ids
end

#Finds all oss/pcc/gen Ids
function ppm_xtrctOssIds(links,nw)
        sol=Array{Tuple,1}()
		for link in links
			for (i, bus) in nw["bus"]
		        if bus["bus_i"]==link[2]
					hd=bus["eyeD_bs"]
					for (j, bs) in nw["bus"]
				        if bs["bus_i"]==link[3]
							tl=bs["eyeD_bs"]
                    		push!(sol,(deepcopy(link[1]),deepcopy(hd),deepcopy(tl)))
						end
					end
                end
	        end
		end
	return sol
end

#Builds an EEZ and adds solution nodes
function ppm_buildNodes(oIds,ocn)
	asBuilt=eez()
	ids_all=Array{Int64, 1}()
	for id in oIds
		push!(ids_all,id[2])
		push!(ids_all,id[3])
	end
	ids_all=unique(ids_all)
	for id in ids_all
		if string(id)[1]=='2'#PCC
			for pcc in ocn.pccs
				if string(id)==string(pcc.id)
					push!(asBuilt.pccs,pcc)
				end
			end
		elseif string(id)[1]=='1'#OWPP
			for gen in ocn.gens
				if string(id)==string(gen.id)
					push!(asBuilt.gens,gen)
				end
			end
		else#OSS
			for oss in ocn.osss
				if string(id)==string(oss.id)
					push!(asBuilt.osss,oss)
				end
			end
		end
	end
	return asBuilt
end

#Adds arcs to solution EEZ
function ppm_buildArcs(oIds,asBuilt)
	for id in oIds
		if string(id[2])[1]=='1' && string(id[3])[1]=='2'#gen to pcc
			link=ppm_arcExtrct(asBuilt.gens,asBuilt.pccs,id)
			push!(asBuilt.gParcs,link)
		elseif string(id[2])[1]=='1'#gen to oss
			link=ppm_arcExtrct(asBuilt.gens,asBuilt.osss,id)
			push!(asBuilt.gOarcs,link)
		elseif string(id[3])[1]=='2'#oss to pcc
			link=ppm_arcExtrct(asBuilt.osss,asBuilt.pccs,id)
			push!(asBuilt.oParcs,link)
		else
			link=ppm_arcExtrct(asBuilt.osss,asBuilt.osss,id)
			push!(asBuilt.oOarcs,link)
		end
	end
end

#Inner loop to build the solution arcs
function ppm_arcExtrct(grp1,grp2,id)
	link=arc()
	for nd in grp1
		if string(nd.id)==string(id[2])
			link.tail=nd
		end
	end
	for nd in grp2
		if string(nd.id)==string(id[3])
			link.head=nd
		end
	end
	link.mva=id[1]
	return link
end
