import SwiftUI
import SceneKit

struct Keycap3DView: UIViewRepresentable {
    let label: String
    let isPressed: Bool
    let keyColor: Color
    let textColor: Color

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.antialiasingMode = .multisampling4X
        view.scene = createScene()
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        guard let rootNode = view.scene?.rootNode,
              let keyNode = rootNode.childNode(withName: "keycap", recursively: true) else { return }

        let targetY: Float = isPressed ? -0.02 : 0.0
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.08
        keyNode.position.y = targetY
        SCNTransaction.commit()
    }

    private func createScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let rootNode = scene.rootNode

        let keyBase = createRoundedBox(width: 0.85, height: 0.08, length: 0.85, cornerRadius: 0.02)
        keyBase.name = "keycap"
        keyBase.position = SCNVector3(0, 0, 0)
        keyBase.geometry?.firstMaterial = createBaseMaterial()
        rootNode.addChildNode(keyBase)

        let keyTop = createRoundedBox(width: 0.75, height: 0.06, length: 0.75, cornerRadius: 0.015)
        keyTop.position = SCNVector3(0, 0.07, 0)
        keyTop.geometry?.firstMaterial = createTopMaterial()
        keyBase.addChildNode(keyTop)

        let labelNode = createLabelNode(text: label)
        labelNode.position = SCNVector3(0, 0.105, 0)
        keyBase.addChildNode(labelNode)

        let light = SCNNode()
        light.light = SCNLight()
        light.light?.type = .directional
        light.light?.intensity = 800
        light.position = SCNVector3(2, 5, 3)
        light.look(at: SCNVector3(0, 0, 0))
        rootNode.addChildNode(light)

        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 300
        ambientLight.light?.color = UIColor.white
        rootNode.addChildNode(ambientLight)

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 40
        camera.position = SCNVector3(0, 1.2, 1.0)
        camera.look(at: SCNVector3(0, 0, 0))
        rootNode.addChildNode(camera)

        return scene
    }

    private func createRoundedBox(width: CGFloat, height: CGFloat, length: CGFloat, cornerRadius: CGFloat) -> SCNNode {
        let geometry = SCNBox(width: width, height: height, length: length, chamferRadius: cornerRadius)
        return SCNNode(geometry: geometry)
    }

    private func createBaseMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1.0)
        material.specular.contents = UIColor(white: 0.4, alpha: 1.0)
        material.shininess = 40
        material.metalness.contents = 0.6
        material.roughness.contents = 0.4
        return material
    }

    private func createTopMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        let uiColor = UIColor(keyColor)
        material.diffuse.contents = uiColor
        material.specular.contents = UIColor(white: 0.5, alpha: 1.0)
        material.shininess = 60
        material.metalness.contents = 0.7
        material.roughness.contents = 0.3
        material.emission.contents = uiColor.withAlphaComponent(0.15)
        return material
    }

    private func createLabelNode(text: String) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.01)
        textGeometry.font = UIFont.systemFont(ofSize: 0.18, weight: .bold)
        textGeometry.flatness = 0.1
        textGeometry.isWrapped = false

        let (min, max) = textGeometry.boundingBox
        let centerX = (min.x + max.x) / 2
        let centerZ = (min.z + max.z) / 2

        let material = SCNMaterial()
        material.diffuse.contents = UIColor(textColor)
        material.emission.contents = UIColor(textColor).withAlphaComponent(0.3)
        textGeometry.materials = [material]

        let node = SCNNode(geometry: textGeometry)
        node.pivot = SCNMatrix4MakeTranslation(centerX, 0, centerZ)
        node.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        return node
    }
}

struct SteampunkKeycapButton: View {
    let key: KeyDefinition
    let onPressed: () -> Void
    let onReleased: () -> Void

    @State private var isPressed: Bool = false
    @State private var isHovering: Bool = false

    private let keyColor: Color = Color(red: 0.22, green: 0.20, blue: 0.25)
    private let pressedColor: Color = Color(red: 0.35, green: 0.30, blue: 0.15)
    private let textColor: Color = Color(red: 0.9, green: 0.85, blue: 0.7)

    var body: some View {
        GeometryReader { geometry in
            let keyWidth = geometry.size.width
            let keyHeight = geometry.size.height

            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.08, green: 0.08, blue: 0.10),
                                Color(red: 0.12, green: 0.12, blue: 0.15)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: keyWidth, height: keyHeight)
                    .offset(y: isPressed ? 2 : 0)

                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: isPressed ? [
                                Color(red: 0.30, green: 0.25, blue: 0.12),
                                Color(red: 0.35, green: 0.30, blue: 0.15)
                            ] : [
                                Color(red: 0.22, green: 0.20, blue: 0.25),
                                Color(red: 0.18, green: 0.16, blue: 0.20)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: keyWidth - 4, height: keyHeight - (isPressed ? 4 : 6))
                    .offset(y: isPressed ? 1 : -1)

                if isHovering && !isPressed {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.9, green: 0.75, blue: 0.3).opacity(0.08))
                        .frame(width: keyWidth - 4, height: keyHeight - 6)
                        .offset(y: -1)
                }

                Text(key.label)
                    .font(.system(size: fontSize(for: key.label), weight: .semibold, design: .monospaced))
                    .foregroundColor(isPressed ? Color(red: 1.0, green: 0.85, blue: 0.4) : textColor)
                    .offset(y: isPressed ? 1 : -1)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isPressed {
                            isPressed = true
                            onPressed()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        onReleased()
                    }
            )
            .onTapGesture {}
        }
    }

    private func fontSize(for label: String) -> CGFloat {
        if label.count <= 1 { return 16 }
        if label.count <= 3 { return 13 }
        return 10
    }
}