//
//  Constants.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation
import SwiftUI

struct Constants {
    // BitMEX WebSocket API
    static let webSocketURL = "wss://ws.bitmex.com/realtime"
    static let symbol = "XBTUSD"
    
    // Subscriptions (using orderBookL2_25 for better performance as recommended by BitMEX)
    static let orderBookTopic = "orderBookL2_25:\(symbol)"
    static let tradeTopic = "trade:\(symbol)"
    
    // UI Configuration
    static let maxOrderBookItems = 20
    static let maxRecentTrades = 30
    static let tradeHighlightDuration: Double = 0.2
    
    // Enhanced Color System
    struct Colors {
        // Buy/Sell Colors (Adaptive)
        static let buyPrimary = Color("BuyPrimary")
        static let buySecondary = Color("BuySecondary")
        static let buyBackground = Color("BuyBackground")
        
        static let sellPrimary = Color("SellPrimary")
        static let sellSecondary = Color("SellSecondary")
        static let sellBackground = Color("SellBackground")
        
        // System Colors
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color(UIColor.tertiaryLabel)
        
        static let cardBackground = Color(UIColor.secondarySystemBackground)
        static let groupedBackground = Color(UIColor.systemGroupedBackground)
        static let primaryBackground = Color(UIColor.systemBackground)
        
        // Status Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Accent Colors
        static let accent = Color.accentColor
        static let highlight = Color("Highlight")
    }
    
    // Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title2.weight(.semibold)
        static let headline = Font.headline.weight(.medium)
        static let body = Font.body
        static let caption = Font.caption
        static let monospaced = Font.system(.body, design: .monospaced)
        static let monospacedSmall = Font.system(.caption, design: .monospaced)
    }
    
    // Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    // Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }
    
    // Shadows
    struct Shadow {
        static let light = Color.black.opacity(0.05)
        static let medium = Color.black.opacity(0.1)
        static let heavy = Color.black.opacity(0.2)
    }
    
    // Legacy Colors (for compatibility)
    static let buyColor = "#00C851"
    static let sellColor = "#FF4444"
    static let buyHighlightColor = "#80E27E"
    static let sellHighlightColor = "#FF8A80"
} 