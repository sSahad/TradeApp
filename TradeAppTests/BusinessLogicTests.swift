//
//  BusinessLogicTests.swift
//  TradeAppTests
//
//  Created by Sahad on 31/05/2025.
//

import XCTest
import Combine
@testable import TradeApp

final class BusinessLogicTests: XCTestCase {
    
    // MARK: - Properties
    
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        try super.tearDownWithError()
    }
}

// MARK: - Price Filtering Logic Tests

extension BusinessLogicTests {
    
    func test_OrderBook_PriceFiltering_ReasonablePriceRange() {
        // Given
        var orderBookState = OrderBookState()
        
        // Create orders with realistic and unrealistic prices
        let realisticBuyOrder = OrderBookItem(id: 1, symbol: "XBTUSD", side: "Buy", size: 100.0, price: 103000.0)
        let realisticSellOrder = OrderBookItem(id: 2, symbol: "XBTUSD", side: "Sell", size: 200.0, price: 103100.0)
        let unrealisticBuyOrder = OrderBookItem(id: 3, symbol: "XBTUSD", side: "Buy", size: 50.0, price: 1.0) // Too low
        let unrealisticSellOrder = OrderBookItem(id: 4, symbol: "XBTUSD", side: "Sell", size: 75.0, price: 1000000.0) // Too high
        
        let allOrders = [realisticBuyOrder, realisticSellOrder, unrealisticBuyOrder, unrealisticSellOrder]
        
        // When
        orderBookState.updateOrders(with: allOrders, action: "partial")
        
        // Then - Should filter out unrealistic prices and keep reasonable ones
        XCTAssertEqual(orderBookState.buyOrders.count, 1)
        XCTAssertEqual(orderBookState.sellOrders.count, 1)
        XCTAssertEqual(orderBookState.buyOrders.first?.id, 1)
        XCTAssertEqual(orderBookState.sellOrders.first?.id, 2)
    }
    
    func test_OrderBook_Sorting_BuyOrdersDescending() {
        // Given
        var orderBookState = OrderBookState()
        let buy1 = OrderBookItem(id: 1, symbol: "XBTUSD", side: "Buy", size: 100.0, price: 103000.0)
        let buy2 = OrderBookItem(id: 2, symbol: "XBTUSD", side: "Buy", size: 200.0, price: 103100.0) // Higher price
        let buy3 = OrderBookItem(id: 3, symbol: "XBTUSD", side: "Buy", size: 150.0, price: 102900.0) // Lower price
        
        // When
        orderBookState.updateOrders(with: [buy1, buy2, buy3], action: "partial")
        
        // Then - Buy orders should be sorted by price descending (highest first)
        XCTAssertEqual(orderBookState.buyOrders.count, 3)
        XCTAssertEqual(orderBookState.buyOrders[0].price, 103100.0) // Highest
        XCTAssertEqual(orderBookState.buyOrders[1].price, 103000.0) // Middle
        XCTAssertEqual(orderBookState.buyOrders[2].price, 102900.0) // Lowest
    }
    
    func test_OrderBook_Sorting_SellOrdersAscending() {
        // Given
        var orderBookState = OrderBookState()
        let sell1 = OrderBookItem(id: 1, symbol: "XBTUSD", side: "Sell", size: 100.0, price: 103200.0)
        let sell2 = OrderBookItem(id: 2, symbol: "XBTUSD", side: "Sell", size: 200.0, price: 103100.0) // Lower price
        let sell3 = OrderBookItem(id: 3, symbol: "XBTUSD", side: "Sell", size: 150.0, price: 103300.0) // Higher price
        
        // When
        orderBookState.updateOrders(with: [sell1, sell2, sell3], action: "partial")
        
        // Then - Sell orders should be sorted by price ascending (lowest first)
        XCTAssertEqual(orderBookState.sellOrders.count, 3)
        XCTAssertEqual(orderBookState.sellOrders[0].price, 103100.0) // Lowest
        XCTAssertEqual(orderBookState.sellOrders[1].price, 103200.0) // Middle
        XCTAssertEqual(orderBookState.sellOrders[2].price, 103300.0) // Highest
    }
}

// MARK: - Trade Animation Logic Tests

extension BusinessLogicTests {
    
