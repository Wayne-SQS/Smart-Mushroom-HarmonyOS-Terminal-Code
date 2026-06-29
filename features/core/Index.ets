export { IotService } from './src/main/ets/service/IotService'
export { IotAuthUtil } from './src/main/ets/service/IotAuthUtil'
export { IamAuthUtil } from './src/main/ets/service/IamAuthUtil'
export { IotTokenManager } from './src/main/ets/service/IotTokenManager'
export type {
  DeviceAuthParams,
  DeviceAuthResponse,
  ServiceProperty,
  PropertiesReportRequest,
  ShadowProperties,
  DeviceShadowService,
  DeviceShadowResponse,
  DeviceCommandParams,
  DeviceCommandRequest,
  DeviceCommandResponse,
  IotApiResponse,
  AuthToken,
  DeviceInfo,
  // 应用侧 API 类型
  IamPasswordUser,
  IamIdentity,
  IamScope,
  IamAuthRequest,
  IotAppConfig,
  SmartRoomProperties,
  LightCommandParas,
  SmartRoomCommandRequest,
  AppSideCommandResponse
} from './src/main/ets/service/IotTypes'

export { DashboardPage } from './src/main/ets/pages/DashboardPage'
export { DevicePage } from './src/main/ets/pages/DevicePage'
export { MapPage } from './src/main/ets/pages/MapPage'
export { GrowthPage } from './src/main/ets/pages/GrowthPage'
export { ProfilePage } from './src/main/ets/pages/ProfilePage'
export { AlertPage } from './src/main/ets/pages/AlertPage'
export { RecipePage } from './src/main/ets/pages/RecipePage'
export type { SensorDataItem, AlertItem, DeviceItem, GrowthBatch, ControlItem } from './src/main/ets/model/GreenhouseModel'
export type { Recipe } from './src/main/ets/model/RecipeModel'
export { DEFAULT_RECIPES, GrowthStage, MushroomType } from './src/main/ets/model/RecipeModel'

export { BaseViewModel } from './src/main/ets/viewmodel/BaseViewModel'
export { DashboardViewModel } from './src/main/ets/viewmodel/DashboardViewModel'
export { DeviceViewModel } from './src/main/ets/viewmodel/DeviceViewModel'
export { GrowthViewModel } from './src/main/ets/viewmodel/GrowthViewModel'
export { AlertViewModel } from './src/main/ets/viewmodel/AlertViewModel'

// 主题系统（双主题 + 毛玻璃 + 原子替换）
export type { ThemeTokens } from './src/main/ets/theme/ThemeTokens'
export { FROSTED_THEME } from './src/main/ets/theme/ThemeFrosted'
export { CONTRAST_THEME } from './src/main/ets/theme/ThemeContrast'
export { ThemeManager } from './src/main/ets/theme/ThemeManager'
