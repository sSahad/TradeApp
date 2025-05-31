//
//  WebSocketManager.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation
import Combine

class WebSocketManager: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    
    // Publishers for data streams
    let orderBookPublisher = PassthroughSubject<BitMEXOrderBookResponse, Never>()
    let tradePublisher = PassthroughSubject<BitMEXTradeResponse, Never>()
    let connectionStatusPublisher = CurrentValueSubject<ConnectionStatus, Never>(.disconnected)
    
    enum ConnectionStatus: Equatable {
        case connecting
        case connected
        case disconnected
        case error(String)
    }
    
    init() {
        self.urlSession = URLSession(configuration: .default)
    }
    
    deinit {
        disconnect()
    }
    
    // MARK: - Connection Management
    
    func connect() {
        guard let url = URL(string: Constants.webSocketURL) else {
            connectionStatusPublisher.send(.error("Invalid WebSocket URL"))
            return
        }
        
        connectionStatusPublisher.send(.connecting)
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Start listening for messages
        receiveMessages()
        
        // Subscribe to required topics after connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.subscribeToTopics()
        }
        
        connectionStatusPublisher.send(.connected)
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionStatusPublisher.send(.disconnected)
    }
    
    // MARK: - Message Handling
    
    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessages() // Continue listening
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self?.connectionStatusPublisher.send(.error(error.localizedDescription))
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseJSONMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseJSONMessage(text)
            }
        @unknown default:
            print("Unknown message type received")
        }
    }
    
    private func parseJSONMessage(_ jsonString: String) {
        // Add debugging to see what we're receiving
        print("📡 Received WebSocket message: \(jsonString)")
        
        guard let data = jsonString.data(using: .utf8) else { 
            print("❌ Failed to convert message to data")
            return 
        }
        
        do {
            // First, try to parse as a generic response to see the structure
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("📋 Message structure: \(json)")
                
                // Check if it's a table response
                if let table = json["table"] as? String {
                    if table == "orderBookL2" {
                        // Try to parse as order book response
                        if let orderBookResponse = try? JSONDecoder().decode(BitMEXOrderBookResponse.self, from: data) {
                            print("✅ Successfully parsed orderBookL2: \(orderBookResponse.data.count) items")
                            DispatchQueue.main.async {
                                self.orderBookPublisher.send(orderBookResponse)
                            }
                        } else {
                            print("❌ Failed to decode orderBookL2 response")
                        }
                    } else if table == "trade" {
                        // Try to parse as trade response
                        if let tradeResponse = try? JSONDecoder().decode(BitMEXTradeResponse.self, from: data) {
                            print("✅ Successfully parsed trade: \(tradeResponse.data.count) items")
                            DispatchQueue.main.async {
                                self.tradePublisher.send(tradeResponse)
                            }
                        } else {
                            print("❌ Failed to decode trade response")
                        }
                    }
                } else {
                    // Handle system messages
                    handleSystemMessage(jsonString)
                }
            }
        } catch {
            print("❌ JSON parsing error: \(error)")
            handleSystemMessage(jsonString)
        }
    }
    
    private func handleSystemMessage(_ message: String) {
        // Handle system messages like heartbeat, info, welcome, etc.
        if message.contains("\"info\"") {
            print("BitMEX info: \(message)")
        } else if message.contains("\"success\"") {
            print("BitMEX success: \(message)")
        } else if message.contains("\"error\"") {
            print("BitMEX error: \(message)")
            connectionStatusPublisher.send(.error("BitMEX API error"))
        }
    }
    
    // MARK: - Subscription Management
    
    private func subscribeToTopics() {
        let subscriptionMessage: [String: Any] = [
            "op": "subscribe",
            "args": [Constants.orderBookTopic, Constants.tradeTopic]
        ]
        
        sendJSONMessage(subscriptionMessage)
    }
    
    private func sendMessage<T: Codable>(_ message: T) {
        do {
            let data = try JSONEncoder().encode(message)
            let string = String(data: data, encoding: .utf8) ?? ""
            
            webSocketTask?.send(.string(string)) { error in
                if let error = error {
                    print("WebSocket send error: \(error)")
                    self.connectionStatusPublisher.send(.error(error.localizedDescription))
                }
            }
        } catch {
            print("Failed to encode message: \(error)")
        }
    }
    
    private func sendJSONMessage(_ message: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: [])
            let string = String(data: data, encoding: .utf8) ?? ""
            
            webSocketTask?.send(.string(string)) { error in
                if let error = error {
                    print("WebSocket send error: \(error)")
                    self.connectionStatusPublisher.send(.error(error.localizedDescription))
                }
            }
        } catch {
            print("Failed to serialize JSON message: \(error)")
        }
    }
    
    // MARK: - Public Interface
    
    func reconnect() {
        disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.connect()
        }
    }
    
    var isConnected: Bool {
        return webSocketTask?.state == .running
    }
} 
