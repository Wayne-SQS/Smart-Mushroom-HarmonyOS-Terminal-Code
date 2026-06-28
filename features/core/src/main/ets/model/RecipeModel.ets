/**
 * 蘑菇种植环境配方数据模型
 *
 * 配方定义不同蘑菇品种在各生长阶段所需的最佳环境参数范围。
 * 用于：一键下发到 IoT 设备 desired 属性、自定义配方管理。
 */

/** 生长阶段常量 */
export class GrowthStage {
  static readonly MYCELIUM: string = '菌丝期';
  static readonly PRIMORDIA: string = '原基期';
  static readonly FRUITING: string = '子实体期';
  static readonly HARVEST: string = '采收期';
}

/** 蘑菇品种常量 */
export class MushroomType {
  static readonly OYSTER: string = '平菇';
  static readonly SHIITAKE: string = '香菇';
  static readonly ENOKI: string = '金针菇';
  static readonly KING_OYSTER: string = '杏鲍菇';
}

/** 环境配方 */
export interface Recipe {
  readonly id: string;
  mushroomType: string;       // 蘑菇品种
  growthStage: string;         // 生长阶段
  tempMin: number;             // 温度范围
  tempMax: number;
  humidityMin: number;         // 湿度范围
  humidityMax: number;
  co2Max: number;              // CO2 上限
  lightMin: number;            // 光照范围
  lightMax: number;
  description: string;         // 配方说明
  isCustom: boolean;           // 是否用户自定义
}

/** 配方预设库（内置） */
export const DEFAULT_RECIPES: Recipe[] = [
  {
    id: 'recipe_oyster_mycelium',
    mushroomType: '平菇',
    growthStage: '菌丝期',
    tempMin: 24,
    tempMax: 28,
    humidityMin: 65,
    humidityMax: 75,
    co2Max: 3000,
    lightMin: 100,
    lightMax: 500,
    description: '平菇菌丝生长期，温度偏高，湿度适中',
    isCustom: false
  },
  {
    id: 'recipe_oyster_fruiting',
    mushroomType: '平菇',
    growthStage: '子实体期',
    tempMin: 15,
    tempMax: 20,
    humidityMin: 85,
    humidityMax: 95,
    co2Max: 1000,
    lightMin: 200,
    lightMax: 800,
    description: '平菇出菇期，需降温刺激，高湿度，低 CO2',
    isCustom: false
  },
  {
    id: 'recipe_shiitake_mycelium',
    mushroomType: '香菇',
    growthStage: '菌丝期',
    tempMin: 22,
    tempMax: 27,
    humidityMin: 60,
    humidityMax: 70,
    co2Max: 2500,
    lightMin: 50,
    lightMax: 300,
    description: '香菇菌丝期，避光培养，温度适中',
    isCustom: false
  },
  {
    id: 'recipe_shiitake_fruiting',
    mushroomType: '香菇',
    growthStage: '子实体期',
    tempMin: 8,
    tempMax: 18,
    humidityMin: 80,
    humidityMax: 90,
    co2Max: 800,
    lightMin: 300,
    lightMax: 1000,
    description: '香菇出菇期，需温差刺激，光照较强',
    isCustom: false
  },
  {
    id: 'recipe_enoki_mycelium',
    mushroomType: '金针菇',
    growthStage: '菌丝期',
    tempMin: 18,
    tempMax: 22,
    humidityMin: 70,
    humidityMax: 80,
    co2Max: 2000,
    lightMin: 100,
    lightMax: 400,
    description: '金针菇菌丝期，低温培养',
    isCustom: false
  },
  {
    id: 'recipe_enoki_fruiting',
    mushroomType: '金针菇',
    growthStage: '子实体期',
    tempMin: 5,
    tempMax: 12,
    humidityMin: 85,
    humidityMax: 95,
    co2Max: 1200,
    lightMin: 50,
    lightMax: 200,
    description: '金针菇出菇期，低温高湿，弱光培养',
    isCustom: false
  },
  {
    id: 'recipe_king_oyster_mycelium',
    mushroomType: '杏鲍菇',
    growthStage: '菌丝期',
    tempMin: 23,
    tempMax: 27,
    humidityMin: 65,
    humidityMax: 75,
    co2Max: 2800,
    lightMin: 100,
    lightMax: 400,
    description: '杏鲍菇菌丝期',
    isCustom: false
  },
  {
    id: 'recipe_king_oyster_fruiting',
    mushroomType: '杏鲍菇',
    growthStage: '子实体期',
    tempMin: 12,
    tempMax: 18,
    humidityMin: 85,
    humidityMax: 95,
    co2Max: 1000,
    lightMin: 200,
    lightMax: 800,
    description: '杏鲍菇出菇期，低温刺激',
    isCustom: false
  }
];