    func test_TradeAnimation_HighlightDuration() {
        // Given
        let trade = TradeItem(timestamp: "2024-01-01T12:00:00.000Z", symbol: "XBTUSD", side: "Buy", size: 1.0, price: 50000.0, trdMatchID: "trade123")
        let animatedTrade = AnimatedTradeItem(trade: trade, isHighlighted: true)
        
        // When - Immediately after creation
        // Then - Should be highlighted
        XCTAssertTrue(animatedTrade.isHighlighted)
        XCTAssertFalse(animatedTrade.shouldStopHighlight) // Should not stop immediately
        
        // When - After highlight duration passes
        let expectation = XCTestExpectation(description: "Highlight should stop")
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.tradeHighlightDuration + 0.1) {
            XCTAssertTrue(animatedTrade.shouldStopHighlight)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_TradeState_SortingByTimestamp() {
        // Given
        var tradesState = TradesState()
        let trade1 = TradeItem(timestamp: "2024-01-01T12:00:00.000Z", symbol: "XBTUSD", side: "Buy", size: 1.0, price: 50000.0, trdMatchID: "trade1")
        let trade2 = TradeItem(timestamp: "2024-01-01T12:01:00.000Z", symbol: "XBTUSD", side: "Sell", size: 2.0, price: 50100.0, trdMatchID: "trade2") // Later
        let trade3 = TradeItem(timestamp: "2024-01-01T11:59:00.000Z", symbol: "XBTUSD", side: "Buy", size: 1.5, price: 49900.0, trdMatchID: "trade3") // Earlier
        
        // When
        tradesState.addNewTrades([trade1, trade2, trade3])
        
        // Then - Should be sorted with most recent first
        XCTAssertEqual(tradesState.trades.count, 3)
        XCTAssertEqual(tradesState.trades[0].trdMatchID, "trade2") // Most recent
        XCTAssertEqual(tradesState.trades[1].trdMatchID, "trade1") // Middle
        XCTAssertEqual(tradesState.trades[2].trdMatchID, "trade3") // Oldest
    }
    
    func test_TradeState_LimitMaxTrades() {
        // Given
        var tradesState = TradesState()
        var trades: [TradeItem] = []
        
        // Create more trades than the limit
        for i in 0..<(Constants.maxRecentTrades + 10) {
            let trade = TradeItem(
                timestamp: "2024-01-01T12:\(String(format: "%02d", i)):00.000Z",
                symbol: "XBTUSD",
                side: i % 2 == 0 ? "Buy" : "Sell",
                size: 1.0,
                price: 50000.0 + Double(i),
                trdMatchID: "trade\(i)"
            )
            trades.append(trade)
        }
        
        // When
        tradesState.addNewTrades(trades)
        
        // Then - Should be limited to max trades
        XCTAssertEqual(tradesState.trades.count, Constants.maxRecentTrades)
        XCTAssertEqual(tradesState.animatedTrades.count, Constants.maxRecentTrades)
    }
}

// MARK: - Formatting Logic Tests

extension BusinessLogicTests {
    
    func test_OrderBookViewModel_VolumePercentageCalculation() {
        // Given
        let mockWebSocketService = MockWebSocketService()
        let mockRepository = MockOrderBookRepository()
        let mockFormattingUseCase = FormattingUseCase()
        let orderBookUseCase = OrderBookUseCase(repository: mockRepository, webSocketService: mockWebSocketService)
        let viewModel = OrderBookViewModel(orderBookUseCase: orderBookUseCase, formattingUseCase: mockFormattingUseCase)
        
        // Set up test data directly
        let order1 = OrderBookItem(id: 1, symbol: "XBTUSD", side: "Buy", size: 100.0, price: 50000.0)
        let order2 = OrderBookItem(id: 2, symbol: "XBTUSD", side: "Buy", size: 200.0, price: 49999.0) // Max volume
        let order3 = OrderBookItem(id: 3, symbol: "XBTUSD", side: "Buy", size: 50.0, price: 49998.0)
        
        // Simulate order book state
        viewModel.orderBookState.buyOrders = [order1, order2, order3]
        
        // When & Then
        XCTAssertEqual(viewModel.volumePercentage(for: order1), 0.5) // 100/200
        XCTAssertEqual(viewModel.volumePercentage(for: order2), 1.0) // 200/200 (max)
        XCTAssertEqual(viewModel.volumePercentage(for: order3), 0.25) // 50/200
    }
    
