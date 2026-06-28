/**
 * 图表通用接口与工具
 */

/** 图表数据点 */
export interface ChartPoint {
  readonly label: string;
  value: number;
}

/** 图表系列 */
export interface ChartSeries {
  readonly name: string;
  color: string;
  points: ChartPoint[];
}

/** 仪表盘配置 */
export interface GaugeConfig {
  min: number;
  max: number;
  value: number;
  unit: string;
  label: string;
  color: string;
}

/** 图表绘制工具 */
export class ChartUtils {
  /** 计算数据最大值，向上取整到合适刻度 */
  static calcMaxValue(values: number[]): number {
    if (values.length === 0) {
      return 100;
    }
    let max = 0;
    for (let i = 0; i < values.length; i++) {
      if (values[i] > max) {
        max = values[i];
      }
    }
    if (max <= 0) {
      return 100;
    }
    const magnitude = Math.pow(10, Math.floor(Math.log10(max)));
    return Math.ceil(max / magnitude) * magnitude;
  }

  /** 计算最小值 */
  static calcMinValue(values: number[]): number {
    if (values.length === 0) {
      return 0;
    }
    let min = values[0];
    for (let i = 1; i < values.length; i++) {
      if (values[i] < min) {
        min = values[i];
      }
    }
    return Math.floor(min);
  }

  /** 把数值映射到画布坐标 */
  static mapValue(v: number, min: number, max: number, canvasSize: number, padding: number): number {
    if (max === min) {
      return canvasSize / 2;
    }
    const range = max - min;
    const usable = canvasSize - padding * 2;
    return padding + ((v - min) / range) * usable;
  }
}
