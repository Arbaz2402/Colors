import SwiftUI

struct ColorsView: View {
    @StateObject private var viewModel = ColorViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Connectivity Indicator
                HStack {
                    Circle()
                        .fill(viewModel.isOnline ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    Text(viewModel.isOnline ? "Online" : "Offline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }.padding([.top, .horizontal])
                
                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Color Cards List with swipe-to-delete
                List {
                    ForEach(viewModel.colorCards) { card in
                        ColorCardView(card: card)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let card = viewModel.colorCards[index]
                            viewModel.deleteColor(card)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .padding(.top, -10)

                
                // Generate Button
                Button(action: {
                    viewModel.generateRandomColor()
                }) {
                    Text("Generate Random Color")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Color Cards")
        }
    }
}

struct ColorCardView: View {
    let card: ColorCard
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(card.color)
                .frame(height: 100)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            HStack {
                Text(card.hexCode)
                    .font(.headline)
                Spacer()
                Text(card.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ColorsView()
}
