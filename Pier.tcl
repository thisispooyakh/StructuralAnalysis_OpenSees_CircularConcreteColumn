# 1- Defining The Model
# 2- Defining The Units
# 3- Defining Variables and Parameters
# 4- Defining Nodes
# 5- Defining Boundary Conditions
# 6- Defining Materials

# ================================================================================================

# Circular Bridge Pier
# Units: N, m, sec

model BasicBuilder -ndm 2 - ndf 3

set pi 3.14

set pier_Height 1.1
set pier_Radius 0.15
set pier_Diameter 0.3; #[expr 2*$pier_Radius]
set pier_Area 0.07; #[expr ($pi/4)*($pier_Diameter)*($pier_Diameter)]
set pier_Perimeter 0.942; #[expr 2*$pi*$pier_Radius]

set bars_Number 8
set bars_TiesDistances 0.075
set bar_Diameter 0.012
set bar_Area 0.000113; #[expr $pi*($bar_Diameter)*($bar_Diameter)/4]
set bar_YieldingStrength 453e6
set bar_UltimateStrength 634e6
set bar_ElasticityModulus 2.0e11
set bar_YieldingStrain 0.0022; #[expr $bar_YieldingStrength/$bar_ElasticityModulus]

# f'c was 55.9 MPa by using 150*150*150 mm cubic specimens (Because the test speciments were cubic but our pier cross section is circular, we gotta convert the compressive strength.)
set concrete_CompressiveStrength [expr 0.85*55.9e6]
set concrete_CompressiveStrength_Core [expr 1.2*$concrete_CompressiveStrength]
set concrete_CompressiveStrength_Cover [expr $concrete_CompressiveStrength]
set concrete_TensileStrength [expr 0.33*sqrt($concrete_CompressiveStrength/1e6)]
set concrete_UltimateStrength_Core [expr 0.2*$concrete_CompressiveStrength_Core]
set concrete_UltimateStrength_Cover [expr 0.2*$concrete_CompressiveStrength_Cover]
set concrete_ElasticityModulus [expr 4700*sqrt($concrete_CompressiveStrength_Core/1e6)]
set concrete_ElasticModulus_Tensile [expr 0.05*$concrete_ElasticityModulus]
set concrete_epsc0 [expr 2*($concrete_CompressiveStrength_Core/1e6)/$concrete_ElasticityModulus]
set concrete_epsc0_Core [expr 2*$concrete_epsc0]
set concrete_epsc0_Cover [expr 2*($concrete_CompressiveStrength/1e6)/$concrete_ElasticityModulus]

set concrete_Ultimate_epsc0_Core [expr 3*$concrete_epsc0_Core]
set concrete_Ultimate_epsc0_Cover [expr 2*$concrete_epsc0_Core]
set concrete_Cover 0.02
set concrete_Core 0.13; #[expr $pier_Radius-$concrete_Cover]
set concrete_Area_Core 0.05306; #[expr $pi*($concrete_Core*$concrete_Core)]
set concrete_Area_Cover 0.017584; #[expr $pi*(($pier_Radius*$pier_Radius)-($concrete_Core*$concrete_Core))]

# node $nodeTag (ndm $coords) <-mass (ndf $massValues)>
node 1 0 0
node 2 0 0.3
node 3 0 1.1

# fix $nodeTag (ndf $constrValues)
fix 1 1 1 1

# uniaxialMaterial Concrete02 $matTag $fpc $epsc0 $fpcu $epsU $lambda $ft $Ets
	# Core Concrete
uniaxialMaterial Concrete02 1 -$concrete_CompressiveStrength_Core -$concrete_epsc0_Core -$concrete_UltimateStrength_Core -$concrete_Ultimate_epsc0_Core 0.15 $concrete_TensileStrength $concrete_ElasticModulus_Tensile
	# Cover Concrete
uniaxialMaterial Concrete02 2 -$concrete_CompressiveStrength_Cover -$concrete_epsc0_Cover -$concrete_UltimateStrength_Cover -$concrete_Ultimate_epsc0_Cover 0.15 $concrete_TensileStrength $concrete_ElasticModulus_Tensile

# uniaxialMaterial Steel02 $matTag $Fy $E $b $R0<10-20> $cR1<0.925> $cR2<0.15>
uniaxialMaterial Steel02 3 $bar_YieldingStrength $bar_ElasticityModulus 0.01 15 0.925 0.25

puts "Material Definition Done!"


section Fiber 1 {
#Core
patch circ 1 16 3 0.0 0.0 0.0 [expr $pier_Radius-$concrete_Cover] 0 360
#Cover
patch circ 2 16 1 0.0 0.0 [expr $pier_Radius-$concrete_Cover] $pier_Radius 0 360
#Bars
layer circ 3 8 $bar_Area 0.0 0.0 [expr $pier_Radius-$concrete_Cover] 0 360
}


geomTransf PDelta 1

timeSeries Linear 1

element dispBeamColumn 1 1 2 5 1 1
element dispBeamColumn 2 2 3 5 1 1


pattern Plain 1 1 {
#Axial Load= 0.1*Ac*f'c
load 3 0.0 [expr -1 * 0.1 * $pier_Area * $concrete_CompressiveStrength] 0.0
}

wipeAnalysis;
constraints      Transformation;
numberer         RCM;
system           SparseGEN;
test             EnergyIncr 1e-3 25 0;
algorithm        ModifiedNewton;
integrator       LoadControl 0.01;
analysis         Static;
analyze          100;
loadConst        -time 0.0;

puts "****************** Static Analysis Done ******************"