//
//  UploadStepView.swift
//  ScanSheet
//
//  Created by Rodrigo Barbosa on 24/07/25.
//

import SwiftUI

struct UploadStepView: View {
    @EnvironmentObject var router: AppRouter
    @State private var image1: UIImage?
    @State private var image2: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingActionSheet = false
    @State private var currentImageSlot = 1 // 1 para image1, 2 para image2
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Estados do modal de carregamento
    @State private var showingLoadingModal = false
    @State private var requestState: RequestState = .loading
    
    let gradientColors = [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)]
    
    var bothImagesLoaded: Bool {
        return image1 != nil && image2 != nil
    }
    
    var body: some View {
        ZStack {
            // Background gradient
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
                        
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 35, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    // Title and subtitle
                    VStack(spacing: 8) {
                        Text("Upload de Imagens")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Adicione duas imagens da ficha para processamento")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 40)
                
                // Upload Cards Section
                VStack(spacing: 20) {
                    // Section label
                    HStack {
                        Text("Selecione as imagens")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // Image upload cards
                    VStack(spacing: 16) {
                        ImageUploadCard(
                            title: "Imagem 1",
                            image: image1,
                            hasImage: image1 != nil,
                            action: {
                                currentImageSlot = 1
                                showingActionSheet = true
                            }
                        )
                        
                        ImageUploadCard(
                            title: "Imagem 2",
                            image: image2,
                            hasImage: image2 != nil,
                            action: {
                                currentImageSlot = 2
                                showingActionSheet = true
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Send Button
                Button(action: {
                    if let img1 = image1, let img2 = image2 {
                        showingLoadingModal = true
                        requestState = .loading
                        
                        createRequestWithCallback(images: [img1, img2]) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success:
                                    requestState = .success
                                case .failure(let error):
                                    requestState = .failure(error)
                                }
                            }
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20, weight: .medium))
                        
                        Text("Enviar")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(bothImagesLoaded ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: bothImagesLoaded ? gradientColors : [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(bothImagesLoaded ? 0.3 : 0.1), radius: bothImagesLoaded ? 15 : 5, x: 0, y: bothImagesLoaded ? 8 : 2)
                    )
                }
                .disabled(!bothImagesLoaded)
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
        .confirmationDialog("Selecionar Imagem", isPresented: $showingActionSheet) {
            Button("Câmera") {
                showingCamera = true
            }
            Button("Galeria") {
                showingImagePicker = true
            }
            Button("Cancelar", role: .cancel) { }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(
                selectedImage: currentImageSlot == 1 ? $image1 : $image2,
                showingAlert: $showingAlert,
                alertMessage: $alertMessage
            )
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(
                capturedImage: currentImageSlot == 1 ? $image1 : $image2
            )
        }
        .alert("Erro", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .overlay(
            // Loading Modal Overlay
            Group {
                if showingLoadingModal {
                    LoadingModalView(
                        isPresented: $showingLoadingModal,
                        requestState: requestState,
                        onSuccess: {
                            router.navigate(to: .exportResults)
                        }
                    )
                }
            }
        )
    }
}

struct ImageUploadCard: View {
    let title: String
    let image: UIImage?
    let hasImage: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Image preview or placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Title and status
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(hasImage ? "Imagem carregada" : "Toque para adicionar")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(hasImage ? 0.9 : 0.6))
                }
                
                Spacer()
                
                // Status indicator
                if hasImage {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        Color.white.opacity(hasImage ? 0.15 : 0.1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                Color.white.opacity(hasImage ? 0.4 : 0.2),
                                lineWidth: hasImage ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    UploadStepView()
}
