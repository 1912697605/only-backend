"""
    economic_analysis(machines, fin, powers, ΔE, ::Val{1})

    返回设备的经济评价指标。

- `machines`：设备元组
- `fin`：金融参数
- `powers`：设备发电量、电解量等（储氢能耗忽略）
- `::Val{1}`：用于类型分派, 离网制氢不用燃料电池
- `::Val{2}`：用于类型分派, 离网制氢用燃料电池
- `::Val{3}`：用于类型分派, 风光制氢余电上网

"""

function economicAnalysisData(machines::Tuple, fin::Financial, powers::Tuple, ΔE::Tuple, ::Val{1})
  #组件：光电、风电，燃气轮机，电解槽，储氢罐，氢气压缩机，空气储能装置
  pv, wt, gt, ec, fc, hc, es,  _ = machines
  # 光伏发电量、风机发电量、燃气轮机发电量、电解槽与压缩机耗电量、空气储能量
  pv_power, wt_power, gt_power, load_power, ec_power, es_power = powers
  # 光伏发电总量、风机发电总量、燃气轮机发电总量、电解槽与压缩机耗电总量、电解槽耗电量、空气储能总量
  sum_pv_power, sum_wt_power, sum_gt_power, sum_load_power, sum_ec_power, sum_es_power = map(sum, powers)
  # 风机、光伏总发电
  sum_RE_power = sum_pv_power + sum_wt_power
  # 费电、补电
  ΔE_to, ΔE_from = ΔE
  # 风光利用率
  utilization_ratio = 1 - ΔE_to / sum_RE_power
  # 电解槽总产氢量
  sum_H2_load = outputH2Mass(sum_ec_power, ec, 1.0)
  # 初始投资与替换成本
  cost_construct = sum(x -> initialInvestment(x) + replacementCost(x, fin), machines)
  # 运维成本
  cost_maintenance = sum(annualOperationCost, machines)
  # 用水成本
  cost_water = costWater(sum_H2_load, fin)
  # 买气成本
  cost_gas = costGas(sum_gt_power, gt, fin)
  # 耗气体积
  sum_gas = cost_gas / fin.price_gas_per_Nm3
  # 制氢成本
  cost_H2 = (cost_gas + cost_water + cost_maintenance) / sum_H2_load

  return OrderedDict(
      "系统设计寿命（年）" => fin.n_sys,
      "光伏电量（亿千瓦时）" => sum_pv_power / 1e8,
      "风电电量（亿千瓦时）" => sum_wt_power / 1e8,
      "风电光伏电量（亿千瓦时）" => sum_RE_power / 1e8,
      "风电光伏利用率（%）" => utilization_ratio * 100,
      "风电光伏弃电率（%）" => (1 - utilization_ratio) * 100,
      "制氢量（万吨）" => sum_H2_load / 1e7,
      "制氢用电量（亿千瓦时）" => sum_load_power / 1e8,
      "风光电量占制氢用电量比例（%）" => (sum_RE_power - ΔE_to) / sum_load_power  * 100,
      "静态总投资（亿元）" => cost_construct / 1e8,
      "年度运维成本（亿元）" => cost_maintenance / 1e8,
      "年度用水成本（亿元）" => cost_water / 1e8,
      "年度买气成本（亿元）"=> cost_gas /1e8,
      "制氢成本（元/kg）" => cost_H2,
  )
end