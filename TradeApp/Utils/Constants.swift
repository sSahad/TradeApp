//
//  Constants.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation

struct Constants {
    // BitMEX WebSocket API
    static let webSocketURL = "wss://ws.bitmex.com/realtime"
    static let symbol = "XBTUSD"
    
    // Subscriptions
    static let orderBookTopic = "orderBookL2:\(symbol)"
    static let tradeTopic = "trade:\(symbol)"
    
    // UI Configuration
    static let maxOrderBookItems = 20
    static let maxRecentTrades = 30
    static let tradeHighlightDuration: Double = 0.2
    
    // Colors
    static let buyColor = "#00C851"
    static let sellColor = "#FF4444"
    static let buyHighlightColor = "#80E27E"
    static let sellHighlightColor = "#FF8A80"
} 