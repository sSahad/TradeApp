//
//  OrderBookUseCase.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation
import Combine

// MARK: - Order Book Use Case Implementation

final class OrderBookUseCase: OrderBookUseCaseProtocol {
    
    // MARK: - Properties
    
    private let repository: OrderBookRepositoryProtocol
    private let webSocketService: WebSocketServiceProtocol
    private let orderBookStateSubject = CurrentValueSubject<OrderBookState, Never>(OrderBookState())
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Publishers
    
    var orderBookStatePublisher: AnyPublisher<OrderBookState, Never> {
        orderBookStateSubject.eraseToAnyPublisher()
    }
    
    var connectionStatusPublisher: AnyPublisher<ConnectionStatus, Never> {
        webSocketService.connectionStatusPublisher.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(repository: OrderBookRepositoryProtocol, webSocketService: WebSocketServiceProtocol) {
        self.repository = repository
        self.webSocketService = webSocketService
        setupSubscriptions()
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        repository.orderBookPublisher
            .sink { [weak self] update in
                self?.processOrderBookUpdate(update)
            }
            .store(in: &cancellables)
    }
    
    private func processOrderBookUpdate(_ update: OrderBookUpdate) {
        var currentState = orderBookStateSubject.value
        currentState.updateOrders(with: update.orders, action: update.action)
        orderBookStateSubject.send(currentState)
    }
    
    // MARK: - Public Methods
    
    func startOrderBookUpdates() {
        // Connection is managed externally, just start the subscription
        repository.subscribeToOrderBook()
    }
    
    func stopOrderBookUpdates() {
        repository.unsubscribeFromOrderBook()
        // Don't disconnect here as other use cases might still need the connection
    }
    
    func reconnect() {
        webSocketService.reconnect()
    }
} 