//
//  teste.swift
//  ScanSheet
//
//  Created by Rodrigo Barbosa on 10/06/25.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var router: AppRouter
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingShareSheet = false
    @State private var fileToShare: URL?
    @State private var showingNoFilesAlert = false
    @State private var savedFilesCount = 0
    
    var body: some View {
        ZStack {
            // Background gradient
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
            
            VStack(spacing: 40) {
                // Header section
                VStack(spacing: 20) {
                    // App icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "doc.text")
                            .font(.system(size: 35, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    // Title and subtitle
                    VStack(spacing: 8) {
                        Text("Scansheet")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                    }
                    
                    // Description
                    Text("Transform any table or spreadsheet photo into a fully editable Excel file with AI-powered precision")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Action cards
                VStack(spacing: 16) {
                    ActionCard(
                        icon: "camera.fill",
                        title: "Upload Spreadsheet",
                        subtitle: "Via Camera or Gallery",
                        gradientColors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)],
                        action: {router.navigate(to: .fichaSelection)}
                        
                    )
                    ActionCard(
                        icon: "square.and.arrow.up.on.square",
                        title: "Share Sheets",
                        subtitle: "Export and collaborate easily",
                        gradientColors: [Color.green.opacity(0.7), Color.mint.opacity(0.6)],
                        action: { router.navigate(to: .exportResults)}
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .alert("Erro", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GridPatternView: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 40
            
            context.stroke(
                Path { path in
                    // Vertical lines
                    for x in stride(from: 0, through: size.width, by: spacing) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    
                    // Horizontal lines
                    for y in stride(from: 0, through: size.height, by: spacing) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                },
                with: .color(.white.opacity(0.1)),
                lineWidth: 1
            )
        }
    }
}

#Preview {
    HomeView()
}


