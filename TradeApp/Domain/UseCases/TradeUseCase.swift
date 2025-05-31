//
//  TradeUseCase.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Trade Use Case Implementation

final class TradeUseCase: TradeUseCaseProtocol {
    
    // MARK: - Properties
    
    private let repository: TradeRepositoryProtocol
    private let webSocketService: WebSocketServiceProtocol
    private let tradesStateSubject = CurrentValueSubject<TradesState, Never>(TradesState())
    private var highlightTimer: Timer?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Publishers
    
    var tradesStatePublisher: AnyPublisher<TradesState, Never> {
        tradesStateSubject.eraseToAnyPublisher()
    }
    
    var connectionStatusPublisher: AnyPublisher<ConnectionStatus, Never> {
        webSocketService.connectionStatusPublisher.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(repository: TradeRepositoryProtocol, webSocketService: WebSocketServiceProtocol) {
        self.repository = repository
        self.webSocketService = webSocketService
        setupSubscriptions()
        startHighlightTimer()
    }
    
    deinit {
        highlightTimer?.invalidate()
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        repository.tradePublisher
            .sink { [weak self] update in
                self?.processTradeUpdate(update)
            }
            .store(in: &cancellables)
    }
    
    private func processTradeUpdate(_ update: TradeUpdate) {
        guard !update.trades.isEmpty else { return }
        
        var currentState = tradesStateSubject.value
        currentState.addNewTrades(update.trades)
        tradesStateSubject.send(currentState)
    }
    
    private func startHighlightTimer() {
        highlightTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateHighlights()
        }
    }
    
    private func updateHighlights() {
        var currentState = tradesStateSubject.value
        currentState.updateHighlights()
        
        let hasActiveHighlights = currentState.animatedTrades.contains { $0.isHighlighted }
        if hasActiveHighlights {
            tradesStateSubject.send(currentState)
        }
    }
    
    // MARK: - Public Methods
    
    func startTradeUpdates() {
        // Connection is managed externally, just start the subscription
        repository.subscribeToTrades()
    }
    
    func stopTradeUpdates() {
        repository.unsubscribeFromTrades()
        // Don't disconnect here as other use cases might still need the connection
    }
    
    func reconnect() {
        webSocketService.reconnect()
    }
} 