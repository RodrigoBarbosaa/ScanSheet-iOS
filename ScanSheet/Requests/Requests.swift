//
//  Requests.swift
//  ScanSheet
//
//  Created by Rodrigo Barbosa on 19/07/25.
//

import Foundation
import PhotosUI
import CryptoKit

// Enum para resultado da requisição
enum RequestResult {
    case success
    case failure(String)
}

// Função com callback para comunicar com o modal
func createRequestWithCallback(images: [UIImage], completion: @escaping (RequestResult) -> Void) {
    print("--- INICIANDO CRIAÇÃO DO REQUEST ---")
    
    var imageBytesList: [Data] = []
    
    // Converter cada imagem para bytes
    for (index, image) in images.enumerated() {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            print("Erro ao converter imagem \(index + 1) para dados binários.")
            completion(.failure("Erro ao processar as imagens"))
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
    
    guard let encryptedData = encryptPayload(payload: payload) else {
        completion(.failure("Erro na criptografia dos dados"))
        return
    }
    
    let encryptedBase64String = encryptedData.base64EncodedString()
    
    let jsonPayloadForRequest: [String: String] = [
        "payload": encryptedBase64String
    ]
    
    // Chamar função doRequest com callback
    doRequestWithCallback(payload: jsonPayloadForRequest, completion: completion)
}

// Função para fazer o request com callback
func doRequestWithCallback(payload: [String: Any], completion: @escaping (RequestResult) -> Void) {
    print("--- INICIANDO REQUISIÇÃO PARA O SERVIDOR ---")
    
    guard let url = URL(string: "https://scansheet-api.onrender.com/process-image") else {
        print("ERRO: URL inválida")
        completion(.failure("URL do servidor inválida"))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("u3-yBDVGGh40o1L7uth", forHTTPHeaderField: "Authorization")
    request.timeoutInterval = 60.0 // Timeout de 60 segundos
    
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        request.httpBody = jsonData
        
        print("Dados JSON preparados: \(jsonData.count) bytes")
        print("URL de destino: \(url.absoluteString)")
        
        // Fazer a requisição
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("--- ERRO NA REQUISIÇÃO ---")
                print("Erro: \(error.localizedDescription)")
                
                let errorMessage: String
                if (error as NSError).code == NSURLErrorTimedOut {
                    errorMessage = "Tempo limite da requisição excedido. Tente novamente."
                } else if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                    errorMessage = "Sem conexão com a internet. Verifique sua conexão."
                } else {
                    errorMessage = "Erro de conexão: \(error.localizedDescription)"
                }
                
                completion(.failure(errorMessage))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure("Resposta inválida do servidor"))
                return
            }
            
            print("--- RESPOSTA RECEBIDA ---")
            print("Status Code: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
            
            // Verificar código de status HTTP
            guard 200...299 ~= httpResponse.statusCode else {
                let errorMessage: String
                switch httpResponse.statusCode {
                case 400:
                    errorMessage = "Dados enviados são inválidos"
                case 401:
                    errorMessage = "Não autorizado. Verifique as credenciais"
                case 403:
                    errorMessage = "Acesso negado"
                case 404:
                    errorMessage = "Serviço não encontrado"
                case 500...599:
                    errorMessage = "Erro interno do servidor"
                default:
                    errorMessage = "Erro no servidor (código \(httpResponse.statusCode))"
                }
                
                completion(.failure(errorMessage))
                return
            }
            
            guard let data = data else {
                completion(.failure("Nenhum dado recebido do servidor"))
                return
            }
            
            print("--- DADOS DA RESPOSTA ---")
            print("Tamanho da resposta: \(data.count) bytes")
            
            guard let responseString = String(data: data, encoding: .utf8) else {
                completion(.failure("Erro ao decodificar resposta do servidor"))
                return
            }
            
            print("Conteúdo da resposta:")
            print(responseString)
            
            // Processar a resposta JSON
            do {
                // Parse do JSON da resposta
                guard let jsonData = responseString.data(using: .utf8),
                      let jsonResponse = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                      let encryptedTable = jsonResponse["table"] as? String else {
                    print("Erro: Não foi possível extrair o campo 'table' da resposta")
                    completion(.failure("Resposta do servidor está em formato inválido"))
                    return
                }
                
                print("Campo 'table' extraído da resposta")
                
                // Decodificar de Base64
                guard let encryptedData = Data(base64Encoded: encryptedTable) else {
                    print("Erro: Não foi possível decodificar o Base64 do campo 'table'")
                    completion(.failure("Erro ao decodificar dados do servidor"))
                    return
                }
                
                print("Base64 decodificado com sucesso: \(encryptedData.count) bytes")
                
                // Descriptografar os dados
                guard let decryptedCSVString = decryptPayload(encryptedData: encryptedData) else {
                    print("Erro: Não foi possível descriptografar os dados")
                    completion(.failure("Erro ao descriptografar dados do servidor"))
                    return
                }
                
                print("Dados descriptografados com sucesso")
                print("CSV descriptografado (primeiros 400 caracteres): \(String(decryptedCSVString.prefix(400)))")
                
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
                        
                        completion(.success)
                        
                    case .failure(let error):
                        print("Erro ao processar e salvar o CSV: \(error.localizedDescription)")
                        completion(.failure("Erro ao salvar dados: \(error.localizedDescription)"))
                    }
                }
                
            } catch {
                print("Erro ao processar JSON da resposta: \(error.localizedDescription)")
                completion(.failure("Erro ao processar resposta do servidor"))
            }
        }
        
        task.resume()
        print("Requisição enviada com sucesso!")
        
    } catch {
        print("--- ERRO AO SERIALIZAR JSON ---")
        print("Erro: \(error.localizedDescription)")
        completion(.failure("Erro ao preparar dados para envio"))
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
