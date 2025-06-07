/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
//
//  threeDimensionalButton.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 4/25/23.
//

import SwiftUI

struct threeDimensionalButton: ButtonStyle {
    
    let lateralGradient: LinearGradient
    let flatGradient: LinearGradient
    @State private var isExecutingAction = false
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            let offset: CGFloat = 6
            let cornerRadius: CGFloat = 16
            let shadowOffset: CGFloat = (configuration.isPressed || isExecutingAction) ? 2 : 8
            let buttonOffset: CGFloat = (configuration.isPressed || isExecutingAction) ? 4 : 0
            
            // Shadow layer (deepest)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(x: 1, y: shadowOffset)
                .blur(radius: (configuration.isPressed || isExecutingAction) ? 2 : 4)
            
            // Bottom/Side layer (lateral gradient)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(lateralGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.2),
                                    Color.clear,
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .offset(y: offset)
            
            // Top layer (main button)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(flatGradient)
                .overlay(
                    // Inner highlight
                    RoundedRectangle(cornerRadius: cornerRadius - 1)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .padding(1)
                )
                .overlay(
                    // Outer border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.1),
                                    Color.black.opacity(0.3),
                                    Color.black.opacity(0.1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
                .offset(y: buttonOffset)
            
            // Label
            configuration.label
                .font(.title2.weight(.semibold))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.004, green: 0.157, blue: 0.545),
                            Color(red: 0.004, green: 0.107, blue: 0.395)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: buttonOffset)
                .scaleEffect((configuration.isPressed || isExecutingAction) ? 0.98 : 1.0)
        }
        .scaleEffect((configuration.isPressed || isExecutingAction) ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: configuration.isPressed || isExecutingAction) // Slightly longer animation
        .onChange(of: configuration.isPressed) { isPressed in
            if isPressed {
                // Soft haptic feedback when pressed
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                // Perform the pressed animation first, then execute the action
                isExecutingAction = true
                
                // Increased delay to ensure animation is fully visible
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // Reset the visual state after a brief moment
                    isExecutingAction = false
                }
            }
        }
    }
}

struct threeDimensionalButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            Button("Press Me") {
                print("Button pressed!")
            }
            .frame(width: 200, height: 60)
            .buttonStyle(threeDimensionalButton(
                lateralGradient: LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .init(red: 0.2, green: 0.4, blue: 0.8), location: 0.0),
                        .init(color: .init(red: 0.384, green: 0.6, blue: 0.9), location: 0.1),
                        .init(color: .init(red: 0.384, green: 0.6, blue: 0.9), location: 0.9),
                        .init(color: .init(red: 0.2, green: 0.4, blue: 0.8), location: 1.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                flatGradient: LinearGradient(
                    gradient: Gradient(colors: [
                        .white,
                        Color(red: 0.584, green: 0.749, blue: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            ))
            
            Button("Another Button") {
                print("Another button pressed!")
            }
            .frame(width: 180, height: 50)
            .buttonStyle(threeDimensionalButton(
                lateralGradient: LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.8),
                        Color.green
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ),
                flatGradient: LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white,
                        Color.green.opacity(0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            ))
        }
        .padding(50)
        .background(Color.gray.opacity(0.1))
    }
}
