//
//  WebSocketServiceProtocol.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation
import Combine

// MARK: - WebSocket Service Protocol

protocol WebSocketServiceProtocol: AnyObject {
    var connectionStatusPublisher: CurrentValueSubject<ConnectionStatus, Never> { get }
    var isConnected: Bool { get }
    
    func connect()
    func disconnect()
    func reconnect()
}

// MARK: - Connection Status

enum ConnectionStatus: Equatable {
    case connecting
    case connected
    case disconnected
    case noInternet
    case error(String)
} 