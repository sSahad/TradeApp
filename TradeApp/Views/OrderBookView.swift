//
//  OrderBookView.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import SwiftUI

struct OrderBookView: View {
    @ObservedObject var viewModel: OrderBookViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with single merged price title
            HStack {
                Text("Qty")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Price (USD)")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                
                Text("Qty")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
            
            // Order Book Content
            if viewModel.isLoading {
                loadingView
            } else {
                orderBookContent
            }
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading Order Book...")
                .progressViewStyle(CircularProgressViewStyle())
            Spacer()
        }
    }
    
    private var orderBookContent: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(0..<Constants.maxOrderBookItems, id: \.self) { index in
                        orderBookRow(at: index, containerWidth: geometry.size.width)
                    }
                }
            }
            .refreshable {
                viewModel.reconnect()
            }
        }
    }
    
    private func orderBookRow(at index: Int, containerWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            // Buy side (left)
            buyOrderCell(at: index, containerWidth: containerWidth)
            
            // Sell side (right)
            sellOrderCell(at: index, containerWidth: containerWidth)
        }
        .frame(height: 28)
    }
    
    private func buyOrderCell(at index: Int, containerWidth: CGFloat) -> some View {
        Group {
            if index < viewModel.buyOrders.count {
                let order = viewModel.buyOrders[index]
                ZStack(alignment: .trailing) {
                    // Volume background gradient
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: Constants.buyColor).opacity(0.1),
                                    Color(hex: Constants.buyColor).opacity(0.3)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: (containerWidth * 0.5) * viewModel.accumulatedVolumePercentage(for: order, in: viewModel.buyOrders))
                    
                    // Order data
                    HStack {
                        Text(viewModel.formatSize(order.actualSize))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(hex: Constants.buyColor))
                        
                        Spacer()
                        
                        Text(viewModel.formatPrice(order.actualPrice))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(hex: Constants.buyColor))
                    }
                    .padding(.horizontal, 8)
                }
            } else {
                // Empty cell
                Rectangle()
                    .fill(Color.clear)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func sellOrderCell(at index: Int, containerWidth: CGFloat) -> some View {
        Group {
            if index < viewModel.sellOrders.count {
                let order = viewModel.sellOrders[index]
                ZStack(alignment: .leading) {
                    // Volume background gradient
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: Constants.sellColor).opacity(0.3),
                                    Color(hex: Constants.sellColor).opacity(0.1)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: (containerWidth * 0.5) * viewModel.accumulatedVolumePercentage(for: order, in: viewModel.sellOrders))
                    
                    // Order data
                    HStack {
                        Text(viewModel.formatPrice(order.actualPrice))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(hex: Constants.sellColor))
                        
                        Spacer()
                        
                        Text(viewModel.formatSize(order.actualSize))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(hex: Constants.sellColor))
                    }
                    .padding(.horizontal, 8)
                }
            } else {
                // Empty cell
                Rectangle()
                    .fill(Color.clear)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let webSocketManager = WebSocketManager()
    let viewModel = OrderBookViewModel(webSocketManager: webSocketManager)
    return OrderBookView(viewModel: viewModel)
} 