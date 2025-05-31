//
//  ContentView.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var webSocketManager = WebSocketManager()
    @StateObject private var orderBookViewModel: OrderBookViewModel
    @StateObject private var tradeViewModel: TradeViewModel
    
    @State private var selectedTab: TabType = .orderBook
    @State private var showConnectionDetails = false
    
    enum TabType: String, CaseIterable {
        case orderBook = "Order Book"
        case recentTrades = "Recent Trades"
        
        var icon: String {
            switch self {
            case .orderBook: return "list.bullet.rectangle"
            case .recentTrades: return "clock.arrow.circlepath"
            }
        }
    }
    
    init() {
        let webSocketManager = WebSocketManager()
        self._webSocketManager = StateObject(wrappedValue: webSocketManager)
        self._orderBookViewModel = StateObject(wrappedValue: OrderBookViewModel(webSocketManager: webSocketManager))
        self._tradeViewModel = StateObject(wrappedValue: TradeViewModel(webSocketManager: webSocketManager))
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Enhanced Navigation Header
                modernNavigationHeader
                
                // Enhanced Tab Control
                modernTabControl
                
                // Content with smooth transitions
                modernContentView
            }
            .background(Constants.Colors.groupedBackground)
            .ignoresSafeArea(.all, edges: .bottom)
        }
        .onAppear {
            connectToWebSocket()
        }
        .onDisappear {
            webSocketManager.disconnect()
        }
        .preferredColorScheme(nil) // Respect system setting
    }
    
    private var modernNavigationHeader: some View {
        VStack(spacing: 0) {
            HStack {
                // Title with enhanced typography
                VStack(alignment: .leading, spacing: Constants.Spacing.xs) {
                    Text("XBTUSD")
                        .font(Constants.Typography.title)
                        .foregroundColor(Constants.Colors.primaryText)
                    
                    Text("Bitcoin / US Dollar")
                        .font(Constants.Typography.caption)
                        .foregroundColor(Constants.Colors.tertiaryText)
                }
                
                Spacer()
                
                // Enhanced connection status
                modernConnectionStatus
            }
            .padding(.horizontal, Constants.Spacing.md)
            .padding(.top, Constants.Spacing.md)
            .padding(.bottom, Constants.Spacing.sm)
            
            // Elegant divider
            Rectangle()
                .fill(Constants.Colors.secondaryText.opacity(0.1))
                .frame(height: 0.5)
        }
        .background(
            Constants.Colors.primaryBackground
                .shadow(color: Constants.Shadow.light, radius: 1, x: 0, y: 1)
        )
    }
    
    private var modernConnectionStatus: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showConnectionDetails.toggle()
            }
        }) {
            HStack(spacing: Constants.Spacing.xs) {
                // Animated connection indicator
                connectionIndicator
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(connectionStatusText)
                        .font(Constants.Typography.caption)
                        .foregroundColor(Constants.Colors.secondaryText)
                    
                    if showConnectionDetails {
                        Text("Tap to refresh")
                            .font(.caption2)
                            .foregroundColor(Constants.Colors.tertiaryText)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                }
            }
            .padding(.horizontal, Constants.Spacing.sm)
            .padding(.vertical, Constants.Spacing.xs)
            .background(
                Capsule()
                    .fill(Constants.Colors.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(connectionStatusColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            if webSocketManager.connectionStatusPublisher.value != .connected {
                webSocketManager.reconnect()
            }
        }
    }
    
    private var connectionIndicator: some View {
        Circle()
            .fill(connectionStatusColor)
            .frame(width: 8, height: 8)
            .scaleEffect(webSocketManager.connectionStatusPublisher.value == .connecting ? 1.2 : 1.0)
            .animation(
                webSocketManager.connectionStatusPublisher.value == .connecting ? 
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : 
                    .easeInOut(duration: 0.3),
                value: webSocketManager.connectionStatusPublisher.value
            )
            .overlay(
                Circle()
                    .stroke(connectionStatusColor.opacity(0.3), lineWidth: 2)
                    .scaleEffect(webSocketManager.connectionStatusPublisher.value == .connected ? 1.5 : 1.0)
                    .opacity(webSocketManager.connectionStatusPublisher.value == .connected ? 0 : 1)
                    .animation(.easeOut(duration: 1.0), value: webSocketManager.connectionStatusPublisher.value)
            )
    }
    
    private var connectionStatusColor: Color {
        switch webSocketManager.connectionStatusPublisher.value {
        case .connected: return Constants.Colors.success
        case .connecting: return Constants.Colors.warning
        case .disconnected: return Constants.Colors.secondaryText
        case .error: return Constants.Colors.error
        }
    }
    
    private var connectionStatusText: String {
        switch webSocketManager.connectionStatusPublisher.value {
        case .connected: return "Live"
        case .connecting: return "Connecting..."
        case .disconnected: return "Offline"
        case .error: return "Error"
        }
    }
    
    private var modernTabControl: some View {
        HStack(spacing: 0) {
            ForEach(TabType.allCases, id: \.self) { tab in
                modernTabButton(for: tab)
            }
        }
        .background(Constants.Colors.primaryBackground)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Constants.Colors.secondaryText.opacity(0.1)),
            alignment: .bottom
        )
    }
    
    private func modernTabButton(for tab: TabType) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: Constants.Spacing.xs) {
                HStack(spacing: Constants.Spacing.xs) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedTab == tab ? Constants.Colors.accent : Constants.Colors.secondaryText)
                    
                    Text(tab.rawValue)
                        .font(Constants.Typography.caption)
                        .fontWeight(selectedTab == tab ? .semibold : .medium)
                        .foregroundColor(selectedTab == tab ? Constants.Colors.accent : Constants.Colors.secondaryText)
                }
                .padding(.vertical, Constants.Spacing.sm)
                .frame(maxWidth: .infinity)
                
                // Animated selection indicator
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(selectedTab == tab ? Constants.Colors.accent : Color.clear)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var modernContentView: some View {
        TabView(selection: $selectedTab) {
            modernOrderBookView
                .tag(TabType.orderBook)
            
            modernTradeView
                .tag(TabType.recentTrades)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
    }
    
    private var modernOrderBookView: some View {
        OrderBookView(viewModel: orderBookViewModel)
            .background(Constants.Colors.groupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.large))
            .padding(.horizontal, Constants.Spacing.sm)
            .shadow(color: Constants.Shadow.light, radius: 4, x: 0, y: 2)
    }
    
    private var modernTradeView: some View {
        TradeView(viewModel: tradeViewModel)
            .background(Constants.Colors.groupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.large))
            .padding(.horizontal, Constants.Spacing.sm)
            .shadow(color: Constants.Shadow.light, radius: 4, x: 0, y: 2)
    }
    
    private func connectToWebSocket() {
        webSocketManager.connect()
    }
}

#Preview {
    ContentView()
}
