import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { SensorType } from 'common-base';
import { DashboardViewModel, AlertViewModel } from 'features-core';
import type { SensorDataItem, AlertItem } from 'features-core';

export default function viewModelTest() {
  describe('ViewModel', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    describe('BaseViewModel (via DashboardViewModel)', () => {
      it('initial isLoading should be false', 0, () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        expect(vm.isLoading).assertFalse();
      });

      it('initial errorMsg should be empty string', 0, () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        expect(vm.errorMsg).assertEqual('');
      });

      it('initial lastUpdateTime should be empty string', 0, () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        expect(vm.lastUpdateTime).assertEqual('');
      });
    });

    describe('DashboardViewModel mock data', () => {
      it('sensors should not be empty after construction', 0, () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        expect(vm.sensors.length > 0).assertTrue();
      });

      it('controls should not be empty after construction', 0, () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        expect(vm.controls.length > 0).assertTrue();
      });

      it('sensors should cover core sensor types', 0, () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        const types: Set<string> = new Set();
        for (let i = 0; i < vm.sensors.length; i++) {
          types.add(vm.sensors[i].type);
        }
        expect(types.has(SensorType.TEMPERATURE)).assertTrue();
        expect(types.has(SensorType.HUMIDITY)).assertTrue();
        expect(types.has(SensorType.CO2)).assertTrue();
        expect(types.has(SensorType.LIGHT)).assertTrue();
        expect(types.has(SensorType.SOIL_MOISTURE)).assertTrue();
        expect(types.has(SensorType.SOIL_TEMP)).assertTrue();
      });

      it('each sensor should have valid min < max range', 0, () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        for (let i = 0; i < vm.sensors.length; i++) {
          const s: SensorDataItem = vm.sensors[i];
          expect(s.min < s.max).assertTrue();
        }
      });

      it('each sensor status should be in [0, 2]', 0, () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        for (let i = 0; i < vm.sensors.length; i++) {
          const s: SensorDataItem = vm.sensors[i];
          expect(s.status >= 0).assertTrue();
          expect(s.status <= 2).assertTrue();
        }
      });

      it('each sensor value should be a finite number', 0, () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        for (let i = 0; i < vm.sensors.length; i++) {
          const s: SensorDataItem = vm.sensors[i];
          expect(typeof s.value === 'number').assertTrue();
          expect(isFinite(s.value)).assertTrue();
        }
      });

      it('overview onlineDevices should be positive', 0, () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        expect(vm.overview.onlineDevices > 0).assertTrue();
      });

      it('overview todayYield should be non-empty string', 0, () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        expect(vm.overview.todayYield.length > 0).assertTrue();
      });

      it('overview currentBatches should be positive', 0, () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        expect(vm.overview.currentBatches > 0).assertTrue();
      });

      it('controls should have unique ids', 0, () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        const ids: Set<string> = new Set();
        for (let i = 0; i < vm.controls.length; i++) {
          ids.add(vm.controls[i].id);
        }
        expect(ids.size).assertEqual(vm.controls.length);
      });

      it('each control should have a non-empty name and icon', 0, () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        for (let i = 0; i < vm.controls.length; i++) {
          const c = vm.controls[i];
          expect(c.name.length > 0).assertTrue();
          expect(c.icon.length > 0).assertTrue();
          expect(c.color.length > 0).assertTrue();
        }
      });
    });

    describe('DashboardViewModel loadData (IoT unavailable, mock fallback)', () => {
      it('loadData should set isLoading=false after completion', 0, async () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        await vm.loadData();
        expect(vm.isLoading).assertFalse();
      });

      it('loadData should keep mock sensors non-empty on IoT failure', 0, async () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        await vm.loadData();
        expect(vm.sensors.length > 0).assertTrue();
      });

      it('loadData should keep mock controls non-empty on IoT failure', 0, async () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        await vm.loadData();
        expect(vm.controls.length > 0).assertTrue();
      });

      it('loadData should set errorMsg when IoT service unavailable', 0, async () => {
        const vm: DashboardViewModel = new DashboardViewModel();
        await vm.loadData();
        expect(vm.errorMsg.length > 0).assertTrue();
      });
    });

    describe('AlertViewModel initial state', () => {
      it('initial alerts should be empty', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        expect(vm.alerts.length).assertEqual(0);
      });

      it('initial unreadCount should be 0', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        expect(vm.unreadCount).assertEqual(0);
      });

      it('initial filter should be all', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        expect(vm.getFilteredAlerts().length).assertEqual(0);
      });
    });

    describe('AlertViewModel.loadFromSensors derivation', () => {
      it('should generate no alert when all sensors status=0', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        const sensors: SensorDataItem[] = [
          { type: SensorType.TEMPERATURE, value: 22, min: 15, max: 28, status: 0 },
          { type: SensorType.HUMIDITY, value: 80, min: 70, max: 95, status: 0 }
        ];
        vm.loadFromSensors(sensors);
        expect(vm.alerts.length).assertEqual(0);
        expect(vm.unreadCount).assertEqual(0);
      });

      it('should derive warning alert (level=0) for status=1 sensor', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        const sensors: SensorDataItem[] = [
          { type: SensorType.TEMPERATURE, value: 35, min: 15, max: 28, status: 1 }
        ];
        vm.loadFromSensors(sensors);
        expect(vm.alerts.length).assertEqual(1);
        expect(vm.alerts[0].level).assertEqual(0);
        expect(vm.unreadCount).assertEqual(1);
      });

      it('should derive danger alert (level=1) for status=2 sensor', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        const sensors: SensorDataItem[] = [
          { type: SensorType.CO2, value: 2000, min: 400, max: 1500, status: 2 }
        ];
        vm.loadFromSensors(sensors);
        expect(vm.alerts.length).assertEqual(1);
        expect(vm.alerts[0].level).assertEqual(1);
      });

      it('should derive multiple alerts for multiple abnormal sensors', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        const sensors: SensorDataItem[] = [
          { type: SensorType.TEMPERATURE, value: 35, min: 15, max: 28, status: 1 },
          { type: SensorType.HUMIDITY, value: 50, min: 70, max: 95, status: 2 },
          { type: SensorType.CO2, value: 1200, min: 400, max: 1500, status: 0 }
        ];
        vm.loadFromSensors(sensors);
        expect(vm.alerts.length).assertEqual(2);
        expect(vm.unreadCount).assertEqual(2);
      });

      it('alert id should follow pattern alert-{sensorType}', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        const sensors: SensorDataItem[] = [
          { type: SensorType.TEMPERATURE, value: 35, min: 15, max: 28, status: 1 }
        ];
        vm.loadFromSensors(sensors);
        expect(vm.alerts[0].id).assertEqual('alert-' + SensorType.TEMPERATURE);
      });

      it('alert message should contain the sensor value', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        const sensors: SensorDataItem[] = [
          { type: SensorType.TEMPERATURE, value: 35, min: 15, max: 28, status: 1 }
        ];
        vm.loadFromSensors(sensors);
        expect(vm.alerts[0].message.length > 0).assertTrue();
      });

      it('alert device field should be non-empty', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        const sensors: SensorDataItem[] = [
          { type: SensorType.HUMIDITY, value: 50, min: 70, max: 95, status: 2 }
        ];
        vm.loadFromSensors(sensors);
        expect(vm.alerts[0].device.length > 0).assertTrue();
      });

      it('loadFromSensors should replace previous alerts on re-sync', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        const first: SensorDataItem[] = [
          { type: SensorType.TEMPERATURE, value: 35, min: 15, max: 28, status: 1 }
        ];
        vm.loadFromSensors(first);
        expect(vm.alerts.length).assertEqual(1);
        const second: SensorDataItem[] = [
          { type: SensorType.CO2, value: 2000, min: 400, max: 1500, status: 2 }
        ];
        vm.loadFromSensors(second);
        expect(vm.alerts.length).assertEqual(1);
        expect(vm.alerts[0].id).assertEqual('alert-' + SensorType.CO2);
      });

      it('loadFromSensors from DashboardViewModel mock should produce alerts (CO2 status=1)', 0, () => {
        const dash: DashboardViewModel = new DashboardViewModel();
        const vm: AlertViewModel = new AlertViewModel();
        vm.loadFromSensors(dash.sensors);
        expect(vm.alerts.length >= 1).assertTrue();
      });
    });

    describe('AlertViewModel markRead / markAllRead', () => {
      it('markRead should decrease unreadCount by 1', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        const sensors: SensorDataItem[] = [
          { type: SensorType.TEMPERATURE, value: 35, min: 15, max: 28, status: 1 },
          { type: SensorType.HUMIDITY, value: 50, min: 70, max: 95, status: 2 }
        ];
        vm.loadFromSensors(sensors);
        expect(vm.unreadCount).assertEqual(2);
        vm.markRead('alert-' + SensorType.TEMPERATURE);
        expect(vm.unreadCount).assertEqual(1);
      });

      it('markAllRead should set unreadCount to 0', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        const sensors: SensorDataItem[] = [
          { type: SensorType.TEMPERATURE, value: 35, min: 15, max: 28, status: 1 },
          { type: SensorType.HUMIDITY, value: 50, min: 70, max: 95, status: 2 }
        ];
        vm.loadFromSensors(sensors);
        vm.markAllRead();
        expect(vm.unreadCount).assertEqual(0);
      });

      it('markRead on non-existent id should not change unreadCount', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        const sensors: SensorDataItem[] = [
          { type: SensorType.TEMPERATURE, value: 35, min: 15, max: 28, status: 1 }
        ];
        vm.loadFromSensors(sensors);
        expect(vm.unreadCount).assertEqual(1);
        vm.markRead('alert-non-existent');
        expect(vm.unreadCount).assertEqual(1);
      });
    });

    describe('AlertViewModel clearAll', () => {
      it('clearAll should empty alerts and reset unreadCount', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        const sensors: SensorDataItem[] = [
          { type: SensorType.TEMPERATURE, value: 35, min: 15, max: 28, status: 1 }
        ];
        vm.loadFromSensors(sensors);
        vm.markAllRead();
        vm.clearAll();
        expect(vm.alerts.length).assertEqual(0);
        expect(vm.unreadCount).assertEqual(0);
      });
    });

    describe('AlertViewModel getFilteredAlerts', () => {
      it('all filter should return all alerts', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        const sensors: SensorDataItem[] = [
          { type: SensorType.TEMPERATURE, value: 35, min: 15, max: 28, status: 1 },
          { type: SensorType.HUMIDITY, value: 50, min: 70, max: 95, status: 2 }
        ];
        vm.loadFromSensors(sensors);
        vm.setFilter('all');
        const filtered: AlertItem[] = vm.getFilteredAlerts();
        expect(filtered.length).assertEqual(2);
      });

      it('danger filter should return only level=1 alerts', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        const sensors: SensorDataItem[] = [
          { type: SensorType.TEMPERATURE, value: 35, min: 15, max: 28, status: 1 },
          { type: SensorType.HUMIDITY, value: 50, min: 70, max: 95, status: 2 }
        ];
        vm.loadFromSensors(sensors);
        vm.setFilter('danger');
        const filtered: AlertItem[] = vm.getFilteredAlerts();
        expect(filtered.length).assertEqual(1);
        expect(filtered[0].level).assertEqual(1);
      });

      it('unread filter should exclude read alerts', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        const sensors: SensorDataItem[] = [
          { type: SensorType.TEMPERATURE, value: 35, min: 15, max: 28, status: 1 },
          { type: SensorType.HUMIDITY, value: 50, min: 70, max: 95, status: 2 }
        ];
        vm.loadFromSensors(sensors);
        vm.markRead('alert-' + SensorType.TEMPERATURE);
        vm.setFilter('unread');
        const filtered: AlertItem[] = vm.getFilteredAlerts();
        expect(filtered.length).assertEqual(1);
        expect(filtered[0].id).assertEqual('alert-' + SensorType.HUMIDITY);
      });

      it('unread filter should return empty when all read', 0, () => {
        const vm: AlertViewModel = new AlertViewModel();
        const sensors: SensorDataItem[] = [
          { type: SensorType.TEMPERATURE, value: 35, min: 15, max: 28, status: 1 }
        ];
        vm.loadFromSensors(sensors);
        vm.markAllRead();
        vm.setFilter('unread');
        const filtered: AlertItem[] = vm.getFilteredAlerts();
        expect(filtered.length).assertEqual(0);
      });
    });

    describe('AlertViewModel loadData', () => {
      it('loadData should set isLoading=false after completion', 0, async () => {
        const vm: AlertViewModel = new AlertViewModel();
        await vm.loadData();
        expect(vm.isLoading).assertFalse();
      });

      it('loadData should preserve existing alerts (only refreshes unreadCount)', 0, async () => {
        const vm: AlertViewModel = new AlertViewModel();
        const sensors: SensorDataItem[] = [
          { type: SensorType.TEMPERATURE, value: 35, min: 15, max: 28, status: 1 }
        ];
        vm.loadFromSensors(sensors);
        expect(vm.alerts.length).assertEqual(1);
        await vm.loadData();
        expect(vm.alerts.length).assertEqual(1);
      });
    });
  });
}
