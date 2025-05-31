//
//  TradeView.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import SwiftUI

struct TradeView: View {
    @ObservedObject var viewModel: TradeViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                Text("Price (USD)")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Qty")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text("Time")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
            
            // Trade Content
            if viewModel.isLoading {
                loadingView
            } else {
                tradeContent
            }
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading Recent Trades...")
                .progressViewStyle(CircularProgressViewStyle())
            Spacer()
        }
    }
    
    private var tradeContent: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(viewModel.animatedTrades.indices, id: \.self) { index in
                    let animatedTrade = viewModel.animatedTrades[index]
                    tradeRow(animatedTrade: animatedTrade)
                        .id(animatedTrade.trade.trdMatchID)
                }
            }
        }
        .refreshable {
            viewModel.reconnect()
        }
    }
    
    private func tradeRow(animatedTrade: AnimatedTradeItem) -> some View {
        let trade = animatedTrade.trade
        
        return HStack(spacing: 0) {
            // Price (USD) - Left aligned
            Text(viewModel.formatPrice(trade.price))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(viewModel.tradeColor(for: trade))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Qty (Size) - Center aligned
            Text(viewModel.formatQty(trade.size))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(viewModel.tradeColor(for: trade))
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Time - Right aligned
            Text(viewModel.formatTime(trade))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(viewModel.tradeColor(for: trade))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .background(
            animatedTrade.isHighlighted ? 
                viewModel.highlightColor(for: trade).opacity(0.3) : 
                Color.clear
        )
        .animation(.easeInOut(duration: 0.2), value: animatedTrade.isHighlighted)
    }
}

#Preview {
    let webSocketManager = WebSocketManager()
    let viewModel = TradeViewModel(webSocketManager: webSocketManager)
    return TradeView(viewModel: viewModel)
} 