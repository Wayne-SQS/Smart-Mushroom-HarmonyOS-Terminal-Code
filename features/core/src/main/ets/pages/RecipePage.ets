import { BreakpointConstants, AdaptiveUtils } from 'common-base';
import { Recipe, DEFAULT_RECIPES } from '../model/RecipeModel';
import { IotService } from '../service/IotService';
import { ThemeManager } from '../theme/ThemeManager';
import { ThemeTokens } from '../theme/ThemeTokens';

/**
 * 环境配方页面 - 主题驱动
 */

interface RecipeFilter {
  readonly id: string;
  label: string;
}

@Component
export struct RecipePage {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.SM;
  @StorageLink('themeName') themeName: string = 'frosted';

  @State recipes: Recipe[] = [...DEFAULT_RECIPES];
  @State currentFilter: string = 'all';
  @State appliedRecipeId: string = '';
  @State showAddForm: boolean = false;
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

  t(): ThemeTokens {
    return ThemeManager.getInstance().getTokens();
  }

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
      .backgroundColor(this.t().bgPage)
    } else {
      Column() {
        this.ContentBody()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.t().bgPage)
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

  private getRecipeSpan(): number {
    const cols = AdaptiveUtils.getCardColumns(this.currentBreakpoint);
    return Math.floor(12 / cols);
  }

  // ==================== Header（暖棕色 accent 渐变） ====================
  @Builder
  HeaderSection() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height(140)
        .linearGradient({
          angle: 135,
          colors: [[this.t().headerGradientTop, 0.0], [this.t().headerGradientBottom, 1.0]]
        })

      Row() {
        Column() {
          Text('环境配方')
            .fontSize(AdaptiveUtils.getTitleFontSize(this.currentBreakpoint))
            .fontColor(this.t().textWhite)
            .fontWeight(FontWeight.Bold)
          Text(`${this.recipes.length} 个配方 · 已应用 ${this.appliedRecipeId.length > 0 ? 1 : 0}`)
            .fontSize(this.t().fontSm)
            .fontColor(this.t().textWhiteSub)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.showAddForm ? '返回' : '+ 新建')
          .fontSize(this.t().fontMd)
          .fontColor(this.t().textWhite)
          .padding({ left: 14, right: 14, top: 8, bottom: 8 })
          .backgroundColor(this.t().bgCardLight)
          .borderRadius(this.t().radiusSm)
          .onClick(() => {
            if (this.showAddForm) { this.showAddForm = false; this.resetForm(); }
            else { this.showAddForm = true; }
          })
      }
      .width('100%')
      .height(140)
      .padding({ left: this.getPagePadding(), right: this.getPagePadding() })
    }
    .width('100%')
    .height(140)
  }

  // ==================== 筛选 Tab ====================
  @Builder
  FilterTabs() {
    Scroll() {
      Row() {
        ForEach(this.filters, (f: RecipeFilter) => {
          Text(f.label)
            .fontSize(this.t().fontMd)
            .fontColor(this.currentFilter === f.id ? this.t().textOnPrimary : this.t().textSub)
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .backgroundColor(this.currentFilter === f.id ? this.t().primary : this.t().bgCard)
            .borderRadius(this.t().radiusSm)
            .margin({ right: 8 })
            .onClick(() => { this.currentFilter = f.id; })
        })
      }
      .padding({ left: this.getPagePadding(), right: this.getPagePadding() })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .padding({ top: 12, bottom: 4 })
  }

  // ==================== 配方列表 ====================
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
      .padding({ left: this.getPagePadding(), right: this.getPagePadding(), top: 8 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }

  @Builder
  RecipeCard(item: Recipe) {
    Column() {
      Row() {
        Text(item.mushroomType)
          .fontSize(this.t().fontMd)
          .fontColor(this.t().textOnPrimary)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.getTypeColor(item.mushroomType))
          .borderRadius(6)
        Text(item.growthStage)
          .fontSize(this.t().fontSm)
          .fontColor(this.getStageColor(item.growthStage))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.t().bgCardLight)
          .borderRadius(6)
          .margin({ left: 8 })
        Blank()
        if (item.isCustom) {
          Text('自定义')
            .fontSize(this.t().fontXs)
            .fontColor(this.t().warning)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .border({ width: 1, color: this.t().warning })
            .borderRadius(4)
        }
      }
      .width('100%')

      Text(item.description)
        .fontSize(this.t().fontSm)
        .fontColor(this.t().textSub)
        .margin({ top: 8 })
        .width('100%')

      // 参数 2x2 grid
      Row() {
        Column() { this.ParamRow('温度', `${item.tempMin}~${item.tempMax}°C`, this.t().colorTemp) }
        .layoutWeight(1)
        Column() { this.ParamRow('湿度', `${item.humidityMin}~${item.humidityMax}%`, this.t().colorHumidity) }
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 12 })

      Row() {
        Column() { this.ParamRow('CO₂', `≤${item.co2Max}ppm`, this.t().colorCo2) }
        .layoutWeight(1)
        Column() { this.ParamRow('光照', `${item.lightMin}~${item.lightMax}lux`, this.t().colorLight) }
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 8 })

      // 操作按钮
      Row() {
        if (item.isCustom) {
          Text('删除')
            .fontSize(this.t().fontMd)
            .fontColor(this.t().danger)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .border({ width: 1, color: this.t().danger })
            .borderRadius(this.t().radiusSm)
            .onClick(() => { this.deleteRecipe(item.id); })
        }
        Blank()
        Text(this.appliedRecipeId === item.id ? '已应用 ✓' : '应用到设备')
          .fontSize(this.t().fontMd)
          .fontColor(this.appliedRecipeId === item.id ? this.t().textSub : this.t().textOnPrimary)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor(this.appliedRecipeId === item.id ? this.t().bgCardLight : this.t().primary)
          .borderRadius(this.t().radiusSm)
          .onClick(() => {
            if (this.appliedRecipeId !== item.id) { this.applyRecipe(item); }
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
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

  @Builder
  ParamRow(label: string, value: string, accentColor: string) {
    Row() {
      Column()
        .width(3)
        .height(20)
        .backgroundColor(accentColor)  // 传感器色仅供装饰（色条），不做文字色
        .borderRadius(2)
        .margin({ right: 8 })
      Column() {
        Text(label)
          .fontSize(this.t().fontXs)
          .fontColor(this.t().textSub)
        Text(value)
          .fontSize(this.t().fontSm)
          .fontColor(this.t().textTitle)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  // ==================== 新建表单 ====================
  @Builder
  AddForm() {
    Scroll() {
      Column() {
        Text('新建自定义配方')
          .fontSize(this.t().fontLg)
          .fontColor(this.t().textTitle)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })
          .width('100%')

        Column() {
          Text('蘑菇品种')
            .fontSize(this.t().fontSm).fontColor(this.t().textSub).width('100%')
          Select([
            { value: '平菇' }, { value: '香菇' }, { value: '金针菇' }, { value: '杏鲍菇' }
          ])
            .selected(this.getFormTypeIndex())
            .value(this.formMushroomType)
            .onSelect((index: number) => {
              const types: string[] = ['平菇', '香菇', '金针菇', '杏鲍菇'];
              this.formMushroomType = types[index];
            })
            .margin({ top: 6 }).width('100%')
        }
        .width('100%').margin({ bottom: 12 })

        Column() {
          Text('生长阶段')
            .fontSize(this.t().fontSm).fontColor(this.t().textSub).width('100%')
          Select([
            { value: '菌丝期' }, { value: '原基期' }, { value: '子实体期' }, { value: '采收期' }
          ])
            .selected(this.getFormStageIndex())
            .value(this.formGrowthStage)
            .onSelect((index: number) => {
              const stages: string[] = ['菌丝期', '原基期', '子实体期', '采收期'];
              this.formGrowthStage = stages[index];
            })
            .margin({ top: 6 }).width('100%')
        }
        .width('100%').margin({ bottom: 12 })

        // 温度范围
        Row() {
          Column() {
            Text('温度最小值 (°C)').fontSize(this.t().fontSm).fontColor(this.t().textSub).width('100%')
            TextInput({ text: this.formTempMin.toString() })
              .type(InputType.Number)
              .onChange((value: string) => { if (value.length > 0) { this.formTempMin = Number(value); } })
              .margin({ top: 6 })
              .backgroundColor(this.t().bgCardLight).borderRadius(this.t().radiusSm)
          }.layoutWeight(1)
          Column() {
            Text('温度最大值 (°C)').fontSize(this.t().fontSm).fontColor(this.t().textSub).width('100%')
            TextInput({ text: this.formTempMax.toString() })
              .type(InputType.Number)
              .onChange((value: string) => { if (value.length > 0) { this.formTempMax = Number(value); } })
              .margin({ top: 6 })
              .backgroundColor(this.t().bgCardLight).borderRadius(this.t().radiusSm)
          }.layoutWeight(1)
        }
        .width('100%').margin({ bottom: 12 })

        // 湿度范围
        Row() {
          Column() {
            Text('湿度最小值 (%)').fontSize(this.t().fontSm).fontColor(this.t().textSub).width('100%')
            TextInput({ text: this.formHumidityMin.toString() })
              .type(InputType.Number)
              .onChange((value: string) => { if (value.length > 0) { this.formHumidityMin = Number(value); } })
              .margin({ top: 6 })
              .backgroundColor(this.t().bgCardLight).borderRadius(this.t().radiusSm)
          }.layoutWeight(1)
          Column() {
            Text('湿度最大值 (%)').fontSize(this.t().fontSm).fontColor(this.t().textSub).width('100%')
            TextInput({ text: this.formHumidityMax.toString() })
              .type(InputType.Number)
              .onChange((value: string) => { if (value.length > 0) { this.formHumidityMax = Number(value); } })
              .margin({ top: 6 })
              .backgroundColor(this.t().bgCardLight).borderRadius(this.t().radiusSm)
          }.layoutWeight(1)
        }
        .width('100%').margin({ bottom: 12 })

        // CO2 上限
        Column() {
          Text('CO₂上限 (ppm)').fontSize(this.t().fontSm).fontColor(this.t().textSub).width('100%')
          TextInput({ text: this.formCo2Max.toString() })
            .type(InputType.Number)
            .onChange((value: string) => { if (value.length > 0) { this.formCo2Max = Number(value); } })
            .margin({ top: 6 })
            .backgroundColor(this.t().bgCardLight).borderRadius(this.t().radiusSm)
        }
        .width('100%').margin({ bottom: 12 })

        // 光照范围
        Row() {
          Column() {
            Text('光照最小值 (lux)').fontSize(this.t().fontSm).fontColor(this.t().textSub).width('100%')
            TextInput({ text: this.formLightMin.toString() })
              .type(InputType.Number)
              .onChange((value: string) => { if (value.length > 0) { this.formLightMin = Number(value); } })
              .margin({ top: 6 })
              .backgroundColor(this.t().bgCardLight).borderRadius(this.t().radiusSm)
          }.layoutWeight(1)
          Column() {
            Text('光照最大值 (lux)').fontSize(this.t().fontSm).fontColor(this.t().textSub).width('100%')
            TextInput({ text: this.formLightMax.toString() })
              .type(InputType.Number)
              .onChange((value: string) => { if (value.length > 0) { this.formLightMax = Number(value); } })
              .margin({ top: 6 })
              .backgroundColor(this.t().bgCardLight).borderRadius(this.t().radiusSm)
          }.layoutWeight(1)
        }
        .width('100%').margin({ bottom: 12 })

        // 说明
        Column() {
          Text('配方说明').fontSize(this.t().fontSm).fontColor(this.t().textSub).width('100%')
          TextInput({ text: this.formDescription, placeholder: '可选，描述配方特点' })
            .onChange((value: string) => { this.formDescription = value; })
            .margin({ top: 6 })
            .backgroundColor(this.t().bgCardLight).borderRadius(this.t().radiusSm)
        }
        .width('100%').margin({ bottom: 20 })

        // 操作按钮
        Row() {
          Text('取消')
            .fontSize(this.t().fontMd).fontColor(this.t().textSub)
            .layoutWeight(1).textAlign(TextAlign.Center)
            .padding({ top: 10, bottom: 10 })
            .backgroundColor(this.t().bgCardLight).borderRadius(this.t().radiusSm)
            .onClick(() => { this.showAddForm = false; this.resetForm(); })
          Blank().width(12)
          Text('保存')
            .fontSize(this.t().fontMd).fontColor(this.t().textOnPrimary)
            .layoutWeight(1).textAlign(TextAlign.Center)
            .padding({ top: 10, bottom: 10 })
            .backgroundColor(this.t().primary).borderRadius(this.t().radiusSm)
            .onClick(() => { this.addCustomRecipe(); })
        }
        .width('100%')

        Blank().height(40)
      }
      .width('100%').padding(16)
    }
    .layoutWeight(1).scrollBar(BarState.Auto)
  }

  // ==================== 私有方法 ====================

  private getFilteredRecipes(): Recipe[] {
    if (this.currentFilter === 'all') { return this.recipes; }
    return this.recipes.filter((r: Recipe) => r.mushroomType === this.currentFilter);
  }

  private getStageColor(stage: string): string {
    if (stage === '菌丝期') { return this.t().info; }
    if (stage === '原基期') { return this.t().warning; }
    if (stage === '子实体期') { return this.t().success; }
    if (stage === '采收期') { return this.t().purple; }
    return this.t().textSub;
  }

  private getTypeColor(type: string): string {
    if (type === '平菇') { return this.t().primary; }
    if (type === '香菇') { return this.t().accent; }
    if (type === '金针菇') { return this.t().info; }
    if (type === '杏鲍菇') { return this.t().purple; }
    return this.t().primary;
  }

  private getFormTypeIndex(): number {
    if (this.formMushroomType === '平菇') { return 0; }
    if (this.formMushroomType === '香菇') { return 1; }
    if (this.formMushroomType === '金针菇') { return 2; }
    if (this.formMushroomType === '杏鲍菇') { return 3; }
    return 0;
  }

  private getFormStageIndex(): number {
    if (this.formGrowthStage === '菌丝期') { return 0; }
    if (this.formGrowthStage === '原基期') { return 1; }
    if (this.formGrowthStage === '子实体期') { return 2; }
    if (this.formGrowthStage === '采收期') { return 3; }
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
    } catch {
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
    if (this.appliedRecipeId === id) { this.appliedRecipeId = ''; }
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
