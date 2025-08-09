//
//  FichaSelectionView.swift
//  ScanSheet
//
//  Created by Rodrigo Barbosa on 16/07/25.
//

import SwiftUI

struct FichaSelectionView: View {
    @EnvironmentObject var router: AppRouter
    @State private var selectedFicha: String = "Cadastro individual SUS"
    
    let fichaOptions = ["Cadastro individual SUS", "Geral"]
    let gradientColors = [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)]
    
    var body: some View {
        ZStack {
            
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.25, blue: 0.45),
                    Color(red: 0.25, green: 0.35, blue: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Grid pattern overlay
            GridPatternView()
                .opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header section
                VStack(spacing: 20) {
                    // App icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 35, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    // Title and subtitle
                    VStack(spacing: 8) {
                        Text("Digitalização")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        // Description
                        Text("Selecione o tipo de ficha que você deseja digitalizar para otimizar o processo de reconhecimento")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 40)
                
                // Picker Card
                VStack(spacing: 20) {
                    // Picker label
                    HStack {
                        Text("Escolha a ficha para digitalização")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // Picker container
                    VStack(spacing: 16) {
                        ForEach(fichaOptions, id: \.self) { option in
                            PickerOptionCard(
                                title: option,
                                isSelected: selectedFicha == option,
                                action: { selectedFicha = option }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    print("Ficha selecionada: \(selectedFicha)")
                    router.navigate(to: .uploadStep)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                        
                        Text("Continuar")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
    }
}

struct PickerOptionCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Title
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        Color.white.opacity(isSelected ? 0.2 : 0.1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                Color.white.opacity(isSelected ? 0.4 : 0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FichaSelectionView()
}


