//
//  CameraView.swift
//  ScanSheet
//
//  Created by Rodrigo Barbosa on 07/06/25.
//
//
// Arquivo que controla o preview de camera

import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var showingPermissionAlert = false
    @Binding var capturedImage: UIImage? // Binding para retornar a imagem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()
            
            if let localCapturedImage = cameraManager.capturedImage {
                // Fundo preto para focar na foto
                Color.black.ignoresSafeArea()
                
                VStack {
                    // Exibe a imagem capturada
                    Image(uiImage: localCapturedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Spacer()
                    
                    // Botões de Ação
                    HStack(spacing: 40) {
                        // Botão Cancelar
                        Button(action: {
                            // Ação para descartar a foto e voltar para a câmera
                            cameraManager.retakePhoto()
                        }) {
                            Text("Cancelar")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding()
                                .frame(minWidth: 120)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                        
                        // Botão Confirmar
                        Button(action: {
                            // Confirmar a foto e retornar para a tela anterior
                            capturedImage = localCapturedImage
                            print("--- IMAGEM CAPTURADA PELA CÂMERA ---")
                            dismiss()
                        }) {
                            Text("Confirmar")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(minWidth: 120)
                                .background(Color.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.bottom, 50)
                }
            } else {
                // Controles da câmera
                VStack {
                    // Botão de fechar no topo
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.top, 50)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Botão de captura
                    HStack {
                        Button(action: {
                            cameraManager.capturePhoto()
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray, lineWidth: 2)
                                        .frame(width: 60, height: 60)
                                )
                        }
                        .disabled(!cameraManager.isSessionRunning)
                    }
                    .padding(.bottom, 50)
                }
            }
            
            if cameraManager.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            cameraManager.checkPermissions()
        }
        .alert("Permissão de Câmera Necessária", isPresented: $showingPermissionAlert) {
            Button("Configurações") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancelar", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Este app precisa de acesso à câmera para tirar fotos. Vá para Configurações e habilite o acesso à câmera.")
        }
        .onChange(of: cameraManager.permissionStatus) { status in
            if status == .denied {
                showingPermissionAlert = true
            }
        }
    }
}
