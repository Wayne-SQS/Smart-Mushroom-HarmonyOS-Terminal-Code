import { StyleConstants } from 'common-base';
import { GrowthBatch } from '../model/GreenhouseModel';

/**
 * 蘑菇生长日记页面（特色功能）
 *
 * 功能：
 * 1. 在培批次列表（时间线展示）
 * 2. 生长阶段标记
 * 3. 采收记录
 * 4. 预计采收时间
 */

@Component
export struct GrowthPage {
  @State batches: GrowthBatch[] = [
    { id: '1', mushroomType: '平菇', startDate: '2026-05-20', day: 20, status: '采收中', yield: '12.5kg' },
    { id: '2', mushroomType: '香菇', startDate: '2026-05-28', day: 12, status: '菌丝生长期', yield: '-' },
    { id: '3', mushroomType: '金针菇', startDate: '2026-06-01', day: 8, status: '原基形成期', yield: '-' }
  ];

  @State totalYield: string = '45.2kg';
  @State currentBatches: number = 3;
  @State harvestedBatches: number = 7;

  build() {
    Column() {
      this.HeaderSection()
      this.StatsCard()
      this.BatchTimeline()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(StyleConstants.BG_PAGE)
  }

  @Builder
  HeaderSection() {
    Row() {
      Text('生长日记')
        .fontSize(StyleConstants.FONT_XXL)
        .fontColor(StyleConstants.TEXT_WHITE)
        .fontWeight(FontWeight.Bold)
      Blank()
      Text('+ 新建')
        .fontSize(StyleConstants.FONT_MD)
        .fontColor(StyleConstants.TEXT_WHITE)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('#FFFFFF20')
        .borderRadius(StyleConstants.RADIUS_SM)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(StyleConstants.ACCENT)
  }

  @Builder
  StatsCard() {
    Row() {
      Column() {
        Text(this.totalYield)
          .fontSize(StyleConstants.FONT_XL)
          .fontColor(StyleConstants.ACCENT)
          .fontWeight(FontWeight.Bold)
        Text('累计产量')
          .fontSize(StyleConstants.FONT_SM)
          .fontColor(StyleConstants.TEXT_SUB)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Divider().vertical(true).height(32).color(StyleConstants.BORDER_LIGHT)

      Column() {
        Text(this.currentBatches.toString())
          .fontSize(StyleConstants.FONT_XL)
          .fontColor(StyleConstants.PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text('在培批次')
          .fontSize(StyleConstants.FONT_SM)
          .fontColor(StyleConstants.TEXT_SUB)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Divider().vertical(true).height(32).color(StyleConstants.BORDER_LIGHT)

      Column() {
        Text(this.harvestedBatches.toString())
          .fontSize(StyleConstants.FONT_XL)
          .fontColor(StyleConstants.INFO)
          .fontWeight(FontWeight.Bold)
        Text('已采收')
          .fontSize(StyleConstants.FONT_SM)
          .fontColor(StyleConstants.TEXT_SUB)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .backgroundColor(StyleConstants.BG_CARD)
    .borderRadius(StyleConstants.RADIUS_LG)
    .margin({ top: 12, left: 12, right: 12 })
    .shadow({
      radius: StyleConstants.SHADOW_CARD_RADIUS,
      color: StyleConstants.SHADOW_CARD_COLOR,
      offsetX: 0,
      offsetY: StyleConstants.SHADOW_CARD_OFFSETY
    })
  }

  @Builder
  BatchTimeline() {
    Scroll() {
      Column() {
        Text('在培批次')
          .fontSize(StyleConstants.FONT_LG)
          .fontColor(StyleConstants.TEXT_TITLE)
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
      // 时间线
      Column() {
        Circle({ width: 12, height: 12 })
          .fill(this.getStatusColor(item.status))
          .border({ width: 3, color: '#FFFFFF' })
        if (!isLast) {
          Column()
            .width(2)
            .layoutWeight(1)
            .backgroundColor(StyleConstants.BORDER_LIGHT)
            .margin({ top: 4 })
        }
      }
      .width(20)
      .height('100%')

      // 卡片内容
      Column() {
        Row() {
          Text(item.mushroomType)
            .fontSize(StyleConstants.FONT_LG)
            .fontColor(StyleConstants.TEXT_TITLE)
            .fontWeight(FontWeight.Bold)
          Blank()
          Text(item.status)
            .fontSize(StyleConstants.FONT_XS)
            .fontColor(this.getStatusColor(item.status))
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(this.getStatusColor(item.status) + '20')
            .borderRadius(4)
        }
        .width('100%')

        Row() {
          Column() {
            Text(`第${item.day}天`)
              .fontSize(StyleConstants.FONT_MD)
              .fontColor(StyleConstants.TEXT_BODY)
              .fontWeight(FontWeight.Medium)
            Text(`开始: ${item.startDate}`)
              .fontSize(StyleConstants.FONT_XS)
              .fontColor(StyleConstants.TEXT_HINT)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Column() {
            if (item.yield !== '-') {
              Text(item.yield)
                .fontSize(StyleConstants.FONT_LG)
                .fontColor(StyleConstants.SUCCESS)
                .fontWeight(FontWeight.Bold)
              Text('产量')
                .fontSize(StyleConstants.FONT_XS)
                .fontColor(StyleConstants.TEXT_HINT)
            } else {
              Text(this.getExpectedHarvest(item.day))
                .fontSize(StyleConstants.FONT_SM)
                .fontColor(StyleConstants.WARNING)
              Text('预计采收')
                .fontSize(StyleConstants.FONT_XS)
                .fontColor(StyleConstants.TEXT_HINT)
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
            .backgroundColor(StyleConstants.BORDER_LIGHT)
            .borderRadius(2)
        }
        .width('100%')
        .margin({ top: 10 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .padding(14)
      .backgroundColor(StyleConstants.BG_CARD)
      .borderRadius(StyleConstants.RADIUS_MD)
      .shadow({
        radius: 4,
        color: '#0A000000',
        offsetX: 0,
        offsetY: 1
      })
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  private getStatusColor(status: string): string {
    if (status === '采收中') {
      return StyleConstants.SUCCESS;
    }
    if (status === '原基形成期') {
      return StyleConstants.WARNING;
    }
    return StyleConstants.INFO;
  }

  private getExpectedHarvest(currentDay: number): string {
    const remaining = 30 - currentDay;
    if (remaining <= 0) {
      return '可采收';
    }
    return `${remaining}天后`;
  }
}
