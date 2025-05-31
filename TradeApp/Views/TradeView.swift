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
            // Modern header with enhanced typography
            modernHeader
            
            // Trade Content with enhanced loading states
            if viewModel.connectionStatus == .noInternet {
                modernNoInternetView
            } else if viewModel.isLoading {
                modernLoadingView
            } else {
                modernTradeContent
            }
        }
        .background(Constants.Colors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
    }
    
    private var modernHeader: some View {
        VStack(spacing: Constants.Spacing.sm) {
            // Main header
            HStack(spacing: 0) {
                Text("Price (USD)")
                    .font(Constants.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Constants.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Qty")
                    .font(Constants.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Constants.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text("Time")
                    .font(Constants.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Constants.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, Constants.Spacing.md)
            .padding(.top, Constants.Spacing.md)
            
            // Trade activity indicator
            modernActivityIndicator
        }
        .background(
            Constants.Colors.cardBackground
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Constants.Colors.secondaryText.opacity(0.1)),
                    alignment: .bottom
                )
        )
    }
    
    private var modernActivityIndicator: some View {
        HStack {
            HStack(spacing: Constants.Spacing.xs) {
                Circle()
                    .fill(Constants.Colors.buyPrimary)
                    .frame(width: 6, height: 6)
                
                Text("BUY")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(Constants.Colors.buyPrimary)
            }
            
            Spacer()
            
            Text("RECENT TRADES")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(Constants.Colors.tertiaryText)
            
            Spacer()
            
            HStack(spacing: Constants.Spacing.xs) {
                Text("SELL")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(Constants.Colors.sellPrimary)
                
                Circle()
                    .fill(Constants.Colors.sellPrimary)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, Constants.Spacing.md)
        .padding(.bottom, Constants.Spacing.sm)
    }
    
    private var modernLoadingView: some View {
        VStack(spacing: Constants.Spacing.lg) {
            // Beautiful loading animation
            ZStack {
                Circle()
                    .stroke(Constants.Colors.accent.opacity(0.2), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Constants.Colors.accent, Constants.Colors.accent.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: UUID())
            }
            
            VStack(spacing: Constants.Spacing.xs) {
                Text("Loading Recent Trades")
                    .font(Constants.Typography.headline)
                    .foregroundColor(Constants.Colors.primaryText)
                
                Text("Fetching live trading activity...")
                    .font(Constants.Typography.caption)
                    .foregroundColor(Constants.Colors.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.Colors.primaryBackground)
    }
    
    private var modernTradeContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.animatedTrades.indices, id: \.self) { index in
                    let animatedTrade = viewModel.animatedTrades[index]
                    modernTradeRow(animatedTrade: animatedTrade, index: index)
                        .id(animatedTrade.trade.trdMatchID)
                }
            }
            .padding(.horizontal, 2)
        }
        .refreshable {
            await refreshTrades()
        }
    }
    
    private func modernTradeRow(animatedTrade: AnimatedTradeItem, index: Int) -> some View {
        let trade = animatedTrade.trade
        
        return HStack(spacing: 0) {
            // Price (USD) - Left aligned with enhanced styling
            Text(viewModel.formatPrice(trade.price))
                .font(Constants.Typography.monospacedSmall)
                .fontWeight(.semibold)
                .foregroundColor(modernTradeColor(for: trade))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Qty (Size) - Center aligned with enhanced styling
            Text(viewModel.formatQty(trade.size))
                .font(Constants.Typography.monospacedSmall)
                .fontWeight(.medium)
                .foregroundColor(modernTradeColor(for: trade))
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Time - Right aligned with enhanced styling
            Text(viewModel.formatTime(trade))
                .font(Constants.Typography.monospacedSmall)
                .fontWeight(.medium)
                .foregroundColor(Constants.Colors.tertiaryText)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, Constants.Spacing.sm)
        .padding(.horizontal, Constants.Spacing.md)
        .background(
            Group {
                if animatedTrade.isHighlighted {
                    modernHighlightBackground(for: trade)
                } else {
                    modernRowBackground(index: index)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.small))
        .animation(.easeInOut(duration: 0.2), value: animatedTrade.isHighlighted)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .opacity
        ))
    }
    
    private func modernTradeColor(for trade: TradeItem) -> Color {
        return trade.isBuy ? Constants.Colors.buyPrimary : Constants.Colors.sellPrimary
    }
    
    private func modernHighlightBackground(for trade: TradeItem) -> some View {
        LinearGradient(
            colors: [
                (trade.isBuy ? Constants.Colors.buyBackground : Constants.Colors.sellBackground),
                (trade.isBuy ? Constants.Colors.buyBackground : Constants.Colors.sellBackground).opacity(0.3)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private func modernRowBackground(index: Int) -> some View {
        Group {
            if index % 2 == 0 {
                Constants.Colors.primaryBackground
            } else {
                Constants.Colors.cardBackground.opacity(0.3)
            }
        }
    }
    
    private var modernNoInternetView: some View {
        VStack(spacing: Constants.Spacing.lg) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Constants.Colors.error)
            
            VStack(spacing: Constants.Spacing.xs) {
                Text("No Internet Connection")
                    .font(Constants.Typography.headline)
                    .foregroundColor(Constants.Colors.primaryText)
                
                Text("Check your connection to view live trades")
                    .font(Constants.Typography.caption)
                    .foregroundColor(Constants.Colors.tertiaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.Colors.primaryBackground)
    }
    
    @MainActor
    private func refreshTrades() async {
        await withCheckedContinuation { continuation in
            // Use the safe refresh method that doesn't disrupt WebSocket connection
            viewModel.refresh()
            
            // Small delay to provide user feedback that refresh happened
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
}

#Preview {
    let diContainer = DIContainer.shared
    let viewModel = diContainer.makeTradeViewModel()
    return TradeView(viewModel: viewModel)
        .background(Constants.Colors.groupedBackground)
} 