//
//  FullCode.swift
//  GoldenEyes
//
//  Created by Yang Xu on 2023/5/27.
//

import ARKit
import Foundation
import RealityKit
import SwiftUI

struct FullCodeView: View {
    @State var showAR = true

    var body: some View {
        ZStack {
            if showAR {
                ARViewContainer()
            }
            Button(showAR ? "Hide AR" : "Show AR") {
                showAR.toggle()
            }.padding()
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // 设置人脸跟踪会话
        let config = ARFaceTrackingConfiguration()
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])

        // 设置会话代理
        arView.session.delegate = context.coordinator
        context.coordinator.arView = arView
        context.coordinator.addEyes(to: arView)
        return arView
    }

    func updateUIView(_: ARView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, ARSessionDelegate {
        var arView: ARView?
        var faceAnchor: ARFaceAnchor?
        var eyeL: Entity?
        var eyeR: Entity?

        func addEyes(to arView: ARView) {
            // 创建左眼Entity
            eyeL = Entity()
            eyeL?.name = "Left Eye"
            let scale: Float = 0.36 // 缩放因子
            let radius: Float = 0.1 * scale // 根据缩放因子计算半径

            eyeL?.components[ModelComponent.self] = ModelComponent(
                mesh: .generateSphere(radius: radius),
                materials: [SimpleMaterial(color: .yellow, isMetallic: false)]
            )
            eyeL?.transform.rotation = simd_quatf()
            eyeL?.position = SIMD3<Float>(0.0305, 0.0497, 1)
//            eyeL?.position = SIMD3<Float>(-0.0321, 0.0497, -0.03)

            // 创建右眼Entity
            eyeR = Entity()
            eyeR?.name = "Right Eye"
            eyeR?.components[ModelComponent.self] = ModelComponent(
                mesh: .generateSphere(radius: radius),
                materials: [SimpleMaterial(color: .yellow, isMetallic: false)]
            )
            eyeR?.transform.rotation = simd_quatf()
            eyeR?.position = SIMD3<Float>(0.002, 0.01, -0.03)

            let anchorEntity = AnchorEntity(world: .zero)
            anchorEntity.addChild(eyeL!)
            anchorEntity.addChild(eyeR!)
            arView.scene.addAnchor(anchorEntity)

            // 为ARView添加点击手势
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            arView.addGestureRecognizer(tapGesture)
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                if let faceAnchor = anchor as? ARFaceAnchor {
                    if let leftEyeNode = eyeL,
                       let rightEyeNode = eyeR
                    {
                        let leftEyeTransform = faceAnchor.leftEyeTransform
                        let rightEyeTransform = faceAnchor.rightEyeTransform
                        
                        let leftEyePosition = simd_make_float3(leftEyeTransform.columns.3.x, leftEyeTransform.columns.3.y, leftEyeTransform.columns.3.z)
                        let rightEyePosition = simd_make_float3(rightEyeTransform.columns.3.x, rightEyeTransform.columns.3.y, rightEyeTransform.columns.3.z)
                        
                        // 调整球体的位置
                        let horizontalOffset: Float = 0.005 // 水平方向的偏移量
                        let verticalOffset: Float = 0.01 // 垂直方向的偏移量
                        let forwardOffset: Float = 0   // 向前移动的偏移量
                        
                        leftEyeNode.position = leftEyePosition + SIMD3<Float>(horizontalOffset, verticalOffset, forwardOffset)
                        rightEyeNode.position = rightEyePosition + SIMD3<Float>(-horizontalOffset, verticalOffset, forwardOffset)
                        
                        print(leftEyePosition,rightEyePosition,"$$$")
                        
                        let blendShapes = faceAnchor.blendShapes
                        if let jawOpen = blendShapes[.jawOpen]?.floatValue {
                            // 根据下颚开合程度设置眼睛Entity大小
                            leftEyeNode.scale = SIMD3<Float>(1, 1, 1) * (0.3 + jawOpen / 2)
                            rightEyeNode.scale = SIMD3<Float>(1, 1, 1) * (0.3 + jawOpen / 2)
                        }
                        
                        // 输出眼球位置
                        print(leftEyeNode.position, rightEyeNode.position)
                    }
                }
            }
        }

        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            guard let arView else { return }
            let location = gestureRecognizer.location(in: arView)
            if let entity = arView.entity(at: location) {
                if entity == eyeL {
                    // 左眼被点击的处理逻辑
                    playSound()
                } else if entity == eyeR {
                    // 右眼被点击的处理逻辑
                    playSound()
                }
            }
        }

        func playSound() {
            // 创建音频文件的URL
            print("play sound")
            guard let soundURL = Bundle.main.url(forResource: "sound_file", withExtension: "mp3") else {
                return
            }

            // 播放音频
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer.play()
            } catch {
                print("Failed to play sound: \(error)")
            }
        }
    }
}
