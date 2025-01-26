import App
import AppBase
import SplashScreen
import DebugMenuScreen
internal import DefaultDebugMenuScreen
internal import DefaultSplashScreen

@MainActor final class DefaultSharedAppSession: SharedAppSession {
    var splash: any ScreenProvider<Void, SplashView, ModalTransition>
    var debug: any ScreenProvider<DebugMenuEvent, DebugMenuView, Void>
    
    init() {
        self.splash = DefaultSplashFactory().create()
        self.debug = DefaultDebugMenuFactory().create()
    }
}
