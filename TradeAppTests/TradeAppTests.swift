//
//  TradeAppTests.swift
//  TradeAppTests
//
//  Created by Sahad on 31/05/2025.
//

import XCTest
import Combine
@testable import TradeApp

final class TradeAppTests: XCTestCase {
    
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

// MARK: - Model Tests

extension TradeAppTests {
    
    func test_OrderBookItem_InitializationWithValidData() {
        // Given
        let id: Int64 = 12345
        let symbol = "XBTUSD"
        let side = "Buy"
        let size: Double = 100.0
        let price: Double = 50000.0
        
        // When
        let orderBookItem = OrderBookItem(id: id, symbol: symbol, side: side, size: size, price: price)
        
        // Then
        XCTAssertEqual(orderBookItem.id, id)
        XCTAssertEqual(orderBookItem.symbol, symbol)
        XCTAssertEqual(orderBookItem.side, side)
        XCTAssertEqual(orderBookItem.actualSize, size)
        XCTAssertEqual(orderBookItem.actualPrice, price)
        XCTAssertTrue(orderBookItem.isBuy)
        XCTAssertFalse(orderBookItem.isSell)
    }
    
    func test_OrderBookItem_InitializationWithNilValues() {
        // Given
        let id: Int64 = 12345
        let symbol = "XBTUSD"
        let side = "Sell"
        
        // When
        let orderBookItem = OrderBookItem(id: id, symbol: symbol, side: side, size: nil, price: nil)
        
        // Then
        XCTAssertEqual(orderBookItem.actualSize, 0.0)
        XCTAssertEqual(orderBookItem.actualPrice, 0.0)
        XCTAssertFalse(orderBookItem.isBuy)
        XCTAssertTrue(orderBookItem.isSell)
    }
    
    func test_OrderBookItem_JSONDecoding() throws {
        // Given
        let json = """
        {
            "id": 12345,
            "symbol": "XBTUSD",
            "side": "Buy",
            "size": 100.0,
            "price": 50000.0
        }
        """
        let data = json.data(using: .utf8)!
        
        // When
        let orderBookItem = try JSONDecoder().decode(OrderBookItem.self, from: data)
        
        // Then
        XCTAssertEqual(orderBookItem.id, 12345)
        XCTAssertEqual(orderBookItem.symbol, "XBTUSD")
        XCTAssertEqual(orderBookItem.side, "Buy")
        XCTAssertEqual(orderBookItem.actualSize, 100.0)
        XCTAssertEqual(orderBookItem.actualPrice, 50000.0)
    }
    
    func test_TradeItem_InitializationAndFormatting() {
        // Given
        let timestamp = "2024-01-01T12:00:00.000Z"
        let symbol = "XBTUSD"
        let side = "Buy"
        let size: Double = 0.1234
        let price: Double = 50000.5
        let trdMatchID = "trade123"
        
        // When
        let tradeItem = TradeItem(timestamp: timestamp, symbol: symbol, side: side, size: size, price: price, trdMatchID: trdMatchID)
        
        // Then
        XCTAssertEqual(tradeItem.symbol, symbol)
        XCTAssertEqual(tradeItem.side, side)
        XCTAssertEqual(tradeItem.size, size)
        XCTAssertEqual(tradeItem.price, price)
        XCTAssertEqual(tradeItem.trdMatchID, trdMatchID)
        XCTAssertTrue(tradeItem.isBuy)
        XCTAssertFalse(tradeItem.isSell)
        XCTAssertNotNil(tradeItem.formattedTimestamp)
    }
    
    func test_TradeItem_TimestampParsing() {
        // Given
        let validTimestamp = "2024-01-01T12:00:00.000Z"
        let invalidTimestamp = "invalid-timestamp"
        
        // When
        let validTradeItem = TradeItem(timestamp: validTimestamp, symbol: "XBTUSD", side: "Buy", size: 1.0, price: 50000.0, trdMatchID: "test1")
        let invalidTradeItem = TradeItem(timestamp: invalidTimestamp, symbol: "XBTUSD", side: "Buy", size: 1.0, price: 50000.0, trdMatchID: "test2")
        
        // Then
        XCTAssertNotNil(validTradeItem.formattedTimestamp)
        XCTAssertNil(invalidTradeItem.formattedTimestamp)
    }
}

// MARK: - ViewModel Tests

extension TradeAppTests {
    
