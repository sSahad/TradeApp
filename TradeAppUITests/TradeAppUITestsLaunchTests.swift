//
//  TradeAppUITestsLaunchTests.swift
//  TradeAppUITests
//
//  Created by Sahad on 31/05/2025.
//

import XCTest

final class TradeAppUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func test_Launch_BasicFunctionality() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify essential elements are present after launch
        XCTAssertTrue(app.staticTexts["XBTUSD"].exists, "Main title should be visible")
        XCTAssertTrue(app.staticTexts["Bitcoin / US Dollar"].exists, "Subtitle should be visible")
        XCTAssertTrue(app.buttons["Order Book"].exists, "Order Book tab should be visible")
        XCTAssertTrue(app.buttons["Recent Trades"].exists, "Recent Trades tab should be visible")
        
        // Verify tab functionality works immediately after launch
        app.buttons["Recent Trades"].tap()
        XCTAssertTrue(app.staticTexts["RECENT TRADES"].waitForExistence(timeout: 3), "Recent Trades view should load")
        
        app.buttons["Order Book"].tap()
        XCTAssertTrue(app.staticTexts["BUY"].waitForExistence(timeout: 3), "Order Book view should load")
        
        // Take a screenshot for visual regression testing
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch State - Order Book"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func test_Launch_ConnectionStatus() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for connection status to appear
        let connectingExists = app.staticTexts["Connecting..."].waitForExistence(timeout: 2)
        let liveExists = app.staticTexts["Live"].waitForExistence(timeout: 5)
        let offlineExists = app.staticTexts["Offline"].exists
        
        // Should have some connection status
        XCTAssertTrue(connectingExists || liveExists || offlineExists, 
                     "App should show connection status")
        
        // Take screenshot of connection state
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch State - Connection Status"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func test_Launch_DarkModeAppearance() throws {
        let app = XCUIApplication()
        
        // Launch in dark mode
        app.launchArguments.append("--UITests-DarkMode")
        app.launch()
        
        // Verify app launches successfully in dark mode
        XCTAssertTrue(app.staticTexts["XBTUSD"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Order Book"].exists)
        XCTAssertTrue(app.buttons["Recent Trades"].exists)
        
        // Take screenshot for dark mode validation
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch State - Dark Mode"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func test_Launch_LandscapeOrientation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Rotate to landscape
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // Verify app adapts to landscape orientation
        XCTAssertTrue(app.staticTexts["XBTUSD"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Order Book"].exists)
        XCTAssertTrue(app.buttons["Recent Trades"].exists)
        
        // Take screenshot for landscape validation
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch State - Landscape"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Rotate back to portrait
        XCUIDevice.shared.orientation = .portrait
    }
    
    @MainActor
    func test_Launch_MemoryFootprint() throws {
        // Measure memory usage during launch
        let launchMetrics: [XCTMetric] = [XCTMemoryMetric(), XCTApplicationLaunchMetric()]
        
        measure(metrics: launchMetrics) {
            let app = XCUIApplication()
            app.launch()
            
            // Ensure app is fully loaded
            _ = app.staticTexts["XBTUSD"].waitForExistence(timeout: 5)
            
            // Perform basic navigation to ensure full initialization
            app.buttons["Recent Trades"].tap()
            _ = app.staticTexts["RECENT TRADES"].waitForExistence(timeout: 3)
            
            app.buttons["Order Book"].tap()
            _ = app.staticTexts["BUY"].waitForExistence(timeout: 3)
            
            app.terminate()
        }
    }
    
    @MainActor
    func test_Launch_RepeatedLaunches() throws {
        // Test app stability with repeated launches
        for i in 1...5 {
            let app = XCUIApplication()
            app.launch()
            
            // Verify core functionality
            XCTAssertTrue(app.staticTexts["XBTUSD"].waitForExistence(timeout: 5), 
                         "Launch \(i): Main title should appear")
            XCTAssertTrue(app.buttons["Order Book"].exists, 
                         "Launch \(i): Order Book tab should exist")
            XCTAssertTrue(app.buttons["Recent Trades"].exists, 
                         "Launch \(i): Recent Trades tab should exist")
            
            // Test basic functionality
            app.buttons["Recent Trades"].tap()
            XCTAssertTrue(app.staticTexts["RECENT TRADES"].waitForExistence(timeout: 3), 
                         "Launch \(i): Recent Trades should load")
            
            app.terminate()
        }
    }
    
    @MainActor
    func test_Launch_AccessibilityCompliance() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify key elements are accessible
        let xbtTitle = app.staticTexts["XBTUSD"]
        XCTAssertTrue(xbtTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(xbtTitle.isHittable, "Main title should be accessible")
        
        let orderBookTab = app.buttons["Order Book"]
        XCTAssertTrue(orderBookTab.exists)
        XCTAssertTrue(orderBookTab.isHittable, "Order Book tab should be accessible")
        
        let recentTradesTab = app.buttons["Recent Trades"]
        XCTAssertTrue(recentTradesTab.exists)
        XCTAssertTrue(recentTradesTab.isHittable, "Recent Trades tab should be accessible")
        
        // Test navigation with accessibility
        recentTradesTab.tap()
        let recentTradesHeader = app.staticTexts["RECENT TRADES"]
        XCTAssertTrue(recentTradesHeader.waitForExistence(timeout: 3))
        XCTAssertTrue(recentTradesHeader.isHittable, "Recent Trades header should be accessible")
    }
}
