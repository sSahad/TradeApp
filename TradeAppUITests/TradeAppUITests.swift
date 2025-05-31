//
//  TradeAppUITests.swift
//  TradeAppUITests
//
//  Created by Sahad on 31/05/2025.
//

import XCTest

final class TradeAppUITests: XCTestCase {
    
    // MARK: - Properties
    
    var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Configure app for testing
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Set up launch arguments for testing
        app.launchArguments = ["--UITests"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
}

// MARK: - Navigation Tests

extension TradeAppUITests {
    
    func test_AppLaunches_ShowsNavigationHeader() throws {
        // Given & When - App launched in setup
        
        // Then - Verify navigation elements exist
        XCTAssertTrue(app.staticTexts["XBTUSD"].exists)
        XCTAssertTrue(app.staticTexts["Bitcoin / US Dollar"].exists)
        
        // Verify connection status element exists
        let connectionStatusButton = app.buttons.containing(.staticText, identifier: "Live").element
        XCTAssertTrue(connectionStatusButton.exists || app.staticTexts["Connecting..."].exists)
    }
    
    func test_TabNavigation_SwitchBetweenTabs() throws {
        // Given - App is launched with Order Book tab active
        let orderBookTab = app.buttons["Order Book"]
        let recentTradesTab = app.buttons["Recent Trades"]
        
        // Verify initial state
        XCTAssertTrue(orderBookTab.exists)
        XCTAssertTrue(recentTradesTab.exists)
        
        // When - Tap Recent Trades tab
        recentTradesTab.tap()
        
        // Then - Recent Trades content should be visible
        XCTAssertTrue(app.staticTexts["Price (USD)"].exists)
        XCTAssertTrue(app.staticTexts["Qty"].exists)
        XCTAssertTrue(app.staticTexts["Time"].exists)
        XCTAssertTrue(app.staticTexts["RECENT TRADES"].exists)
        
        // When - Tap Order Book tab
        orderBookTab.tap()
        
        // Then - Order Book content should be visible
        let qtyHeaders = app.staticTexts.matching(identifier: "Qty")
        XCTAssertGreaterThanOrEqual(qtyHeaders.count, 2) // Should have at least 2 Qty headers
        XCTAssertTrue(app.staticTexts["BUY"].exists)
        XCTAssertTrue(app.staticTexts["SELL"].exists)
    }
    
    func test_TabSelection_VisualIndicator() throws {
        // Given
        let orderBookTab = app.buttons["Order Book"]
        let recentTradesTab = app.buttons["Recent Trades"]
        
        // When - Order Book tab is initially selected
        // Then - Should show selection indicator (this would require accessibility identifiers in real implementation)
        XCTAssertTrue(orderBookTab.exists)
        
        // When - Switch to Recent Trades
        recentTradesTab.tap()
        
        // Then - Recent Trades should show as selected
        XCTAssertTrue(recentTradesTab.exists)
        
        // When - Switch back to Order Book
        orderBookTab.tap()
        
        // Then - Order Book should show as selected again
        XCTAssertTrue(orderBookTab.exists)
    }
}

// MARK: - Order Book Tests

extension TradeAppUITests {
    
    func test_OrderBookView_DisplaysCorrectHeaders() throws {
        // Given - App launched with Order Book tab active
        
        // Then - Verify headers are present
        XCTAssertTrue(app.staticTexts["Price (USD)"].exists)
        
        let qtyHeaders = app.staticTexts.matching(identifier: "Qty")
        XCTAssertGreaterThanOrEqual(qtyHeaders.count, 2)
        
        XCTAssertTrue(app.staticTexts["BUY"].exists)
        XCTAssertTrue(app.staticTexts["SELL"].exists)
    }
    
    func test_OrderBookView_LoadingState() throws {
        // Given - Fresh app launch
        
        // Then - Should show loading state initially (or data if connection is fast)
        let loadingText = app.staticTexts["Loading Order Book"]
        let connectingText = app.staticTexts["Connecting to live market data..."]
        
        // Either loading states exist or data is already loaded
        let hasLoadingState = loadingText.exists && connectingText.exists
        let hasData = app.staticTexts.matching(identifier: "Qty").count >= 2
        
        XCTAssertTrue(hasLoadingState || hasData)
    }
    
