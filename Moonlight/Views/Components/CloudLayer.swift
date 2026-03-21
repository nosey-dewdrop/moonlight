import SwiftUI

struct CloudLayer<S: ShapeStyle>: View {
    let color: S
    let width: CGFloat
    let height: CGFloat
    let yPosition: CGFloat
    let offset: CGFloat

    var body: some View {
        CloudShape()
            .fill(color)
            .frame(width: width, height: height)
            .offset(x: offset, y: yPosition)
    }
}

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Fluffy cloud shape with multiple bumps
        path.move(to: CGPoint(x: 0, y: height))

        // Bottom left
        path.addLine(to: CGPoint(x: 0, y: height * 0.7))

        // First bump
        path.addQuadCurve(
            to: CGPoint(x: width * 0.15, y: height * 0.4),
            control: CGPoint(x: width * 0.05, y: height * 0.3)
        )

        // Second bump (taller)
        path.addQuadCurve(
            to: CGPoint(x: width * 0.35, y: height * 0.2),
            control: CGPoint(x: width * 0.22, y: height * 0.05)
        )

        // Third bump (tallest)
        path.addQuadCurve(
            to: CGPoint(x: width * 0.55, y: height * 0.15),
            control: CGPoint(x: width * 0.45, y: height * 0.0)
        )

        // Fourth bump
        path.addQuadCurve(
            to: CGPoint(x: width * 0.75, y: height * 0.3),
            control: CGPoint(x: width * 0.65, y: height * 0.1)
        )

        // Fifth bump
        path.addQuadCurve(
            to: CGPoint(x: width * 0.9, y: height * 0.5),
            control: CGPoint(x: width * 0.85, y: height * 0.2)
        )

        // Right side down
        path.addQuadCurve(
            to: CGPoint(x: width, y: height * 0.7),
            control: CGPoint(x: width * 0.95, y: height * 0.6)
        )

        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()

        return path
    }
}
