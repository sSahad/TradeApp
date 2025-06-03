//
//  ContentView.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var orderBookViewModel: OrderBookViewModel
    @StateObject private var tradeViewModel: TradeViewModel
    
    private let webSocketService: WebSocketServiceProtocol
    private let networkMonitor: NetworkMonitor
    
    @State private var selectedTab: TabType = .chart
    @State private var showConnectionDetails = false
    @State private var connectionStatus: ConnectionStatus = .disconnected
    @State private var networkConnected: Bool = true // Assume connected initially
    @State private var isInitialLoading: Bool = true // Add proper loading state
    @State private var hasInitializedNetwork: Bool = false
    
    enum TabType: String, CaseIterable {
        case chart = "Chart"
        case orderBook = "Order Book"
        case recentTrades = "Recent Trades"
        
        var icon: String {
            switch self {
            case .chart: return "chart.line.uptrend.xyaxis"
            case .orderBook: return "list.bullet.rectangle"
            case .recentTrades: return "clock.arrow.circlepath"
            }
        }
    }
    
    init(diContainer: DIContainer = DIContainer.shared) {
        self.webSocketService = diContainer.getWebSocketService()
        self.networkMonitor = diContainer.getNetworkMonitor()
        self._orderBookViewModel = StateObject(wrappedValue: diContainer.makeOrderBookViewModel())
        self._tradeViewModel = StateObject(wrappedValue: diContainer.makeTradeViewModel())
    }
    
    var body: some View {
        GeometryReader { geometry in
            if isInitialLoading {
                // Proper splash screen
                splashScreen
                    .transition(.opacity)
            } else if connectionStatus == .noInternet {
                // Show no internet only when explicitly set to no internet status
                NoInternetView(onRetry: {
                    print("🔄 Try Again button pressed")
                    Task {
                        await retryConnection()
                    }
                })
                .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    // Enhanced Navigation Header
                    modernNavigationHeader
                    
                    // Enhanced Tab Control
                    modernTabControl
                    
                    // Content with smooth transitions
                    modernContentView
                }
                .background(Constants.Colors.groupedBackground)
                .ignoresSafeArea(.all, edges: .bottom)
                .transition(.opacity)
            }
        }
        .onAppear {
            setupNetworkMonitoring()
            setupConnectionStatusMonitoring()
            
            // Initialize connection with proper async handling
            Task {
                await initializeConnection()
            }
        }
        .onDisappear {
            orderBookViewModel.disconnect()
            tradeViewModel.disconnect()
            webSocketService.disconnect()
        }
        .preferredColorScheme(nil) // Respect system setting
    }
    
    private var splashScreen: some View {
        VStack(spacing: Constants.Spacing.xl) {
            Spacer()
            
            // App Logo/Icon
            VStack(spacing: Constants.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Constants.Colors.accent.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(Constants.Colors.accent)
                }
                
                VStack(spacing: Constants.Spacing.sm) {
                    Text("TradeApp")
                        .font(Constants.Typography.title)
                        .foregroundColor(Constants.Colors.primaryText)
                    
                    Text("Real-time Bitcoin Trading")
                        .font(Constants.Typography.body)
                        .foregroundColor(Constants.Colors.secondaryText)
                }
            }
            
            // Loading indicator
            VStack(spacing: Constants.Spacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(Constants.Colors.accent)
                
                Text("Initializing...")
                    .font(Constants.Typography.caption)
                    .foregroundColor(Constants.Colors.tertiaryText)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.Colors.groupedBackground)
    }
    
    private var modernNavigationHeader: some View {
        VStack(spacing: 0) {
            HStack {
                // Title with enhanced typography
                VStack(alignment: .leading, spacing: Constants.Spacing.xs) {
                    Text("XBTUSD")
                        .font(Constants.Typography.title)
                        .foregroundColor(Constants.Colors.primaryText)
                    
                    Text("Bitcoin / US Dollar")
                        .font(Constants.Typography.caption)
                        .foregroundColor(Constants.Colors.tertiaryText)
                }
                
                Spacer()
                
                // Enhanced connection status
                modernConnectionStatus
            }
            .padding(.horizontal, Constants.Spacing.md)
            .padding(.top, Constants.Spacing.md)
            .padding(.bottom, Constants.Spacing.sm)
            
            // Elegant divider
            Rectangle()
                .fill(Constants.Colors.secondaryText.opacity(0.1))
                .frame(height: 0.5)
        }
        .background(
            Constants.Colors.primaryBackground
                .shadow(color: Constants.Shadow.light, radius: 1, x: 0, y: 1)
        )
    }
    
    private var modernConnectionStatus: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showConnectionDetails.toggle()
            }
        }) {
            HStack(spacing: Constants.Spacing.xs) {
                // Animated connection indicator
                connectionIndicator
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(connectionStatusText)
                        .font(Constants.Typography.caption)
                        .foregroundColor(Constants.Colors.secondaryText)
                    
                    if showConnectionDetails {
                        Text("Tap to refresh")
                            .font(.caption2)
                            .foregroundColor(Constants.Colors.tertiaryText)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                }
            }
            .padding(.horizontal, Constants.Spacing.sm)
            .padding(.vertical, Constants.Spacing.xs)
            .background(
                Capsule()
                    .fill(Constants.Colors.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(connectionStatusColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            if connectionStatus != .connected {
                if connectionStatus == .noInternet {
                    // For no internet, just try to reconnect (it will check network first)
                    webSocketService.connect()
                } else {
                    webSocketService.reconnect()
                }
            }
        }
    }
    
    private var connectionIndicator: some View {
        Circle()
            .fill(connectionStatusColor)
            .frame(width: 8, height: 8)
            .scaleEffect(connectionStatus == .connecting ? 1.2 : 1.0)
            .animation(
                connectionStatus == .connecting ? 
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : 
                    .easeInOut(duration: 0.3),
                value: connectionStatus
            )
            .overlay(
                Circle()
                    .stroke(connectionStatusColor.opacity(0.3), lineWidth: 2)
                    .scaleEffect(connectionStatus == .connected ? 1.5 : 1.0)
                    .opacity(connectionStatus == .connected ? 0 : 1)
                    .animation(.easeOut(duration: 1.0), value: connectionStatus)
            )
    }
    
    private var connectionStatusColor: Color {
        switch connectionStatus {
        case .connected: return Constants.Colors.success
        case .connecting: return Constants.Colors.warning
        case .disconnected: return Constants.Colors.secondaryText
        case .noInternet: return Constants.Colors.error
        case .error: return Constants.Colors.error
        }
    }
    
    private var connectionStatusText: String {
        switch connectionStatus {
        case .connected: return "Live"
        case .connecting: return "Connecting..."
        case .disconnected: return "Offline"
        case .noInternet: return "No Internet"
        case .error: return "Error"
        }
    }
    
    private var modernTabControl: some View {
        HStack(spacing: 0) {
            ForEach(TabType.allCases, id: \.self) { tab in
                modernTabButton(for: tab)
            }
        }
        .background(Constants.Colors.primaryBackground)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Constants.Colors.secondaryText.opacity(0.1)),
            alignment: .bottom
        )
    }
    
    private func modernTabButton(for tab: TabType) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: Constants.Spacing.xs) {
                HStack(spacing: Constants.Spacing.xs) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedTab == tab ? Constants.Colors.accent : Constants.Colors.secondaryText)
                    
                    Text(tab.rawValue)
                        .font(Constants.Typography.caption)
                        .fontWeight(selectedTab == tab ? .semibold : .medium)
                        .foregroundColor(selectedTab == tab ? Constants.Colors.accent : Constants.Colors.secondaryText)
                }
                .padding(.vertical, Constants.Spacing.sm)
                .frame(maxWidth: .infinity)
                
                // Animated selection indicator
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(selectedTab == tab ? Constants.Colors.accent : Color.clear)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var modernContentView: some View {
        TabView(selection: $selectedTab) {
            modernChartView
                .tag(TabType.chart)
            
            modernOrderBookView
                .tag(TabType.orderBook)
            
            modernTradeView
                .tag(TabType.recentTrades)
        }
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
    }
    
    private var modernOrderBookView: some View {
        OrderBookView(viewModel: orderBookViewModel)
            .background(Constants.Colors.groupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.large))
            .padding(.horizontal, Constants.Spacing.sm)
            .shadow(color: Constants.Shadow.light, radius: 4, x: 0, y: 2)
    }
    
    private var modernTradeView: some View {
        TradeView(viewModel: tradeViewModel)
            .background(Constants.Colors.groupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.large))
            .padding(.horizontal, Constants.Spacing.sm)
            .shadow(color: Constants.Shadow.light, radius: 4, x: 0, y: 2)
    }
    
    private var modernChartView: some View {
        ChartView()
            .background(Constants.Colors.groupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.large))
            .padding(.horizontal, Constants.Spacing.sm)
            .shadow(color: Constants.Shadow.light, radius: 4, x: 0, y: 2)
    }
    
    private func setupConnectionStatusMonitoring() {
        webSocketService.connectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.connectionStatus, on: self)
            .store(in: &cancellables)
    }
    
    @MainActor
    private func initializeConnection() async {
        // Wait for network monitoring to initialize
        try? await Task.sleep(for: .milliseconds(500))
        
        self.isInitialLoading = false
        
        if self.networkConnected {
            await connectToWebSocket()
        }
    }
    
    @MainActor
    private func connectToWebSocket() async {
        print("🔌 ContentView: Starting WebSocket connection...")
        
        // Force set to connecting to show proper state
        connectionStatus = .connecting
        
        // Ensure clean state before connecting
        orderBookViewModel.disconnect()
        tradeViewModel.disconnect()
        webSocketService.disconnect()
        
        // Wait for clean disconnect
        try? await Task.sleep(for: .milliseconds(300))
        
        // Start connection
        webSocketService.connect()
        
        // Start the use cases after connection is initiated
        print("📊 ContentView: Starting OrderBook and Trade subscriptions...")
        orderBookViewModel.connect()
        tradeViewModel.connect()
    }
    
    @MainActor
    private func retryConnection() async {
        print("🔄 ContentView: Retrying connection...")
        
        // Force set to connecting immediately to show progress
        connectionStatus = .connecting
        
        // Ensure everything is disconnected and reset
        orderBookViewModel.disconnect()
        tradeViewModel.disconnect()
        webSocketService.disconnect()
        
        // Wait a moment for cleanup
        try? await Task.sleep(for: .milliseconds(500))
        
        // Force connection attempt
        await connectToWebSocket()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.networkStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { isConnected in
                let wasConnected = networkConnected
                networkConnected = isConnected
                hasInitializedNetwork = true
                
                print("🌐 Network status changed: \(isConnected ? "Connected" : "Disconnected")")
                
                // Handle network loss immediately
                if !isConnected && wasConnected {
                    print("🌐 Network lost - setting no internet status")
                    connectionStatus = .noInternet
                }
                // Handle network restoration
                else if isConnected && !wasConnected {
                    print("🌐 Network restored - clearing no internet and reconnecting")
                    // Clear no internet status immediately
                    if connectionStatus == .noInternet {
                        connectionStatus = .connecting
                    }
                    // Attempt to reconnect after brief delay
                    Task {
                        try? await Task.sleep(for: .milliseconds(500))
                        await connectToWebSocket()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

#Preview {
    ContentView()
}
