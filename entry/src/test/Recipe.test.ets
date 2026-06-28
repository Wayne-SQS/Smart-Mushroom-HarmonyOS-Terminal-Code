import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { DEFAULT_RECIPES, GrowthStage, MushroomType } from 'features-core';
import type { Recipe } from 'features-core';

export default function recipeTest() {
  describe('RecipeModel', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('DEFAULT_RECIPES should not be empty', 0, () => {
      expect(DEFAULT_RECIPES.length > 0).assertTrue();
    });

    it('DEFAULT_RECIPES should have at least 8 recipes', 0, () => {
      expect(DEFAULT_RECIPES.length).assertLargerOrEqual(8);
    });

    it('each recipe should have a non-empty id', 0, () => {
      for (let i = 0; i < DEFAULT_RECIPES.length; i++) {
        const r: Recipe = DEFAULT_RECIPES[i];
        expect(r.id.length > 0).assertTrue();
      }
    });

    it('each recipe should have a non-empty mushroomType', 0, () => {
      for (let i = 0; i < DEFAULT_RECIPES.length; i++) {
        const r: Recipe = DEFAULT_RECIPES[i];
        expect(r.mushroomType.length > 0).assertTrue();
      }
    });

    it('each recipe should have a non-empty growthStage', 0, () => {
      for (let i = 0; i < DEFAULT_RECIPES.length; i++) {
        const r: Recipe = DEFAULT_RECIPES[i];
        expect(r.growthStage.length > 0).assertTrue();
      }
    });

    it('each recipe should have numeric tempMin and tempMax', 0, () => {
      for (let i = 0; i < DEFAULT_RECIPES.length; i++) {
        const r: Recipe = DEFAULT_RECIPES[i];
        expect(typeof r.tempMin === 'number').assertTrue();
        expect(typeof r.tempMax === 'number').assertTrue();
      }
    });

    it('each recipe should have numeric humidityMin and humidityMax', 0, () => {
      for (let i = 0; i < DEFAULT_RECIPES.length; i++) {
        const r: Recipe = DEFAULT_RECIPES[i];
        expect(typeof r.humidityMin === 'number').assertTrue();
        expect(typeof r.humidityMax === 'number').assertTrue();
      }
    });

    it('each recipe should have numeric co2Max, lightMin, lightMax', 0, () => {
      for (let i = 0; i < DEFAULT_RECIPES.length; i++) {
        const r: Recipe = DEFAULT_RECIPES[i];
        expect(typeof r.co2Max === 'number').assertTrue();
        expect(typeof r.lightMin === 'number').assertTrue();
        expect(typeof r.lightMax === 'number').assertTrue();
      }
    });

    it('each recipe should have a non-empty description', 0, () => {
      for (let i = 0; i < DEFAULT_RECIPES.length; i++) {
        const r: Recipe = DEFAULT_RECIPES[i];
        expect(r.description.length > 0).assertTrue();
      }
    });

    it('each recipe should have a boolean isCustom field', 0, () => {
      for (let i = 0; i < DEFAULT_RECIPES.length; i++) {
        const r: Recipe = DEFAULT_RECIPES[i];
        expect(typeof r.isCustom === 'boolean').assertTrue();
      }
    });

    it('each recipe should satisfy tempMin < tempMax', 0, () => {
      for (let i = 0; i < DEFAULT_RECIPES.length; i++) {
        const r: Recipe = DEFAULT_RECIPES[i];
        expect(r.tempMin < r.tempMax).assertTrue();
      }
    });

    it('each recipe should satisfy humidityMin < humidityMax', 0, () => {
      for (let i = 0; i < DEFAULT_RECIPES.length; i++) {
        const r: Recipe = DEFAULT_RECIPES[i];
        expect(r.humidityMin < r.humidityMax).assertTrue();
      }
    });

    it('each recipe should satisfy lightMin < lightMax', 0, () => {
      for (let i = 0; i < DEFAULT_RECIPES.length; i++) {
        const r: Recipe = DEFAULT_RECIPES[i];
        expect(r.lightMin < r.lightMax).assertTrue();
      }
    });

    it('each recipe should have positive co2Max', 0, () => {
      for (let i = 0; i < DEFAULT_RECIPES.length; i++) {
        const r: Recipe = DEFAULT_RECIPES[i];
        expect(r.co2Max > 0).assertTrue();
      }
    });

    it('all default recipes should be marked as not custom (isCustom=false)', 0, () => {
      for (let i = 0; i < DEFAULT_RECIPES.length; i++) {
        const r: Recipe = DEFAULT_RECIPES[i];
        expect(r.isCustom).assertFalse();
      }
    });

    it('recipe ids should be unique', 0, () => {
      const ids: Set<string> = new Set();
      for (let i = 0; i < DEFAULT_RECIPES.length; i++) {
        ids.add(DEFAULT_RECIPES[i].id);
      }
      expect(ids.size).assertEqual(DEFAULT_RECIPES.length);
    });

    it('GrowthStage should contain all known stages', 0, () => {
      expect(GrowthStage.MYCELIUM).assertEqual('菌丝期');
      expect(GrowthStage.PRIMORDIA).assertEqual('原基期');
      expect(GrowthStage.FRUITING).assertEqual('子实体期');
      expect(GrowthStage.HARVEST).assertEqual('采收期');
    });

    it('MushroomType should contain all known types', 0, () => {
      expect(MushroomType.OYSTER).assertEqual('平菇');
      expect(MushroomType.SHIITAKE).assertEqual('香菇');
      expect(MushroomType.ENOKI).assertEqual('金针菇');
      expect(MushroomType.KING_OYSTER).assertEqual('杏鲍菇');
    });

    it('default recipes should cover all four mushroom types', 0, () => {
      const types: Set<string> = new Set();
      for (let i = 0; i < DEFAULT_RECIPES.length; i++) {
        types.add(DEFAULT_RECIPES[i].mushroomType);
      }
      expect(types.has(MushroomType.OYSTER)).assertTrue();
      expect(types.has(MushroomType.SHIITAKE)).assertTrue();
      expect(types.has(MushroomType.ENOKI)).assertTrue();
      expect(types.has(MushroomType.KING_OYSTER)).assertTrue();
    });
  });
}
