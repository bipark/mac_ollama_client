//
//  Localized.swift
//  macollama
//
//  Created by BillyPark on 2/3/25.
//
import SwiftUI


extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
