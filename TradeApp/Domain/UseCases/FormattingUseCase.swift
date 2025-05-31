//
//  FormattingUseCase.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation

// MARK: - Formatting Use Case Implementation

final class FormattingUseCase: FormattingUseCaseProtocol {
    
    // MARK: - Private Properties
    
    private lazy var priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    // MARK: - Public Methods
    
    func formatPrice(_ price: Double) -> String {
        return priceFormatter.string(from: NSNumber(value: price)) ?? String(format: "%.1f", price)
    }
    
    func formatSize(_ size: Double) -> String {
        if size >= 1000000 {
            return String(format: "%.1fM", size / 1000000)
        } else if size >= 1000 {
            return String(format: "%.1fK", size / 1000)
        } else if size >= 1.0 {
            return String(format: "%.4f", size)
        } else {
            return String(format: "%.4f", size)
        }
    }
    
    func formatTime(_ trade: TradeItem) -> String {
        guard let date = trade.formattedTimestamp else { return "N/A" }
        return timeFormatter.string(from: date)
    }
    
    func formatQty(_ size: Double) -> String {
        return String(format: "%.4f", size)
    }
    
    func volumePercentage(for item: OrderBookItem, maxVolume: Double) -> Double {
        guard maxVolume > 0 else { return 0 }
        return item.actualSize / maxVolume
    }
    
    func accumulatedVolumePercentage(for item: OrderBookItem, in orders: [OrderBookItem]) -> Double {
        guard let index = orders.firstIndex(of: item) else { return 0 }
        
        let accumulatedVolume: Double
        if item.isBuy {
            // For buy orders, accumulate from top (highest price)
            accumulatedVolume = orders.prefix(index + 1).reduce(0) { $0 + $1.actualSize }
        } else {
            // For sell orders, accumulate from top (lowest price)
            accumulatedVolume = orders.prefix(index + 1).reduce(0) { $0 + $1.actualSize }
        }
        
        let totalVolume = orders.reduce(0) { $0 + $1.actualSize }
        guard totalVolume > 0 else { return 0 }
        
        return accumulatedVolume / totalVolume
    }
} 