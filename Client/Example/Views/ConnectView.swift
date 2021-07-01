import SwiftUI


struct ConnectView: View {
    var action: (URL) -> Void
    @State private var url = ""
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                TextField("URL", text: $url)
                Button("Connect", action: load)
            }
            .padding(32)
            .navigationTitle("Select Server")
        }
    }
    
    
    private func load() {
        if let url = URL(string: self.url) {
            action(url)
        }
    }
}
