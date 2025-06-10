//
//  NavigationManager.swift
//  ScanSheet
//
//  Created by Rodrigo Barbosa on 07/06/25.
//

import Foundation
import SwiftUI

enum AppRoute: Hashable {
    case home
    case camera
}

struct NavigationState {
    var activeRoute: AppRoute? = nil
}

class AppRouter: ObservableObject {
    @Published var navigationState = NavigationState()
    
    func navigate(to route: AppRoute) {
        navigationState.activeRoute = route
    }
    
    func goBack() {
        navigationState.activeRoute = nil
    }
}
// entender o que isso faz
struct NavigationManager: View {
    @EnvironmentObject var router: AppRouter
    let content: AnyView
    
    init<Content: View>(@ViewBuilder content: @escaping () -> Content) {
        self.content = AnyView(content())
    }
    
    var body: some View {
        content
            .background(navigationLinks)
    }
    
    @ViewBuilder
    private var navigationLinks: some View {
        Group {
            NavigationLink(
                destination: CameraView()
                    .onDisappear { router.goBack() },
                
                isActive: .constant(router.navigationState.activeRoute == .camera)
            ) { EmptyView() }
        }
    }
}
