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
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    private let orderBookUseCase: OrderBookUseCaseProtocol
    private let formattingUseCase: FormattingUseCaseProtocol
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
    
    init(orderBookUseCase: OrderBookUseCaseProtocol, formattingUseCase: FormattingUseCaseProtocol) {
        self.orderBookUseCase = orderBookUseCase
        self.formattingUseCase = formattingUseCase
        setupSubscriptions()
        // Don't auto-start here - let ContentView manage the connection
    }
    
    private func setupSubscriptions() {
        // Subscribe to order book state updates
        orderBookUseCase.orderBookStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.orderBookState = state
                if self?.isLoading == true {
                    self?.isLoading = false
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to connection status
        orderBookUseCase.connectionStatusPublisher
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
        print("📊 OrderBookViewModel: Starting connection...")
        isLoading = true
        // Reset state for fresh connection
        orderBookState = OrderBookState()
        orderBookUseCase.startOrderBookUpdates()
    }
    
    func disconnect() {
        print("📊 OrderBookViewModel: Disconnecting...")
        orderBookUseCase.stopOrderBookUpdates()
        // Reset state on disconnect to ensure fresh start on reconnect
        orderBookState = OrderBookState()
        isLoading = false
    }
    
    func reconnect() {
        orderBookUseCase.reconnect()
    }
    
    func refresh() {
        // Trigger a safe refresh without disconnecting WebSocket
        // This just updates the UI state without affecting the connection
        objectWillChange.send()
    }
    
    // MARK: - Helper Methods for UI
    
    func volumePercentage(for item: OrderBookItem) -> Double {
        let maxVolume = item.isBuy ? maxBuyVolume : maxSellVolume
        return formattingUseCase.volumePercentage(for: item, maxVolume: maxVolume)
    }
    
    func accumulatedVolumePercentage(for item: OrderBookItem, in orders: [OrderBookItem]) -> Double {
        return formattingUseCase.accumulatedVolumePercentage(for: item, in: orders)
    }
    
    func formatPrice(_ price: Double) -> String {
        return formattingUseCase.formatPrice(price)
    }
    
    func formatSize(_ size: Double) -> String {
        return formattingUseCase.formatSize(size)
    }
} 