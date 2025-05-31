//
//  NoInternetView.swift
//  TradeApp
//
//  Created by Sahad on 31/05/2025.
//

import SwiftUI

struct NoInternetView: View {
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: Constants.Spacing.xl) {
            Spacer()
            
            // No Internet Icon
            VStack(spacing: Constants.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Constants.Colors.error.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(Constants.Colors.error)
                }
                
                VStack(spacing: Constants.Spacing.sm) {
                    Text("No Internet Connection")
                        .font(Constants.Typography.title)
                        .foregroundColor(Constants.Colors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("Please check your connection and try again")
                        .font(Constants.Typography.body)
                        .foregroundColor(Constants.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Constants.Spacing.xl)
                }
            }
            
            // Retry Button
            Button(action: onRetry) {
                HStack(spacing: Constants.Spacing.sm) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Try Again")
                        .font(Constants.Typography.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, Constants.Spacing.xl)
                .padding(.vertical, Constants.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                        .fill(Constants.Colors.accent)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.Colors.groupedBackground)
    }
}

#Preview {
    NoInternetView(onRetry: {})
} 