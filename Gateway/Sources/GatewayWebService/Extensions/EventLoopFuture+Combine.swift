//
// This source file is part of the Collector-Analyst-Presenter Example open source project
//
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import NIO


// swiftlint:disable function_parameter_count identifier_name large_tuple
extension EventLoopFuture {
    static func combine<A, B>(
        _ a: EventLoopFuture<A>,
        _ b: EventLoopFuture<B>
    ) -> EventLoopFuture<(A, B)> where Value == (A, B) {
        a.flatMap { aValue in b.map { (aValue, $0) } }
    }

    static func combine<A, B, C>(
        _ a: EventLoopFuture<A>,
        _ b: EventLoopFuture<B>,
        _ c: EventLoopFuture<C>
    ) -> EventLoopFuture<(A, B, C)> where Value == (A, B, C) {
        EventLoopFuture<(A, B)>.combine(a, b)
        .flatMap { aValue, bValue in c.map { (aValue, bValue, $0) } }
    }

    static func combine<A, B, C, D>(
        _ a: EventLoopFuture<A>,
        _ b: EventLoopFuture<B>,
        _ c: EventLoopFuture<C>,
        _ d: EventLoopFuture<D>
    ) -> EventLoopFuture<(A, B, C, D)> where Value == (A, B, C, D) {
        EventLoopFuture<((A, B), (C, D))>
        .combine(.combine(a, b), .combine(c, d))
        .map { abValues, cdValues in (abValues.0, abValues.1, cdValues.0, cdValues.1) }
    }

    static func combine<A, B, C, D, E>(
        _ a: EventLoopFuture<A>,
        _ b: EventLoopFuture<B>,
        _ c: EventLoopFuture<C>,
        _ d: EventLoopFuture<D>,
        _ e: EventLoopFuture<E>
    ) -> EventLoopFuture where Value == (A, B, C, D, E) {
        EventLoopFuture<((A, B), (C, D, E))>
        .combine(.combine(a, b), .combine(c, d, e))
        .map { abValues, cdeValues in (abValues.0, abValues.1, cdeValues.0, cdeValues.1, cdeValues.2) }
    }

    static func combine<A, B, C, D, E, F>(
        _ a: EventLoopFuture<A>,
        _ b: EventLoopFuture<B>,
        _ c: EventLoopFuture<C>,
        _ d: EventLoopFuture<D>,
        _ e: EventLoopFuture<E>,
        _ f: EventLoopFuture<F>
    ) -> EventLoopFuture where Value == (A, B, C, D, E, F) {
        EventLoopFuture<((A, B, C), (D, E, F))>
        .combine(.combine(a, b, c), .combine(d, e, f))
        .map { first, second in (first.0, first.1, first.2, second.0, second.1, second.2) }
    }
}
