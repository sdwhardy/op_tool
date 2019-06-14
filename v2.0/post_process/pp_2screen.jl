function ppf_printOcnXY_cst(ocean)
	pcc=Array{Tuple,1}()
	gen=Array{Tuple,1}()
	oss=Array{Tuple,1}()

	for i in ocean.pccs
		txt=text(string(i.num),12,:black,:right)
		push!(pcc,(i.coord.x,i.coord.y,txt))
	end

	for i in ocean.gens
		txt=text(string(i.num),12,:red,:right)
		push!(gen,(i.coord.x,i.coord.y,txt))
	end

	for i in ocean.osss
		txt=text(string(i.num),12,:blue,:left)
		push!(oss,(i.coord.x,i.coord.y,txt))
	end


	os=0
	Xoss=[x[1] for x in oss]
	Yoss=[x[2] for x in oss]

	Xpcc=[x[1] for x in pcc]
	Xgen=[x[1] for x in gen]

	Ypcc=[x[2] for x in pcc]
	Ygen=[x[2] for x in gen]
	xlimax=trunc(Int,findmax(findmax([Xoss,Xpcc,Xgen])[1])[1])+os
	ylimax=trunc(Int,findmax(findmax([Yoss,Ypcc,Ygen])[1])[1])+os
	xlimin=trunc(Int,findmin(findmin([Xoss,Xpcc,Xgen])[1])[1])-os
	ylimin=trunc(Int,findmin(findmin([Yoss,Ypcc,Ygen])[1])[1])-os

	plotly()
	p=plot(Xpcc,Ypcc,annotations=pcc,color = :blue,seriestype=:scatter,xticks = ylimin:5:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="PCC",xaxis = ("km", font(15, "Courier")),yaxis = ("km", font(15, "Courier")))
	plot!(p,Xgen,Ygen,annotations=gen,color = :red,seriestype=:scatter,xticks = ylimin:5:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="OWPP")
	plot!(p,Xoss,Yoss,color = :black,seriestype=:scatter,xticks = ylimin:5:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="OSS")

	xd=Array{Float64,1}()
	yd=Array{Float64,1}()
	op=Array{Tuple,1}()
	cost=0
	for i in ocean.oParcs
		push!(xd,i.tail.coord.x)
		push!(xd,i.head.coord.x)
		push!(yd,i.tail.coord.y)
		push!(yd,i.head.coord.y)
		plot!(p,xd,yd,color = :black,xticks = ylimin:5:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="")
		ln=lof_pnt2pnt_dist(i.tail.coord,i.head.coord)
		cbx=cstF_HVcbl2pcc(ln,i.mva,lod_ossKv(),wndF_wndPrf(i.tail.wnds))
		cost=cost+cbx.costs.ttl
		println(string(cbx.num)*" - "*string(lod_ossKv())*"kV, "*string(i.mva)*"mva, "*string(round(Int,ln))*"km, "*string(cbx.size)*"mm from OSS "*string(i.tail.num)*" to PCC "*string(i.head.num)*" costs: "*string(cbx.costs.ttl))
		xd=[]
		yd=[]
	end
	for i in ocean.oOarcs
		push!(xd,i.tail.coord.x)
		push!(xd,i.head.coord.x)
		push!(yd,i.tail.coord.y)
		push!(yd,i.head.coord.y)
		plot!(p,xd,yd,color = :black,xticks = ylimin:5:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="")
		ln=lof_pnt2pnt_dist(i.tail.coord,i.head.coord)
		cbx=cstF_HVcbl2oss(ln,i.mva,lod_ossKv(),wndF_wndPrf(i.tail.wnds))
		println(string(cbx.num)*" - "*string(lod_ossKv())*"kV, "*string(i.mva)*"mva, "*string(round(Int,ln))*"km, "*string(cbx.size)*"mm from OSS "*string(i.tail.num)*" to OSS "*string(i.head.num)*" costs: "*string(cbx.costs.ttl))
		cost=cost+cbx.costs.ttl
		xd=[]
		yd=[]
	end
	for i in ocean.gOarcs
		push!(xd,i.tail.coord.x)
		push!(xd,i.head.coord.x)
		push!(yd,i.tail.coord.y)
		push!(yd,i.head.coord.y)
		plot!(p,xd,yd,color = :red,xticks = ylimin:5:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="")
		ln=lof_pnt2pnt_dist(i.tail.coord,i.head.coord)
		if round(Int,ln) > 1
			ln=ln-1
		end
		cbx=cstF_MVcbl2ossX(ln,i.mva,lod_cncsKv(),wndF_wndPrf([i.tail.name]))
		cost=cost+cbx.costs.ttl
		println(string(cbx.cable.num)*" - "*string(lod_cncsKv())*"kV, "*string(i.mva)*"mva, "*string(round(Int,ln))*"km, "*string(cbx.cable.size)*"mm from OWPP "*string(i.tail.num)*" to OSS "*string(i.head.num)*" with "*string(cbx.xfm.num)*" - "*string(cbx.xfm.mva)*"transformers costs: "*string(cbx.costs.ttl))
		xd=[]
		yd=[]
	end
	for i in ocean.gParcs
		push!(xd,i.tail.coord.x)
		push!(xd,i.head.coord.x)
		push!(yd,i.tail.coord.y)
		push!(yd,i.head.coord.y)
		plot!(p,xd,yd,color = :red,xticks = ylimin:5:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="")
		ln=lof_pnt2pnt_dist(i.tail.coord,i.head.coord)
		cbx=cstF_MVcbl2pccX(ln,i.mva,lod_cncsKv(),wndF_wndPrf(i.tail.name))
		println(string(cbx.num)*" - "*string(lod_cncsKv())*"kV, "*string(i.mva)*"mva, "*string(round(Int,ln))*"km, "*string(cbx.size)*"mm from OWPP "*string(i.tail.num)*" to PCC "*string(i.head.num)*" costs: "*string(cbx.costs.ttl))
		cost=cost+cbx.costs.ttl
		xd=[]
		yd=[]
	end
	println("Total: "*string(cost))
	p
