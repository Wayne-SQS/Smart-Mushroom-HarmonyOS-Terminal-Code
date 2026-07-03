import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { DeviceViewModel } from 'features-core';

export default function deviceViewModelTest() {
  describe('DeviceViewModel', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    describe('初始 mock 数据', () => {
      it('初始 totalCount 为 8', 0, () => {
        const vm = new DeviceViewModel();
        expect(vm.totalCount).assertEqual(8);
      });

      it('初始 onlineCount 为 7', 0, () => {
        const vm = new DeviceViewModel();
        expect(vm.onlineCount).assertEqual(7);
      });

      it('初始 devices 数组长度为 8', 0, () => {
        const vm = new DeviceViewModel();
        expect(vm.devices.length).assertEqual(8);
      });
    });

    describe('loadData()', () => {
      it('loadData() 完成后 isLoading 为 false', 0, async () => {
        const vm = new DeviceViewModel();
        await vm.loadData();
        expect(vm.isLoading).assertFalse();
      });

      it('loadData() 后 totalCount 与 devices 状态一致', 0, async () => {
        const vm = new DeviceViewModel();
        await vm.loadData();
        expect(vm.totalCount).assertEqual(vm.devices.length);
        expect(vm.onlineCount + vm.offlineCount).assertEqual(vm.totalCount);
      });
    });

    describe('refreshStatus()', () => {
      it('refreshStatus 不存在的设备 ID 不抛异常，计数不变', 0, async () => {
        const vm = new DeviceViewModel();
        await vm.loadData();
        const beforeOnline = vm.onlineCount;
        const beforeTotal = vm.totalCount;
        await vm.refreshStatus('nonexistent-id');
        expect(vm.onlineCount).assertEqual(beforeOnline);
        expect(vm.totalCount).assertEqual(beforeTotal);
      });

      it('控制器类设备状态不受 IoT 在线状态影响', 0, async () => {
        const vm = new DeviceViewModel();
        await vm.loadData();
        let controllerIndex = -1;
        for (let i = 0; i < vm.devices.length; i++) {
          if (vm.devices[i].type === '控制器') {
            controllerIndex = i;
            break;
          }
        }
        expect(controllerIndex >= 0).assertTrue();
        const beforeStatus = vm.devices[controllerIndex].status;
        const beforeUpdate = vm.devices[controllerIndex].lastUpdate;
        await vm.refreshStatus(vm.devices[controllerIndex].id);
        expect(vm.devices[controllerIndex].status).assertEqual(beforeStatus);
        expect(vm.devices[controllerIndex].lastUpdate).assertEqual(beforeUpdate);
      });
    });
  });
}
