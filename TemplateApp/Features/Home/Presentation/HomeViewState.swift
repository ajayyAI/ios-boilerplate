//
//  HomeViewState.swift
//  TemplateApp
//
//

import Foundation

enum HomeViewState {
    case data(userEmailTitle: String?)
    case loading
    case error(Error)
    case empty
}
