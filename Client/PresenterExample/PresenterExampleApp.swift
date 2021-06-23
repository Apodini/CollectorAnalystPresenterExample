import AnalystPresenter
import SwiftUI


@main
struct PresenterExampleApp: App {
    @StateObject var model = Model()

    init() {
        Presenter.use(plugin: AnalystPresenter())
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }
}
