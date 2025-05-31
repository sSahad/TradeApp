//
//  TradeRepository.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation
import Combine

// MARK: - Trade Repository Implementation

final class TradeRepository: TradeRepositoryProtocol {
    
    // MARK: - Properties
    
    private let webSocketService: WebSocketServiceProtocol
    private let tradeSubject = PassthroughSubject<TradeUpdate, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Publishers
    
    var tradePublisher: AnyPublisher<TradeUpdate, Never> {
        tradeSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(webSocketService: WebSocketServiceProtocol) {
        self.webSocketService = webSocketService
        setupWebSocketDataBinding()
    }
    
    // MARK: - Private Methods
    
    private func setupWebSocketDataBinding() {
        // Bind to the actual WebSocket manager's trade publisher
        if let webSocketManager = webSocketService as? WebSocketManager {
            webSocketManager.tradePublisher
                .map { response in
                    TradeUpdate(action: response.action, trades: response.data)
                }
                .sink { [weak self] update in
                    self?.tradeSubject.send(update)
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Public Methods
    
    func subscribeToTrades() {
        // Subscription is handled automatically when WebSocket connects
        // This could be extended to handle specific subscription messages
        print("📈 Trade subscription activated")
    }
    
    func unsubscribeFromTrades() {
        // Unsubscription logic if needed
        print("📈 Trade subscription deactivated")
    }
} 