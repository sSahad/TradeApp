//
//  DIContainer.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation

// MARK: - Dependency Injection Container

final class DIContainer {
    
    // MARK: - Shared Instance
    
    static let shared = DIContainer()
    
    // MARK: - Private Properties
    
    private lazy var networkMonitor: NetworkMonitor = NetworkMonitor()
    private lazy var webSocketService: WebSocketServiceProtocol = WebSocketManager(networkMonitor: networkMonitor)
    private lazy var formattingUseCase: FormattingUseCaseProtocol = FormattingUseCase()
    
    // MARK: - Private Initialization
    
    private init() {}
    
    // MARK: - Factory Methods
    
    func makeOrderBookRepository() -> OrderBookRepositoryProtocol {
        return OrderBookRepository(webSocketService: webSocketService)
    }
    
    func makeTradeRepository() -> TradeRepositoryProtocol {
        return TradeRepository(webSocketService: webSocketService)
    }
    
    func makeOrderBookUseCase() -> OrderBookUseCaseProtocol {
        let repository = makeOrderBookRepository()
        return OrderBookUseCase(repository: repository, webSocketService: webSocketService)
    }
    
    func makeTradeUseCase() -> TradeUseCaseProtocol {
        let repository = makeTradeRepository()
        return TradeUseCase(repository: repository, webSocketService: webSocketService)
    }
    
    func makeFormattingUseCase() -> FormattingUseCaseProtocol {
        return formattingUseCase
    }
    
    func makeOrderBookViewModel() -> OrderBookViewModel {
        let orderBookUseCase = makeOrderBookUseCase()
        let formattingUseCase = makeFormattingUseCase()
        return OrderBookViewModel(orderBookUseCase: orderBookUseCase, formattingUseCase: formattingUseCase)
    }
    
    func makeTradeViewModel() -> TradeViewModel {
        let tradeUseCase = makeTradeUseCase()
        let formattingUseCase = makeFormattingUseCase()
        return TradeViewModel(tradeUseCase: tradeUseCase, formattingUseCase: formattingUseCase)
    }
    
    // MARK: - Service Access
    
    func getWebSocketService() -> WebSocketServiceProtocol {
        return webSocketService
    }
    
    func getNetworkMonitor() -> NetworkMonitor {
        return networkMonitor
    }
} 