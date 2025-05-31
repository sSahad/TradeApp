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
    
    enum TabType: String, CaseIterable {
        case orderBook = "Order Book"
        case recentTrades = "Recent Trades"
    }
    
    init() {
        let webSocketManager = WebSocketManager()
        self._webSocketManager = StateObject(wrappedValue: webSocketManager)
        self._orderBookViewModel = StateObject(wrappedValue: OrderBookViewModel(webSocketManager: webSocketManager))
        self._tradeViewModel = StateObject(wrappedValue: TradeViewModel(webSocketManager: webSocketManager))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Header
            navigationHeader
            
            // Tab Control
            tabControl
            
            // Content
            contentView
        }
        .background(Color(UIColor.systemBackground))
        .onAppear {
            connectToWebSocket()
        }
        .onDisappear {
            webSocketManager.disconnect()
        }
    }
    
    private var navigationHeader: some View {
        VStack {
            HStack {
                Text("XBTUSD")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                connectionStatusView
            }
            .padding(.horizontal)
            .padding(.top)
            
            Divider()
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private var connectionStatusView: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(connectionStatusColor)
                .frame(width: 8, height: 8)
            
            Text(connectionStatusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var connectionStatusColor: Color {
        switch webSocketManager.connectionStatusPublisher.value {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected:
            return .red
        case .error:
            return .red
        }
    }
    
    private var connectionStatusText: String {
        switch webSocketManager.connectionStatusPublisher.value {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    private var tabControl: some View {
        HStack(spacing: 0) {
            ForEach(TabType.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == tab ? 
                                Color(UIColor.secondarySystemBackground) : 
                                Color.clear
                        )
                        .overlay(
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(selectedTab == tab ? .accentColor : .clear),
                            alignment: .bottom
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(UIColor.separator)),
            alignment: .bottom
        )
    }
    
    private var contentView: some View {
        Group {
            switch selectedTab {
            case .orderBook:
                OrderBookView(viewModel: orderBookViewModel)
            case .recentTrades:
                TradeView(viewModel: tradeViewModel)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
    
    private func connectToWebSocket() {
        webSocketManager.connect()
    }
}

#Preview {
    ContentView()
}
