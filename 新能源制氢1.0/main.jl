

include("energy-structs.jl")
include("energy-simulate.jl")
include("financial-functions.jl")
include("energy-functions.jl")
include("financial-analysis.jl")

Δt = [1.0 for i in 1:24*7]

pv = Photovoltaic(E_input = [10^6*(1+sin(2*pi*i/24)) for i in 1:length(Δt)], T_photovoltaic = [300 for i in 1:length(Δt)], T_environment = [300 for i in 1:length(Δt)])
wt = WindTurbine(V_input = [7*(1+sin(2*pi*i/24)) for i in 1:length(Δt)])
gt = GasTurbine(Fuel_rate = [0 for i in 1:length(Δt)])
ec = Electrolyzer(I = [5000 for i in 1:length(Δt)], T_electrolyzer = [300 for i in 1:length(Δt)])
ht = HydrogenTank(Z_compression = [0 for i in 1:length(Δt)],
                  T_HydrogenTank = [300 for i in 1:length(Δt)], 
                  Q_in = [0 for i in 1:length(Δt)],
                  Q_out = [1*10^4 for i in 1:length(Δt)],
                  Pressure = [0 for i in 1:length(Δt)],
                  Moles = [0.0 for i in 1:length(Δt)]) 
ri = RectifierInverter(P_input = [0 for i in 1:length(Δt)],
                       P_output = [0 for i in 1:length(Δt)])

machines = (pv, wt, gt, ec, ht,ri)


