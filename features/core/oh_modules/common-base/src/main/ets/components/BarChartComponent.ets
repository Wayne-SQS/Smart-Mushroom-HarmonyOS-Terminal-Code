import { ChartPoint, ChartUtils } from './ChartComponent';

/**
 * 柱状图组件
 *
 * 单系列柱状图，Canvas 自绘
 * 用法：BarChartComponent({ data: points, barColor: '#4CAF50', height: 200 })
 */
@Component
export struct BarChartComponent {
  @Prop data: ChartPoint[];
  @Prop barColor: string = '#4CAF50';
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
    const padding = 24;
    const values = this.extractValues();
    const maxVal = ChartUtils.calcMaxValue(values);
    const minVal = 0;
    const chartH = h - padding * 2;
    const barCount = this.data.length;
    if (barCount === 0) {
      return;
    }
    const slotW = (w - padding * 2) / barCount;
    const barW = slotW * 0.7;

    ctx.clearRect(0, 0, w, h);

    // 底部基线
    ctx.strokeStyle = '#E0E0E0';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(padding, h - padding);
    ctx.lineTo(w - padding, h - padding);
    ctx.stroke();

    // 柱子
    for (let i = 0; i < barCount; i++) {
      const point = this.data[i];
      const x = padding + slotW * i + (slotW - barW) / 2;
      const barH = ChartUtils.mapValue(point.value, minVal, maxVal, chartH, 0);
      const y = h - padding - barH;

      ctx.fillStyle = this.barColor;
      ctx.fillRect(x, y, barW, barH);

      // 数值标签
      ctx.fillStyle = '#333333';
      ctx.font = '10px sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText(this.formatValue(point.value), x + barW / 2, y - 4);

      // X 轴 label
      ctx.fillStyle = '#999999';
      ctx.font = '10px sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText(point.label, x + barW / 2, h - padding + 14);
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
