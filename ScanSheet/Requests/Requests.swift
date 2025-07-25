//
//  Requests.swift
//  ScanSheet
//
//  Created by Rodrigo Barbosa on 19/07/25.
//

import Foundation
import PhotosUI

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
        "image_bytes": imageBytesList.map { $0.base64EncodedString() }, // Converter para base64 para JSON
        "title": "outros"
    ]
    
    print("Payload criado com sucesso:")
    print("- Title: FICHA_CADASTRO_INDIVIDUAL")
    print("- Número de imagens: \(imageBytesList.count)")
    
    // Chamar função doRequest
    doRequest(payload: payload)
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
                    }
                    
                    // Tentar parsear como JSON
                    do {
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            print("--- RESPOSTA JSON PARSEADA ---")
                            print(jsonResponse)
                        }
                    } catch {
                        print("Erro ao parsear JSON da resposta: \(error)")
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
