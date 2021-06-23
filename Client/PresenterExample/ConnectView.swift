import SwiftUI


struct ConnectView: View {
    // MARK: Stored Properties

    var action: (URL) -> Void

    @State private var url = ""

    // MARK: Computed Properties

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

    // MARK: Actions

    private func load() {
        if let url = URL(string: self.url) {
            action(url)
        }
    }
}
