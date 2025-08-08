//
//  CSVHandler.swift
//  ScanSheet
//
//  Created by Rodrigo Barbosa on 03/08/25.
//

import Foundation
import UIKit

class CSVHandler {
    
    static let shared = CSVHandler()
    
    private init() {}
    
    struct APIResponse: Codable {
        let table: String
    }
    
    /// Processa uma string JSON descriptografada e salva como CSV
    func processAndSaveCSV(from jsonString: String, completion: @escaping (Result<URL, Error>) -> Void) {
        print("--- INICIANDO PROCESSAMENTO DA STRING JSON PARA CSV ---")
        print("JSON recebido (primeiros 200 chars): \(String(jsonString.prefix(200)))")
        
        do {
            // Converter string JSON para Data
            guard let jsonData = jsonString.data(using: .utf8) else {
                throw NSError(domain: "CSVHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Não foi possível converter string para Data"])
            }
            
            // Primeiro tentar como array de objetos diretamente
            if let fichasArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                print("✅ Array de objetos encontrado diretamente: \(fichasArray.count) fichas")
                
                let csvContent = convertDictionaryArrayToCSV(fichasArray)
                saveCSVFile(content: csvContent) { result in
                    completion(result)
                }
            }
            // Se não for array, tentar como objeto único
            else if let fichaUnica = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                print("✅ Objeto único encontrado, convertendo para array")
                let fichasArray = [fichaUnica]
                
