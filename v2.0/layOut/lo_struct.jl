################################################################################
###################### mapping args ############################################
################################################################################
#struct used to pass mapping connection arguments
mutable struct control
      xrad::Bool
      neib1::Bool
      neib3::Bool
      xradPcc::Bool
      xradHlf::Bool
      xXrad::Array{Int64,1}
      xXneib1::Array{Int64,1}
      xXneib3::Array{Int64,1}
end
control()=control(false,false,false,false,false,[],[],[])
###################################################################
mutable struct xy
      x::Float64
      y::Float64
end
xy()=xy(69.69,69.69)
###################################################################
mutable struct gps
      lat::Float64
      lng::Float64
end
gps()=gps(69.69,69.69)
################################################################################
###################### Nodes ###################################################
################################################################################
mutable struct node
      gps::gps
      name::String
      coord::xy
      mva::Float64
      kv::Float64
      mvas::Array{Float64}
      wnds::Array{String}
      num::Int64
      id::String
      upstrm::Int64
      dwnstrm::Int64
end
node()=node(gps(),"colruyt",xy(),69.69,69.69,[],[],69,"sixty-nine",69,69)
####################################################################
##################### Arcs #########################################
####################################################################
mutable struct arc
      head::node
      tail::node
      lngth::Float64
      mva::Float64#Only used for disaplaying solution
end
arc()=arc(node(),node(),69.69,69.69)
###################################################################
mutable struct eez
      osss::Array{node}
      gens::Array{node}
      pccs::Array{node}
      gOarcs::Array{arc}
      oOarcs::Array{arc}
      oParcs::Array{arc}
      gParcs::Array{arc}
      angle::Float64
      offset::Float64
      mnGap::Float64
      oOcbls::Array{Tuple}
      oPcbls::Array{Tuple}
      oPXcbls::Array{Tuple}
      gOcbls::Array{Tuple}
      gPcbls::Array{Tuple}
      dcCbls::Array{Tuple}
end
eez()=eez([],[],[],[],[],[],[],69.69,69.69,69.69,[],[],[],[],[],[])
###################################################################
