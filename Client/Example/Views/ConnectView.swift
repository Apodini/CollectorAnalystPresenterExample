//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

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
        components.host = hostname.lowercased()
        components.path = "/v1/metrics-ui"
        return components.url
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 8) {
                TextField("hostname", text: $hostname)
                    .textFieldStyle(.roundedBorder)
                Text(url?.relativeString ?? "Please enter a hostname")
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .font(.callout)
                    .foregroundColor(Color.gray)
                    .padding(.bottom, 16)
                Button("Connect", action: load)
                    .disabled(url == nil)
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                    .controlSize(.large)
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
