//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Analyst


extension Trace {
    var rootSpan: Span? {
        spans.first { $0.references.isEmpty }
    }
}


extension Span {
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}