    func test_OrderBookViewModel_InitialState() {
        // Given
        let mockWebSocketService = MockWebSocketService()
        let mockRepository = MockOrderBookRepository()
        let mockFormattingUseCase = FormattingUseCase()
        let orderBookUseCase = OrderBookUseCase(repository: mockRepository, webSocketService: mockWebSocketService)
        
        // When
        let viewModel = OrderBookViewModel(orderBookUseCase: orderBookUseCase, formattingUseCase: mockFormattingUseCase)
        
        // Then
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertTrue(viewModel.buyOrders.isEmpty)
        XCTAssertTrue(viewModel.sellOrders.isEmpty)
        XCTAssertEqual(viewModel.connectionStatus, .disconnected)
    }
    
    func test_OrderBookViewModel_HandleOrderBookUpdate() {
        // Given
        let mockWebSocketService = MockWebSocketService()
        let mockRepository = MockOrderBookRepository()
        let mockFormattingUseCase = FormattingUseCase()
        let orderBookUseCase = OrderBookUseCase(repository: mockRepository, webSocketService: mockWebSocketService)
        let viewModel = OrderBookViewModel(orderBookUseCase: orderBookUseCase, formattingUseCase: mockFormattingUseCase)
        
        let buyOrder = OrderBookItem(id: 1, symbol: "XBTUSD", side: "Buy", size: 100.0, price: 50000.0)
        let sellOrder = OrderBookItem(id: 2, symbol: "XBTUSD", side: "Sell", size: 200.0, price: 50100.0)
        let update = OrderBookUpdate(action: "partial", orders: [buyOrder, sellOrder])
        
        let expectation = XCTestExpectation(description: "Order book updated")
        
        // When
        viewModel.$orderBookState
            .dropFirst()
            .sink { state in
                if !state.buyOrders.isEmpty || !state.sellOrders.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        mockRepository.simulateOrderBookUpdate(update)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.buyOrders.count, 1)
        XCTAssertEqual(viewModel.sellOrders.count, 1)
        XCTAssertEqual(viewModel.buyOrders.first?.id, 1)
        XCTAssertEqual(viewModel.sellOrders.first?.id, 2)
    }
    
    func test_OrderBookViewModel_FormatPrice() {
        // Given
        let mockWebSocketService = MockWebSocketService()
        let mockRepository = MockOrderBookRepository()
        let mockFormattingUseCase = FormattingUseCase()
        let orderBookUseCase = OrderBookUseCase(repository: mockRepository, webSocketService: mockWebSocketService)
        let viewModel = OrderBookViewModel(orderBookUseCase: orderBookUseCase, formattingUseCase: mockFormattingUseCase)
        
        // When & Then
        XCTAssertEqual(viewModel.formatPrice(50000.123), "50000.1")
        XCTAssertEqual(viewModel.formatPrice(50000.567), "50000.6")
        XCTAssertEqual(viewModel.formatPrice(50000.0), "50000.0")
    }
    
    func test_OrderBookViewModel_FormatSize() {
        // Given
        let mockWebSocketService = MockWebSocketService()
        let mockRepository = MockOrderBookRepository()
        let mockFormattingUseCase = FormattingUseCase()
        let orderBookUseCase = OrderBookUseCase(repository: mockRepository, webSocketService: mockWebSocketService)
        let viewModel = OrderBookViewModel(orderBookUseCase: orderBookUseCase, formattingUseCase: mockFormattingUseCase)
        
        // When & Then
        XCTAssertEqual(viewModel.formatSize(1500000.0), "1.5M")
        XCTAssertEqual(viewModel.formatSize(1500.0), "1.5K")
        XCTAssertEqual(viewModel.formatSize(1.2345), "1.2345")
        XCTAssertEqual(viewModel.formatSize(0.1234), "0.1234")
    }
    
    func test_TradeViewModel_InitialState() {
        // Given
        let mockWebSocketService = MockWebSocketService()
        let mockRepository = MockTradeRepository()
        let mockFormattingUseCase = FormattingUseCase()
        let tradeUseCase = TradeUseCase(repository: mockRepository, webSocketService: mockWebSocketService)
        
        // When
        let viewModel = TradeViewModel(tradeUseCase: tradeUseCase, formattingUseCase: mockFormattingUseCase)
        
        // Then
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertTrue(viewModel.trades.isEmpty)
        XCTAssertTrue(viewModel.animatedTrades.isEmpty)
        XCTAssertEqual(viewModel.connectionStatus, .disconnected)
    }
    