end

function ppf_printOcnXY(ocean)
	pcc=Array{Tuple,1}()
	gen=Array{Tuple,1}()
	oss=Array{Tuple,1}()

	for i in ocean.pccs
		txt=text(string(i.num),12,:black,:right)
		push!(pcc,(i.coord.x,i.coord.y,txt))
	end

	for i in ocean.gens
		txt=text(string(i.num),12,:red,:right)
		push!(gen,(i.coord.x,i.coord.y,txt))
	end

	for i in ocean.osss
		txt=text(string(i.num),12,:blue,:left)
		push!(oss,(i.coord.x,i.coord.y,txt))
	end


	os=0
	Xoss=[x[1] for x in oss]
	Yoss=[x[2] for x in oss]

	Xpcc=[x[1] for x in pcc]
	Xgen=[x[1] for x in gen]

	Ypcc=[x[2] for x in pcc]
	Ygen=[x[2] for x in gen]
	xlimax=trunc(Int,findmax(findmax([Xoss,Xpcc,Xgen])[1])[1])+os
	ylimax=trunc(Int,findmax(findmax([Yoss,Ypcc,Ygen])[1])[1])+os
	xlimin=trunc(Int,findmin(findmin([Xoss,Xpcc,Xgen])[1])[1])-os
	ylimin=trunc(Int,findmin(findmin([Yoss,Ypcc,Ygen])[1])[1])-os

	plotly()
	p=plot(Xpcc,Ypcc,annotations=pcc,color = :blue,seriestype=:scatter,xticks = ylimin:5:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="PCC",xaxis = ("km", font(15, "Courier")),yaxis = ("km", font(15, "Courier")))
	plot!(p,Xgen,Ygen,annotations=gen,color = :red,seriestype=:scatter,xticks = ylimin:5:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="OWPP")
	plot!(p,Xoss,Yoss,color = :black,seriestype=:scatter,xticks = ylimin:5:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="OSS")

	xd=Array{Float64,1}()
	yd=Array{Float64,1}()
	op=Array{Tuple,1}()
	cost=0
	for i in ocean.oParcs
		push!(xd,i.tail.coord.x)
		push!(xd,i.head.coord.x)
		push!(yd,i.tail.coord.y)
		push!(yd,i.head.coord.y)
		plot!(p,xd,yd,color = :black,xticks = ylimin:5:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="")
		xd=[]
		yd=[]
	end
	for i in ocean.oOarcs
		push!(xd,i.tail.coord.x)
		push!(xd,i.head.coord.x)
		push!(yd,i.tail.coord.y)
		push!(yd,i.head.coord.y)
		plot!(p,xd,yd,color = :black,xticks = ylimin:5:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="")
		xd=[]
		yd=[]
	end
	for i in ocean.gOarcs
		push!(xd,i.tail.coord.x)
		push!(xd,i.head.coord.x)
		push!(yd,i.tail.coord.y)
		push!(yd,i.head.coord.y)
		plot!(p,xd,yd,color = :red,xticks = ylimin:5:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="")
		xd=[]
		yd=[]
	end
	for i in ocean.gParcs
		push!(xd,i.tail.coord.x)
		push!(xd,i.head.coord.x)
		push!(yd,i.tail.coord.y)
		push!(yd,i.head.coord.y)
		plot!(p,xd,yd,color = :red,xticks = ylimin:5:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="")
		xd=[]
		yd=[]
	end
	p
