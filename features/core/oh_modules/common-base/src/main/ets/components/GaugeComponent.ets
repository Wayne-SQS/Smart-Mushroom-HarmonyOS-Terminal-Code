import { GaugeConfig } from './ChartComponent';

/**
 * 仪表盘组件
 *
 * 半圆仪表盘，Canvas 自绘。所有颜色通过 @Prop 传入，支持主题切换。
 * 用法：GaugeComponent({ config: gaugeConfig, chartSize: 160 })
 */
@Component
export struct GaugeComponent {
  @Prop config: GaugeConfig;
  @Prop chartSize: number = 160;
  @Prop bgArcColor: string = '#E0E0E0';
  @Prop textValueColor: string = '#1A1A1A';
  @Prop textLabelColor: string = '#666666';
  @Prop textAuxColor: string = '#999999';
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Canvas(this.context)
      .width(this.chartSize)
      .height(this.chartSize * 0.6 + 20)
      .onReady(() => {
        this.drawGauge();
      })
  }

  private drawGauge(): void {
    const ctx = this.context;
    const w = ctx.width;
    const h = ctx.height;
    const cx = w / 2;
    const cy = h - 10;
    const radius = Math.min(w, h * 2) / 2 - 16;
    if (radius <= 0) {
      return;
    }

    ctx.clearRect(0, 0, w, h);

    const startAngle = Math.PI;
    const endAngle = Math.PI * 2;

    // 背景弧
    ctx.strokeStyle = this.bgArcColor;
    ctx.lineWidth = 12;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.arc(cx, cy, radius, startAngle, endAngle);
    ctx.stroke();

    // 数值弧
    const range = this.config.max - this.config.min;
    const ratio = range > 0 ? Math.max(0, Math.min(1, (this.config.value - this.config.min) / range)) : 0;
    const valueEndAngle = startAngle + (endAngle - startAngle) * ratio;

    ctx.strokeStyle = this.config.color;
    ctx.lineWidth = 12;
    ctx.beginPath();
    ctx.arc(cx, cy, radius, startAngle, valueEndAngle);
    ctx.stroke();

    // 中心数值
    ctx.fillStyle = this.textValueColor;
    ctx.font = 'bold 24px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(this.formatValue(this.config.value), cx, cy - 8);

    // 单位
    ctx.fillStyle = this.textLabelColor;
    ctx.font = '12px sans-serif';
    ctx.fillText(this.config.unit, cx, cy + 8);

    // 顶部 label
    ctx.fillStyle = this.textLabelColor;
    ctx.font = '12px sans-serif';
    ctx.fillText(this.config.label, cx, 16);

    // min / max
    ctx.fillStyle = this.textAuxColor;
    ctx.font = '10px sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText(this.config.min.toString(), cx - radius, cy + 16);
    ctx.textAlign = 'right';
    ctx.fillText(this.config.max.toString(), cx + radius, cy + 16);
  }

  private formatValue(v: number): string {
    if (v >= 1000) {
      return (v / 1000).toFixed(1) + 'k';
    }
    return v.toFixed(1);
  }
}
