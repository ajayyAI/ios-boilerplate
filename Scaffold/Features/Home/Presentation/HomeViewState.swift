//
//  HomeViewState.swift
//  Scaffold
//

import Foundation

/// What the Home screen is currently showing.
///
/// `Equatable` is load-bearing: the `@Observable` macro's generated setter skips
/// invalidating observing views when the new value equals the current one, but only
/// when it can compare them. Without the conformance every assignment re-renders.
enum HomeViewState: Equatable {
    case empty
    case loading
    case data(userEmailTitle: String?)
    case failed(PresentableError)
}
