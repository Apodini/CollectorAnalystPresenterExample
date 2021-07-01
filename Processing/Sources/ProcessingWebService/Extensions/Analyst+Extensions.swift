import Analyst


extension Trace {
    var rootSpan: Span? {
        spans.first { $0.references.isEmpty }
    }

    var id: UUID {
        rootSpan!.context.traceID
    }

    var name: String {
        rootSpan!.name
    }

    var duration: TimeInterval {
        rootSpan!.duration
    }
}


extension Span {
    var id: UUID {
        context.spanID
    }

    var traceID: UUID {
        context.traceID
    }

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}
