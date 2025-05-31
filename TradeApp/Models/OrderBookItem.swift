//
//  OrderBookItem.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation

struct OrderBookItem: Codable, Identifiable, Hashable {
    let id: Int64
    let symbol: String
    let side: String
    let size: Double?
    let price: Double?
    
    var isBuy: Bool {
        return side == "Buy"
    }
    
    var isSell: Bool {
        return side == "Sell"
    }
    
    var actualSize: Double {
        return size ?? 0.0
    }
    
    var actualPrice: Double {
        return price ?? 0.0
    }
    
    // For API response mapping
    private enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case side
        case size
        case price
    }
    
    // Custom initializer for manual creation
    init(id: Int64, symbol: String, side: String, size: Double?, price: Double?) {
        self.id = id
        self.symbol = symbol
        self.side = side
        self.size = size
        self.price = price
    }
    
    // Decoder initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.symbol = try container.decode(String.self, forKey: .symbol)
        self.side = try container.decode(String.self, forKey: .side)
        self.size = try container.decodeIfPresent(Double.self, forKey: .size)
        self.price = try container.decodeIfPresent(Double.self, forKey: .price)
    }
    
    // Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable implementation
    static func == (lhs: OrderBookItem, rhs: OrderBookItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// BitMEX WebSocket Response Structure
struct BitMEXOrderBookResponse: Codable {
    let table: String
    let action: String
    let data: [OrderBookItem]
}

// Processed order book state
struct OrderBookState {
    var buyOrders: [OrderBookItem] = []
    var sellOrders: [OrderBookItem] = []
    
    mutating func updateOrders(with items: [OrderBookItem], action: String) {
        switch action {
        case "partial":
            print("🔄 Processing \(items.count) order book items")
            
            // Initial data load with filtering for reasonable prices
            let allBuys = items.filter { $0.isBuy && $0.actualPrice > 0 }.sorted { $0.actualPrice > $1.actualPrice }
            let allSells = items.filter { $0.isSell && $0.actualPrice > 0 }.sorted { $0.actualPrice < $1.actualPrice }
            
            print("📊 Raw data: \(allBuys.count) buys, \(allSells.count) sells")
            print("💰 Price range - Buys: \(allBuys.first?.actualPrice ?? 0) to \(allBuys.last?.actualPrice ?? 0)")
            print("💰 Price range - Sells: \(allSells.first?.actualPrice ?? 0) to \(allSells.last?.actualPrice ?? 0)")
            
            // Find reasonable price range around current market price
            if let topBuy = allBuys.first, let topSell = allSells.first {
                let midPrice = (topBuy.actualPrice + topSell.actualPrice) / 2
                let priceRange = midPrice * 0.05 // 5% range around mid price
                
                print("📈 Mid price: \(midPrice), range: ±\(priceRange)")
                
                buyOrders = allBuys.filter { abs($0.actualPrice - midPrice) <= priceRange }.prefix(Constants.maxOrderBookItems).map { $0 }
                sellOrders = allSells.filter { abs($0.actualPrice - midPrice) <= priceRange }.prefix(Constants.maxOrderBookItems).map { $0 }
                
                print("✅ Filtered: \(buyOrders.count) buys, \(sellOrders.count) sells")
            } else {
                // Fallback: just take the closest orders to a reasonable price range
                buyOrders = allBuys.filter { $0.actualPrice >= 90000 && $0.actualPrice <= 120000 }.prefix(Constants.maxOrderBookItems).map { $0 }
                sellOrders = allSells.filter { $0.actualPrice >= 90000 && $0.actualPrice <= 120000 }.prefix(Constants.maxOrderBookItems).map { $0 }
                
                print("⚠️ Using fallback filtering: \(buyOrders.count) buys, \(sellOrders.count) sells")
            }
        case "insert":
            // New orders
            let newBuys = items.filter { $0.isBuy }
            let newSells = items.filter { $0.isSell }
            
            buyOrders.append(contentsOf: newBuys)
            sellOrders.append(contentsOf: newSells)
            
            sortOrders()
        case "update":
            // Update existing orders
            for item in items {
                if item.isBuy {
                    if let index = buyOrders.firstIndex(where: { $0.id == item.id }) {
                        buyOrders[index] = item
                    }
                } else {
                    if let index = sellOrders.firstIndex(where: { $0.id == item.id }) {
                        sellOrders[index] = item
                    }
                }
            }
        case "delete":
            // Remove orders
            let idsToDelete = items.map { $0.id }
            buyOrders.removeAll { idsToDelete.contains($0.id) }
            sellOrders.removeAll { idsToDelete.contains($0.id) }
        default:
            break
        }
        
        limitOrders()
    }
    
    private mutating func sortOrders() {
        buyOrders.sort { $0.actualPrice > $1.actualPrice }  // Descending for buys
        sellOrders.sort { $0.actualPrice < $1.actualPrice } // Ascending for sells
    }
    
    private mutating func limitOrders() {
        if buyOrders.count > Constants.maxOrderBookItems {
            buyOrders = Array(buyOrders.prefix(Constants.maxOrderBookItems))
        }
        if sellOrders.count > Constants.maxOrderBookItems {
            sellOrders = Array(sellOrders.prefix(Constants.maxOrderBookItems))
        }
    }
} 