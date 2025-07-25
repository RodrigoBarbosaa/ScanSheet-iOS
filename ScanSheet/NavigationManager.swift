//
//  NavigationManager.swift
//  ScanSheet
//
//  Created by Rodrigo Barbosa on 07/06/25.
//

import Foundation
import SwiftUI

import SwiftUI

// Defina as rotas possíveis da sua aplicação
enum AppRoute: Hashable {
    case fichaSelection
    case uploadStep
}

class AppRouter: ObservableObject {
    @Published var path = [AppRoute]()

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func goBack() {
        _ = path.popLast()
    }

    func goBackToRoot() {
        path.removeAll()
    }
}
