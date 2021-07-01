import SwiftUI


struct ErrorView: View {
    var error: String
    var action: () -> Void
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Text(error)
                Button("Try again", action: action)
            }
            .padding(32)
            .navigationTitle("Error")
        }
    }
}
