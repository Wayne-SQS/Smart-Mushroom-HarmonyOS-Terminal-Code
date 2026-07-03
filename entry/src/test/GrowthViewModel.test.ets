import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { GrowthViewModel } from 'features-core';
import type { GrowthBatch } from 'features-core';

export default function growthViewModelTest() {
  describe('GrowthViewModel', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    describe('初始 mock 数据', () => {
      it('初始 batches 数组长度为 3', 0, () => {
        const vm = new GrowthViewModel();
        expect(vm.batches.length).assertEqual(3);
      });

      it('初始 currentBatches 为 3', 0, () => {
        const vm = new GrowthViewModel();
        expect(vm.currentBatches).assertEqual(3);
      });

      it('初始无已采收批次（loadData 前 mock 字段 harvestedBatches 为 7）', 0, () => {
        const vm = new GrowthViewModel();
        const harvestedInList = vm.batches.filter(b => b.status === '已采收').length;
        expect(harvestedInList).assertEqual(0);
      });
    });

    describe('addBatch()', () => {
      it('addBatch() 后 batches.length 增加 1', 0, () => {
        const vm = new GrowthViewModel();
        const before = vm.batches.length;
        const batch: GrowthBatch = {
          id: '99',
          mushroomType: '平菇',
          startDate: '2026-07-01',
          day: 1,
          status: '菌丝生长期',
          yield: '-'
        };
        vm.addBatch(batch);
        expect(vm.batches.length).assertEqual(before + 1);
      });

      it('addBatch() 后 currentBatches 增加 1', 0, () => {
        const vm = new GrowthViewModel();
        const before = vm.currentBatches;
        const batch: GrowthBatch = {
          id: '100',
          mushroomType: '香菇',
          startDate: '2026-07-02',
          day: 1,
          status: '原基形成期',
          yield: '-'
        };
        vm.addBatch(batch);
        expect(vm.currentBatches).assertEqual(before + 1);
      });
    });

    describe('archiveBatch()', () => {
      it('archiveBatch(id) 指定批次 status 变为"已采收"', 0, () => {
        const vm = new GrowthViewModel();
        vm.archiveBatch('2');
        const target = vm.batches.find(b => b.id === '2');
        expect(target !== undefined).assertTrue();
        expect(target!.status).assertEqual('已采收');
      });

      it('archiveBatch(id) 后 currentBatches 减 1', 0, () => {
        const vm = new GrowthViewModel();
        const before = vm.currentBatches;
        vm.archiveBatch('1');
        expect(vm.currentBatches).assertEqual(before - 1);
      });

      it('archiveBatch(不存在的 id) 列表不变，不抛异常', 0, () => {
        const vm = new GrowthViewModel();
        const before = vm.batches.length;
        vm.archiveBatch('nonexistent-id');
        expect(vm.batches.length).assertEqual(before);
      });
    });

    describe('loadData()', () => {
      it('loadData() 完成后 isLoading 为 false', 0, async () => {
        const vm = new GrowthViewModel();
        await vm.loadData();
        expect(vm.isLoading).assertFalse();
      });

      it('loadData() 完成后 lastUpdateTime 非空', 0, async () => {
        const vm = new GrowthViewModel();
        await vm.loadData();
        expect(vm.lastUpdateTime.length > 0).assertTrue();
      });

      it('loadData() 后 updateCounts 重算 harvestedBatches 为 0', 0, async () => {
        const vm = new GrowthViewModel();
        await vm.loadData();
        expect(vm.harvestedBatches).assertEqual(0);
        expect(vm.currentBatches).assertEqual(3);
      });
    });
  });
}
