//
//  PaywallPlacement.swift
//  Scaffold
//

import Foundation

/// The places in the app that can ask for a paywall.
///
/// A placement only names *where*; which paywall appears there, for which audience and in
/// which experiment is decided by a campaign on the dashboard and changes without a release.
/// A closed set for the same reason as `AnalyticsEvent.Name`: a raw value that drifts from
/// the dashboard fails silently, as a paywall that is simply never shown.
///
/// Add a case, then add the same raw value to a campaign.
nonisolated enum PaywallPlacement: String, Sendable {
    case premiumFeature = "premium_feature"
}
