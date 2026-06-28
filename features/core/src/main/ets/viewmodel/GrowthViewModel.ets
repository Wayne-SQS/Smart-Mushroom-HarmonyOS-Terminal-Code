import { GrowthBatch } from '../model/GreenhouseModel';
import { BaseViewModel } from './BaseViewModel';

/**
 * 蘑菇生长批次 ViewModel
 *
 * 生长批次数据为本地管理（暂无 IoT 集成）。
 * 提供批次列表加载、新增、归档能力。
 */
export class GrowthViewModel extends BaseViewModel {
  /** 生长批次列表（默认 mock） */
  batches: GrowthBatch[] = [
    { id: '1', mushroomType: '平菇', startDate: '2026-05-20', day: 20, status: '采收中', yield: '12.5kg' },
    { id: '2', mushroomType: '香菇', startDate: '2026-05-28', day: 12, status: '菌丝生长期', yield: '-' },
    { id: '3', mushroomType: '金针菇', startDate: '2026-06-01', day: 8, status: '原基形成期', yield: '-' }
  ];

  /** 累计产量 */
  totalYield: string = '45.2kg';
  /** 在培批次 */
  currentBatches: number = 3;
  /** 已采收批次 */
  harvestedBatches: number = 7;

  /**
   * 加载生长批次数据
   *
   * 当前为本地 mock 数据，仅刷新时间戳与统计字段。
   */
  async loadData(): Promise<void> {
    await this.handleAsync(async () => {
      this.updateCounts();
    });
  }

  /**
   * 添加新批次
   *
   * @param batch 新批次对象（调用方负责生成 id）
   */
  addBatch(batch: GrowthBatch): void {
    this.batches.push(batch);
    this.updateCounts();
  }

  /**
   * 归档批次（标记状态为"已采收"）
   *
   * @param id 批次 ID
   */
  archiveBatch(id: string): void {
    for (let i = 0; i < this.batches.length; i++) {
      if (this.batches[i].id === id) {
        this.batches[i].status = '已采收';
        break;
      }
    }
    this.updateCounts();
  }

  /** 重新计算在培 / 已采收数量 */
  private updateCounts(): void {
    let active = 0;
    let harvested = 0;
    for (let i = 0; i < this.batches.length; i++) {
      if (this.batches[i].status === '已采收') {
        harvested++;
      } else {
        active++;
      }
    }
    this.currentBatches = active;
    this.harvestedBatches = harvested;
  }
}
