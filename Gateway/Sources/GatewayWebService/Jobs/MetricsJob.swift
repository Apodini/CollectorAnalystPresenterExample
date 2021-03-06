//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniJobs
import Collector
import Foundation

enum KeyStore: EnvironmentAccessible {
    var metricsJob: MetricsJob {
        fatalError("Only usable as a KeyPath")
    }
}

struct MetricsJob: Job {
    func run() {
        let startDate = Date()

        Metric.counter(label: "gateway_periodic_task")
            .increment()

        let process = ProcessInfo.processInfo

        Metric.gauge(label: "gateway_active_processor_count")
            .record(process.activeProcessorCount)

        Metric.gauge(label: "gateway_physical_memory")
            .record(process.physicalMemory)

        Metric.recorder(label: "gateway_processor_count")
            .record(process.processorCount)

        Metric.timer(label: "gateway_periodic_task_duration")
            .record(-startDate.timeIntervalSinceNow)
    }
}
