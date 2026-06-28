import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { StyleConstants, SensorType, BreakpointConstants, AdaptiveUtils } from 'common-base';

export default function iotTypesTest() {
  describe('IotTypes', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    describe('SensorType', () => {
      it('should define all sensor type enum values', 0, () => {
        expect(SensorType.TEMPERATURE).assertEqual('temperature');
        expect(SensorType.HUMIDITY).assertEqual('humidity');
        expect(SensorType.CO2).assertEqual('co2');
        expect(SensorType.LIGHT).assertEqual('light');
        expect(SensorType.SOIL_MOISTURE).assertEqual('soil_moisture');
        expect(SensorType.SOIL_TEMP).assertEqual('soil_temp');
        expect(SensorType.PH).assertEqual('ph');
      });

      it('all sensor type values should be non-empty strings', 0, () => {
        expect(SensorType.TEMPERATURE.length > 0).assertTrue();
        expect(SensorType.HUMIDITY.length > 0).assertTrue();
        expect(SensorType.CO2.length > 0).assertTrue();
        expect(SensorType.LIGHT.length > 0).assertTrue();
        expect(SensorType.SOIL_MOISTURE.length > 0).assertTrue();
        expect(SensorType.SOIL_TEMP.length > 0).assertTrue();
        expect(SensorType.PH.length > 0).assertTrue();
      });

      it('sensor type values should be unique', 0, () => {
        const values: Set<string> = new Set();
        values.add(SensorType.TEMPERATURE);
        values.add(SensorType.HUMIDITY);
        values.add(SensorType.CO2);
        values.add(SensorType.LIGHT);
        values.add(SensorType.SOIL_MOISTURE);
        values.add(SensorType.SOIL_TEMP);
        values.add(SensorType.PH);
        expect(values.size).assertEqual(7);
      });
    });

    describe('StyleConstants', () => {
      it('brand colors should exist with correct values', 0, () => {
        expect(StyleConstants.PRIMARY).assertEqual('#2E7D32');
        expect(StyleConstants.PRIMARY_LIGHT).assertEqual('#4CAF50');
        expect(StyleConstants.PRIMARY_DARK).assertEqual('#1B5E20');
        expect(StyleConstants.ACCENT).assertEqual('#8D6E63');
        expect(StyleConstants.ACCENT_LIGHT).assertEqual('#BCAAA4');
      });

      it('functional colors should exist as non-empty strings', 0, () => {
        expect(StyleConstants.SUCCESS.length > 0).assertTrue();
        expect(StyleConstants.WARNING.length > 0).assertTrue();
        expect(StyleConstants.DANGER.length > 0).assertTrue();
        expect(StyleConstants.INFO.length > 0).assertTrue();
        expect(StyleConstants.PURPLE.length > 0).assertTrue();
      });

      it('background colors should exist', 0, () => {
        expect(StyleConstants.BG_PAGE.length > 0).assertTrue();
        expect(StyleConstants.BG_CARD.length > 0).assertTrue();
        expect(StyleConstants.BG_CARD_LIGHT.length > 0).assertTrue();
        expect(StyleConstants.BG_DARK_CARD.length > 0).assertTrue();
      });

      it('text colors should exist', 0, () => {
        expect(StyleConstants.TEXT_TITLE.length > 0).assertTrue();
        expect(StyleConstants.TEXT_BODY.length > 0).assertTrue();
        expect(StyleConstants.TEXT_SUB.length > 0).assertTrue();
        expect(StyleConstants.TEXT_HINT.length > 0).assertTrue();
        expect(StyleConstants.TEXT_WHITE.length > 0).assertTrue();
      });

      it('sensor Colors should exist for all sensor categories', 0, () => {
        expect(StyleConstants.COLOR_TEMP.length > 0).assertTrue();
        expect(StyleConstants.COLOR_HUMIDITY.length > 0).assertTrue();
        expect(StyleConstants.COLOR_CO2.length > 0).assertTrue();
        expect(StyleConstants.COLOR_LIGHT.length > 0).assertTrue();
        expect(StyleConstants.COLOR_SOIL.length > 0).assertTrue();
        expect(StyleConstants.COLOR_PH.length > 0).assertTrue();
      });

      it('all colors should start with # (hex format)', 0, () => {
        expect(StyleConstants.PRIMARY.startsWith('#')).assertTrue();
        expect(StyleConstants.SUCCESS.startsWith('#')).assertTrue();
        expect(StyleConstants.DANGER.startsWith('#')).assertTrue();
        expect(StyleConstants.COLOR_TEMP.startsWith('#')).assertTrue();
        expect(StyleConstants.BG_PAGE.startsWith('#')).assertTrue();
      });

      it('radius constants should be positive numbers in ascending order', 0, () => {
        expect(StyleConstants.RADIUS_SM > 0).assertTrue();
        expect(StyleConstants.RADIUS_MD > 0).assertTrue();
        expect(StyleConstants.RADIUS_LG > 0).assertTrue();
        expect(StyleConstants.RADIUS_XL > 0).assertTrue();
        expect(StyleConstants.RADIUS_SM < StyleConstants.RADIUS_MD).assertTrue();
        expect(StyleConstants.RADIUS_MD < StyleConstants.RADIUS_LG).assertTrue();
        expect(StyleConstants.RADIUS_LG < StyleConstants.RADIUS_XL).assertTrue();
      });

      it('spacing constants should be positive numbers', 0, () => {
        expect(StyleConstants.SPACE_XS > 0).assertTrue();
        expect(StyleConstants.SPACE_SM > 0).assertTrue();
        expect(StyleConstants.SPACE_MD > 0).assertTrue();
        expect(StyleConstants.SPACE_LG > 0).assertTrue();
        expect(StyleConstants.SPACE_XL > 0).assertTrue();
        expect(StyleConstants.SPACE_XXL > 0).assertTrue();
      });

      it('font size constants should be positive numbers', 0, () => {
        expect(StyleConstants.FONT_XS > 0).assertTrue();
        expect(StyleConstants.FONT_SM > 0).assertTrue();
        expect(StyleConstants.FONT_MD > 0).assertTrue();
        expect(StyleConstants.FONT_LG > 0).assertTrue();
        expect(StyleConstants.FONT_XL > 0).assertTrue();
        expect(StyleConstants.FONT_XXL > 0).assertTrue();
        expect(StyleConstants.FONT_TITLE > 0).assertTrue();
        expect(StyleConstants.FONT_DATA > 0).assertTrue();
      });
    });

    describe('BreakpointConstants', () => {
      it('breakpoint names should be defined as lowercase strings', 0, () => {
        expect(BreakpointConstants.XS).assertEqual('xs');
        expect(BreakpointConstants.SM).assertEqual('sm');
        expect(BreakpointConstants.MD).assertEqual('md');
        expect(BreakpointConstants.LG).assertEqual('lg');
        expect(BreakpointConstants.XL).assertEqual('xl');
      });

      it('breakpoint thresholds should match spec', 0, () => {
        expect(BreakpointConstants.BREAKPOINT_SM).assertEqual(320);
        expect(BreakpointConstants.BREAKPOINT_MD).assertEqual(600);
        expect(BreakpointConstants.BREAKPOINT_LG).assertEqual(840);
        expect(BreakpointConstants.BREAKPOINT_XL).assertEqual(1440);
      });

      it('breakpoint thresholds should be in strictly ascending order', 0, () => {
        expect(BreakpointConstants.BREAKPOINT_SM < BreakpointConstants.BREAKPOINT_MD).assertTrue();
        expect(BreakpointConstants.BREAKPOINT_MD < BreakpointConstants.BREAKPOINT_LG).assertTrue();
        expect(BreakpointConstants.BREAKPOINT_LG < BreakpointConstants.BREAKPOINT_XL).assertTrue();
      });

      it('all thresholds should be positive', 0, () => {
        expect(BreakpointConstants.BREAKPOINT_SM > 0).assertTrue();
        expect(BreakpointConstants.BREAKPOINT_MD > 0).assertTrue();
        expect(BreakpointConstants.BREAKPOINT_LG > 0).assertTrue();
        expect(BreakpointConstants.BREAKPOINT_XL > 0).assertTrue();
      });
    });

    describe('AdaptiveUtils.getSensorColumns', () => {
      it('should return 2 columns for xs breakpoint', 0, () => {
        expect(AdaptiveUtils.getSensorColumns(BreakpointConstants.XS)).assertEqual(2);
      });

      it('should return 2 columns for sm breakpoint', 0, () => {
        expect(AdaptiveUtils.getSensorColumns(BreakpointConstants.SM)).assertEqual(2);
      });

      it('should return 3 columns for md breakpoint', 0, () => {
        expect(AdaptiveUtils.getSensorColumns(BreakpointConstants.MD)).assertEqual(3);
      });

      it('should return 4 columns for lg breakpoint', 0, () => {
        expect(AdaptiveUtils.getSensorColumns(BreakpointConstants.LG)).assertEqual(4);
      });

      it('should return 6 columns for xl breakpoint', 0, () => {
        expect(AdaptiveUtils.getSensorColumns(BreakpointConstants.XL)).assertEqual(6);
      });

      it('should return 2 (default) for unknown breakpoint', 0, () => {
        expect(AdaptiveUtils.getSensorColumns('unknown')).assertEqual(2);
        expect(AdaptiveUtils.getSensorColumns('')).assertEqual(2);
      });

      it('columns should be non-decreasing across breakpoints', 0, () => {
        const xs: number = AdaptiveUtils.getSensorColumns(BreakpointConstants.XS);
        const sm: number = AdaptiveUtils.getSensorColumns(BreakpointConstants.SM);
        const md: number = AdaptiveUtils.getSensorColumns(BreakpointConstants.MD);
        const lg: number = AdaptiveUtils.getSensorColumns(BreakpointConstants.LG);
        const xl: number = AdaptiveUtils.getSensorColumns(BreakpointConstants.XL);
        expect(xs <= sm).assertTrue();
        expect(sm <= md).assertTrue();
        expect(md <= lg).assertTrue();
        expect(lg <= xl).assertTrue();
      });
    });

    describe('AdaptiveUtils.isDualPane', () => {
      it('should return true for md breakpoint', 0, () => {
        expect(AdaptiveUtils.isDualPane(BreakpointConstants.MD)).assertTrue();
      });

      it('should return true for lg breakpoint', 0, () => {
        expect(AdaptiveUtils.isDualPane(BreakpointConstants.LG)).assertTrue();
      });

      it('should return true for xl breakpoint', 0, () => {
        expect(AdaptiveUtils.isDualPane(BreakpointConstants.XL)).assertTrue();
      });

      it('should return false for xs breakpoint', 0, () => {
        expect(AdaptiveUtils.isDualPane(BreakpointConstants.XS)).assertFalse();
      });

      it('should return false for sm breakpoint', 0, () => {
        expect(AdaptiveUtils.isDualPane(BreakpointConstants.SM)).assertFalse();
      });

      it('should return false for unknown breakpoint', 0, () => {
        expect(AdaptiveUtils.isDualPane('unknown')).assertFalse();
      });
    });

    describe('AdaptiveUtils.isLargeScreen', () => {
      it('should return true for lg breakpoint', 0, () => {
        expect(AdaptiveUtils.isLargeScreen(BreakpointConstants.LG)).assertTrue();
      });

      it('should return true for xl breakpoint', 0, () => {
        expect(AdaptiveUtils.isLargeScreen(BreakpointConstants.XL)).assertTrue();
      });

      it('should return false for xs breakpoint', 0, () => {
        expect(AdaptiveUtils.isLargeScreen(BreakpointConstants.XS)).assertFalse();
      });

      it('should return false for sm breakpoint', 0, () => {
        expect(AdaptiveUtils.isLargeScreen(BreakpointConstants.SM)).assertFalse();
      });

      it('should return false for md breakpoint', 0, () => {
        expect(AdaptiveUtils.isLargeScreen(BreakpointConstants.MD)).assertFalse();
      });

      it('should return false for unknown breakpoint', 0, () => {
        expect(AdaptiveUtils.isLargeScreen('unknown')).assertFalse();
      });
    });
  });
}
