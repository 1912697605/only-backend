#电力系统中的能量转换函数
import FinanceCore.rate
using ActuaryUtilities: present_value, irr, breakeven
using OrderedCollections: OrderedDict

include("energy-structs.jl")

"""
将电解槽和压缩制氢的额定功率做成向量
"""
function maxpower(ec::ElectrolyticCell, n::Int)
    ec_maxload = 5e5 * ones(n)
    return ec_maxload
end

function maxpower(hc::HydrogenCompressed, n::Int)
    hc_maxload = 5e5 * ones(n)
    return hc_maxload
end

"""
制氢耗能
"""
function load(maxload::Vector, renewable_power::Vector, ec_maxload::Vector)
    load_power = zeros(length(maxload))
    for i in eachindex(maxload)
        if renewable_power[i] > maxload[i] #发电大于所需
            load_power[i] = ec_maxload[i]
        elseif renewable_power[i] == maxload[i] #发电等于所需
            load_power[i] = ec_maxload[i]
        elseif (maxload[i]*0.3 < renewable_power[i]) && (renewable_power[i] < maxload[i]) #发电小于所需，大于所需的30%
            load_power[i] = ec_maxload[i]*renewable_power[i]/maxload[i]
        elseif maxload[i]*0.3 > renewable_power[i] #发电小于所需的30%
            load_power[i] = ec_maxload[i]*0.3
        end
    end
    return load_power
end

"""
将向量x中的正数和负数分开，返回两个向量：postive, negative
"""
function pn_split(x::Vector)
    postive, negative = zeros(length(x)), zeros(length(x))
    for i in eachindex(x)
        if x[i] > 0
            postive[i] = x[i]
        else
            negative[i] = x[i]
        end
    end
    return postive, negative
end

"""
电解槽氢气产生率
"""
outputHydrogen(ec::ElectrolyticCell) = @. 0.0046+7.0564e-5*ec.input_T+0.0030*ec.input_i*ec.input_u

"""
返回电解槽用电产生的氢气量
"""
outputH2Mass(power::Vector, ec::ElectrolyticCell, coefficient_H2::Float64) = @. power / coefficient_H2 * ec.Δt * ec.M_H2 / ec.LHV_H2 * 3.6 * ec.η_EC

outputH2Mass(power::Real, ec::ElectrolyticCell, coefficient_H2::Float64) = power / coefficient_H2 * ec.Δt * ec.M_H2 / ec.LHV_H2 * 3.6 * ec.η_EC

"""
燃料电池输出功率
"""
function outputEnergy(fc::FuelCell)
	epower = -1.2645+0.0034*fc.input_T+140.3867*fc.input_power
	hpower = 1.2645-0.0034*fc.input_T+30.9707*fc.input_power
	return epower,hpower
end

"""
压缩空气储能，充放电
"""
function outputEnergy(es::EnergyStorage, ΔE::Vector)
    to_es, es_power = zeros(Float64, length(ΔE)), zeros(Float64, length(ΔE))
    es_limit = es.capacity * es.charging_limit # 储能最大容量
    for i in 1:length(ΔE)-1
        if ΔE[i] > 0 # 风光盈余电量, 储能充电，不可超过储能的最大容量
           to_es[i] = ΔE[i] > es_limit - es_power[i] ? es_limit - es_power[i] : ΔE[i]
        elseif ΔE[i] < 0 # 风光未达到制氢满载的30%, 储能放电使其达到30%，但同时不可超过当前储存的能量
           to_es[i] = ΔE[i] < -es_power[i] ? -es_power[i] : ΔE[i]
        end
        es_power[i+1] = es_power[i] + to_es[i] #压缩空气储能当前储存的能量
    end
    return to_es, es_power
end

"""
燃气轮机输出功率
"""
outputEnergy(gt::GasTurbine) = @. gt.gt_η*gt.input_power

"""
光伏发电总功率输出
"""
outputEnergy(pv::PhotovoltaicPanel) = @. pv.pv_number*pv.pv_refpower*(pv.input_solar/1000)*(1+pv.pv_alpha*(pv.ref_T+pv.pv_T))

"""
风机输出总功率
"""
function outputEnergy(wt::WindTurbine)
	wt.wt_ws = wt.input_ws*(wt.wt_h/wt.input_h)^0.14
	if wt.wt_ws<wt.wt_cutinws || wt.wt_ws>wt.wt_cutoffws
		outputpower = 0
	else if wt.wt_ws>=wt.wt_cutinws || wt.wt_ws<wt.wt_refws
		outputpower = wt.wt_number*wt.wt_refpower*(wt.wt_ws-wt.wt_cutinws)/(wt.wt_refws-wt.wt_cutinws)
	else if wt.wt_ws>=wt.wt_refws || wt.wt_ws<=wt.wt_cutoffws
		outputpower = wt.wt_number*wt.wt_refpower
	end
	return outputpower
end







