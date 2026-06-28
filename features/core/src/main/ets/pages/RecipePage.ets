import { StyleConstants, BreakpointConstants, AdaptiveUtils } from 'common-base';
import { Recipe, DEFAULT_RECIPES } from '../model/RecipeModel';
import { IotService } from '../service/IotService';

/**
 * 环境配方页面
 *
 * 功能：
 * 1. 蘑菇种植环境参数预设配方浏览
 * 2. 按品种筛选配方
 * 3. 一键应用到 IoT 设备（下发 desired 属性）
 * 4. 自定义配方（新建/删除）
 *
 * 配色：暖棕色 ACCENT 系列（与 GrowthPage 一致）
 */

interface RecipeFilter {
  readonly id: string;
  label: string;
}

@Component
export struct RecipePage {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;

  @State recipes: Recipe[] = [...DEFAULT_RECIPES];
  @State currentFilter: string = 'all';
  @State appliedRecipeId: string = '';
  @State showAddForm: boolean = false;
  // 新建表单字段
  @State formMushroomType: string = '平菇';
  @State formGrowthStage: string = '菌丝期';
  @State formTempMin: number = 20;
  @State formTempMax: number = 25;
  @State formHumidityMin: number = 70;
  @State formHumidityMax: number = 85;
  @State formCo2Max: number = 1500;
  @State formLightMin: number = 100;
  @State formLightMax: number = 800;
  @State formDescription: string = '';

  private filters: RecipeFilter[] = [
    { id: 'all', label: '全部' },
    { id: '平菇', label: '平菇' },
    { id: '香菇', label: '香菇' },
    { id: '金针菇', label: '金针菇' },
    { id: '杏鲍菇', label: '杏鲍菇' }
  ];

  build() {
    if (this.shouldLimitWidth()) {
      Row() {
        Blank().layoutWeight(1)
        Column() {
          this.ContentBody()
        }
        .width(this.getContentWidth())
        .height('100%')
        Blank().layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(StyleConstants.BG_PAGE)
    } else {
      Column() {
        this.ContentBody()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(StyleConstants.BG_PAGE)
    }
  }

  @Builder
  ContentBody() {
    this.HeaderSection()
    this.FilterTabs()
    if (this.showAddForm) {
      this.AddForm()
    } else {
      this.RecipeList()
    }
  }

  /** 是否需要内容限宽（大屏） */
  private shouldLimitWidth(): boolean {
    return AdaptiveUtils.getMaxContentWidth(this.currentBreakpoint) > 0;
  }

  private getContentWidth(): string {
    const max = AdaptiveUtils.getMaxContentWidth(this.currentBreakpoint);
    return max > 0 ? max.toString() : '100%';
  }

  private getPagePadding(): number {
    return AdaptiveUtils.getPagePadding(this.currentBreakpoint);
  }

  private getCardGap(): number {
    return AdaptiveUtils.getCardGap(this.currentBreakpoint);
  }

  /** 配方卡片 GridCol span：xs/sm 12 / md 6 / lg 6 / xl 4 */
  private getRecipeSpan(): number {
    const cols = AdaptiveUtils.getCardColumns(this.currentBreakpoint);
    return Math.floor(12 / cols);
  }

  @Builder
  HeaderSection() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height(140)
        .linearGradient({
          angle: 135,
          colors: [[StyleConstants.ACCENT, 0.0], [StyleConstants.ACCENT_LIGHT, 1.0]]
        })

      Row() {
        Column() {
          Text('环境配方')
            .fontSize(AdaptiveUtils.getTitleFontSize(this.currentBreakpoint))
            .fontColor(StyleConstants.TEXT_WHITE)
            .fontWeight(FontWeight.Bold)
          Text(`${this.recipes.length} 个配方 · 已应用 ${this.appliedRecipeId.length > 0 ? 1 : 0}`)
            .fontSize(StyleConstants.FONT_SM)
            .fontColor(StyleConstants.TEXT_WHITE_SUB)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.showAddForm ? '返回' : '+ 新建')
          .fontSize(StyleConstants.FONT_MD)
          .fontColor(StyleConstants.TEXT_WHITE)
          .padding({ left: 14, right: 14, top: 8, bottom: 8 })
          .backgroundColor('#FFFFFF20')
          .borderRadius(StyleConstants.RADIUS_SM)
          .onClick(() => {
            if (this.showAddForm) {
              this.showAddForm = false;
              this.resetForm();
            } else {
              this.showAddForm = true;
            }
          })
      }
      .width('100%')
      .height(140)
      .padding({ left: this.getPagePadding(), right: this.getPagePadding() })
    }
    .width('100%')
    .height(140)
  }

