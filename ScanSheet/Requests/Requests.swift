//
//  Requests.swift
//  ScanSheet
//
//  Created by Rodrigo Barbosa on 19/07/25.
//

import Foundation
import PhotosUI
import CryptoKit

func createRequest(images: [UIImage]) {
    print("--- INICIANDO CRIAÇÃO DO REQUEST ---")
    
    var imageBytesList: [Data] = []
    
    // Converter cada imagem para bytes
    for (index, image) in images.enumerated() {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            print("Erro ao converter imagem \(index + 1) para dados binários.")
            return
        }
        
        imageBytesList.append(imageData)
        print("Imagem \(index + 1) convertida para bytes: \(imageData.count) bytes")
    }
    
    print("--- CRIANDO PAYLOAD ---")
    
    //  payload JSON
    let payload: [String: Any] = [
        "image_bytes": imageBytesList.map { $0.base64EncodedString() }, // base64
        "title": "ficha_cadastro_individual"
    ]
    
    let encryptedData = encryptPayload(payload: payload)
    
    let encryptedBase64String = encryptedData!.base64EncodedString()
    
    let jsonPayloadForRequest: [String: String] = [
        "payload": encryptedBase64String
    ]
    
    // Chamar função doRequest
    doRequest(payload: jsonPayloadForRequest)
}

// Função para fazer o request
func doRequest(payload: [String: Any]) {
    print("--- INICIANDO REQUISIÇÃO PARA O SERVIDOR ---")
    
    guard let url = URL(string: "https://scansheet-api.onrender.com/process-image") else {
        print("ERRO: URL inválida")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("u3-yBDVGGh40o1L7uth", forHTTPHeaderField: "Authorization")
    
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        request.httpBody = jsonData
        
        print("Dados JSON preparados: \(jsonData.count) bytes")
        print("URL de destino: \(url.absoluteString)")
        
        // Fazer a requisição
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("--- ERRO NA REQUISIÇÃO ---")
                    print("Erro: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("--- RESPOSTA RECEBIDA ---")
                    print("Status Code: \(httpResponse.statusCode)")
                    print("Headers: \(httpResponse.allHeaderFields)")
                }
                
                if let data = data {
                    print("--- DADOS DA RESPOSTA ---")
                    print("Tamanho da resposta: \(data.count) bytes")
                    
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Conteúdo da resposta:")
                        print(responseString)
                        
                        
                        // Processar a resposta JSON
                        do {
                            // Parse do JSON da resposta
                            guard let jsonData = responseString.data(using: .utf8),
                                  let jsonResponse = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                                  let encryptedTable = jsonResponse["table"] as? String else {
                                print("Erro: Não foi possível extrair o campo 'table' da resposta")
                                return
                            }
                            
                            print("Campo 'table' extraído da resposta")
                            
                            // Decodificar de Base64
                            guard let encryptedData = Data(base64Encoded: encryptedTable) else {
                                print("Erro: Não foi possível decodificar o Base64 do campo 'table'")
                                return
                            }
                            
                            print("Base64 decodificado com sucesso: \(encryptedData.count) bytes")
                            
                            // Descriptografar os dados
                            guard let decryptedCSVString = decryptPayload(encryptedData: encryptedData) else {
                                print("Erro: Não foi possível descriptografar os dados")
                                return
                            }
                            
                            print("Dados descriptografados com sucesso")
                            print("CSV descriptografado (primeiros 100 caracteres): \(String(decryptedCSVString.prefix(100)))")
                            
                            // Enviar para o CSVHandler
                            let finalCSVData = decryptedCSVString
                            CSVHandler.shared.processAndSaveCSV(from: finalCSVData) { result in
                                switch result {
                                case .success(let fileURL):
                                    print("CSV salvo com sucesso em: \(fileURL.path)")
                                    print("Arquivo disponível em: \(fileURL.path)")
                                    
                                    // Opcionalmente, você pode mostrar informações do arquivo
                                    if let fileInfo = CSVHandler.shared.getFileInfo(at: fileURL) {
                                        print("Tamanho do arquivo: \(CSVHandler.shared.formatFileSize(fileInfo["size"] as? Int ?? 0))")
                                    }
                                    
                                case .failure(let error):
                                    print("Erro ao processar e salvar o CSV: \(error.localizedDescription)")
                                }
                            }
                            
                        } catch {
                            print("Erro ao processar JSON da resposta: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        
        task.resume()
        print("Requisição enviada com sucesso!")
        
    } catch {
        print("--- ERRO AO SERIALIZAR JSON ---")
        print("Erro: \(error.localizedDescription)")
    }
}

func encryptPayload(payload: [String: Any]) -> Data? {
    
    let key = "qaqn0vD3fx4ibDB84m2Kmoaj90wxDb7zBLGAevu4MtY="
    
    guard let keyData = Data(base64Encoded: key) else {
        print("Erro: Chave Base64 inválida.")
        return nil
    }

    let symmetricKey = SymmetricKey(data: keyData)

    do {
        // 3. Converter o payload para JSON Data
        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])

        // 4. Criptografar os dados usando AES-GCM
        let sealedBox = try AES.GCM.seal(jsonData, using: symmetricKey)

        // 5. Retornar os dados combinados.
        return sealedBox.combined
    } catch {
        print("Erro durante a criptografia: \(error.localizedDescription)")
        return nil
    }
}

func decryptPayload(encryptedData: Data) -> String? {
    // 1. Chave simétrica (deve ser a mesma usada para criptografar)
    let key = "qaqn0vD3fx4ibDB84m2Kmoaj90wxDb7zBLGAevu4MtY="
    
    guard let keyData = Data(base64Encoded: key) else {
        print("Erro: Chave Base64 para descriptografia é inválida.")
        return nil
    }

    let symmetricKey = SymmetricKey(data: keyData)

    do {
        // 2. Recriar o 'SealedBox' a partir dos dados combinados (nonce + ciphertext + tag)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        
        // 3. Descriptografar os dados usando a chave simétrica
        let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
        
        // 4. Converter os dados descriptografados de volta para uma String
        if let decryptedString = String(data: decryptedData, encoding: .utf8) {
            return decryptedString
        } else {
            print("Erro ao converter os dados descriptografados para String.")
            return nil
        }
    } catch {
        print("Erro durante a descriptografia: \(error.localizedDescription)")
        return nil
    }
}
