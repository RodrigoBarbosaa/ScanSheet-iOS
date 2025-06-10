//
//  ScanSheetApp.swift
//  ScanSheet
//
//  Created by Rodrigo Barbosa on 07/06/25.
//

import SwiftUI

@main
struct ScanSheetApp: App {
    @StateObject private var router = AppRouter()
    var body: some Scene {
        WindowGroup {
            NavigationView {
                NavigationManager {
                    HomeView()
                }
                .environmentObject(router)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
