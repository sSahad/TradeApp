//
//  TradeItem.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation

struct TradeItem: Codable, Identifiable, Hashable {
    let id = UUID()
    let timestamp: String
    let symbol: String
    let side: String
    let size: Double
    let price: Double
    let trdMatchID: String
    let grossValue: Double?
    let homeNotional: Double?
    let foreignNotional: Double?
    
    var isBuy: Bool {
        return side == "Buy"
    }
    
    var isSell: Bool {
        return side == "Sell"
    }
    
    var formattedTimestamp: Date? {
        // BitMEX typically sends timestamps in ISO8601 format
        // Try multiple formatters to handle different timestamp formats
        
        // First try: ISO8601 with fractional seconds
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: timestamp) {
            return date
        }
        
        // Second try: ISO8601 without fractional seconds
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: timestamp) {
            return date
        }
        
        // Third try: Custom format for BitMEX timestamps
        let customFormatter = DateFormatter()
        customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        customFormatter.timeZone = TimeZone(abbreviation: "UTC")
        if let date = customFormatter.date(from: timestamp) {
            return date
        }
        
        // Fourth try: Without milliseconds
        customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        if let date = customFormatter.date(from: timestamp) {
            return date
        }
        
        // Debug: Print timestamp if parsing fails
        print("⚠️ Failed to parse timestamp: '\(timestamp)'")
        return nil
    }
    
    var timeString: String {
        guard let date = formattedTimestamp else { return "N/A" }
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    // For API response mapping
    private enum CodingKeys: String, CodingKey {
        case timestamp
        case symbol
        case side
        case size
        case price
        case trdMatchID
        case grossValue
        case homeNotional
        case foreignNotional
    }
    
    // Custom initializer for manual creation
    init(timestamp: String, symbol: String, side: String, size: Double, price: Double, trdMatchID: String, grossValue: Double? = nil, homeNotional: Double? = nil, foreignNotional: Double? = nil) {
        self.timestamp = timestamp
        self.symbol = symbol
        self.side = side
        self.size = size
        self.price = price
        self.trdMatchID = trdMatchID
        self.grossValue = grossValue
        self.homeNotional = homeNotional
        self.foreignNotional = foreignNotional
    }
    
    // Decoder initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.timestamp = try container.decode(String.self, forKey: .timestamp)
        self.symbol = try container.decode(String.self, forKey: .symbol)
        self.side = try container.decode(String.self, forKey: .side)
        self.size = try container.decode(Double.self, forKey: .size)
        self.price = try container.decode(Double.self, forKey: .price)
        self.trdMatchID = try container.decode(String.self, forKey: .trdMatchID)
        self.grossValue = try? container.decode(Double.self, forKey: .grossValue)
        self.homeNotional = try? container.decode(Double.self, forKey: .homeNotional)
        self.foreignNotional = try? container.decode(Double.self, forKey: .foreignNotional)
    }
    
    // Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(trdMatchID)
        hasher.combine(timestamp)
    }
    
    // Equatable implementation
    static func == (lhs: TradeItem, rhs: TradeItem) -> Bool {
        return lhs.trdMatchID == rhs.trdMatchID && lhs.timestamp == rhs.timestamp
    }
}

// BitMEX WebSocket Response Structure for Trades
struct BitMEXTradeResponse: Codable {
    let table: String
    let action: String
    let data: [TradeItem]
}

// Trade item with highlight state for animations
struct AnimatedTradeItem {
    let trade: TradeItem
    var isHighlighted: Bool = false
    let highlightStartTime: Date
    
    init(trade: TradeItem, isHighlighted: Bool = true) {
        self.trade = trade
        self.isHighlighted = isHighlighted
        self.highlightStartTime = Date()
    }
    
    var shouldStopHighlight: Bool {
        Date().timeIntervalSince(highlightStartTime) > Constants.tradeHighlightDuration
    }
}

// Processed trades state
struct TradesState {
    var trades: [TradeItem] = []
    var animatedTrades: [AnimatedTradeItem] = []
    
    mutating func addNewTrades(_ newTrades: [TradeItem]) {
        // Add new trades to the beginning (most recent first)
        trades.insert(contentsOf: newTrades, at: 0)
        
        // Create animated versions of new trades
        let newAnimatedTrades = newTrades.map { AnimatedTradeItem(trade: $0, isHighlighted: true) }
        animatedTrades.insert(contentsOf: newAnimatedTrades, at: 0)
        
        // Limit to maximum trades
        limitTrades()
        
        // Sort by timestamp (most recent first)
        sortTrades()
    }
    
    mutating func updateHighlights() {
        for index in animatedTrades.indices {
            if animatedTrades[index].shouldStopHighlight {
                animatedTrades[index].isHighlighted = false
            }
        }
    }
    
    private mutating func sortTrades() {
        trades.sort { trade1, trade2 in
            guard let date1 = trade1.formattedTimestamp,
                  let date2 = trade2.formattedTimestamp else {
                return false
            }
            return date1 > date2 // Most recent first
        }
        
        animatedTrades.sort { item1, item2 in
            guard let date1 = item1.trade.formattedTimestamp,
                  let date2 = item2.trade.formattedTimestamp else {
                return false
            }
            return date1 > date2 // Most recent first
        }
    }
    
    private mutating func limitTrades() {
        if trades.count > Constants.maxRecentTrades {
            trades = Array(trades.prefix(Constants.maxRecentTrades))
        }
        if animatedTrades.count > Constants.maxRecentTrades {
            animatedTrades = Array(animatedTrades.prefix(Constants.maxRecentTrades))
        }
    }
} 