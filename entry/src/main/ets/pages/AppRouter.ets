/**
 * 全局路由栈管理
 *
 * 由于 @Component V1 页面不能直接接收 NavPathStack 参数，
 * 使用单例模式在全局共享 NavPathStack，供任何页面调用路由跳转。
 */
export class AppRouter {
  private static instance: NavPathStack;

  static getStack(): NavPathStack {
    if (!AppRouter.instance) {
      AppRouter.instance = new NavPathStack();
    }
    return AppRouter.instance;
  }

  static push(name: string): void {
    AppRouter.getStack().pushPath({ name: name });
  }

  static pop(): void {
    AppRouter.getStack().pop();
  }

  static pushWithParam(name: string, param: Object): void {
    AppRouter.getStack().pushPath({ name: name, param: param });
  }
}
