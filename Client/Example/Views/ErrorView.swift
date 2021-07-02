import SwiftUI


struct ErrorView: View {
    var error: String
    var action: () -> Void
    var reload: () -> Void
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Text(error)
                Button("Enter different hostname", action: action)
                    .buttonStyle(.bordered)
                    .tint(.primary)
                    .controlSize(.large)
                    .controlProminence(.increased)
            }
                .padding(32)
                .navigationTitle("Error")
                .navigationBarItems(trailing: Button(action: reload, label: { Image(systemName: "arrow.clockwise") }))
        }
    }
}