end

function ppf_printOcnGPS(ocn)
	ocean=deepcopy(ocn)
	pcc=Array{Tuple,1}()
	gen=Array{Tuple,1}()
	oss=Array{Tuple,1}()

	for i in ocean.pccs
		txt=text(string(i.num),12,:black,:right)
		push!(pcc,(i.gps.lng,i.gps.lat,txt))
	end

	for i in ocean.gens
		txt=text(string(i.num),12,:red,:right)
		push!(gen,(i.gps.lng,i.gps.lat,txt))
	end

	base=lof_bseCrd(ocean)
	lof_unXformAxis(ocean)
	lof_cartesian2gps(ocean.osss,base)
	for i in ocean.osss
		txt=text(string(i.num),12,:blue,:left)
		push!(oss,(i.gps.lng,i.gps.lat,txt))
		print("OSS "*string(i.num)*" gps: ")
		println("Lat: "*string(i.gps.lat)*" Lng: "*string(i.gps.lng))
	end

	Xoss=[x[1] for x in oss]
	Yoss=[x[2] for x in oss]

	Xpcc=[x[1] for x in pcc]
	Xgen=[x[1] for x in gen]

	Ypcc=[x[2] for x in pcc]
	Ygen=[x[2] for x in gen]

	plotly()
	p=plot(Xpcc,Ypcc,annotations=pcc,color = :blue,seriestype=:scatter,label="PCC",xaxis = ("Longitude", font(15, "Courier")),yaxis = ("Latitude", font(15, "Courier")))
	plot!(p,Xgen,Ygen,annotations=gen,color = :red,seriestype=:scatter,label="OWPP")
	plot!(p,Xoss,Yoss,color = :black,seriestype=:scatter,label="OSS")


	xd=Array{Float64,1}()
	yd=Array{Float64,1}()
	op=Array{Tuple,1}()
	cost=0
	for i in ocean.oParcs
		push!(xd,i.tail.gps.lng)
		push!(xd,i.head.gps.lng)
		push!(yd,i.tail.gps.lat)
		push!(yd,i.head.gps.lat)
		plot!(p,xd,yd,color = :black,label="")
		xd=[]
		yd=[]
	end
	for i in ocean.oOarcs
		push!(xd,i.tail.gps.lng)
		push!(xd,i.head.gps.lng)
		push!(yd,i.tail.gps.lat)
		push!(yd,i.head.gps.lat)
		plot!(p,xd,yd,color = :black,label="")
		xd=[]
		yd=[]
	end
	for i in ocean.gOarcs
		push!(xd,i.tail.gps.lng)
		push!(xd,i.head.gps.lng)
		push!(yd,i.tail.gps.lat)
		push!(yd,i.head.gps.lat)
		plot!(p,xd,yd,color = :red,label="")
		xd=[]
		yd=[]
	end
	for i in ocean.gParcs
		push!(xd,i.tail.gps.lng)
		push!(xd,i.head.gps.lng)
		push!(yd,i.tail.gps.lat)
		push!(yd,i.head.gps.lat)
		plot!(p,xd,yd,color = :red,label="")
		xd=[]
		yd=[]
	end
	p
end
