//
//  WebSocketManager.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation
import Combine

class WebSocketManager: WebSocketServiceProtocol, ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private var heartbeatTimer: Timer?
    private var hasReceivedPartial: [String: Bool] = [:] // Track which tables have received partial data
    private var networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    
    // Publishers for data streams
    let orderBookPublisher = PassthroughSubject<BitMEXOrderBookResponse, Never>()
    let tradePublisher = PassthroughSubject<BitMEXTradeResponse, Never>()
    let connectionStatusPublisher = CurrentValueSubject<ConnectionStatus, Never>(.disconnected)
    
    init(networkMonitor: NetworkMonitor = NetworkMonitor()) {
        self.urlSession = URLSession(configuration: .default)
        self.networkMonitor = networkMonitor
        setupNetworkMonitoring()
    }
    
    deinit {
        disconnect()
        heartbeatTimer?.invalidate()
        networkMonitor.stopMonitoring()
        cancellables.removeAll()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.isConnectedPublisher
            .sink { [weak self] isConnected in
                if !isConnected {
                    print("🌐 Network lost - setting no internet status")
                    self?.connectionStatusPublisher.send(.noInternet)
                    self?.disconnect() // Disconnect WebSocket when no internet
                } else {
                    print("🌐 Network restored - attempting reconnection")
                    // Only auto-reconnect if we were previously connected
                    if self?.connectionStatusPublisher.value == .noInternet {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self?.connect()
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Connection Management
    
    func connect() {
        // Prevent multiple simultaneous connection attempts
        guard connectionStatusPublisher.value != .connecting else {
            print("🔄 Connection already in progress, skipping...")
            return
        }
        
        // Check internet connectivity first
        guard networkMonitor.isConnected else {
            print("🌐 No internet connection available")
            connectionStatusPublisher.send(.noInternet)
            return
        }
        
        guard let url = URL(string: Constants.webSocketURL) else {
            connectionStatusPublisher.send(.error("Invalid WebSocket URL"))
            return
        }
        
        print("🔌 WebSocketManager: Starting connection to \(url)")
        connectionStatusPublisher.send(.connecting)
        
        // Reset partial data tracking
        hasReceivedPartial = [:]
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Start listening for messages
        receiveMessages()
        
        // Subscribe to required topics after a short delay to ensure connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("📡 WebSocketManager: Subscribing to topics...")
            self.subscribeToTopics()
        }
        
        // Start heartbeat after connection
        startHeartbeat()
    }
    
    func disconnect() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        hasReceivedPartial = [:]
        connectionStatusPublisher.send(.disconnected)
        print("🔌 WebSocketManager: Disconnected")
    }
    
    // MARK: - Message Handling
    
    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessages() // Continue listening
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self?.connectionStatusPublisher.send(.error(error.localizedDescription))
                
                // Clean up and attempt to reconnect after a delay
                self?.heartbeatTimer?.invalidate()
                self?.heartbeatTimer = nil
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self?.reconnect()
                }
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
        guard let data = jsonString.data(using: .utf8) else { 
            print("❌ Failed to convert message to data")
            return 
        }
        
        do {
            // First, try to parse as a generic response to see the structure
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                
                // Handle table data responses
                if let table = json["table"] as? String,
                   let action = json["action"] as? String {
                    
                    print("📡 Received \(table) with action: \(action)")
                    
                    // Handle partial data - this is the initial table image
                    if action == "partial" {
                        hasReceivedPartial[table] = true
                        print("✅ Received partial data for \(table)")
                        
                        // Set connected status when we receive our first partial
                        if connectionStatusPublisher.value == .connecting {
                            connectionStatusPublisher.send(.connected)
                            print("🎉 WebSocket connection established successfully")
                        }
                    }
                    
                    // Only process messages after we've received the partial for this table
                    guard hasReceivedPartial[table] == true else {
                        print("⏳ Ignoring \(table) message before receiving partial")
                        return
                    }
                    
                    // Parse specific table types
                    if table == "orderBookL2_25" || table == "orderBookL2" {
                        if let orderBookResponse = try? JSONDecoder().decode(BitMEXOrderBookResponse.self, from: data) {
                            print("✅ Processing \(table): \(orderBookResponse.data.count) items")
                            DispatchQueue.main.async {
                                self.orderBookPublisher.send(orderBookResponse)
                            }
                        } else {
                            print("❌ Failed to decode \(table) response")
                        }
                    } else if table == "trade" {
                        if let tradeResponse = try? JSONDecoder().decode(BitMEXTradeResponse.self, from: data) {
                            print("✅ Processing trade: \(tradeResponse.data.count) items")
                            DispatchQueue.main.async {
                                self.tradePublisher.send(tradeResponse)
                            }
                        } else {
                            print("❌ Failed to decode trade response")
                        }
                    }
                    
                } else {
                    // Handle system messages (success, error, info, etc.)
                    handleSystemMessage(json, jsonString)
                }
            }
        } catch {
            print("❌ JSON parsing error: \(error)")
            handleSystemMessage([:], jsonString)
        }
    }
    
    private func handleSystemMessage(_ json: [String: Any], _ message: String) {
        // Handle subscription success
        if let success = json["success"] as? Bool, success == true {
            if let subscribe = json["subscribe"] as? String {
                print("✅ Successfully subscribed to: \(subscribe)")
            }
        }
        
        // Handle errors
        else if let error = json["error"] as? String {
            print("❌ BitMEX error: \(error)")
            
            // Handle rate limiting
            if let status = json["status"] as? Int, status == 429 {
                if let retryAfter = json["meta"] as? [String: Any],
                   let retrySeconds = retryAfter["retryAfter"] as? Int {
                    print("⏳ Rate limited, retrying in \(retrySeconds) seconds")
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(retrySeconds)) {
                        self.subscribeToTopics()
                    }
                    return
                }
            }
            
            // Handle server busy
            else if let status = json["status"] as? Int, status == 503 {
                print("🔄 Server busy, retrying subscription in 1 second")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.subscribeToTopics()
                }
                return
            }
            
            connectionStatusPublisher.send(.error(error))
        }
        
        // Handle welcome message
        else if let info = json["info"] as? String {
            print("ℹ️ BitMEX: \(info)")
            if info.contains("Welcome") {
                print("🎉 Connected to BitMEX WebSocket API")
            }
        }
        
        // Handle pong responses
        else if message.trimmingCharacters(in: .whitespacesAndNewlines) == "pong" {
            print("🏓 Received pong from server")
        }
        
        // Log other messages for debugging
        else {
            print("📨 Other message: \(message)")
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
        // Prevent multiple simultaneous reconnection attempts
        guard connectionStatusPublisher.value != .connecting else {
            print("🔄 Reconnection already in progress, skipping...")
            return
        }
        
        print("🔄 WebSocketManager: Initiating reconnection...")
        disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.connect()
        }
    }
    
    var isConnected: Bool {
        return webSocketTask?.state == .running
    }
    
    // MARK: - Heartbeat Management
    
    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    private func sendHeartbeat() {
        guard webSocketTask?.state == .running else { return }
        
        webSocketTask?.send(.string("ping")) { error in
            if let error = error {
                print("❌ Heartbeat error: \(error)")
            } else {
                print("🏓 Sent ping to server")
            }
        }
    }
} 
