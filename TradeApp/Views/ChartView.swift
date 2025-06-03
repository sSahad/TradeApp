//
//  ChartView.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import SwiftUI
import WebKit

struct ChartView: View {
    @State private var isLoading = true
    @State private var hasError = false
    
    private let chartURL = "https://www.bitmex.com/chartEmbed?symbol=XBTUSD&theme=dark-v3"
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern header
            modernHeader
            
            // Chart content
            ZStack {
                if hasError {
                    errorView
                } else {
                    VStack(spacing: 0) {
                        WebView(
                            url: URL(string: chartURL)!,
                            isLoading: $isLoading,
                            hasError: $hasError
                        )
                        .background(Constants.Colors.primaryBackground)
                        
                        if isLoading {
                            modernLoadingOverlay
                        }
                    }
                }
            }
        }
        .background(Constants.Colors.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
    }
    
    private var modernHeader: some View {
        VStack(spacing: Constants.Spacing.sm) {
            HStack {
                HStack(spacing: Constants.Spacing.xs) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Constants.Colors.accent)
                    
                    Text("Price Chart")
                        .font(Constants.Typography.headline)
                        .foregroundColor(Constants.Colors.primaryText)
                }
                
                Spacer()
                
                Text("XBTUSD")
                    .font(Constants.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Constants.Colors.secondaryText)
            }
            .padding(.horizontal, Constants.Spacing.md)
            .padding(.top, Constants.Spacing.md)
            .padding(.bottom, Constants.Spacing.sm)
        }
        .background(
            Constants.Colors.cardBackground
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Constants.Colors.secondaryText.opacity(0.1)),
                    alignment: .bottom
                )
        )
    }
    
    private var modernLoadingOverlay: some View {
        VStack(spacing: Constants.Spacing.lg) {
            ZStack {
                Circle()
                    .stroke(Constants.Colors.accent.opacity(0.2), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Constants.Colors.accent, Constants.Colors.accent.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: UUID())
            }
            
            VStack(spacing: Constants.Spacing.xs) {
                Text("Loading Chart")
                    .font(Constants.Typography.headline)
                    .foregroundColor(Constants.Colors.primaryText)
                
                Text("Fetching BitMEX chart data...")
                    .font(Constants.Typography.caption)
                    .foregroundColor(Constants.Colors.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.Colors.primaryBackground.opacity(0.95))
    }
    
    private var errorView: some View {
        VStack(spacing: Constants.Spacing.lg) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Constants.Colors.error)
            
            VStack(spacing: Constants.Spacing.xs) {
                Text("Chart Unavailable")
                    .font(Constants.Typography.headline)
                    .foregroundColor(Constants.Colors.primaryText)
                
                Text("Unable to load chart data. Please check your internet connection.")
                    .font(Constants.Typography.caption)
                    .foregroundColor(Constants.Colors.tertiaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.Spacing.xl)
            }
            
            Button(action: {
                hasError = false
                isLoading = true
            }) {
                HStack(spacing: Constants.Spacing.xs) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("Retry")
                        .font(Constants.Typography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(Constants.Colors.accent)
                .padding(.horizontal, Constants.Spacing.lg)
                .padding(.vertical, Constants.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Constants.CornerRadius.small)
                        .stroke(Constants.Colors.accent, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.Colors.primaryBackground)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var hasError: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        webView.scrollView.backgroundColor = UIColor.clear
        
        // Enable zoom and scroll
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        webView.scrollView.bouncesZoom = true
        webView.scrollView.maximumZoomScale = 3.0
        webView.scrollView.minimumZoomScale = 0.5
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.hasError = false
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.hasError = true
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.hasError = true
        }
    }
}

#Preview {
    ChartView()
        .background(Constants.Colors.groupedBackground)
} 