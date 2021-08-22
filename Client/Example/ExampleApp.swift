//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import AnalystPresenter
import SwiftUI


@main
struct ExampleApp: App {
    @StateObject var model = Model()
    
    
    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }
    
    
    init() {
        Presenter.use(plugin: AnalystPresenter())
    }
}
