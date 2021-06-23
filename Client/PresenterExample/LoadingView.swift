import Presenter
import SwiftUI


struct LoadingView: SwiftUI.View {
    // MARK: Stored Properties

    var url: URL
    @SwiftUI.Binding var view: AnyView?
    @SwiftUI.Binding var error: String?

    // MARK: Computed Properties

    var body: some SwiftUI.View {
        SwiftUI.NavigationView {
            SwiftUI.Color.clear
                .onAppear(perform: load)
                .navigationTitle("Loading...")
        }
    }

    // MARK: Actions

    private func load() {
        URLSession.shared
            .dataTask(with: url, completionHandler: receive)
            .resume()
    }

    // MARK: Helpers

    private func receive(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            self.error = "\(error)"
        }

        guard let data = data else {
            self.error = "Response contains no data."
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            self.error = "Illegal response type: \(response?.description ?? "nil")"
            return
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            self.error = "Failed: \(httpResponse)"
            return
        }

        do {
            self.view = try Presenter.decode(from: data).eraseToAnyView()
        } catch {
            self.error = "\(error)"
        }
    }

}
