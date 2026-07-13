import SwiftUI

struct TouchpadView: View {
    @StateObject private var viewModel = TouchpadViewModel()
    @State private var dragStart: CGPoint = .zero
    @State private var isDragging: Bool = false
    @State private var lastPosition: CGPoint = .zero

    var body: some View {
        VStack(spacing: 0) {
            touchpadArea

            Divider().background(Color(red: 0.3, green: 0.25, blue: 0.15))

            mouseButtons
        }
        .background(Color.black)
    }

    private var touchpadArea: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.10, green: 0.10, blue: 0.12),
                                Color(red: 0.14, green: 0.13, blue: 0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.35, blue: 0.2).opacity(0.5),
                                Color(red: 0.2, green: 0.18, blue: 0.12).opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )

                if !isDragging {
                    VStack(spacing: 4) {
                        Image(systemName: "cursorarrow")
                            .font(.system(size: 28))
                            .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.3).opacity(0.3))
                        Text("触控板")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.3).opacity(0.3))
                    }
                }
            }
            .padding(8)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            lastPosition = value.location
                            return
                        }
                        let dx = value.location.x - lastPosition.x
                        let dy = value.location.y - lastPosition.y
                        lastPosition = value.location
                        viewModel.handleMove(dx: dx, dy: dy)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { scale in
                        let delta = Int((scale - 1.0) * 120)
                        viewModel.handleScroll(delta: delta)
                    }
            )
        }
    }

    private var mouseButtons: some View {
        HStack(spacing: 0) {
            Button(action: { viewModel.handleLeftDown() }) {
                ZStack {
                    Rectangle()
                        .fill(viewModel.isLeftButtonDown ? Color(red: 0.35, green: 0.30, blue: 0.15) : Color(red: 0.15, green: 0.14, blue: 0.17))
                    Text("左键")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.5))
                }
            }
            .frame(height: 50)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !viewModel.isLeftButtonDown { viewModel.handleLeftDown() } }
                    .onEnded { _ in viewModel.handleLeftUp() }
            )

            Rectangle()
                .fill(Color(red: 0.3, green: 0.25, blue: 0.15))
                .frame(width: 1, height: 50)

            Button(action: { viewModel.handleScroll(delta: 120) }) {
                ZStack {
                    Rectangle()
                        .fill(Color(red: 0.12, green: 0.11, blue: 0.14))
                    VStack(spacing: 2) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.5))
                }
            }
            .frame(width: 44, height: 50)

            Rectangle()
                .fill(Color(red: 0.3, green: 0.25, blue: 0.15))
                .frame(width: 1, height: 50)

            Button(action: { viewModel.handleRightClick() }) {
                ZStack {
                    Rectangle()
                        .fill(viewModel.isRightButtonDown ? Color(red: 0.35, green: 0.30, blue: 0.15) : Color(red: 0.15, green: 0.14, blue: 0.17))
                    Text("右键")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.5))
                }
            }
            .frame(height: 50)
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.10))
    }
}