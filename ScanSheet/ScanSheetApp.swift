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
            NavigationStack(path: $router.path) {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        // Defina para qual view cada rota deve levar
                        switch route {
                        case .fichaSelection:
                            FichaSelectionView()
                        case .uploadStep:
                            UploadStepView()
                        }
                        
                    }
            }
            .environmentObject(router) 
        }
    }
}
