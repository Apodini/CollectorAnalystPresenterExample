//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

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
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                    .controlSize(.large)
            }
                .padding(32)
                .navigationTitle("Error")
                .navigationBarItems(trailing: Button(action: reload, label: { Image(systemName: "arrow.clockwise") }))
        }
    }
}
