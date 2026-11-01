import SwiftUI
import PencilKit

/// Draw on an evidence photo with a finger or Apple Pencil. Saves the marked-up version as a
/// new photo so the original stays untouched as evidence.
struct MarkupView: View {
    let image: UIImage
    let save: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var canvas = PKCanvasView()

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let fitted = fittedSize(for: image.size, in: proxy.size)
                ZStack {
                    Color.black.ignoresSafeArea()
                    ZStack {
                        Image(uiImage: image).resizable()
                        CanvasRepresentable(canvas: canvas)
                    }
                    .frame(width: fitted.width, height: fitted.height)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Mark Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Undo") { canvas.undoManager?.undo() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Copy") {
                        save(render())
                        dismiss()
                    }
                }
            }
        }
    }

    private func fittedSize(for size: CGSize, in bounds: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return bounds }
        let scale = min(bounds.width / size.width, bounds.height / size.height)
        return CGSize(width: size.width * scale, height: size.height * scale)
    }

    /// The photo at full resolution with the drawing scaled on top.
    private func render() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let bounds = canvas.bounds
        let scale = bounds.width > 0 ? image.size.width / bounds.width : 1
        let drawing = canvas.drawing.image(from: bounds, scale: scale)
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
            drawing.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}

private struct CanvasRepresentable: UIViewRepresentable {
    let canvas: PKCanvasView

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .systemRed, width: 10)
        context.coordinator.picker.setVisible(true, forFirstResponder: canvas)
        context.coordinator.picker.addObserver(canvas)
        DispatchQueue.main.async { canvas.becomeFirstResponder() }
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    final class Coordinator {
        let picker = PKToolPicker()
    }
}
