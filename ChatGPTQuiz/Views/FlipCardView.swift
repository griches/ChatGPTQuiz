import SwiftUI

struct FlipCard3D<Front: View, Back: View>: View {
    let front: Front
    let back: Back
    let isFlipped: Bool
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            front
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(rotation),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            back
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(rotation + 180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .onChange(of: isFlipped) { _, newValue in
            withAnimation(.easeInOut(duration: 0.6)) {
                rotation = newValue ? 180 : 0
            }
        }
    }
}

struct SwipeableCard<Content: View>: View {
    let content: Content
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    
    var body: some View {
        content
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(1 - abs(offset.width) / 1000)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                        rotation = Double(gesture.translation.width / 10)
                    }
                    .onEnded { gesture in
                        if abs(gesture.translation.width) > 100 {
                            // Swipe detected
                            let swipeLeft = gesture.translation.width < 0
                            
                            withAnimation(.easeOut(duration: 0.3)) {
                                offset = CGSize(
                                    width: swipeLeft ? -1000 : 1000,
                                    height: gesture.translation.height
                                )
                                rotation = swipeLeft ? -45 : 45
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if swipeLeft {
                                    onSwipeLeft()
                                } else {
                                    onSwipeRight()
                                }
                                
                                // Reset for next card
                                offset = .zero
                                rotation = 0
                            }
                        } else {
                            // Return to center
                            withAnimation(.spring()) {
                                offset = .zero
                                rotation = 0
                            }
                        }
                    }
            )
    }
}

struct PulsingView<Content: View>: View {
    let content: Content
    let isActive: Bool
    
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        content
            .scaleEffect(scale)
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        scale = 1.05
                    }
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        scale = 1.05
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scale = 1.0
                    }
                }
            }
    }
}

struct BouncyButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.3)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.3)) {
                    isPressed = false
                }
            }
            
            action()
        }) {
            content
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WaveEffect: View {
    let color: Color
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midHeight = height / 2
                let wavelength = width / 4
                
                path.move(to: CGPoint(x: 0, y: midHeight))
                
                for x in stride(from: 0, through: width, by: 1) {
                    let relativeX = x / wavelength
                    let sine = sin(relativeX + waveOffset)
                    let y = midHeight + sine * 20
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
            }
            .fill(color)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    waveOffset = .pi * 2
                }
            }
        }
    }
}