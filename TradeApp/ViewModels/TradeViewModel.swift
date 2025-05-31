//
//  TradeViewModel.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation
import Combine
import SwiftUI

class TradeViewModel: ObservableObject {
    @Published var tradesState = TradesState()
    @Published var isLoading = true
    @Published var connectionStatus: WebSocketManager.ConnectionStatus = .disconnected
    
    private let webSocketManager: WebSocketManager
    private var cancellables = Set<AnyCancellable>()
    private var highlightTimer: Timer?
    
    // Computed properties for UI
    var trades: [TradeItem] {
        return tradesState.trades
    }
    
    var animatedTrades: [AnimatedTradeItem] {
        return tradesState.animatedTrades
    }
    
    init(webSocketManager: WebSocketManager) {
        self.webSocketManager = webSocketManager
        setupSubscriptions()
        startHighlightTimer()
    }
    
    deinit {
        highlightTimer?.invalidate()
    }
    
    private func setupSubscriptions() {
        // Subscribe to trade updates
        webSocketManager.tradePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                self?.handleTradeUpdate(response)
            }
            .store(in: &cancellables)
        
        // Subscribe to connection status
        webSocketManager.connectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.connectionStatus = status
                if status == .connected {
                    self?.isLoading = true
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleTradeUpdate(_ response: BitMEXTradeResponse) {
        guard !response.data.isEmpty else { return }
        
        // Debug: Print trade data to see timestamps
        print("📈 Received \(response.data.count) trades:")
        for trade in response.data.prefix(3) { // Print first 3 trades
            print("  - Trade: \(trade.trdMatchID), timestamp: '\(trade.timestamp)', formatted: \(trade.formattedTimestamp?.description ?? "nil")")
        }
        
        tradesState.addNewTrades(response.data)
        
        // Stop loading indicator after first data
        if isLoading {
            isLoading = false
        }
        
        // Force UI update for animations
        objectWillChange.send()
    }
    
    private func startHighlightTimer() {
        highlightTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateHighlights()
        }
    }
    
    private func updateHighlights() {
        tradesState.updateHighlights()
        
        // Check if any highlights need to be removed
        let hasActiveHighlights = tradesState.animatedTrades.contains { $0.isHighlighted }
        if hasActiveHighlights {
            objectWillChange.send()
        }
    }
    
    // MARK: - Public Methods
    
    func connect() {
        webSocketManager.connect()
    }
    
    func disconnect() {
        webSocketManager.disconnect()
    }
    
    func reconnect() {
        webSocketManager.reconnect()
    }
    
    // MARK: - Helper Methods for UI
    
    func tradeColor(for trade: TradeItem) -> Color {
        return trade.isBuy ? Color.green : Color.red
    }
    
    func highlightColor(for trade: TradeItem) -> Color {
        return trade.isBuy ? 
            Color(hex: Constants.buyHighlightColor) : 
            Color(hex: Constants.sellHighlightColor)
    }
    
    func normalColor(for trade: TradeItem) -> Color {
        return trade.isBuy ? 
            Color(hex: Constants.buyColor) : 
            Color(hex: Constants.sellColor)
    }
    
    func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: price)) ?? String(format: "%.1f", price)
    }
    
    func formatQty(_ size: Double) -> String {
        return String(format: "%.4f", size)
    }
    
    func formatSize(_ size: Double) -> String {
        if size >= 1000000 {
            return String(format: "%.1fM", size / 1000000)
        } else if size >= 1000 {
            return String(format: "%.1fK", size / 1000)
        } else {
            return String(format: "%.0f", size)
        }
    }
    
    func formatTime(_ trade: TradeItem) -> String {
        guard let date = trade.formattedTimestamp else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    func sideText(for trade: TradeItem) -> String {
        return trade.isBuy ? "BUY" : "SELL"
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 