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
