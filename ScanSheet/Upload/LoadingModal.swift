//
//  LoadingModalView.swift
//  ScanSheet
//
//  Created by Rodrigo Barbosa on 08/08/25.
//

import SwiftUI

enum RequestState: Equatable {
    case loading
    case success
    case failure(String)
    
    static func == (lhs: RequestState, rhs: RequestState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.success, .success):
            return true
        case (.failure(let lhsMessage), .failure(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

struct LoadingModalView: View {
    @Binding var isPresented: Bool
    let requestState: RequestState
    @State private var progress: Double = 0.0
    @State private var animationTimer: Timer?
    let onSuccess: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent dismissing while loading
                    if case .loading = requestState {
                        return
                    }
                }
            
            // Modal content
            VStack(spacing: 24) {
                // Header with icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    Group {
                        switch requestState {
                        case .loading:
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 35, weight: .medium))
                                .foregroundColor(.white)
                        case .success:
                            Image(systemName: "checkmark")
                                .font(.system(size: 35, weight: .bold))
                                .foregroundColor(.white)
                        case .failure:
                            Image(systemName: "xmark")
                                .font(.system(size: 35, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Title and message
                VStack(spacing: 12) {
                    Text(titleText)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(messageText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                
                // Progress or status content
                VStack(spacing: 16) {
                    switch requestState {
                    case .loading:
                        // Animated progress bar
                        VStack(spacing: 12) {
                            ProgressView(value: progress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .scaleEffect(1.1)
                            
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                    case .success:
                        // Success animation
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 20))
                            
                            Text("Processamento concluído!")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.green)
                        }
                        
                    case .failure(let error):
                        // Error state
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))
                                
                                Text("Erro no processamento")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.red)
                            }
                            
                            Text(error)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
                
                // Action buttons
                if case .success = requestState {
                    Button(action: {
                        isPresented = false
                        onSuccess()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .medium))
                            Text("Continuar")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                } else if case .failure = requestState {
                    Button(action: {
                        isPresented = false
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Tentar Novamente")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.red.opacity(0.8), Color.orange.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
        .onAppear {
            if case .loading = requestState {
                startProgressAnimation()
            }
        }
        .onChange(of: requestState) { newState in
            withAnimation(.easeInOut(duration: 0.3)) {
                if case .success = newState {
                    progress = 1.0
                    stopProgressAnimation()
                } else if case .failure = newState {
                    stopProgressAnimation()
                }
            }
        }
        .onDisappear {
            stopProgressAnimation()
        }
    }
    
    private var titleText: String {
        switch requestState {
        case .loading:
            return "Processando Imagens"
        case .success:
            return "Sucesso!"
        case .failure:
            return "Ops! Algo deu errado"
        }
    }
    
    private var messageText: String {
        switch requestState {
        case .loading:
            return "Estamos analisando suas imagens e extraindo os dados. Isso pode levar alguns momentos..."
        case .success:
            return "Suas imagens foram processadas com sucesso. Os dados estão prontos para exportação."
        case .failure:
            return "Não foi possível processar suas imagens. Verifique sua conexão e tente novamente."
        }
    }
    
    private func startProgressAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                if progress < 0.9 {
                    progress += Double.random(in: 0.01...0.03)
                } else if progress < 0.95 {
                    progress += 0.001
                }
            }
        }
    }
    
    private func stopProgressAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// Preview
#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        LoadingModalView(
            isPresented: .constant(true),
            requestState: .loading,
            onSuccess: {}
        )
    }
}
