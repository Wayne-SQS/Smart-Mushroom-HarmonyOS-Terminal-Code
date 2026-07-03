import localUnitTest from './LocalUnit.test';
import iotTypesTest from './IotTypes.test';
import recipeTest from './Recipe.test';
import viewModelTest from './ViewModel.test';
import deviceViewModelTest from './DeviceViewModel.test';
import growthViewModelTest from './GrowthViewModel.test';
import chartUtilsTest from './ChartUtils.test';
import iotTokenManagerTest from './IotTokenManager.test';
import themeManagerTest from './ThemeManager.test';
import baseViewModelTest from './BaseViewModel.test';

export default function testsuite() {
  localUnitTest();
  iotTypesTest();
  recipeTest();
  viewModelTest();
  deviceViewModelTest();
  growthViewModelTest();
  chartUtilsTest();
  iotTokenManagerTest();
  themeManagerTest();
  baseViewModelTest();
}
