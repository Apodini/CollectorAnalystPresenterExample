import Presenter
import SwiftUI


struct ContentView: SwiftUI.View {
    @ObservedObject var model: Model
    @SwiftUI.State private var url: URL?
    @SwiftUI.State private var error: String?
    @SwiftUI.State private var view: AnyView?
    
    
    var body: some SwiftUI.View {
        NavigationView {
            if let view = view {
                view.environmentObject(model)
                    .navigationBarItems(trailing: reloadButton)
            } else if let error = error {
                ErrorView(error: error) {
                    self.view = nil
                    self.error = nil
                    self.url = nil
                }.navigationBarItems(trailing: reloadButton)
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
    
    var reloadButton: some SwiftUI.View {
        Button(action: {
           self.view = nil
           self.error = nil
        }, label: {
            Image(systemName: "arrow.clockwise")
        })
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some SwiftUI.View {
        ContentView(model: .init())
    }
}
