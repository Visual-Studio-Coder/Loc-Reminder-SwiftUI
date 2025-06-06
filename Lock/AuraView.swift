/// Copyright © 2025 Vaibhav Satishkumar. All rights reserved.
import SwiftUI

struct AuroraView: View {
    
    private enum AnimationProperties {
        static let animationSpeed: Double = 4
        static let timerDuration: TimeInterval = 3
        static let blurRadius: CGFloat = 170
    }
    
    @State private var timer = Timer.publish(every: AnimationProperties.timerDuration, on: .main, in: .common).autoconnect()
    @ObservedObject private var animator = CircleAnimator(colors: AuroraColors.all)
    
    var body: some View {
        ZStack {
            ZStack {
                ForEach(animator.circles) { circle in
                    MovingCircle(originOffset: circle.position)
                        .foregroundColor(circle.color)
                }
            }.blur(radius: AnimationProperties.blurRadius)
        }
        .background(AuroraColors.backgroundColor)
        .onDisappear {
            timer.upstream.connect().cancel()
        }
        .onAppear {
            animateCircles()
            timer = Timer.publish(every: AnimationProperties.timerDuration, on: .main, in: .common).autoconnect()
        }
        .onReceive(timer) { _ in
            animateCircles()
        }
    }
    
    private func animateCircles() {
        withAnimation(.easeInOut(duration: AnimationProperties.animationSpeed)) {
            animator.animate()
        }
    }
    
}

private enum AuroraColors {
    static var all: [Color] {
        [
            .yellow,
            Color(red: 0.016, green: 0.106, blue: 0.251, opacity: 10),
            Color(red: 0.69, green: 0.808, blue: 1),
            Color(red: 0.278, green: 0.557, blue: 1, opacity: 0.6),
            Color(red: 0, green: 0.384, blue: 1)
          
        ]
    }
    
    static var backgroundColor: Color {
        Color(red: 23/255, green: 81/255, blue: 104/255)
    }
}

private struct MovingCircle: Shape {
    
    var originOffset: CGPoint
    
    var animatableData: CGPoint.AnimatableData {
        get {
            originOffset.animatableData
        }
        set {
            originOffset.animatableData = newValue
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let adjustedX = rect.width * originOffset.x
        let adjustedY = rect.height * originOffset.y
        let smallestDimension = min(rect.width, rect.height)
        path.addArc(center: CGPoint(x: adjustedX, y: adjustedY), radius: smallestDimension/2, startAngle: .zero, endAngle: .degrees(360), clockwise: true)
        return path
    }
}

private class CircleAnimator: ObservableObject {
    class Circle: Identifiable {
        internal init(position: CGPoint, color: Color) {
            self.position = position
            self.color = color
        }
        var position: CGPoint
        let id = UUID().uuidString
        let color: Color
    }
    
    @Published private(set) var circles: [Circle] = []
    
    
    init(colors: [Color]) {
        circles = colors.map({ color in
            Circle(position: CircleAnimator.generateRandomPosition(), color: color)
        })
    }
    
    func animate() {
        objectWillChange.send()
        for circle in circles {
            circle.position = CircleAnimator.generateRandomPosition()
        }
    }
    
    static func generateRandomPosition() -> CGPoint {
        CGPoint(x: CGFloat.random(in: 0 ... 1), y: CGFloat.random(in: 0 ... 1))
    }
}

struct AuroraView_Previews: PreviewProvider {
    static var previews: some View {
        AuroraView()
    }
}
