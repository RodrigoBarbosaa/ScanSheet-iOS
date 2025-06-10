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
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(width: 60, height: 60)
                            )
                    }
                    .disabled(!cameraManager.isSessionRunning)
                }
                .padding(.bottom, 30)
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
