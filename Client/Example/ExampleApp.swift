import AnalystPresenter
import SwiftUI


@main
struct ExampleApp: App {
    @StateObject var model = Model()
    
    
    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }
    
    
    init() {
        Presenter.use(plugin: AnalystPresenter())
    }
}
