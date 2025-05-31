//
//  NetworkMonitor.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import Foundation
import Network
import Combine

// MARK: - Network Monitor

final class NetworkMonitor: ObservableObject {
    
    // MARK: - Properties
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = false
    @Published var connectionType: NWInterface.InterfaceType?
    
    private let isConnectedSubject = CurrentValueSubject<Bool, Never>(false)
    
    // MARK: - Public Publishers
    
    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        isConnectedSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let isConnected = path.status == .satisfied
                self?.isConnected = isConnected
                self?.isConnectedSubject.send(isConnected)
                
                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .wiredEthernet
                } else {
                    self?.connectionType = nil
                }
                
                print("🌐 Network status: \(isConnected ? "Connected" : "Disconnected")")
                if let connectionType = self?.connectionType {
                    print("📶 Connection type: \(connectionType)")
                }
            }
        }
        
        monitor.start(queue: queue)
        print("🌐 NetworkMonitor: Started monitoring")
    }
    
    func stopMonitoring() {
        monitor.cancel()
        print("🌐 NetworkMonitor: Stopped monitoring")
    }
    
    // MARK: - Utility Methods
    
    var connectionDescription: String {
        guard isConnected else { return "No Internet" }
        
        switch connectionType {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        default:
            return "Connected"
        }
    }
} 