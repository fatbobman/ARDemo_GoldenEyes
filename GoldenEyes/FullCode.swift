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
            context.coordinator.face = arAnchor
            uiView.scene.anchors.append(arAnchor)
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
        let eyeBallSize: Float = 0.015 // 小球的尺寸
        // 创建左眼小球并设置位置
        let leftEyeBall = createEyeBall(scale: eyeBallSize)
        let leftEyeOffset = SIMD3<Float>(0.03, 0.02, 0.05) // 左眼相对于头部的偏移量
        leftEyeBall.name = "leftEye"
        leftEyeBall.position = leftEyeOffset
        eyesAnchor.addChild(leftEyeBall)
        // 创建右眼小球并设置位置
        let rightEyeBall = createEyeBall(scale: eyeBallSize)
        let rightEyeOffset = SIMD3<Float>(-0.03, 0.02, 0.05) // 右眼相对于头部的偏移量
        rightEyeBall.name = "rightEye"
        rightEyeBall.position = rightEyeOffset
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
        guard let faceAnchor = anchors.first as? ARFaceAnchor,
              let face = face
        else {
            return
        }

        // 更新头部实体的位置和方向
        let facePosition = simd_make_float3(faceAnchor.transform.columns.3)
        let faceOrientation = simd_quatf(faceAnchor.transform)
        face.position = facePosition
        face.orientation = faceOrientation
        
        // 获取头部节点的旋转值
        let faceRotation = face.orientation

        // 更新左眼小球的旋转
        if let leftEye = face.children.first(where: { $0.name == "leftEye" }) as? ModelEntity {
            let parentRotation = faceOrientation
            let eyeLocalRotation = simd_mul(parentRotation.inverse, faceRotation)
            leftEye.orientation = eyeLocalRotation
        }

        // 更新右眼小球的旋转
        if let rightEye = face.children.first(where: { $0.name == "rightEye" }) as? ModelEntity {
            let parentRotation = faceOrientation
            let eyeLocalRotation = simd_mul(parentRotation.inverse, faceRotation)
            rightEye.orientation = eyeLocalRotation
        }
        

        print("Face Position and Orientation:", facePosition, faceOrientation)

        let maxScale: Float = 1.6 // 小球的最大缩放倍数

        // 获取张嘴程度
        let blendShapes = faceAnchor.blendShapes

        if let jawOpen = blendShapes[.jawOpen]?.floatValue {
            // 调整小球的缩放倍数
            let scale = 1 + (jawOpen * maxScale)

            face.children.compactMap { $0 as? ModelEntity }.forEach { eyeBall in
                eyeBall.scale = SIMD3<Float>(repeating: scale)
            }
        }

        // 获取眼球相对于头部的位置
        if let leftEye = face.children.first(where: { $0.name == "leftEye" }),
           let rightEye = face.children.first(where: { $0.name == "rightEye" })
        {
            let leftEyePosition = leftEye.position
            let rightEyePosition = rightEye.position

            // 输出眼球相对于头部的位置
            print("Left Eye Relative Position:", leftEyePosition)
            print("Right Eye Relative Position:", rightEyePosition)

            // 获取眼球的世界位置
            let leftEyeWorldPosition = face.convert(position: leftEyePosition, to: nil)
            let rightEyeWorldPosition = face.convert(position: rightEyePosition, to: nil)

            // 输出眼球的世界位置
            print("Left Eye World Position:", leftEyeWorldPosition)
            print("Right Eye World Position:", rightEyeWorldPosition)
        }

        // ...
    }
}

#if DEBUG
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
#endif
