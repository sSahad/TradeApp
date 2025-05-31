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
    
    var networkStatusPublisher: AnyPublisher<Bool, Never> {
        $isConnected.eraseToAnyPublisher()
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
                let wasConnected = self?.isConnected ?? false
                
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
                
                // Only log changes to avoid spam
                if wasConnected != isConnected {
                    print("🌐 NetworkMonitor: Status changed to \(isConnected ? "Connected" : "Disconnected")")
                    if let connectionType = self?.connectionType {
                        print("📶 Connection type: \(connectionType)")
                    }
                }
            }
        }
        
        monitor.start(queue: queue)
        
        // Get initial state immediately
        DispatchQueue.main.async {
            let currentPath = self.monitor.currentPath
            self.isConnected = currentPath.status == .satisfied
            self.isConnectedSubject.send(self.isConnected)
            print("🌐 NetworkMonitor: Started monitoring, initial status: \(self.isConnected ? "Connected" : "Disconnected")")
        }
    }
    
    @MainActor
    func startMonitoringAsync() async {
        startMonitoring()
        
        // Give it a brief moment to establish initial connection state
        try? await Task.sleep(for: .milliseconds(50))
    }
    
    func stopMonitoring() {
        monitor.cancel()
        print("🌐 NetworkMonitor: Stopped monitoring")
    }
    
    @MainActor
    func stopMonitoringAsync() async {
        stopMonitoring()
        
        // Brief delay to ensure clean stop
        try? await Task.sleep(for: .milliseconds(50))
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