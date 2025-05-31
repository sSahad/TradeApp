//
//  OrderBookViewModel.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation
import Combine

class OrderBookViewModel: ObservableObject {
    @Published var orderBookState = OrderBookState()
    @Published var isLoading = true
    @Published var connectionStatus: WebSocketManager.ConnectionStatus = .disconnected
    
    private let webSocketManager: WebSocketManager
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties for UI
    var buyOrders: [OrderBookItem] {
        return orderBookState.buyOrders
    }
    
    var sellOrders: [OrderBookItem] {
        return orderBookState.sellOrders
    }
    
    // Volume calculations for background gradients
    var maxBuyVolume: Double {
        return buyOrders.map { $0.actualSize }.max() ?? 0
    }
    
    var maxSellVolume: Double {
        return sellOrders.map { $0.actualSize }.max() ?? 0
    }
    
    init(webSocketManager: WebSocketManager) {
        self.webSocketManager = webSocketManager
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Subscribe to order book updates
        webSocketManager.orderBookPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                self?.handleOrderBookUpdate(response)
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
    
    private func handleOrderBookUpdate(_ response: BitMEXOrderBookResponse) {
        orderBookState.updateOrders(with: response.data, action: response.action)
        
        // Stop loading indicator after first data
        if isLoading && response.action == "partial" {
            isLoading = false
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
    
    func volumePercentage(for item: OrderBookItem) -> Double {
        let maxVolume = item.isBuy ? maxBuyVolume : maxSellVolume
        guard maxVolume > 0 else { return 0 }
        return item.actualSize / maxVolume
    }
    
    func accumulatedVolumePercentage(for item: OrderBookItem, in orders: [OrderBookItem]) -> Double {
        guard let index = orders.firstIndex(of: item) else { return 0 }
        
        let accumulatedVolume: Double
        if item.isBuy {
            // For buy orders, accumulate from top (highest price)
            accumulatedVolume = orders.prefix(index + 1).reduce(0) { $0 + $1.actualSize }
        } else {
            // For sell orders, accumulate from top (lowest price)
            accumulatedVolume = orders.prefix(index + 1).reduce(0) { $0 + $1.actualSize }
        }
        
        let totalVolume = orders.reduce(0) { $0 + $1.actualSize }
        guard totalVolume > 0 else { return 0 }
        
        return accumulatedVolume / totalVolume
    }
    
    func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: price)) ?? String(format: "%.1f", price)
    }
    
    func formatSize(_ size: Double) -> String {
        if size >= 1000000 {
            return String(format: "%.1fM", size / 1000000)
        } else if size >= 1000 {
            return String(format: "%.1fK", size / 1000)
        } else if size >= 1.0 {
            return String(format: "%.4f", size)
        } else {
            return String(format: "%.4f", size)
        }
    }
} 