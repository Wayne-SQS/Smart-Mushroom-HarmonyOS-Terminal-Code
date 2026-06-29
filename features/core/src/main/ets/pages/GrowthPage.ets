import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';
import { GrowthBatch } from '../model/GreenhouseModel';

/**
 * 蘑菇生长日记页面 - 主题驱动
 */

@Component
export struct GrowthPage {
  @StorageLink('themeName') themeName: string = 'frosted';

  @State batches: GrowthBatch[] = [
    { id: '1', mushroomType: '平菇', startDate: '2026-05-20', day: 20, status: '采收中', yield: '12.5kg' },
    { id: '2', mushroomType: '香菇', startDate: '2026-05-28', day: 12, status: '菌丝生长期', yield: '-' },
    { id: '3', mushroomType: '金针菇', startDate: '2026-06-01', day: 8, status: '原基形成期', yield: '-' }
  ];

  @State totalYield: string = '45.2kg';
  @State currentBatches: number = 3;
  @State harvestedBatches: number = 7;

  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

  build() {
    Column() {
      this.HeaderSection()
      this.StatsCard()
      this.BatchTimeline()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.t().bgPage)
  }

  @Builder
  HeaderSection() {
    Row() {
      Text('生长日记')
        .fontSize(this.t().fontXxl)
        .fontColor(this.t().textWhite)
        .fontWeight(FontWeight.Bold)
      Blank()
      Text('+ 新建')
        .fontSize(this.t().fontMd)
        .fontColor(this.t().textWhite)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor(this.t().bgCardLight)
        .borderRadius(this.t().radiusSm)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.t().primary)
  }

  @Builder
  StatsCard() {
    Row() {
      Column() {
        Text(this.totalYield)
          .fontSize(this.t().fontXl)
          .fontColor(this.t().accent)
          .fontWeight(FontWeight.Bold)
        Text('累计产量')
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textSub)
          .margin({ top: 2 })
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Center)

      Divider().vertical(true).height(32).color(this.t().borderLight)

      Column() {
        Text(this.currentBatches.toString())
          .fontSize(this.t().fontXl)
          .fontColor(this.t().primary)
          .fontWeight(FontWeight.Bold)
        Text('在培批次')
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textSub)
          .margin({ top: 2 })
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Center)

      Divider().vertical(true).height(32).color(this.t().borderLight)

      Column() {
        Text(this.harvestedBatches.toString())
          .fontSize(this.t().fontXl)
          .fontColor(this.t().info)
          .fontWeight(FontWeight.Bold)
        Text('已采收')
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textSub)
          .margin({ top: 2 })
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .backgroundColor(this.t().bgCard)
    .backdropBlur(this.t().blurAmount)
    .border({ width: 1, color: this.t().border })
    .borderRadius(this.t().radiusLg)
    .margin({ top: 12, left: 12, right: 12 })
    .shadow({
      radius: this.t().shadowCardRadius,
      color: this.t().shadowCardColor,
      offsetX: 0,
      offsetY: this.t().shadowCardOffsetY
    })
  }

  @Builder
  BatchTimeline() {
    Scroll() {
      Column() {
        Text('在培批次')
          .fontSize(this.t().fontLg)
          .fontColor(this.t().textTitle)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 12 })

        ForEach(this.batches, (item: GrowthBatch, index: number) => {
          this.BatchCard(item, index === this.batches.length - 1)
        })

        Blank().height(80)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }

  @Builder
  BatchCard(item: GrowthBatch, isLast: boolean) {
    Row() {
      // 时间线圆点
      Column() {
        Circle({ width: 12, height: 12 })
          .fill(this.getStatusColor(item.status))
          .border({ width: 3, color: this.t().bgCard })
        if (!isLast) {
          Column()
            .width(2)
            .layoutWeight(1)
            .backgroundColor(this.t().borderLight)
            .margin({ top: 4 })
        }
      }
      .width(20)
      .height('100%')

      Column() {
        Row() {
          Text(item.mushroomType)
            .fontSize(this.t().fontLg)
            .fontColor(this.t().textTitle)
            .fontWeight(FontWeight.Bold)
          Blank()
          Text(item.status)
            .fontSize(this.t().fontXs)
            .fontColor(this.getStatusColor(item.status))
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(this.t().bgCardLight)
            .borderRadius(4)
        }
        .width('100%')

        Row() {
          Column() {
            Text(`第${item.day}天`)
              .fontSize(this.t().fontMd)
              .fontColor(this.t().textBody)
              .fontWeight(FontWeight.Medium)
            Text(`开始: ${item.startDate}`)
              .fontSize(this.t().fontXs)
              .fontColor(this.t().textSub)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Column() {
            if (item.yield !== '-') {
              Text(item.yield)
                .fontSize(this.t().fontLg)
                .fontColor(this.t().success)
                .fontWeight(FontWeight.Bold)
              Text('产量')
                .fontSize(this.t().fontXs)
                .fontColor(this.t().textSub)
            } else {
              Text(this.getExpectedHarvest(item.day))
                .fontSize(this.t().fontSm)
                .fontColor(this.t().warning)
              Text('预计采收')
                .fontSize(this.t().fontXs)
                .fontColor(this.t().textSub)
                .margin({ top: 2 })
            }
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .margin({ top: 10 })

        // 生长进度条
        Row() {
          Column()
            .layoutWeight(Math.min(item.day / 30, 1))
            .height(4)
            .backgroundColor(this.getStatusColor(item.status))
            .borderRadius(2)
          Column()
            .layoutWeight(Math.max(1 - item.day / 30, 0.01))
            .height(4)
            .backgroundColor(this.t().borderLight)
            .borderRadius(2)
        }
        .width('100%')
        .margin({ top: 10 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .padding(14)
      .backgroundColor(this.t().bgCard)
      .backdropBlur(this.t().blurAmount)
      .border({ width: 1, color: this.t().border })
      .borderRadius(this.t().radiusMd)
      .shadow({
        radius: this.t().shadowCardRadius,
        color: this.t().shadowCardColor,
        offsetX: 0,
        offsetY: this.t().shadowCardOffsetY
      })
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  private getStatusColor(status: string): string {
    if (status === '采收中') { return this.t().success; }
    if (status === '原基形成期') { return this.t().warning; }
    return this.t().info;
  }

  private getExpectedHarvest(currentDay: number): string {
    const remaining = 30 - currentDay;
    if (remaining <= 0) { return '可采收'; }
    return `${remaining}天后`;
  }
}
