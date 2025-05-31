//
//  UseCaseProtocols.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation
import Combine

// MARK: - Order Book Use Case Protocol

protocol OrderBookUseCaseProtocol: AnyObject {
    var orderBookStatePublisher: AnyPublisher<OrderBookState, Never> { get }
    var connectionStatusPublisher: AnyPublisher<ConnectionStatus, Never> { get }
    
    func startOrderBookUpdates()
    func stopOrderBookUpdates()
    func reconnect()
}

// MARK: - Trade Use Case Protocol

protocol TradeUseCaseProtocol: AnyObject {
    var tradesStatePublisher: AnyPublisher<TradesState, Never> { get }
    var connectionStatusPublisher: AnyPublisher<ConnectionStatus, Never> { get }
    
    func startTradeUpdates()
    func stopTradeUpdates()
    func reconnect()
}

// MARK: - Formatting Use Case Protocol

protocol FormattingUseCaseProtocol: AnyObject {
    func formatPrice(_ price: Double) -> String
    func formatSize(_ size: Double) -> String
    func formatTime(_ trade: TradeItem) -> String
    func formatQty(_ size: Double) -> String
    func volumePercentage(for item: OrderBookItem, maxVolume: Double) -> Double
    func accumulatedVolumePercentage(for item: OrderBookItem, in orders: [OrderBookItem]) -> Double
} 