    func test_OrderBookViewModel_AccumulatedVolumeCalculation() {
        // Given
        let mockWebSocketService = MockWebSocketService()
        let mockRepository = MockOrderBookRepository()
        let mockFormattingUseCase = FormattingUseCase()
        let orderBookUseCase = OrderBookUseCase(repository: mockRepository, webSocketService: mockWebSocketService)
        let viewModel = OrderBookViewModel(orderBookUseCase: orderBookUseCase, formattingUseCase: mockFormattingUseCase)
        
        let orders = [
            OrderBookItem(id: 1, symbol: "XBTUSD", side: "Buy", size: 100.0, price: 50000.0),
            OrderBookItem(id: 2, symbol: "XBTUSD", side: "Buy", size: 200.0, price: 49999.0),
            OrderBookItem(id: 3, symbol: "XBTUSD", side: "Buy", size: 100.0, price: 49998.0)
        ]
        // Total volume: 400
        
        // When & Then
        XCTAssertEqual(viewModel.accumulatedVolumePercentage(for: orders[0], in: orders), 0.25) // 100/400
        XCTAssertEqual(viewModel.accumulatedVolumePercentage(for: orders[1], in: orders), 0.75) // 300/400
        XCTAssertEqual(viewModel.accumulatedVolumePercentage(for: orders[2], in: orders), 1.0)  // 400/400
    }
    
    func test_TradeViewModel_TimestampFormatting() {
        // Given
        let mockWebSocketService = MockWebSocketService()
        let mockRepository = MockTradeRepository()
        let mockFormattingUseCase = FormattingUseCase()
        let tradeUseCase = TradeUseCase(repository: mockRepository, webSocketService: mockWebSocketService)
        let viewModel = TradeViewModel(tradeUseCase: tradeUseCase, formattingUseCase: mockFormattingUseCase)
        
        let validTrade = TradeItem(timestamp: "2024-01-01T15:30:45.000Z", symbol: "XBTUSD", side: "Buy", size: 1.0, price: 50000.0, trdMatchID: "valid")
        let invalidTrade = TradeItem(timestamp: "invalid-timestamp", symbol: "XBTUSD", side: "Buy", size: 1.0, price: 50000.0, trdMatchID: "invalid")
        
        // When & Then
        XCTAssertEqual(viewModel.formatTime(validTrade), "15:30:45")
        XCTAssertEqual(viewModel.formatTime(invalidTrade), "N/A")
    }
}

// MARK: - WebSocket Message Parsing Tests

extension BusinessLogicTests {
    
