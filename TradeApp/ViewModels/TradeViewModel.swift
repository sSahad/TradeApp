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
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    private let tradeUseCase: TradeUseCaseProtocol
    private let formattingUseCase: FormattingUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties for UI
    var trades: [TradeItem] {
        return tradesState.trades
    }
    
    var animatedTrades: [AnimatedTradeItem] {
        return tradesState.animatedTrades
    }
    
    init(tradeUseCase: TradeUseCaseProtocol, formattingUseCase: FormattingUseCaseProtocol) {
        self.tradeUseCase = tradeUseCase
        self.formattingUseCase = formattingUseCase
        setupSubscriptions()
        // Don't auto-start here - let ContentView manage the connection
    }
    
    private func setupSubscriptions() {
        // Subscribe to trades state updates
        tradeUseCase.tradesStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.tradesState = state
                if self?.isLoading == true {
                    self?.isLoading = false
                }
                // Force UI update for animations
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Subscribe to connection status
        tradeUseCase.connectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.connectionStatus = status
                if status == .connected {
                    self?.isLoading = true
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func connect() {
        tradeUseCase.startTradeUpdates()
    }
    
    func disconnect() {
        tradeUseCase.stopTradeUpdates()
    }
    
    func reconnect() {
        tradeUseCase.reconnect()
    }
    
    func refresh() {
        // Trigger a safe refresh without disconnecting WebSocket
        // This just updates the UI state without affecting the connection
        objectWillChange.send()
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
        return formattingUseCase.formatPrice(price)
    }
    
    func formatQty(_ size: Double) -> String {
        return formattingUseCase.formatQty(size)
    }
    
    func formatSize(_ size: Double) -> String {
        return formattingUseCase.formatSize(size)
    }
    
    func formatTime(_ trade: TradeItem) -> String {
        return formattingUseCase.formatTime(trade)
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