    func test_TradeViewModel_HandleTradeUpdate() {
        // Given
        let mockWebSocketService = MockWebSocketService()
        let mockRepository = MockTradeRepository()
        let mockFormattingUseCase = FormattingUseCase()
        let tradeUseCase = TradeUseCase(repository: mockRepository, webSocketService: mockWebSocketService)
        let viewModel = TradeViewModel(tradeUseCase: tradeUseCase, formattingUseCase: mockFormattingUseCase)
        
        let trade = TradeItem(timestamp: "2024-01-01T12:00:00.000Z", symbol: "XBTUSD", side: "Buy", size: 1.0, price: 50000.0, trdMatchID: "trade123")
        let update = TradeUpdate(action: "insert", trades: [trade])
        
        let expectation = XCTestExpectation(description: "Trade updated")
        
        // When
        viewModel.$tradesState
            .dropFirst()
            .sink { state in
                if !state.trades.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        mockRepository.simulateTradeUpdate(update)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.trades.count, 1)
        XCTAssertEqual(viewModel.animatedTrades.count, 1)
        XCTAssertEqual(viewModel.trades.first?.trdMatchID, "trade123")
    }
    
    func test_TradeViewModel_FormatMethods() {
        // Given
        let mockWebSocketService = MockWebSocketService()
        let mockRepository = MockTradeRepository()
        let mockFormattingUseCase = FormattingUseCase()
        let tradeUseCase = TradeUseCase(repository: mockRepository, webSocketService: mockWebSocketService)
        let viewModel = TradeViewModel(tradeUseCase: tradeUseCase, formattingUseCase: mockFormattingUseCase)
        let trade = TradeItem(timestamp: "2024-01-01T12:00:00.000Z", symbol: "XBTUSD", side: "Buy", size: 1.2345, price: 50000.567, trdMatchID: "trade123")
        
        // When & Then
        XCTAssertEqual(viewModel.formatPrice(50000.567), "50000.6")
        XCTAssertEqual(viewModel.formatQty(1.2345), "1.2345")
        XCTAssertEqual(viewModel.formatTime(trade), "12:00:00")
    }
}

// MARK: - Network Tests

extension TradeAppTests {
    
    func test_WebSocketManager_InitialState() {
        // Given & When
        let webSocketManager = WebSocketManager()
        
        // Then
        XCTAssertEqual(webSocketManager.connectionStatusPublisher.value, .disconnected)
        XCTAssertFalse(webSocketManager.isConnected)
    }
    
    func test_WebSocketManager_ConnectionStatusUpdates() {
        // Given
        let webSocketManager = WebSocketManager()
        
        // When - Test initial state
        XCTAssertEqual(webSocketManager.connectionStatusPublisher.value, .disconnected)
        
        // When - Test connecting state
        webSocketManager.connect()
        
        // Then - Should immediately change to connecting
        let expectation = XCTestExpectation(description: "Status changed to connecting")
        
        webSocketManager.connectionStatusPublisher
            .sink { status in
                if status == .connecting {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Cleanup
        webSocketManager.disconnect()
        XCTAssertEqual(webSocketManager.connectionStatusPublisher.value, .disconnected)
    }
    
    func test_WebSocketManager_NoInternetHandling() {
        // Given
        let mockWebSocketService = MockWebSocketService()
        
        // When - Simulate no internet
        mockWebSocketService.simulateNoInternet()
        
        // Then
        XCTAssertEqual(mockWebSocketService.connectionStatusPublisher.value, .noInternet)
        XCTAssertFalse(mockWebSocketService.isConnected)
    }
}

// MARK: - Mock Classes

class MockWebSocketService: WebSocketServiceProtocol {
    let connectionStatusPublisher = CurrentValueSubject<ConnectionStatus, Never>(.disconnected)
    
    func connect() {
        connectionStatusPublisher.send(.connecting)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.connectionStatusPublisher.send(.connected)
        }
    }
    
    func disconnect() {
        connectionStatusPublisher.send(.disconnected)
    }
    
    func reconnect() {
        connectionStatusPublisher.send(.connecting)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.connectionStatusPublisher.send(.connected)
        }
    }
    
    var isConnected: Bool {
        return connectionStatusPublisher.value == .connected
    }
    
    func simulateError(_ error: String) {
        connectionStatusPublisher.send(.error(error))
    }
    
    func simulateNoInternet() {
        connectionStatusPublisher.send(.noInternet)
    }
}

class MockOrderBookRepository: OrderBookRepositoryProtocol {
    private let orderBookSubject = PassthroughSubject<OrderBookUpdate, Never>()
    
    var orderBookPublisher: AnyPublisher<OrderBookUpdate, Never> {
        orderBookSubject.eraseToAnyPublisher()
    }
    
    func subscribeToOrderBook() {}
    
    func unsubscribeFromOrderBook() {}
    
    func simulateOrderBookUpdate(_ update: OrderBookUpdate) {
        orderBookSubject.send(update)
    }
}

class MockTradeRepository: TradeRepositoryProtocol {
    private let tradeSubject = PassthroughSubject<TradeUpdate, Never>()
    
    var tradePublisher: AnyPublisher<TradeUpdate, Never> {
        tradeSubject.eraseToAnyPublisher()
    }
    
