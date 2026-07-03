import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { ChartUtils } from 'common-base';

export default function chartUtilsTest() {
  describe('ChartUtils', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    describe('calcMaxValue()', () => {
      it('空数组返回默认值 100', 0, () => {
        expect(ChartUtils.calcMaxValue([])).assertEqual(100);
      });

      it('全零数组返回默认值 100', 0, () => {
        expect(ChartUtils.calcMaxValue([0, 0, 0])).assertEqual(100);
      });

      it('[23, 45, 12] 向上取整到 50', 0, () => {
        expect(ChartUtils.calcMaxValue([23, 45, 12])).assertEqual(50);
      });

      it('[85, 90, 78] 向上取整到 90', 0, () => {
        expect(ChartUtils.calcMaxValue([85, 90, 78])).assertEqual(90);
      });

      it('[150, 200, 180] 向上取整到 200', 0, () => {
        expect(ChartUtils.calcMaxValue([150, 200, 180])).assertEqual(200);
      });

      it('单个值 [37] 向上取整到 40', 0, () => {
        expect(ChartUtils.calcMaxValue([37])).assertEqual(40);
      });
    });

    describe('calcMinValue()', () => {
      it('空数组返回 0', 0, () => {
        expect(ChartUtils.calcMinValue([])).assertEqual(0);
      });

      it('[5, 3, 8] 返回最小值 3', 0, () => {
        expect(ChartUtils.calcMinValue([5, 3, 8])).assertEqual(3);
      });

      it('[10, 20, 30] 返回最小值 10', 0, () => {
        expect(ChartUtils.calcMinValue([10, 20, 30])).assertEqual(10);
      });

      it('全零数组返回 0', 0, () => {
        expect(ChartUtils.calcMinValue([0, 0, 0])).assertEqual(0);
      });
    });
  });
}
