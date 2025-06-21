import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var showingImagePicker = false
    @State private var showingPermissionAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()
            
            if let capturedImage = cameraManager.capturedImage {
                // Fundo preto para focar na foto
                Color.black.ignoresSafeArea()
                
                VStack {
                    // Exibe a imagem capturada
                    Image(uiImage: capturedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Spacer()
                    
                    // Botões de Ação
                    HStack(spacing: 40) {
                        // Botão Cancelar
                        Button(action: {
                            // Ação para descartar a foto, apagar o arquivo e voltar para a câmera
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
                            // Ação para confirmar a foto. O salvamento e a notificação já ocorreram.
                            cameraManager.confirmPhoto()
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
                // vai em cima da camera
                VStack {
                    Spacer()
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
                    .padding(.bottom, 30)
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
