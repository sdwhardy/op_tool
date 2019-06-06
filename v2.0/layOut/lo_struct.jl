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
end
node()=node(gps(),"colruyt",xy(),69.69,69.69,[],[],69,"sixty-nine")
####################################################################
##################### Arcs #########################################
####################################################################
mutable struct arc
      head::node
      tail::node
      lngth::Float64
end
arc()=arc(node(),node(),69.69)
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
end
eez()=eez([],[],[],[],[],[],[],69.69,69.69)
###################################################################
