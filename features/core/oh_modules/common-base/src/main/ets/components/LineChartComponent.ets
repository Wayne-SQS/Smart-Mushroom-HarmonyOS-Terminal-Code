import { ChartPoint, ChartUtils } from './ChartComponent';

/**
 * 折线图组件
 *
 * 单系列折线图，Canvas 自绘
 * 用法：LineChartComponent({ data: points, lineColor: '#1890FF', height: 200 })
 */
@Component
export struct LineChartComponent {
  @Prop data: ChartPoint[];
  @Prop lineColor: string = '#1890FF';
  @Prop chartHeight: number = 200;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Canvas(this.context)
      .width('100%')
      .height(this.chartHeight)
      .onReady(() => {
        this.drawChart();
      })
  }

  private drawChart(): void {
    const ctx = this.context;
    const w = ctx.width;
    const h = ctx.height;
    const padding = 28;
    const chartH = h - padding * 2;
    const chartW = w - padding * 2;
    const values = this.extractValues();
    if (values.length === 0) {
      return;
    }
    const maxVal = ChartUtils.calcMaxValue(values);
    const minVal = ChartUtils.calcMinValue(values);

    ctx.clearRect(0, 0, w, h);

    // 网格线（3 条虚线）
    ctx.strokeStyle = '#F0F0F0';
    ctx.lineWidth = 1;
    ctx.setLineDash([4, 4]);
    for (let i = 0; i <= 3; i++) {
      const y = padding + chartH * (i / 3);
      ctx.beginPath();
      ctx.moveTo(padding, y);
      ctx.lineTo(w - padding, y);
      ctx.stroke();
    }
    ctx.setLineDash([]);

    // 折线
    ctx.strokeStyle = this.lineColor;
    ctx.lineWidth = 2;
    ctx.beginPath();
    for (let i = 0; i < this.data.length; i++) {
      const x = padding + chartW * (i / Math.max(this.data.length - 1, 1));
      const y = h - padding - ChartUtils.mapValue(this.data[i].value, minVal, maxVal, chartH, 0);
      if (i === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    }
    ctx.stroke();

    // 数据点 + 数值
    ctx.fillStyle = this.lineColor;
    for (let i = 0; i < this.data.length; i++) {
      const x = padding + chartW * (i / Math.max(this.data.length - 1, 1));
      const y = h - padding - ChartUtils.mapValue(this.data[i].value, minVal, maxVal, chartH, 0);
      ctx.beginPath();
      ctx.arc(x, y, 3, 0, Math.PI * 2);
      ctx.fill();

      ctx.fillStyle = '#333333';
      ctx.font = '10px sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText(this.formatValue(this.data[i].value), x, y - 8);
      ctx.fillStyle = this.lineColor;
    }

    // X 轴 label
    ctx.fillStyle = '#999999';
    ctx.font = '10px sans-serif';
    ctx.textAlign = 'center';
    for (let i = 0; i < this.data.length; i++) {
      const x = padding + chartW * (i / Math.max(this.data.length - 1, 1));
      ctx.fillText(this.data[i].label, x, h - padding + 14);
    }
  }

  private extractValues(): number[] {
    const result: number[] = [];
    for (let i = 0; i < this.data.length; i++) {
      result.push(this.data[i].value);
    }
    return result;
  }

  private formatValue(v: number): string {
    if (v >= 1000) {
      return (v / 1000).toFixed(1) + 'k';
    }
    return v.toFixed(0);
  }
}
