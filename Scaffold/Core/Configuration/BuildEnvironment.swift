//
//  BuildEnvironment.swift
//  Scaffold
//

import Foundation

/// Which kind of build is running: a developer's or a customer's.
///
/// Vendors segment by this. A crash from a debug build and a crash from the App Store
/// build are different problems, and every SDK receives ``name`` as its environment so
/// the two never share a bucket.
///
/// TestFlight is deliberately not a third case. The only synchronous tell, the receipt
/// file name, is deprecated since iOS 18; the replacement, `AppTransaction.shared`, is
/// async and cannot answer before the SDKs start. Segment testers on the vendor side
/// by build number instead, which CI already stamps on every archive.
nonisolated enum BuildEnvironment: String, Sendable {
    case development
    case production

    /// The vendor-facing environment string.
    var name: String {
        rawValue
    }

    static let current: BuildEnvironment = {
        #if DEBUG
            .development
        #else
            .production
        #endif
    }()
}
