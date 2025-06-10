//
//  CameraManager.swift
//  ScanSheet
//
//  Created by Rodrigo Barbosa on 07/06/25.
//

import Foundation
import AVFoundation
import SwiftUI

/*
 Arquivo responsável pelas configurações e preview de camera
 */

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isSessionRunning = false
    @Published var isLoading = false
    @Published var permissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var capturedImage: UIImage?
    
    private var photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    override init() {
        super.init()
        setupSession()
    }
    
    func checkPermissions() {
        permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch permissionStatus {
        case .authorized:
            startSession()
        case .notDetermined:
            requestPermission()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
    
    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionStatus = granted ? .authorized : .denied
                if granted {
                    self?.startSession()
                }
            }
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        
        // Configure session preset
        session.sessionPreset = .photo
        print("Configurando sessão da câmera...")
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Erro: Não foi possível acessar a câmera traseira")
            session.commitConfiguration()
            return
        }
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("Erro: Não foi possível criar input da câmera")
            session.commitConfiguration()
            return
        }
        
        guard session.canAddInput(videoDeviceInput) else {
            print("Erro: Não foi possível adicionar input à sessão")
            session.commitConfiguration()
            return
        }
        
        session.addInput(videoDeviceInput)
        self.videoDeviceInput = videoDeviceInput
        print("Input da câmera adicionado com sucesso")
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            print("Output de foto adicionado com sucesso")
        } else {
            print("Erro: Não foi possível adicionar output de foto")
        }
        
        session.commitConfiguration()
        print("Configuração da sessão concluída")
    }
    
    func startSession() {
        guard !session.isRunning else { return }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
                print("Sessão da câmera iniciada: \(self.session.isRunning)")
            }
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session.stopRunning()
            
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }
    
    func capturePhoto() {
        // iOS 15:
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = false
        isLoading = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // Método para salvar a imagem temporariamente
    func saveImageTemporarily(_ image: UIImage) -> URL? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "captured_photo_\(Date().timeIntervalSince1970).jpg"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileURL
        } catch {
            print("Erro ao salvar imagem temporariamente: \(error)")
            return nil
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
        }
        
        if let error = error {
            print("Erro ao capturar foto: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Não foi possível processar a imagem")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = image
            
            // Salvar a imagem temporariamente
            if let tempURL = self?.saveImageTemporarily(image) {
                print("Imagem salva temporariamente em: \(tempURL)")
                
                // TODO: Processar imagem e enviar para backend
                NotificationCenter.default.post(
                    name: NSNotification.Name("PhotoCaptured"),
                    object: nil,
                    userInfo: ["imageURL": tempURL, "image": image]
                )
            }
        }
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.session = session
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        uiView.session = session
    }
}

// MARK: - Camera Preview View
class CameraPreviewView: UIView {
    var session: AVCaptureSession? {
        didSet {
            guard let session = session else { return }
            previewLayer.session = session
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
        previewLayer.videoGravity = .resizeAspectFill
    }
}
