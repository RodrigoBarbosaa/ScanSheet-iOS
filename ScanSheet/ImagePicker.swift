//
//  ImagePicker.swift
//  ScanSheet
//
//  Created by Rodrigo Barbosa on 07/06/25.
//
//
// Arquivo que controla a lógica para abrir galeria do usuário

import Foundation
import PhotosUI
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            guard let image = info[.originalImage] as? UIImage else {
                parent.alertMessage = "Erro ao carregar a imagem"
                parent.showingAlert = true
                parent.dismiss()
                return
            }
            
            // Validar formato da imagem
            guard let imageData = image.jpegData(compressionQuality: 1.0) ?? image.pngData() else {
                parent.alertMessage = "Formato de imagem não suportado. Use PNG, JPG ou JPEG."
                parent.showingAlert = true
                parent.dismiss()
                return
            }
            
            // Validar tamanho da imagem (5MB = 5 * 1024 * 1024 bytes)
            let maxSizeInBytes = 5 * 1024 * 1024
            if imageData.count > maxSizeInBytes {
                let sizeInMB = Double(imageData.count) / (1024 * 1024)
                parent.alertMessage = String(format: "Imagem muito grande (%.1f MB). O tamanho máximo é 5MB.", sizeInMB)
                parent.showingAlert = true
                parent.dismiss()
                return
            }
            
            // Se passou em todas as validações, salvar a imagem
            parent.selectedImage = image
            
            // converter em byte e printar
            guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                print("Não foi possível converter a imagem para dados binários.")
                return
            }
            // Exibe os dados binários no log.
            print("--- DADOS BINÁRIOS DA IMAGEM (JPEG Qualidade Máxima) ---")
            print(imageData)
            print("--- FIM DOS DADOS BINÁRIOS (Tamanho: \(imageData.count) bytes) ---")
            
            // TODO: Enviar 'imageData' para o backend ou processar conforme necessário.
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Função utilitária para validar formato de imagem
extension UIImage {
    var isValidFormat: Bool {
        return jpegData(compressionQuality: 1.0) != nil || pngData() != nil
    }
}
