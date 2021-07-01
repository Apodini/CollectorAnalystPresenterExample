import Presenter
import SwiftUI


struct ContentView: SwiftUI.View {
    @ObservedObject var model: Model
    @SwiftUI.State private var url: URL?
    @SwiftUI.State private var error: String?
    @SwiftUI.State private var view: AnyView?
    
    
    var body: some SwiftUI.View {
        if let view = view {
            view.environmentObject(model)
        } else if let error = error {
            ErrorView(error: error) {
                self.view = nil
                self.error = nil
                self.url = nil
            }
        } else if let url = url {
            LoadingView(
                url: url,
                view: $view,
                error: $error
            )
        } else {
            ConnectView { url in
                self.url = url
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some SwiftUI.View {
        ContentView(model: .init())
    }
}
