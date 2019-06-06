function ppf_printOcn(ocean)
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


	os=1
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
	p=plot(Xpcc,Ypcc,annotations=pcc,color = :blue,seriestype=:scatter,xticks = ylimin:1:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="PCC")
	plot!(p,Xgen,Ygen,annotations=gen,color = :red,seriestype=:scatter,xticks = ylimin:1:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="OWPP")
	plot!(p,Xoss,Yoss,annotations=oss,color = :black,seriestype=:scatter,xticks = ylimin:1:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="OSS")


	xd=Array{Float64,1}()
	yd=Array{Float64,1}()
	op=Array{Tuple,1}()
	#=for i in ocean.oParcs
		push!(xd,i.tail.coord.x)
		push!(xd,i.head.coord.x)
		push!(yd,i.tail.coord.y)
		push!(yd,i.head.coord.y)
		plot!(p,xd,yd,color = :black,xticks = ylimin:1:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="")
		xd=[]
		yd=[]
	end
	for i in ocean.oOarcs
		push!(xd,i.tail.coord.x)
		push!(xd,i.head.coord.x)
		push!(yd,i.tail.coord.y)
		push!(yd,i.head.coord.y)
		plot!(p,xd,yd,color = :black,xticks = ylimin:1:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="")
		xd=[]
		yd=[]
	end=#
	for i in ocean.gOarcs
		push!(xd,i.tail.coord.x)
		push!(xd,i.head.coord.x)
		push!(yd,i.tail.coord.y)
		push!(yd,i.head.coord.y)
		plot!(p,xd,yd,color = :red,xticks = ylimin:1:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="")
		xd=[]
		yd=[]
	end
	for i in ocean.gParcs
		push!(xd,i.tail.coord.x)
		push!(xd,i.head.coord.x)
		push!(yd,i.tail.coord.y)
		push!(yd,i.head.coord.y)
		plot!(p,xd,yd,color = :red,xticks = ylimin:1:ylimax,xlims=(ylimin,ylimax),yticks = ylimin:5:ylimax,label="")
		xd=[]
		yd=[]
	end
	p
end