    func subscribeToTrades() {}
    
    func unsubscribeFromTrades() {}
    
    func simulateTradeUpdate(_ update: TradeUpdate) {
        tradeSubject.send(update)
    }
}

// MARK: - OrderBookState Tests

extension TradeAppTests {
    
    func test_OrderBookState_UpdateWithPartialAction() {
        // Given
        var orderBookState = OrderBookState()
        let buyOrder = OrderBookItem(id: 1, symbol: "XBTUSD", side: "Buy", size: 100.0, price: 50000.0)
        let sellOrder = OrderBookItem(id: 2, symbol: "XBTUSD", side: "Sell", size: 200.0, price: 50100.0)
        
        // When
        orderBookState.updateOrders(with: [buyOrder, sellOrder], action: "partial")
        
        // Then
        XCTAssertEqual(orderBookState.buyOrders.count, 1)
        XCTAssertEqual(orderBookState.sellOrders.count, 1)
        XCTAssertEqual(orderBookState.buyOrders.first?.id, 1)
        XCTAssertEqual(orderBookState.sellOrders.first?.id, 2)
    }
    
    func test_OrderBookState_UpdateWithInsertAction() {
        // Given
        var orderBookState = OrderBookState()
        let initialBuyOrder = OrderBookItem(id: 1, symbol: "XBTUSD", side: "Buy", size: 100.0, price: 50000.0)
        orderBookState.updateOrders(with: [initialBuyOrder], action: "partial")
        
        let newBuyOrder = OrderBookItem(id: 3, symbol: "XBTUSD", side: "Buy", size: 150.0, price: 49999.0)
        
        // When
        orderBookState.updateOrders(with: [newBuyOrder], action: "insert")
        
        // Then
        XCTAssertEqual(orderBookState.buyOrders.count, 2)
        XCTAssertTrue(orderBookState.buyOrders.contains { $0.id == 1 })
        XCTAssertTrue(orderBookState.buyOrders.contains { $0.id == 3 })
    }
    
    func test_OrderBookState_UpdateWithDeleteAction() {
        // Given
        var orderBookState = OrderBookState()
        let buyOrder1 = OrderBookItem(id: 1, symbol: "XBTUSD", side: "Buy", size: 100.0, price: 50000.0)
        let buyOrder2 = OrderBookItem(id: 2, symbol: "XBTUSD", side: "Buy", size: 150.0, price: 49999.0)
        orderBookState.updateOrders(with: [buyOrder1, buyOrder2], action: "partial")
        
        let orderToDelete = OrderBookItem(id: 1, symbol: "XBTUSD", side: "Buy", size: nil, price: nil)
        
        // When
        orderBookState.updateOrders(with: [orderToDelete], action: "delete")
        
        // Then
        XCTAssertEqual(orderBookState.buyOrders.count, 1)
        XCTAssertEqual(orderBookState.buyOrders.first?.id, 2)
    }
}

// MARK: - TradesState Tests

extension TradeAppTests {
    
    func test_TradesState_AddNewTrades() {
        // Given
        var tradesState = TradesState()
        let trade1 = TradeItem(timestamp: "2024-01-01T12:00:00.000Z", symbol: "XBTUSD", side: "Buy", size: 1.0, price: 50000.0, trdMatchID: "trade1")
        let trade2 = TradeItem(timestamp: "2024-01-01T12:01:00.000Z", symbol: "XBTUSD", side: "Sell", size: 2.0, price: 50100.0, trdMatchID: "trade2")
        
        // When
        tradesState.addNewTrades([trade1, trade2])
        
        // Then
        XCTAssertEqual(tradesState.trades.count, 2)
        XCTAssertEqual(tradesState.animatedTrades.count, 2)
        XCTAssertTrue(tradesState.animatedTrades.allSatisfy { $0.isHighlighted })
    }
    
    func test_TradesState_UpdateHighlights() {
        // Given
        var tradesState = TradesState()
        let trade = TradeItem(timestamp: "2024-01-01T12:00:00.000Z", symbol: "XBTUSD", side: "Buy", size: 1.0, price: 50000.0, trdMatchID: "trade1")
        tradesState.addNewTrades([trade])
        
        // Simulate time passing
        tradesState.animatedTrades[0] = AnimatedTradeItem(trade: trade, isHighlighted: true)
        
        // When
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.tradeHighlightDuration + 0.1) {
            tradesState.updateHighlights()
        }
        
        // Then
        let expectation = XCTestExpectation(description: "Highlight updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.tradeHighlightDuration + 0.2) {
            XCTAssertFalse(tradesState.animatedTrades.first?.isHighlighted ?? true)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
