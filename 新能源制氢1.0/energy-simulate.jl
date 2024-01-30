"""
返回仿真结果的字典数据

- Val{1}：离网制氢（不用燃料电池）
- Val{2}: 离网制氢（用燃料电池）

"""

function simulate!(machines::Tuple, fin::Financial, ::Val{1})
  #组件：光电、风电，燃气轮机，电解槽，储氢罐，氢气压缩机，空气储能装置
  pv, wt, gt, ec, ht, hc, es,  _ = machines
  machines = (pv, wt, gt, ec, ht, fc)
  #计算出单位时间内光电、风电发电量
  pv_power, wt_power = map(outputEnergy, (pv, wt))
  #获取电解槽和压缩氢气最大运行功率
  n = length(pv_power)
  ec_maxload, hc_maxload = map(maxpower,(ec,hc,n))
  renewable_power = pv_power + wt_power
  maxload = ec_maxload + hc_maxload
  #计算制造氢气的电能
  load_power = load(maxload, renewable_power, ec_maxload)
  #计算制造氢气的量
  hc_load = outputH2Mass(load_power, ec, 1.0)
  #计算能量差值
  ΔE = renewable_power - load_power * maxload / ec_maxload
  #计算压缩空气储能的当前储能、充放能
  to_es, es_power = outputEnergy(es, ΔE)
  #如果大于零，则为废电量;如果小于零，则说明储能装置没有满足要求，需要燃气轮机和燃料电池来补充
  ΔE -= to_es
  ΔE_to, ΔE_from = pn_split(ΔE)
  #计算燃气轮机和燃料电池的发电量
  gt_power = ΔE_from
  waste_power = ΔE_to
  ec_power = load_power
  load_power = load_power * maxload / ec_maxload
  powers = (pv_power, wt_power, gt_power, load_power, ec_power, es_power)
  ecd = economicAnalysisData(machines, fin, powers,
      (sum(ΔE_to), sum(ΔE_from)), Val(1))
  return ecd
end


