//
//  RepositoryProtocols.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation
import Combine

// MARK: - Order Book Repository Protocol

protocol OrderBookRepositoryProtocol: AnyObject {
    var orderBookPublisher: AnyPublisher<OrderBookUpdate, Never> { get }
    
    func subscribeToOrderBook()
    func unsubscribeFromOrderBook()
}

// MARK: - Trade Repository Protocol

protocol TradeRepositoryProtocol: AnyObject {
    var tradePublisher: AnyPublisher<TradeUpdate, Never> { get }
    
    func subscribeToTrades()
    func unsubscribeFromTrades()
}

// MARK: - Domain Models

struct OrderBookUpdate {
    let action: String
    let orders: [OrderBookItem]
}

struct TradeUpdate {
    let action: String
    let trades: [TradeItem]
} 