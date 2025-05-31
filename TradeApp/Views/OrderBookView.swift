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
            // Modern header with enhanced typography
            modernHeader
            
            // Order Book Content with enhanced loading states
            if viewModel.isLoading {
                modernLoadingView
            } else {
                modernOrderBookContent
            }
        }
        .background(Constants.Colors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
    }
    
    private var modernHeader: some View {
        VStack(spacing: Constants.Spacing.sm) {
            // Main header
            HStack {
                Text("Qty")
                    .font(Constants.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Constants.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Price (USD)")
                    .font(Constants.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Constants.Colors.secondaryText)
                    .frame(maxWidth: .infinity)
                
                Text("Qty")
                    .font(Constants.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Constants.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, Constants.Spacing.md)
            .padding(.top, Constants.Spacing.md)
            
            // Subheader with market indicators
            HStack {
                modernMarketIndicator(title: "BUY", color: Constants.Colors.buyPrimary, alignment: .leading)
                
                Spacer()
                
                modernMarketIndicator(title: "SELL", color: Constants.Colors.sellPrimary, alignment: .trailing)
            }
            .padding(.horizontal, Constants.Spacing.md)
            .padding(.bottom, Constants.Spacing.sm)
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
    
    private func modernMarketIndicator(title: String, color: Color, alignment: Alignment) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
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
                Text("Loading Order Book")
                    .font(Constants.Typography.headline)
                    .foregroundColor(Constants.Colors.primaryText)
                
                Text("Connecting to live market data...")
                    .font(Constants.Typography.caption)
                    .foregroundColor(Constants.Colors.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.Colors.primaryBackground)
    }
    
    private var modernOrderBookContent: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 1) {
                    ForEach(0..<Constants.maxOrderBookItems, id: \.self) { index in
                        modernOrderBookRow(at: index, containerWidth: geometry.size.width)
                    }
                }
                .padding(.horizontal, 2)
            }
            .refreshable {
                await refreshOrderBook()
            }
        }
    }
    
    private func modernOrderBookRow(at index: Int, containerWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            // Enhanced buy side
            modernBuyOrderCell(at: index, containerWidth: containerWidth)
            
            // Enhanced sell side
            modernSellOrderCell(at: index, containerWidth: containerWidth)
        }
        .frame(height: 32)
        .background(Constants.Colors.primaryBackground)
    }
    
    private func modernBuyOrderCell(at index: Int, containerWidth: CGFloat) -> some View {
        Group {
            if index < viewModel.buyOrders.count {
                let order = viewModel.buyOrders[index]
                ZStack(alignment: .trailing) {
                    // Enhanced volume background with gradient
                    modernVolumeBackground(
                        for: order,
                        width: (containerWidth * 0.5) * viewModel.accumulatedVolumePercentage(for: order, in: viewModel.buyOrders),
                        colors: [Constants.Colors.buyBackground, Constants.Colors.buyBackground.opacity(0.3)],
                        direction: .leading
                    )
                    
                    // Order data with enhanced typography
                    HStack {
                        Text(viewModel.formatSize(order.actualSize))
                            .font(Constants.Typography.monospacedSmall)
                            .fontWeight(.medium)
                            .foregroundColor(Constants.Colors.buyPrimary)
                        
                        Spacer()
                        
                        Text(viewModel.formatPrice(order.actualPrice))
                            .font(Constants.Typography.monospacedSmall)
                            .fontWeight(.semibold)
                            .foregroundColor(Constants.Colors.buyPrimary)
                    }
                    .padding(.horizontal, Constants.Spacing.sm)
                }
            } else {
                modernEmptyCell()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func modernSellOrderCell(at index: Int, containerWidth: CGFloat) -> some View {
        Group {
            if index < viewModel.sellOrders.count {
                let order = viewModel.sellOrders[index]
                ZStack(alignment: .leading) {
                    // Enhanced volume background with gradient
                    modernVolumeBackground(
                        for: order,
                        width: (containerWidth * 0.5) * viewModel.accumulatedVolumePercentage(for: order, in: viewModel.sellOrders),
                        colors: [Constants.Colors.sellBackground.opacity(0.3), Constants.Colors.sellBackground],
                        direction: .trailing
                    )
                    
                    // Order data with enhanced typography
                    HStack {
                        Text(viewModel.formatPrice(order.actualPrice))
                            .font(Constants.Typography.monospacedSmall)
                            .fontWeight(.semibold)
                            .foregroundColor(Constants.Colors.sellPrimary)
                        
                        Spacer()
                        
                        Text(viewModel.formatSize(order.actualSize))
                            .font(Constants.Typography.monospacedSmall)
                            .fontWeight(.medium)
                            .foregroundColor(Constants.Colors.sellPrimary)
                    }
                    .padding(.horizontal, Constants.Spacing.sm)
                }
            } else {
                modernEmptyCell()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func modernVolumeBackground(for order: OrderBookItem, width: CGFloat, colors: [Color], direction: HorizontalAlignment) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: colors),
                    startPoint: direction == .leading ? .leading : .trailing,
                    endPoint: direction == .leading ? .trailing : .leading
                )
            )
            .frame(width: width)
            .animation(.easeInOut(duration: 0.3), value: width)
    }
    
    private func modernEmptyCell() -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(maxWidth: .infinity)
    }
    
    @MainActor
    private func refreshOrderBook() async {
        await withCheckedContinuation { continuation in
            viewModel.reconnect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                continuation.resume()
            }
        }
    }
}

#Preview {
    let webSocketManager = WebSocketManager()
    let viewModel = OrderBookViewModel(webSocketManager: webSocketManager)
    return OrderBookView(viewModel: viewModel)
        .background(Constants.Colors.groupedBackground)
} 