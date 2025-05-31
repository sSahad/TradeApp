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
        
        // When & Then - Test the actual formatting behavior
        let result1 = viewModel.formatPrice(50000.123)
        let result2 = viewModel.formatPrice(50000.567) 
        let result3 = viewModel.formatPrice(50000.0)
        
        // Verify results are properly formatted strings (not nil or empty)
        XCTAssertFalse(result1.isEmpty)
        XCTAssertFalse(result2.isEmpty)
        XCTAssertFalse(result3.isEmpty)
        
        // Test that the formatting is consistent
        XCTAssertTrue(result1.contains("50000"))
        XCTAssertTrue(result2.contains("50000"))
        XCTAssertTrue(result3.contains("50000"))
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
        
        // When & Then - Test that methods return valid formatted strings
        let priceResult = viewModel.formatPrice(50000.567)
        let qtyResult = viewModel.formatQty(1.2345)
        let timeResult = viewModel.formatTime(trade)
        
        // Verify results are valid formatted strings
        XCTAssertFalse(priceResult.isEmpty)
        XCTAssertFalse(qtyResult.isEmpty)
        XCTAssertFalse(timeResult.isEmpty)
        
        // Test specific expected behavior
        XCTAssertTrue(priceResult.contains("50000"))
        XCTAssertTrue(qtyResult.contains("1.2345"))
        XCTAssertTrue(timeResult.contains(":")) // Should contain time separators
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
        
        // When - Test connecting state (immediate check, no async wait)
        webSocketManager.connect()
        
        // Then - Should immediately change to connecting
        XCTAssertEqual(webSocketManager.connectionStatusPublisher.value, .connecting)
        
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
        // Use prices close to market range to pass filtering
        let initialBuyOrder = OrderBookItem(id: 1, symbol: "XBTUSD", side: "Buy", size: 100.0, price: 103000.0)
        let initialSellOrder = OrderBookItem(id: 2, symbol: "XBTUSD", side: "Sell", size: 100.0, price: 103100.0)
        orderBookState.updateOrders(with: [initialBuyOrder, initialSellOrder], action: "partial")
        
        // New order with price close to market price
        let newBuyOrder = OrderBookItem(id: 3, symbol: "XBTUSD", side: "Buy", size: 150.0, price: 102950.0)
        
        // When
        orderBookState.updateOrders(with: [newBuyOrder], action: "insert")
        
        // Then - Should contain both original orders since they're in the same price range
        XCTAssertEqual(orderBookState.buyOrders.count, 2)
        XCTAssertTrue(orderBookState.buyOrders.contains { $0.id == 1 })
        XCTAssertTrue(orderBookState.buyOrders.contains { $0.id == 3 })
    }
    
    func test_OrderBookState_UpdateWithDeleteAction() {
        // Given
        var orderBookState = OrderBookState()
        // Use prices close to market range to pass filtering
        let buyOrder1 = OrderBookItem(id: 1, symbol: "XBTUSD", side: "Buy", size: 100.0, price: 103000.0)
        let buyOrder2 = OrderBookItem(id: 2, symbol: "XBTUSD", side: "Buy", size: 150.0, price: 102950.0)
        let sellOrder = OrderBookItem(id: 3, symbol: "XBTUSD", side: "Sell", size: 100.0, price: 103100.0)
        orderBookState.updateOrders(with: [buyOrder1, buyOrder2, sellOrder], action: "partial")
        
        // Ensure we have orders before deletion
        XCTAssertEqual(orderBookState.buyOrders.count, 2)
        
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

// MARK: - DIContainer Tests

extension TradeAppTests {
    
    func test_DIContainer_SharedInstance() {
        // Given & When
        let container1 = DIContainer.shared
        let container2 = DIContainer.shared
        
        // Then
        XCTAssertTrue(container1 === container2)
    }
    
    func test_DIContainer_MakeOrderBookViewModel() {
        // Given
        let container = DIContainer.shared
        
        // When
        let viewModel = container.makeOrderBookViewModel()
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertEqual(viewModel.connectionStatus, .disconnected)
    }
    
    func test_DIContainer_MakeTradeViewModel() {
        // Given
        let container = DIContainer.shared
        
        // When
        let viewModel = container.makeTradeViewModel()
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertEqual(viewModel.connectionStatus, .disconnected)
    }
    
    func test_DIContainer_GetWebSocketService() {
        // Given
        let container = DIContainer.shared
        
        // When
        let service = container.getWebSocketService()
        
        // Then
        XCTAssertNotNil(service)
        XCTAssertEqual(service.connectionStatusPublisher.value, .disconnected)
    }
    
    func test_DIContainer_GetNetworkMonitor() {
        // Given
        let container = DIContainer.shared
        
        // When
        let monitor = container.getNetworkMonitor()
        
        // Then
        XCTAssertNotNil(monitor)
    }
}

// MARK: - NetworkMonitor Tests

extension TradeAppTests {
    
    func test_NetworkMonitor_InitialState() {
        // Given & When
        let networkMonitor = NetworkMonitor()
        
        // Then
        XCTAssertNotNil(networkMonitor)
        // Note: isConnected state depends on actual network, so we just verify the object exists
    }
    
    func test_NetworkMonitor_ConnectionDescription() {
        // Given
        let networkMonitor = NetworkMonitor()
        
        // When
        let description = networkMonitor.connectionDescription
        
        // Then
        XCTAssertFalse(description.isEmpty)
        // Should be one of the expected states
        let validDescriptions = ["No Internet", "WiFi", "Cellular", "Ethernet", "Connected"]
        XCTAssertTrue(validDescriptions.contains(description))
    }
}

// MARK: - FormattingUseCase Tests

extension TradeAppTests {
    
    func test_FormattingUseCase_FormatPrice() {
        // Given
        let formattingUseCase = FormattingUseCase()
        
        // When & Then
        let result1 = formattingUseCase.formatPrice(50000.123)
        let result2 = formattingUseCase.formatPrice(0.0)
        let result3 = formattingUseCase.formatPrice(-1000.567)
        
        XCTAssertFalse(result1.isEmpty)
        XCTAssertFalse(result2.isEmpty)
        XCTAssertFalse(result3.isEmpty)
    }
    
    func test_FormattingUseCase_FormatSize() {
        // Given
        let formattingUseCase = FormattingUseCase()
        
        // When & Then
        let millionResult = formattingUseCase.formatSize(1500000.0)
        let thousandResult = formattingUseCase.formatSize(1500.0)
        let decimalResult = formattingUseCase.formatSize(1.2345)
        let smallResult = formattingUseCase.formatSize(0.1234)
        
        XCTAssertTrue(millionResult.contains("M"))
        XCTAssertTrue(thousandResult.contains("K"))
        XCTAssertTrue(decimalResult.contains("1.2345"))
        XCTAssertTrue(smallResult.contains("0.1234"))
    }
    
    func test_FormattingUseCase_VolumePercentage() {
        // Given
        let formattingUseCase = FormattingUseCase()
        let orderBookItem = OrderBookItem(id: 1, symbol: "XBTUSD", side: "Buy", size: 50.0, price: 50000.0)
        
        // When & Then
        XCTAssertEqual(formattingUseCase.volumePercentage(for: orderBookItem, maxVolume: 100.0), 0.5)
        XCTAssertEqual(formattingUseCase.volumePercentage(for: orderBookItem, maxVolume: 0.0), 0.0)
    }
}

// MARK: - ConnectionStatus Tests

extension TradeAppTests {
    
    func test_ConnectionStatus_Equality() {
        // Given & When & Then
        XCTAssertEqual(ConnectionStatus.connected, ConnectionStatus.connected)
        XCTAssertEqual(ConnectionStatus.connecting, ConnectionStatus.connecting)
        XCTAssertEqual(ConnectionStatus.disconnected, ConnectionStatus.disconnected)
        XCTAssertEqual(ConnectionStatus.noInternet, ConnectionStatus.noInternet)
        XCTAssertEqual(ConnectionStatus.error("test"), ConnectionStatus.error("test"))
        
        XCTAssertNotEqual(ConnectionStatus.connected, ConnectionStatus.connecting)
        XCTAssertNotEqual(ConnectionStatus.error("test1"), ConnectionStatus.error("test2"))
    }
}

// MARK: - Async Tests

extension TradeAppTests {
    
    @MainActor
    func test_OrderBookViewModel_AsyncRefresh() async {
        // Given
        let mockWebSocketService = MockWebSocketService()
        let mockRepository = MockOrderBookRepository()
        let mockFormattingUseCase = FormattingUseCase()
        let orderBookUseCase = OrderBookUseCase(repository: mockRepository, webSocketService: mockWebSocketService)
        let viewModel = OrderBookViewModel(orderBookUseCase: orderBookUseCase, formattingUseCase: mockFormattingUseCase)
        
        // When
        viewModel.refresh()
        
        // Then - Should complete without error
        XCTAssertNotNil(viewModel)
    }
    
    @MainActor
    func test_TradeViewModel_AsyncRefresh() async {
        // Given
        let mockWebSocketService = MockWebSocketService()
        let mockRepository = MockTradeRepository()
        let mockFormattingUseCase = FormattingUseCase()
        let tradeUseCase = TradeUseCase(repository: mockRepository, webSocketService: mockWebSocketService)
        let viewModel = TradeViewModel(tradeUseCase: tradeUseCase, formattingUseCase: mockFormattingUseCase)
        
        // When
        viewModel.refresh()
        
        // Then - Should complete without error
        XCTAssertNotNil(viewModel)
    }
}

// MARK: - Error Handling Tests

extension TradeAppTests {
    
    func test_OrderBookItem_JSONDecoding_MissingFields() {
        // Given
        let jsonMissingSize = """
        {
            "id": 12345,
            "symbol": "XBTUSD",
            "side": "Buy",
            "price": 50000.0
        }
        """
        let data = jsonMissingSize.data(using: .utf8)!
        
        // When & Then
        XCTAssertNoThrow(try JSONDecoder().decode(OrderBookItem.self, from: data))
    }
    
    func test_TradeItem_JSONDecoding_AllFields() throws {
        // Given
        let json = """
        {
            "timestamp": "2024-01-01T12:00:00.000Z",
            "symbol": "XBTUSD",
            "side": "Sell",
            "size": 0.5,
            "price": 49999.5,
            "trdMatchID": "trade456",
            "grossValue": 1000.0,
            "homeNotional": 0.5,
            "foreignNotional": 24999.75
        }
        """
        let data = json.data(using: .utf8)!
        
        // When
        let tradeItem = try JSONDecoder().decode(TradeItem.self, from: data)
        
        // Then
        XCTAssertEqual(tradeItem.symbol, "XBTUSD")
        XCTAssertEqual(tradeItem.side, "Sell")
        XCTAssertEqual(tradeItem.size, 0.5)
        XCTAssertEqual(tradeItem.price, 49999.5)
        XCTAssertEqual(tradeItem.trdMatchID, "trade456")
        XCTAssertEqual(tradeItem.grossValue, 1000.0)
        XCTAssertEqual(tradeItem.homeNotional, 0.5)
        XCTAssertEqual(tradeItem.foreignNotional, 24999.75)
        XCTAssertFalse(tradeItem.isBuy)
        XCTAssertTrue(tradeItem.isSell)
    }
}
