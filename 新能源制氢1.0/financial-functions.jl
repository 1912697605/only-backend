"""
设备的初始投资
"""
initialInvestment(machine::RenewableEnergyMachine) = machine.cost_construct * machine.number

"""
设备的替换投资
"""
replaceInvestment(machine::RenewableEnergyMachine) = machine.cost_construct * machine.number

"""
设备的年运维成本
"""
annualOperationCost(machine::RenewableEnergyMachine) = machine.cost_maintenance * machine.running_year * machine.number

"""
设备的更换成本
"""
replacementCost(machine::RenewableEnergyMachine, fin::Financial) = fin.n_sys > machine.running_year ? machine.cost_construct * ceil(fin.n_sys / machine.running_year) : 0

"""
设备的总成本
"""
totalCost(machine::RenewableEnergyMachine, fin::Financial) = initialInvestment(machine) + operationCost(machine, fin) + replacementCost(machine, fin)

"""
返回年用水成本
"""
costWater(capacity, fin::Financial) = fin.cost_water_per_kg_H2 * capacity

"""
返回年用气成本
"""
costGas(capacity, gt::GasTurbine, fin::Financial) = capacity * 3.6 / (gt.gt_η * gt.lhv_gas) * fin.price_gas_per_Nm3

"""
返回设备的资金回收系数
"""
crf(fin::Financial) = (fin.r * (1 + fin.r)^fin.n_sys) / ((1 + fin.r)^fin.n_sys - 1)








