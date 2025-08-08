//
//  ExportResults.swift
//  ScanSheet
//
//  Created by Rodrigo Barbosa on 08/08/25.
//

import Foundation
import SwiftUI

struct ExportResultsView: View {
    @EnvironmentObject var router: AppRouter
    @State private var csvFiles: [URL] = []
    @State private var selectedFiles: Set<URL> = []
    @State private var isLoading = true
    @State private var showingDeleteAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isProcessing = false
    
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
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                if isLoading {
                    loadingView
                } else if csvFiles.isEmpty {
                    emptyStateView
                } else {
                    // Files list
                    filesListView
                    
                    // Bottom actions
                    bottomActionsView
                }
            }
        }
        .onAppear {
            loadCSVFiles()
        }
        .alert("Confirmar Exclusão", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Excluir", role: .destructive) {
                deleteSelectedFiles()
            }
        } message: {
            Text("Deseja excluir \(selectedFiles.count) arquivo(s) selecionado(s)? Esta ação não pode ser desfeita.")
        }
        .alert("Erro", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            
            VStack(spacing: 8) {
                Text("Arquivos Salvos")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if !csvFiles.isEmpty {
                    Text("\(csvFiles.count) arquivo(s) encontrado(s)")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Carregando arquivos...")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "doc.text")
                    .font(.system(size: 35, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                Text("Nenhum arquivo encontrado")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Escaneie suas primeiras planilhas para começar a gerenciar seus arquivos CSV")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            Button(action: { router.navigate(to: .fichaSelection) }) {
                HStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text("Escanear Planilha")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    private var filesListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(csvFiles, id: \.self) { fileURL in
                    CSVFileRow(
                        fileURL: fileURL,
                        isSelected: selectedFiles.contains(fileURL),
                        onToggleSelection: {
                            toggleFileSelection(fileURL)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120) // Espaço para os botões fixos
        }
    }
    
    private var bottomActionsView: some View {
        VStack(spacing: 16) {
            if !selectedFiles.isEmpty {
                Text("\(selectedFiles.count) arquivo(s) selecionado(s)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            HStack(spacing: 16) {
                // Botão Deletar
                Button(action: {
                    if !selectedFiles.isEmpty {
                        showingDeleteAlert = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Excluir")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red.opacity(selectedFiles.isEmpty ? 0.3 : 0.7))
                            .shadow(color: .black.opacity(selectedFiles.isEmpty ? 0.1 : 0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .disabled(selectedFiles.isEmpty || isProcessing)
                .buttonStyle(PlainButtonStyle())
                
                // Botão Compartilhar
                Button(action: shareSelectedFiles) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Compartilhar")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: selectedFiles.isEmpty ?
                                    [Color.gray.opacity(0.3), Color.gray.opacity(0.3)] :
                                    [Color.green.opacity(0.7), Color.mint.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(selectedFiles.isEmpty ? 0.1 : 0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .disabled(selectedFiles.isEmpty || isProcessing)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
}

struct CSVFileRow: View {
    let fileURL: URL
    let isSelected: Bool
    let onToggleSelection: () -> Void
    
    @State private var fileInfo: [String: Any]?
    
    var body: some View {
        Button(action: onToggleSelection) {
            HStack(spacing: 16) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue.opacity(0.8) : Color.white.opacity(0.2))
                        .frame(width: 24, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // File icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.7))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "tablecells.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // File info
                VStack(alignment: .leading, spacing: 4) {
                    Text(fileURL.lastPathComponent)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let info = fileInfo {
                        HStack(spacing: 12) {
                            if let size = info["size"] as? Int {
                                Text(CSVHandler.shared.formatFileSize(size))
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            if let creationDate = info["creationDate"] as? Date {
                                Text(formatDate(creationDate))
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.blue.opacity(0.6) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadFileInfo()
        }
    }
    
    private func loadFileInfo() {
        fileInfo = CSVHandler.shared.getFileInfo(at: fileURL)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: date)
    }
}

extension ExportResultsView {
    
    private func loadCSVFiles() {
        print("--- CARREGANDO ARQUIVOS CSV ---")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let files = CSVHandler.shared.getSavedCSVFiles()
            
            DispatchQueue.main.async {
                self.csvFiles = files
                self.isLoading = false
                print("Arquivos carregados: \(files.count)")
            }
        }
    }
    
    private func toggleFileSelection(_ fileURL: URL) {
        if selectedFiles.contains(fileURL) {
            selectedFiles.remove(fileURL)
        } else {
            selectedFiles.insert(fileURL)
        }
    }
    
    private func toggleSelectAll() {
        if selectedFiles.count == csvFiles.count {
            selectedFiles.removeAll()
        } else {
            selectedFiles = Set(csvFiles)
        }
    }
    
    private func deleteSelectedFiles() {
        guard !selectedFiles.isEmpty else { return }
        
        isProcessing = true
        let filesToDelete = Array(selectedFiles)
        
        DispatchQueue.global(qos: .userInitiated).async {
            var deletedCount = 0
            var errors: [String] = []
            
            for fileURL in filesToDelete {
                CSVHandler.shared.deleteCSVFile(at: fileURL) { success in
                    if success {
                        deletedCount += 1
                    } else {
                        errors.append(fileURL.lastPathComponent)
                    }
                    
                    // Quando terminar de processar todos os arquivos
                    if deletedCount + errors.count == filesToDelete.count {
                        DispatchQueue.main.async {
                            self.isProcessing = false
                            
                            if !errors.isEmpty {
                                self.errorMessage = "Erro ao excluir: \(errors.joined(separator: ", "))"
                                self.showingErrorAlert = true
                            }
                            
                            // Recarregar lista e limpar seleção
                            self.selectedFiles.removeAll()
                            self.loadCSVFiles()
                        }
                    }
                }
            }
        }
    }
    
    private func shareSelectedFiles() {
        guard !selectedFiles.isEmpty else {
            errorMessage = "Nenhum arquivo selecionado"
            showingErrorAlert = true
            return
        }
        
        let urlsToShare = Array(selectedFiles)
        print("Compartilhando arquivos: \(urlsToShare.map { $0.lastPathComponent })")
        
        presentActivityViewController(with: urlsToShare)
    }
    
    private func presentActivityViewController(with urls: [URL]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Failed to find root view controller")
            errorMessage = "Não foi possível apresentar a tela de compartilhamento"
            showingErrorAlert = true
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            if let error = error {
                print("Erro no compartilhamento: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Erro ao compartilhar arquivos: \(error.localizedDescription)"
                    self.showingErrorAlert = true
                }
            } else if completed {
                print("Compartilhamento concluído via \(activityType?.rawValue ?? "unknown")")
                DispatchQueue.main.async {
                    // Limpar seleção após compartilhamento bem-sucedido
                    self.selectedFiles.removeAll()
                }
            } else {
                print("Compartilhamento cancelado")
            }
        }
        
        // Para iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        print("Apresentando UIActivityViewController com \(urls.count) item(s)")
        rootViewController.present(activityViewController, animated: true, completion: nil)
    }
}

// MARK: - Preview
#Preview {
    ExportResultsView()
        .environmentObject(AppRouter())
}
