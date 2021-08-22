//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Presenter
import SwiftUI


struct LoadingView: SwiftUI.View {
    var url: URL
    @SwiftUI.Binding var view: AnyView?
    @SwiftUI.Binding var error: String?
    
    
    var body: some SwiftUI.View {
        NavigationView {
            ProgressView()
                .onAppear(perform: load)
                .navigationTitle("Loading...")
        }
    }
    
    
    private func load() {
        URLSession.shared
            .dataTask(with: url, completionHandler: receive)
            .resume()
    }
    
    
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
