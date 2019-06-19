#Imports the Corwind data and calculates load loss/ constrained energy
function wndF_wndPrf(nmes)
    #nmes=lod_gensGps()[3]
    if lod_Belgium() == true
        prof=CSV.File("../../common_wind_profs/profiles/pow_indiv_09.csv")
    else
        prof=CSV.File("../../common_wind_profs/profiles/pow_indiv_india_fluc_new_torque.csv")
    end
    wp=Array{Any,1}()
    for column in prof
        dummy=0.0
        for nme in nmes
            dummy=dummy+getproperty(column, Symbol(nme))
        end
        push!(wp,deepcopy(dummy))
    end

    wnd=wind()
    mx=findmax(wp)[1]
    ord=reverse(sort(wp))./mx
    is=Array{Int,1}()
    for i=1:length(ord)
            push!(is,i)
    end
    wndF_conEng([is ord],wnd,mx)#constraint energy calc
    wndF_ldLss([is ord], wnd)#calculates loss factor
    wnd
    return wnd
end

#Calculates the loss factor associated with the wind profile
function wndF_ldLss(div, wind)
  wind.lf=(sum(div[:,2]))*0.85/length(div[:,2])#saves loss factor, 0.85 is wake penalization
  #loss factor/llf formula ref: Guidelines on the calculation and use of loss factors Te Mana Hiko Electricity Authority
  #0.85 for wake effect from Evaluation of the wind direction uncertainty and its impact on wake modeling at the Horns Rev offshore wind farm
#M. Gaumond  P.‐E. Réthoré  S. Ott  A. Peña  A. Bechmann  K. S. Hansen
  llf=0.0
  for pu in div[:,2]
    llf=llf+(pu*0.85)^2
    #llf=llf+(pu)^2
  end
  wind.delta=llf/length(div[:,2])#saves load loss factor
end

#calc for constrained energy
function wndF_conEng(graph,wind,max)
#create sized arrays
    B=zeros(length(graph[:,2]),2)
    conENG=zeros(length(graph[:,2]),2)
    p_div=polyfit(graph[:,1],graph[:,2],3)#make a polynomial approximation
    area=zeros(length(graph[:,2]),1)
    integral=polyint(p_div)#set up the integral
    area=(polyval(integral,graph[:,1])-(graph[:,1].*graph[:,2]))#take integral to find area under curve
    x_axis=reverse(graph[:,2],2)
    y_axis=reverse(area[:,1],2)#reverse x and y axis
    B=[x_axis y_axis]
    conENG=sortslices(B,dims=1)#sort by x axis
    wind.ce=conENG[:,2]
    wind.pu=conENG[:,1]#store pu and constraind energy in wind object
    return nothing
end