                let csvContent = convertDictionaryArrayToCSV(fichasArray)
                saveCSVFile(content: csvContent) { result in
                    completion(result)
                }
            }
            // Caso especial: pode ser uma string que contém JSON (double-encoded)
            else if let jsonAsString = try JSONSerialization.jsonObject(with: jsonData) as? String {
                print("🔄 JSON double-encoded detectado, fazendo segunda decodificação...")
                
                // Recursivamente chamar o método com a string decodificada
                processAndSaveCSV(from: jsonAsString, completion: completion)
            }
            // Tentar como array de strings que contêm JSON
            else if let stringArray = try JSONSerialization.jsonObject(with: jsonData) as? [String] {
                print("🔄 Array de strings JSON detectado, processando \(stringArray.count) items...")
                
                var fichasArray: [[String: Any]] = []
                
                for jsonStringItem in stringArray {
                    guard let itemData = jsonStringItem.data(using: .utf8) else {
                        print("⚠️ Erro ao converter string item para Data")
                        continue
                    }
                    
                    if let fichaObject = try JSONSerialization.jsonObject(with: itemData) as? [String: Any] {
                        fichasArray.append(fichaObject)
                    } else {
                        print("⚠️ Item não é um objeto JSON válido")
                    }
                }
                
                if !fichasArray.isEmpty {
                    print("✅ \(fichasArray.count) fichas processadas do array de strings")
                    let csvContent = convertDictionaryArrayToCSV(fichasArray)
                    saveCSVFile(content: csvContent) { result in
                        completion(result)
                    }
                } else {
                    throw NSError(domain: "CSVHandler", code: 3, userInfo: [NSLocalizedDescriptionKey: "Nenhuma ficha válida encontrada no array de strings"])
                }
            }
            else {
                // Debug: vamos ver que tipo de dados temos
                let parsedObject = try JSONSerialization.jsonObject(with: jsonData)
                print("❌ Tipo de dados não reconhecido: \(type(of: parsedObject))")
                print("❌ Conteúdo: \(parsedObject)")
                
                throw NSError(domain: "CSVHandler", code: 2, userInfo: [NSLocalizedDescriptionKey: "Formato de dados JSON inválido - tipo: \(type(of: parsedObject))"])
            }
            
        } catch {
            print("Erro ao processar JSON: \(error)")
            completion(.failure(error))
        }
    }
    
    /// Processa a resposta JSON original (mantida para compatibilidade)
    func processAndSaveCSV(from jsonResponse: Data, completion: @escaping (Result<URL, Error>) -> Void) {
        print("--- INICIANDO PROCESSAMENTO DO JSON DATA PARA CSV ---")
        
        do {
            // Parse do JSON da API
            let apiResponse = try JSONDecoder().decode(APIResponse.self, from: jsonResponse)
            
            // Parse da string table que contém os dados das fichas
            let tableData = apiResponse.table.data(using: .utf8)!
            
            // Decodificar como array de dicionários genéricos (mais flexível)
            if let fichasArray = try JSONSerialization.jsonObject(with: tableData) as? [[String: Any]] {
                print("Número de fichas encontradas: \(fichasArray.count)")
                
                // Converter para CSV
                let csvContent = convertDictionaryArrayToCSV(fichasArray)
                
                // Salvar arquivo
                saveCSVFile(content: csvContent) { result in
                    completion(result)
                }
            } else {
                throw NSError(domain: "CSVHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Formato de dados inválido"])
            }
            
        } catch {
            print("Erro ao processar JSON: \(error)")
            completion(.failure(error))
        }
    }
    
    /// Converte array de dicionários para formato CSV
    private func convertDictionaryArrayToCSV(_ dataArray: [[String: Any]]) -> String {
        print("--- CONVERTENDO DADOS PARA CSV ---")
        
        guard !dataArray.isEmpty else {
            print("Array de dados está vazio")
            return ""
        }
        
        var csvLines: [String] = []
        
        // Extrair todos os headers únicos de todas as fichas
        var allKeys: Set<String> = []
        
        for dict in dataArray {
            // Adicionar chaves do nível superior
            allKeys.formUnion(Set(dict.keys))
            
            // Se existe um campo "content", adicionar suas chaves também
            if let content = dict["content"] as? [String: Any] {
                // Prefixar com "content_" para evitar conflitos
                let contentKeys = content.keys.map { "content_\($0)" }
                allKeys.formUnion(Set(contentKeys))
            }
        }
        
        // Converter para array ordenado
        let sortedKeys = Array(allKeys).sorted()
        
        print("Campos encontrados: \(sortedKeys)")
        
        // Cabeçalho do CSV
        csvLines.append(sortedKeys.joined(separator: ","))
        
        // Processar cada ficha
        for (index, dict) in dataArray.enumerated() {
            var row: [String] = []
            
            for key in sortedKeys {
                var value = ""
                
                if key.hasPrefix("content_") {
                    // Campo do content
                    let contentKey = String(key.dropFirst(8)) // Remove "content_"
                    if let content = dict["content"] as? [String: Any],
                       let contentValue = content[contentKey] {
                        value = formatValue(contentValue)
                    }
                } else {
                    // Campo do nível superior
                    if let directValue = dict[key] {
                        value = formatValue(directValue)
                    }
                }
                
                row.append(escapeCSVField(value))
            }
            
            csvLines.append(row.joined(separator: ","))
            
            if (index + 1) % 10 == 0 {
                print("Processadas \(index + 1) fichas...")
            }
        }
        
        let csvContent = csvLines.joined(separator: "\n")
        print("CSV criado com \(csvLines.count) linhas e \(sortedKeys.count) colunas")
        print("Primeiros 300 caracteres do CSV:")
        print(String(csvContent.prefix(300)))
        
        return csvContent
    }
    
    /// Formata valores para CSV (converte arrays, bools, etc)
    private func formatValue(_ value: Any) -> String {
        switch value {
        case let stringValue as String:
            return stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        case let boolValue as Bool:
            return boolValue ? "true" : "false"
        case let numberValue as NSNumber:
            return numberValue.stringValue
        case let arrayValue as [Any]:
            return arrayValue.map { formatValue($0) }.joined(separator: "; ")
        case let dictValue as [String: Any]:
            // Para objetos aninhados, converter para string JSON ou formato chave:valor
            let pairs = dictValue.map { "\($0.key):\(formatValue($0.value))" }
            return pairs.joined(separator: "; ")
        case is NSNull:
            return ""
        default:
            return "\(value)"
        }
    }
    
    /// Escapa campos do CSV (adiciona aspas se necessário)
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedField)\""
        }
        
        return field
    }
    
    /// Salva o conteúdo CSV em arquivo local
    private func saveCSVFile(content: String, completion: @escaping (Result<URL, Error>) -> Void) {
        print("--- SALVANDO ARQUIVO CSV ---")
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Obter diretório Documents
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory,
                                                                 in: .userDomainMask).first!
                
                // Criar nome do arquivo com timestamp
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
                let timestamp = dateFormatter.string(from: Date())
                let fileName = "ficha_cadastro_\(timestamp).csv"
                
                // URL completa do arquivo
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                
                // Salvar arquivo com encoding UTF-8 com BOM para melhor compatibilidade
                let bomString = "\u{FEFF}" + content
                try bomString.write(to: fileURL, atomically: true, encoding: .utf8)
                
                print("Arquivo CSV salvo com sucesso:")
                print("- Nome: \(fileName)")
                print("- Caminho: \(fileURL.path)")
                print("- Tamanho: \(content.count) caracteres")
                
                DispatchQueue.main.async {
                    completion(.success(fileURL))
                }
                
            } catch {
                print("Erro ao salvar arquivo CSV: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Funções utilitárias
    
    /// Retorna todos os arquivos CSV salvos
    func getSavedCSVFiles() -> [URL] {
        print("--- BUSCANDO ARQUIVOS CSV SALVOS ---")
        
        do {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory,
                                                             in: .userDomainMask).first!
            
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory,
                                                                      includingPropertiesForKeys: [.creationDateKey])
            
            let csvFiles = fileURLs.filter { $0.pathExtension.lowercased() == "csv" }
            
            // Ordenar por data de criação (mais recente primeiro)
            let sortedFiles = csvFiles.sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }
            
            print("Encontrados \(sortedFiles.count) arquivos CSV")
            
            return sortedFiles
            
        } catch {
            print("Erro ao buscar arquivos CSV: \(error)")
            return []
        }
    }
    
    /// Remove um arquivo CSV específico
    func deleteCSVFile(at url: URL, completion: @escaping (Bool) -> Void) {
        print("--- REMOVENDO ARQUIVO CSV ---")
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try FileManager.default.removeItem(at: url)
                print("Arquivo removido com sucesso: \(url.lastPathComponent)")
                
                DispatchQueue.main.async {
                    completion(true)
                }
                
            } catch {
                print("Erro ao remover arquivo: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    /// Verifica se um arquivo existe
    func fileExists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    /// Obtém informações do arquivo (tamanho, data de criação, etc.)
    func getFileInfo(at url: URL) -> [String: Any]? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey])
            
            var info: [String: Any] = [:]
            info["size"] = resourceValues.fileSize ?? 0
            info["creationDate"] = resourceValues.creationDate ?? Date()
            info["modificationDate"] = resourceValues.contentModificationDate ?? Date()
            info["name"] = url.lastPathComponent
            info["path"] = url.path
            
            return info
            
        } catch {
            print("Erro ao obter informações do arquivo: \(error)")
            return nil
        }
    }
    
    /// Formata tamanho do arquivo para exibição
    func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// Compartilhar arquivo CSV via UIActivityViewController
    func shareCSVFile(_ fileURL: URL, from viewController: UIViewController) {
        print("--- COMPARTILHANDO ARQUIVO CSV ---")
        
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        // Para iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityViewController, animated: true) {
            print("Activity view controller apresentado")
        }
    }
}