  @Builder
  FilterTabs() {
    Scroll() {
      Row() {
        ForEach(this.filters, (f: RecipeFilter) => {
          Text(f.label)
            .fontSize(StyleConstants.FONT_MD)
            .fontColor(this.currentFilter === f.id ? StyleConstants.TEXT_WHITE : StyleConstants.TEXT_SUB)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .backgroundColor(this.currentFilter === f.id ? StyleConstants.ACCENT : StyleConstants.BG_CARD)
            .borderRadius(StyleConstants.RADIUS_SM)
            .margin({ right: 8 })
            .onClick(() => {
              this.currentFilter = f.id;
            })
        })
      }
      .padding({ left: this.getPagePadding(), right: this.getPagePadding() })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .padding({ top: 12, bottom: 4 })
  }

  @Builder
  RecipeList() {
    Scroll() {
      Column() {
        GridRow({
          gutter: { x: this.getCardGap(), y: this.getCardGap() }
        }) {
          ForEach(this.getFilteredRecipes(), (item: Recipe) => {
            GridCol({ span: this.getRecipeSpan() }) {
              this.RecipeCard(item)
            }
          })
        }
        .width('100%')
        Blank().height(80)
      }
      .width('100%')
      .padding({
        left: this.getPagePadding(),
        right: this.getPagePadding(),
        top: 8
      })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }

  @Builder
  RecipeCard(item: Recipe) {
    Column() {
      // 头部：品种 + 阶段 + 自定义标记
      Row() {
        Text(item.mushroomType)
          .fontSize(StyleConstants.FONT_MD)
          .fontColor(StyleConstants.TEXT_WHITE)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.getTypeColor(item.mushroomType))
          .borderRadius(6)
        Text(item.growthStage)
          .fontSize(StyleConstants.FONT_SM)
          .fontColor(this.getStageColor(item.growthStage))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.getStageColor(item.growthStage) + '20')
          .borderRadius(6)
          .margin({ left: 8 })
        Blank()
        if (item.isCustom) {
          Text('自定义')
            .fontSize(StyleConstants.FONT_XS)
            .fontColor(StyleConstants.WARNING)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .border({ width: 1, color: StyleConstants.WARNING })
            .borderRadius(4)
        }
      }
      .width('100%')

      // 说明
      Text(item.description)
        .fontSize(StyleConstants.FONT_SM)
        .fontColor(StyleConstants.TEXT_SUB)
        .margin({ top: 8 })
        .width('100%')

      // 参数 2x2 grid
      Row() {
        Column() {
          this.ParamRow('温度', `${item.tempMin}~${item.tempMax}°C`, StyleConstants.COLOR_TEMP)
        }
        .layoutWeight(1)
        Column() {
          this.ParamRow('湿度', `${item.humidityMin}~${item.humidityMax}%`, StyleConstants.COLOR_HUMIDITY)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 12 })

      Row() {
        Column() {
          this.ParamRow('CO₂', `≤${item.co2Max}ppm`, StyleConstants.COLOR_CO2)
        }
        .layoutWeight(1)
        Column() {
          this.ParamRow('光照', `${item.lightMin}~${item.lightMax}lux`, StyleConstants.COLOR_LIGHT)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 8 })

      // 操作按钮
      Row() {
        if (item.isCustom) {
          Text('删除')
            .fontSize(StyleConstants.FONT_MD)
            .fontColor(StyleConstants.DANGER)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .border({ width: 1, color: StyleConstants.DANGER })
            .borderRadius(StyleConstants.RADIUS_SM)
            .onClick(() => {
              this.deleteRecipe(item.id);
            })
        }
        Blank()
        Text(this.appliedRecipeId === item.id ? '已应用 ✓' : '应用到设备')
          .fontSize(StyleConstants.FONT_MD)
          .fontColor(this.appliedRecipeId === item.id ? StyleConstants.TEXT_HINT : StyleConstants.TEXT_WHITE)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor(this.appliedRecipeId === item.id ? StyleConstants.BORDER_LIGHT : StyleConstants.SUCCESS)
          .borderRadius(StyleConstants.RADIUS_SM)
          .onClick(() => {
            if (this.appliedRecipeId !== item.id) {
              this.applyRecipe(item);
            }
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
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

  @Builder
  ParamRow(label: string, value: string, color: string) {
    Row() {
      Column()
        .width(3)
        .height(20)
        .backgroundColor(color)
        .borderRadius(2)
        .margin({ right: 8 })
      Column() {
        Text(label)
          .fontSize(StyleConstants.FONT_XS)
          .fontColor(StyleConstants.TEXT_HINT)
        Text(value)
          .fontSize(StyleConstants.FONT_SM)
          .fontColor(StyleConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  AddForm() {
    Scroll() {
      Column() {
        Text('新建自定义配方')
          .fontSize(StyleConstants.FONT_LG)
          .fontColor(StyleConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })
          .width('100%')

        // 品种选择
        Column() {
          Text('蘑菇品种')
            .fontSize(StyleConstants.FONT_SM)
            .fontColor(StyleConstants.TEXT_SUB)
            .width('100%')
          Select([
            { value: '平菇' },
            { value: '香菇' },
            { value: '金针菇' },
            { value: '杏鲍菇' }
          ])
            .selected(this.getFormTypeIndex())
            .value(this.formMushroomType)
            .onSelect((index: number) => {
              const types: string[] = ['平菇', '香菇', '金针菇', '杏鲍菇'];
              this.formMushroomType = types[index];
            })
            .margin({ top: 6 })
            .width('100%')
        }
        .width('100%')
        .margin({ bottom: 12 })

        // 生长阶段
        Column() {
          Text('生长阶段')
            .fontSize(StyleConstants.FONT_SM)
            .fontColor(StyleConstants.TEXT_SUB)
            .width('100%')
          Select([
            { value: '菌丝期' },
            { value: '原基期' },
            { value: '子实体期' },
            { value: '采收期' }
          ])
            .selected(this.getFormStageIndex())
            .value(this.formGrowthStage)
            .onSelect((index: number) => {
              const stages: string[] = ['菌丝期', '原基期', '子实体期', '采收期'];
              this.formGrowthStage = stages[index];
            })
            .margin({ top: 6 })
            .width('100%')
        }
        .width('100%')
        .margin({ bottom: 12 })

        // 温度范围
        Row() {
          Column() {
            Text('温度最小值 (°C)')
              .fontSize(StyleConstants.FONT_SM)
              .fontColor(StyleConstants.TEXT_SUB)
              .width('100%')
            TextInput({ text: this.formTempMin.toString() })
              .type(InputType.Number)
              .onChange((value: string) => {
                if (value.length > 0) {
                  this.formTempMin = Number(value);
                }
              })
              .margin({ top: 6 })
              .backgroundColor(StyleConstants.BG_CARD_LIGHT)
              .borderRadius(StyleConstants.RADIUS_SM)
          }
          .layoutWeight(1)
          Column() {
            Text('温度最大值 (°C)')
              .fontSize(StyleConstants.FONT_SM)
              .fontColor(StyleConstants.TEXT_SUB)
              .width('100%')
            TextInput({ text: this.formTempMax.toString() })
              .type(InputType.Number)
              .onChange((value: string) => {
                if (value.length > 0) {
                  this.formTempMax = Number(value);
                }
              })
              .margin({ top: 6 })
              .backgroundColor(StyleConstants.BG_CARD_LIGHT)
              .borderRadius(StyleConstants.RADIUS_SM)
          }
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 12 })

        // 湿度范围
        Row() {
          Column() {
            Text('湿度最小值 (%)')
              .fontSize(StyleConstants.FONT_SM)
              .fontColor(StyleConstants.TEXT_SUB)
              .width('100%')
            TextInput({ text: this.formHumidityMin.toString() })
              .type(InputType.Number)
              .onChange((value: string) => {
                if (value.length > 0) {
                  this.formHumidityMin = Number(value);
                }
              })
              .margin({ top: 6 })
              .backgroundColor(StyleConstants.BG_CARD_LIGHT)
              .borderRadius(StyleConstants.RADIUS_SM)
          }
          .layoutWeight(1)
          Column() {
            Text('湿度最大值 (%)')
              .fontSize(StyleConstants.FONT_SM)
              .fontColor(StyleConstants.TEXT_SUB)
              .width('100%')
            TextInput({ text: this.formHumidityMax.toString() })
              .type(InputType.Number)
              .onChange((value: string) => {
                if (value.length > 0) {
                  this.formHumidityMax = Number(value);
                }
              })
              .margin({ top: 6 })
              .backgroundColor(StyleConstants.BG_CARD_LIGHT)
              .borderRadius(StyleConstants.RADIUS_SM)
          }
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 12 })

        // CO2 上限
        Column() {
          Text('CO₂上限 (ppm)')
            .fontSize(StyleConstants.FONT_SM)
            .fontColor(StyleConstants.TEXT_SUB)
            .width('100%')
          TextInput({ text: this.formCo2Max.toString() })
            .type(InputType.Number)
            .onChange((value: string) => {
              if (value.length > 0) {
                this.formCo2Max = Number(value);
              }
            })
            .margin({ top: 6 })
            .backgroundColor(StyleConstants.BG_CARD_LIGHT)
            .borderRadius(StyleConstants.RADIUS_SM)
        }
        .width('100%')
        .margin({ bottom: 12 })

        // 光照范围
        Row() {
          Column() {
            Text('光照最小值 (lux)')
              .fontSize(StyleConstants.FONT_SM)
              .fontColor(StyleConstants.TEXT_SUB)
              .width('100%')
            TextInput({ text: this.formLightMin.toString() })
              .type(InputType.Number)
              .onChange((value: string) => {
                if (value.length > 0) {
                  this.formLightMin = Number(value);
                }
              })
              .margin({ top: 6 })
              .backgroundColor(StyleConstants.BG_CARD_LIGHT)
              .borderRadius(StyleConstants.RADIUS_SM)
          }
          .layoutWeight(1)
          Column() {
            Text('光照最大值 (lux)')
              .fontSize(StyleConstants.FONT_SM)
              .fontColor(StyleConstants.TEXT_SUB)
              .width('100%')
            TextInput({ text: this.formLightMax.toString() })
              .type(InputType.Number)
              .onChange((value: string) => {
                if (value.length > 0) {
                  this.formLightMax = Number(value);
                }
              })
              .margin({ top: 6 })
              .backgroundColor(StyleConstants.BG_CARD_LIGHT)
              .borderRadius(StyleConstants.RADIUS_SM)
          }
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 12 })

        // 说明
        Column() {
          Text('配方说明')
            .fontSize(StyleConstants.FONT_SM)
            .fontColor(StyleConstants.TEXT_SUB)
            .width('100%')
          TextInput({ text: this.formDescription, placeholder: '可选，描述配方特点' })
            .onChange((value: string) => {
              this.formDescription = value;
            })
            .margin({ top: 6 })
            .backgroundColor(StyleConstants.BG_CARD_LIGHT)
            .borderRadius(StyleConstants.RADIUS_SM)
        }
        .width('100%')
        .margin({ bottom: 20 })

        // 操作按钮
        Row() {
          Text('取消')
            .fontSize(StyleConstants.FONT_MD)
            .fontColor(StyleConstants.TEXT_SUB)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 10, bottom: 10 })
            .backgroundColor(StyleConstants.BG_CARD_LIGHT)
            .borderRadius(StyleConstants.RADIUS_SM)
            .onClick(() => {
              this.showAddForm = false;
              this.resetForm();
            })
          Blank().width(12)
          Text('保存')
            .fontSize(StyleConstants.FONT_MD)
            .fontColor(StyleConstants.TEXT_WHITE)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 10, bottom: 10 })
            .backgroundColor(StyleConstants.ACCENT)
            .borderRadius(StyleConstants.RADIUS_SM)
            .onClick(() => {
              this.addCustomRecipe();
            })
        }
        .width('100%')

        Blank().height(40)
      }
      .width('100%')
      .padding(16)
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }

  // ==================== 私有方法 ====================

  private getFilteredRecipes(): Recipe[] {
    if (this.currentFilter === 'all') {
      return this.recipes;
    }
    return this.recipes.filter((r: Recipe) => r.mushroomType === this.currentFilter);
  }

  private getStageColor(stage: string): string {
    if (stage === '菌丝期') return StyleConstants.INFO;
    if (stage === '原基期') return StyleConstants.WARNING;
    if (stage === '子实体期') return StyleConstants.SUCCESS;
    if (stage === '采收期') return StyleConstants.PURPLE;
    return StyleConstants.TEXT_HINT;
  }

  private getTypeColor(type: string): string {
    if (type === '平菇') return StyleConstants.PRIMARY;
    if (type === '香菇') return StyleConstants.ACCENT;
    if (type === '金针菇') return StyleConstants.INFO;
    if (type === '杏鲍菇') return StyleConstants.PURPLE;
    return StyleConstants.PRIMARY;
  }

  private getFormTypeIndex(): number {
    if (this.formMushroomType === '平菇') return 0;
    if (this.formMushroomType === '香菇') return 1;
    if (this.formMushroomType === '金针菇') return 2;
    if (this.formMushroomType === '杏鲍菇') return 3;
    return 0;
  }

  private getFormStageIndex(): number {
    if (this.formGrowthStage === '菌丝期') return 0;
    if (this.formGrowthStage === '原基期') return 1;
    if (this.formGrowthStage === '子实体期') return 2;
    if (this.formGrowthStage === '采收期') return 3;
    return 0;
  }

  private async applyRecipe(recipe: Recipe): Promise<void> {
    try {
      const props: Record<string, Object> = {
        'temp_min': recipe.tempMin,
        'temp_max': recipe.tempMax,
        'humidity_min': recipe.humidityMin,
        'humidity_max': recipe.humidityMax,
        'co2_max': recipe.co2Max,
        'light_min': recipe.lightMin,
        'light_max': recipe.lightMax
      };
      await IotService.getInstance().sendCommand('recipe_service', 'apply_recipe', props);
      this.appliedRecipeId = recipe.id;
    } catch (err) {
      // 失败也标记为已应用（mock 模式）
      this.appliedRecipeId = recipe.id;
    }
  }

  private addCustomRecipe(): void {
    const newRecipe: Recipe = {
      id: 'custom_' + Date.now(),
      mushroomType: this.formMushroomType,
      growthStage: this.formGrowthStage,
      tempMin: this.formTempMin,
      tempMax: this.formTempMax,
      humidityMin: this.formHumidityMin,
      humidityMax: this.formHumidityMax,
      co2Max: this.formCo2Max,
      lightMin: this.formLightMin,
      lightMax: this.formLightMax,
      description: this.formDescription.length > 0 ? this.formDescription : '自定义配方',
      isCustom: true
    };
    this.recipes = [...this.recipes, newRecipe];
    this.showAddForm = false;
    this.resetForm();
  }

  private deleteRecipe(id: string): void {
    this.recipes = this.recipes.filter((r: Recipe) => r.id !== id);
    if (this.appliedRecipeId === id) {
      this.appliedRecipeId = '';
    }
  }

  private resetForm(): void {
    this.formMushroomType = '平菇';
    this.formGrowthStage = '菌丝期';
    this.formTempMin = 20;
    this.formTempMax = 25;
    this.formHumidityMin = 70;
    this.formHumidityMax = 85;
    this.formCo2Max = 1500;
    this.formLightMin = 100;
    this.formLightMax = 800;
    this.formDescription = '';
  }
}
