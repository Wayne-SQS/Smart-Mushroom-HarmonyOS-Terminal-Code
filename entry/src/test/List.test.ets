import localUnitTest from './LocalUnit.test';
import iotTypesTest from './IotTypes.test';
import recipeTest from './Recipe.test';
import viewModelTest from './ViewModel.test';

export default function testsuite() {
  localUnitTest();
  iotTypesTest();
  recipeTest();
  viewModelTest();
}