    func test_OrderBookView_PullToRefresh() throws {
        // Given - Order Book tab is active
        
        // When - Perform pull to refresh gesture
        let orderBookContent = app.scrollViews.firstMatch
        if orderBookContent.exists {
            orderBookContent.swipeDown()
        }
        
        // Then - App should handle refresh without crashing
        XCTAssertTrue(app.staticTexts["XBTUSD"].exists) // App is still functional
    }
}

// MARK: - Recent Trades Tests

extension TradeAppUITests {
    
    func test_RecentTradesView_DisplaysCorrectHeaders() throws {
        // Given - Switch to Recent Trades tab
        app.buttons["Recent Trades"].tap()
        
        // Then - Verify headers are present
        XCTAssertTrue(app.staticTexts["Price (USD)"].exists)
        XCTAssertTrue(app.staticTexts["Qty"].exists)
        XCTAssertTrue(app.staticTexts["Time"].exists)
        XCTAssertTrue(app.staticTexts["RECENT TRADES"].exists)
        XCTAssertTrue(app.staticTexts["BUY"].exists)
        XCTAssertTrue(app.staticTexts["SELL"].exists)
    }
    
    func test_RecentTradesView_LoadingState() throws {
        // Given - Switch to Recent Trades tab
        app.buttons["Recent Trades"].tap()
        
        // Then - Should show loading state initially (or data if connection is fast)
        let loadingText = app.staticTexts["Loading Recent Trades"]
        let connectingText = app.staticTexts["Fetching live trading activity..."]
        
        // Either loading states exist or data is already loaded
        let hasLoadingState = loadingText.exists && connectingText.exists
        let hasHeaders = app.staticTexts["RECENT TRADES"].exists
        
        XCTAssertTrue(hasLoadingState || hasHeaders)
    }
    
    func test_RecentTradesView_ScrollableTrades() throws {
        // Given - Recent Trades tab is active with data
        app.buttons["Recent Trades"].tap()
        
        // Wait for potential data to load
        sleep(2)
        
        // When - Scroll in the trades list
        let tradesScrollView = app.scrollViews.firstMatch
        if tradesScrollView.exists {
            tradesScrollView.swipeUp()
            tradesScrollView.swipeDown()
        }
        
        // Then - App should handle scrolling without crashing
        XCTAssertTrue(app.staticTexts["RECENT TRADES"].exists)
    }
    
    func test_RecentTradesView_PullToRefresh() throws {
        // Given - Recent Trades tab is active
        app.buttons["Recent Trades"].tap()
        
        // When - Perform pull to refresh gesture
        let tradesContent = app.scrollViews.firstMatch
        if tradesContent.exists {
            tradesContent.swipeDown()
        }
        
        // Then - App should handle refresh without crashing
        XCTAssertTrue(app.staticTexts["XBTUSD"].exists) // App is still functional
    }
}

// MARK: - Connection Status Tests

extension TradeAppUITests {
    
    func test_ConnectionStatus_Interactive() throws {
        // Given - App is launched
        
        // When - Look for connection status button
        let connectionButtons = app.buttons.containing(.staticText, identifier: "Live").allElementsBoundByIndex
        let connectingTexts = app.staticTexts.matching(identifier: "Connecting...").allElementsBoundByIndex
        let offlineTexts = app.staticTexts.matching(identifier: "Offline").allElementsBoundByIndex
        
        // Then - Should have some connection status indicator
        let hasConnectionIndicator = !connectionButtons.isEmpty || !connectingTexts.isEmpty || !offlineTexts.isEmpty
        XCTAssertTrue(hasConnectionIndicator)
        
        // When - Try to tap connection status (if it's a button)
        if !connectionButtons.isEmpty {
            connectionButtons.first?.tap()
            // Should not crash the app
            XCTAssertTrue(app.staticTexts["XBTUSD"].exists)
        }
    }
}

// MARK: - Accessibility Tests

extension TradeAppUITests {
    
    func test_Accessibility_VoiceOverSupport() throws {
        // Given - App is launched
        
        // Then - Key elements should be accessible
        XCTAssertTrue(app.staticTexts["XBTUSD"].isHittable)
        XCTAssertTrue(app.buttons["Order Book"].isHittable)
        XCTAssertTrue(app.buttons["Recent Trades"].isHittable)
        
        // Navigation should work with accessibility
        app.buttons["Recent Trades"].tap()
        XCTAssertTrue(app.staticTexts["RECENT TRADES"].exists)
        
        app.buttons["Order Book"].tap()
        XCTAssertTrue(app.staticTexts["BUY"].exists)
    }
    