    func test_BitMEXOrderBookResponse_JSONDecoding() throws {
        // Given
        let json = """
        {
            "table": "orderBookL2",
            "action": "partial",
            "data": [
                {
                    "id": 12345,
                    "symbol": "XBTUSD",
                    "side": "Buy",
                    "size": 100.0,
                    "price": 50000.0
                },
                {
                    "id": 12346,
                    "symbol": "XBTUSD",
                    "side": "Sell",
                    "size": 200.0,
                    "price": 50100.0
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        
        // When
        let response = try JSONDecoder().decode(BitMEXOrderBookResponse.self, from: data)
        
        // Then
        XCTAssertEqual(response.table, "orderBookL2")
        XCTAssertEqual(response.action, "partial")
        XCTAssertEqual(response.data.count, 2)
        XCTAssertEqual(response.data[0].id, 12345)
        XCTAssertEqual(response.data[1].id, 12346)
    }
    
    func test_BitMEXTradeResponse_JSONDecoding() throws {
        // Given
        let json = """
        {
            "table": "trade",
            "action": "insert",
            "data": [
                {
                    "timestamp": "2024-01-01T12:00:00.000Z",
                    "symbol": "XBTUSD",
                    "side": "Buy",
                    "size": 0.1234,
                    "price": 50000.5,
                    "trdMatchID": "trade123"
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        
        // When
        let response = try JSONDecoder().decode(BitMEXTradeResponse.self, from: data)
        
        // Then
        XCTAssertEqual(response.table, "trade")
        XCTAssertEqual(response.action, "insert")
        XCTAssertEqual(response.data.count, 1)
        XCTAssertEqual(response.data[0].trdMatchID, "trade123")
        XCTAssertEqual(response.data[0].symbol, "XBTUSD")
    }
}

// MARK: - Edge Cases Tests

extension BusinessLogicTests {
    
    func test_OrderBookItem_EqualityAndHashing() {
        // Given
        let order1 = OrderBookItem(id: 123, symbol: "XBTUSD", side: "Buy", size: 100.0, price: 50000.0)
        let order2 = OrderBookItem(id: 123, symbol: "XBTUSD", side: "Buy", size: 200.0, price: 60000.0) // Same ID
        let order3 = OrderBookItem(id: 456, symbol: "XBTUSD", side: "Buy", size: 100.0, price: 50000.0) // Different ID
        
        // When & Then
        XCTAssertEqual(order1, order2) // Same ID means equal
        XCTAssertNotEqual(order1, order3) // Different ID means not equal
        XCTAssertEqual(order1.hashValue, order2.hashValue) // Same hash for same ID
        XCTAssertNotEqual(order1.hashValue, order3.hashValue) // Different hash for different ID
    }
    
    func test_TradeItem_EqualityAndHashing() {
        // Given
        let trade1 = TradeItem(timestamp: "2024-01-01T12:00:00.000Z", symbol: "XBTUSD", side: "Buy", size: 1.0, price: 50000.0, trdMatchID: "trade123")
        let trade2 = TradeItem(timestamp: "2024-01-01T12:00:00.000Z", symbol: "XBTUSD", side: "Sell", size: 2.0, price: 60000.0, trdMatchID: "trade123") // Same ID and timestamp
        let trade3 = TradeItem(timestamp: "2024-01-01T13:00:00.000Z", symbol: "XBTUSD", side: "Buy", size: 1.0, price: 50000.0, trdMatchID: "trade456") // Different ID and timestamp
        
        // When & Then
        XCTAssertEqual(trade1, trade2) // Same ID and timestamp means equal
        XCTAssertNotEqual(trade1, trade3) // Different ID or timestamp means not equal
    }
    
    func test_OrderBookState_EmptyDataHandling() {
        // Given
        var orderBookState = OrderBookState()
        
        // When - Process empty data
        orderBookState.updateOrders(with: [], action: "partial")
        
        // Then - Should handle gracefully
        XCTAssertTrue(orderBookState.buyOrders.isEmpty)
        XCTAssertTrue(orderBookState.sellOrders.isEmpty)
    }
    
    func test_TradeState_EmptyDataHandling() {
        // Given
        var tradesState = TradesState()
        
        // When - Add empty trades
        tradesState.addNewTrades([])
        
        // Then - Should handle gracefully
        XCTAssertTrue(tradesState.trades.isEmpty)
        XCTAssertTrue(tradesState.animatedTrades.isEmpty)
    }
    
    func test_Constants_ValuesAreReasonable() {
        // Given & When & Then - Verify constants are reasonable
        XCTAssertGreaterThan(Constants.maxOrderBookItems, 0)
        XCTAssertLessThanOrEqual(Constants.maxOrderBookItems, 100) // Not too many for UI
        
        XCTAssertGreaterThan(Constants.maxRecentTrades, 0)
        XCTAssertLessThanOrEqual(Constants.maxRecentTrades, 100) // Not too many for UI
        
        XCTAssertGreaterThan(Constants.tradeHighlightDuration, 0.0)
        XCTAssertLessThanOrEqual(Constants.tradeHighlightDuration, 5.0) // Not too long for UX
        
        XCTAssertFalse(Constants.webSocketURL.isEmpty)
        XCTAssertTrue(Constants.webSocketURL.hasPrefix("wss://"))
        
        XCTAssertFalse(Constants.symbol.isEmpty)
        XCTAssertEqual(Constants.symbol, "XBTUSD")
    }
    
    func test_ConnectionStatus_NoInternetHandling() {
        // Given
        let mockWebSocketService = MockWebSocketService()
        
        // When - Simulate no internet
        mockWebSocketService.simulateNoInternet()
        
        // Then
        XCTAssertEqual(mockWebSocketService.connectionStatusPublisher.value, .noInternet)
        XCTAssertFalse(mockWebSocketService.isConnected)
    }
}

// MARK: - Business Logic Tests use the MockWebSocketManager from TradeAppTests.swift 