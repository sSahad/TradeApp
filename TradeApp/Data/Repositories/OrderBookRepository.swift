//
//  OrderBookRepository.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation
import Combine

// MARK: - Order Book Repository Implementation

final class OrderBookRepository: OrderBookRepositoryProtocol {
    
    // MARK: - Properties
    
    private let webSocketService: WebSocketServiceProtocol
    private let orderBookSubject = PassthroughSubject<OrderBookUpdate, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Publishers
    
    var orderBookPublisher: AnyPublisher<OrderBookUpdate, Never> {
        orderBookSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(webSocketService: WebSocketServiceProtocol) {
        self.webSocketService = webSocketService
        setupWebSocketDataBinding()
    }
    
    // MARK: - Private Methods
    
    private func setupWebSocketDataBinding() {
        // Bind to the actual WebSocket manager's order book publisher
        if let webSocketManager = webSocketService as? WebSocketManager {
            webSocketManager.orderBookPublisher
                .map { response in
                    OrderBookUpdate(action: response.action, orders: response.data)
                }
                .sink { [weak self] update in
                    self?.orderBookSubject.send(update)
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Public Methods
    
    func subscribeToOrderBook() {
        // Subscription is handled automatically when WebSocket connects
        // This could be extended to handle specific subscription messages
        print("📊 OrderBook subscription activated")
    }
    
    func unsubscribeFromOrderBook() {
        // Unsubscription logic if needed
        print("📊 OrderBook subscription deactivated")
    }
} 