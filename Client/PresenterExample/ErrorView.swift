import SwiftUI


struct ErrorView: View {
    // MARK: Stored Properties

    var error: String
    var action: () -> Void

    // MARK: Computed Properties

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
