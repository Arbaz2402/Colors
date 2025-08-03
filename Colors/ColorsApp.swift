//
//  ColorsApp.swift
//  Colors
//
//  Created by Arbaz Kaladiya on 03/08/25.
//

import SwiftUI
import FirebaseCore

@main
struct ColorsApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ColorsView()
        }
    }
}