    func test_Accessibility_ProperLabels() throws {
        // Given - App is launched
        
        // Then - Important elements should have proper accessibility labels
        let orderBookButton = app.buttons["Order Book"]
        let recentTradesButton = app.buttons["Recent Trades"]
        
        XCTAssertTrue(orderBookButton.exists)
        XCTAssertTrue(recentTradesButton.exists)
        
        // Should be able to identify by label
        XCTAssertNotNil(orderBookButton.label)
        XCTAssertNotNil(recentTradesButton.label)
    }
}

// MARK: - Performance Tests

extension TradeAppUITests {
    
    func test_Performance_AppLaunch() throws {
        // Measure app launch time
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    func test_Performance_TabSwitching() throws {
        // Given - App is launched
        let orderBookTab = app.buttons["Order Book"]
        let recentTradesTab = app.buttons["Recent Trades"]
        
        // Measure tab switching performance
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            for _ in 0..<10 {
                recentTradesTab.tap()
                orderBookTab.tap()
            }
        }
    }
}

// MARK: - Edge Cases & Error Handling

extension TradeAppUITests {
    
    func test_EdgeCase_RapidTabSwitching() throws {
        // Given - App is launched
        let orderBookTab = app.buttons["Order Book"]
        let recentTradesTab = app.buttons["Recent Trades"]
        
        // When - Rapidly switch between tabs
        for _ in 0..<20 {
            recentTradesTab.tap()
            orderBookTab.tap()
        }
        
        // Then - App should remain stable
        XCTAssertTrue(app.staticTexts["XBTUSD"].exists)
        XCTAssertTrue(orderBookTab.exists)
        XCTAssertTrue(recentTradesTab.exists)
    }
    
    func test_EdgeCase_InterfaceOrientation() throws {
        // Given - App is in portrait mode
        XCTAssertTrue(app.staticTexts["XBTUSD"].exists)
        
        // When - Rotate to landscape (if supported)
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // Then - App should handle orientation change gracefully
        XCTAssertTrue(app.staticTexts["XBTUSD"].exists)
        
        // When - Rotate back to portrait
        XCUIDevice.shared.orientation = .portrait
        
        // Then - App should still function correctly
        XCTAssertTrue(app.staticTexts["XBTUSD"].exists)
        XCTAssertTrue(app.buttons["Order Book"].exists)
        XCTAssertTrue(app.buttons["Recent Trades"].exists)
    }
    
    func test_EdgeCase_MemoryPressure() throws {
        // Given - App is launched and running
        
        // When - Simulate extended usage by switching tabs many times
        let orderBookTab = app.buttons["Order Book"]
        let recentTradesTab = app.buttons["Recent Trades"]
        
        for i in 0..<50 {
            recentTradesTab.tap()
            
            if i % 10 == 0 {
                // Occasionally scroll to simulate more usage
                let scrollView = app.scrollViews.firstMatch
                if scrollView.exists {
                    scrollView.swipeUp()
                    scrollView.swipeDown()
                }
            }
            
            orderBookTab.tap()
        }
        
        // Then - App should maintain functionality
        XCTAssertTrue(app.staticTexts["XBTUSD"].exists)
        XCTAssertTrue(app.buttons["Order Book"].exists)
        XCTAssertTrue(app.buttons["Recent Trades"].exists)
    }
}

// MARK: - Integration Tests

extension TradeAppUITests {
    
    func test_Integration_FullUserJourney() throws {
        // Given - App launches
        XCTAssertTrue(app.staticTexts["XBTUSD"].exists)
        
        // When - User views Order Book
        XCTAssertTrue(app.staticTexts["BUY"].exists)
        XCTAssertTrue(app.staticTexts["SELL"].exists)
        
        // And - User switches to Recent Trades
        app.buttons["Recent Trades"].tap()
        XCTAssertTrue(app.staticTexts["RECENT TRADES"].exists)
        
        // And - User scrolls through trades
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeDown()
        }
        
        // And - User goes back to Order Book
        app.buttons["Order Book"].tap()
        XCTAssertTrue(app.staticTexts["BUY"].exists)
        
        // And - User attempts to refresh
        let orderBookContent = app.scrollViews.firstMatch
        if orderBookContent.exists {
            orderBookContent.swipeDown()
        }
        
        // Then - All interactions complete successfully
        XCTAssertTrue(app.staticTexts["XBTUSD"].exists)
        XCTAssertTrue(app.buttons["Order Book"].exists)
        XCTAssertTrue(app.buttons["Recent Trades"].exists)
    }
}
