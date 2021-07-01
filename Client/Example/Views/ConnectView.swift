import SwiftUI


struct ConnectView: View {
    var action: (URL) -> Void
    @State private var hostname = ""
    
    var url: URL? {
        if hostname.isEmpty {
            return nil
        }
        
        var components = URLComponents()
        components.scheme = "http"
        components.host = hostname
        components.path = "/v1/metrics-ui"
        return components.url
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 8) {
                TextField("hostname", text: $hostname)
                    .textFieldStyle(.roundedBorder)
                Text(url?.relativeString ?? "")
                    .keyboardType(.URL)
                    .font(.callout)
                    .foregroundColor(Color.gray)
                    .padding(.bottom, 16)
                Button("Connect", action: load)
                    .disabled(url == nil)
                    .buttonStyle(.bordered)
                    .tint(.primary)
                    .controlSize(.large)
                    .controlProminence(.increased)
            }
                .padding(32)
                .frame(maxWidth: .infinity)
                .navigationTitle("Enter Hostname")
        }
    }
    
    
    private func load() {
        if let url = self.url {
            action(url)
        }
    }
}
