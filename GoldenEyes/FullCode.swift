import ARKit
import RealityKit
import SwiftUI

struct ContentView: View {
    @State var show = true

    var body: some View {
        ZStack(alignment: .bottom) {
            FullCodeARViewContainer(show: $show).edgesIgnoringSafeArea(.all)
            Button(action: {
                show.toggle()
            }) {
                Text(show ? "Hide" : "Show")
                    .padding(.horizontal, 20)
            }
            .buttonStyle(.borderedProminent)
            .padding(16)
        }
    }
}

struct FullCodeARViewContainer: UIViewRepresentable {
    @Binding var show: Bool

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let arConfiguration = ARFaceTrackingConfiguration()
        arView.session.run(arConfiguration, options: [.resetTracking, .removeExistingAnchors])
        arView.session.delegate = context.coordinator
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if show {
            let arAnchor = try! makeEyesAnchor()
            uiView.scene.anchors.append(arAnchor)
            context.coordinator.face = arAnchor
        } else {
            context.coordinator.face = nil
            uiView.scene.anchors.removeAll()
        }
    }

    func makeCoordinator() -> FullCodeARDelegateHandler {
        FullCodeARDelegateHandler(arViewContainer: self)
    }

    func makeEyesAnchor() throws -> AnchorEntity {
        let eyesAnchor = AnchorEntity()

        let eyeBallSize: Float = 0.02 // 小球的尺寸

        // 创建左眼小球并设置位置
        let leftEyeBall = createEyeBall(scale: eyeBallSize)
        leftEyeBall.position = SIMD3<Float>(0.030469913, 0.0497, -0.03) // 左眼位置
        eyesAnchor.addChild(leftEyeBall)

        // 创建右眼小球并设置位置
        let rightEyeBall = createEyeBall(scale: eyeBallSize)
        rightEyeBall.position = SIMD3<Float>(-0.032096043, 0.04967857, -0.03) // 右眼位置
        eyesAnchor.addChild(rightEyeBall)

        return eyesAnchor
    }

    func createEyeBall(scale: Float) -> ModelEntity {
        let eyeBall = ModelEntity(mesh: .generateSphere(radius: scale), materials: [SimpleMaterial(color: .yellow, isMetallic: true)])
        return eyeBall
    }
}

class FullCodeARDelegateHandler: NSObject, ARSessionDelegate {
    var arViewContainer: FullCodeARViewContainer
    var face: AnchorEntity?
    

    init(arViewContainer: FullCodeARViewContainer) {
        self.arViewContainer = arViewContainer
        super.init()
    }

    func session(_: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }

        // 获取头部位置
        let facePosition = SIMD3<Float>(faceAnchor.transform.columns.3.x, faceAnchor.transform.columns.3.y, faceAnchor.transform.columns.3.z)

        if let faceEntity = face?.children.compactMap({ $0 as? ModelEntity }) {
            let forwardVector = simd_normalize(faceAnchor.transform.columns.2)
            let upwardVector = simd_normalize(faceAnchor.transform.columns.1)

            let forwardOffset: Float = 0.05 // 向前偏移的量
            let upwardOffset: Float = 0.02 // 向上偏移的量

            let facePosition = SIMD3<Float>(faceAnchor.transform.columns.3.x, faceAnchor.transform.columns.3.y, faceAnchor.transform.columns.3.z)
            let forwardOffsetVector = SIMD3<Float>(forwardVector.x, forwardVector.y, forwardVector.z) * forwardOffset
            let upwardOffsetVector = SIMD3<Float>(upwardVector.x, upwardVector.y, upwardVector.z) * upwardOffset

            let leftEyePosition = facePosition + forwardOffsetVector + upwardOffsetVector
            let rightEyePosition = facePosition - forwardOffsetVector + upwardOffsetVector

            faceEntity.first?.position = leftEyePosition
            faceEntity.last?.position = rightEyePosition

            print("Left Eye Position:", leftEyePosition)
            print("Right Eye Position:", rightEyePosition)
        }

        let maxScale: Float = 2 // 小球的最大缩放倍数
        // 获取张嘴程度
        let blendShapes = faceAnchor.blendShapes
        if let jawOpen = blendShapes[.jawOpen]?.floatValue {
            // 调整小球的缩放倍数
            let scale = 1 + (jawOpen * maxScale)
            face?.children.compactMap { $0 as? ModelEntity }.forEach { eyeBall in
                eyeBall.scale = SIMD3<Float>(repeating: scale)
            }
        }
    }

    func session(_: ARSession, didRemove _: [ARAnchor]) {
        print("didRemove")
    }

    func session(_: ARSession, didAdd _: [ARAnchor]) {
        print("didAdd")
    }
}

#if DEBUG
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
#endif
