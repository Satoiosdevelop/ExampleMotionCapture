//
//  ViewController.swift
//  MotionCapture
//
//  Created by S310 on 2020/11/08.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.session.delegate = self
        
        sceneView.scene = SCNScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Create a session configuration
        let configuration = ARBodyTrackingConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else {
                return
            }
            setARBodyAnchor(anchor: bodyAnchor)
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else {
                return
            }
            setARBodyAnchor(anchor: bodyAnchor)
        }
    }
    
    
    func setARBodyAnchor(anchor: ARBodyAnchor) {
        // skeleton 取得
        let skeleton = anchor.skeleton
        // skeleton の パーツ名でloop
        for jointName in skeleton.definition.jointNames {
            let jointType = ARSkeleton.JointName(rawValue: jointName)
            if let transform = skeleton.modelTransform(for: jointType) {
                /// jointTypeの位置・回転をキャスト
                let partsPoint = SCNMatrix4(transform)
                /// 基準点 hipの位置・回転をキャスト
                let hipPoint = SCNMatrix4(anchor.transform)
                /// func SCNMatrix4Mult(_ a: SCNMatrix4, _ b: SCNMatrix4) -> SCNMatrix4で行列を合成するときは、左のaが後にやる方、右のbが先にやる方、という風に考えて合成します。
                let matrix = SCNMatrix4Mult(partsPoint, hipPoint)
                /// ノードの座標を設定
                // + 1して実際の位置の右側に表示する様にする
                let position = SCNVector3(matrix.m41 + 1, matrix.m42, matrix.m43)
                if let nodeToUpdate = sceneView.scene.rootNode.childNode(withName: jointName, recursively: false) {
                    /// 既に追加されているので、位置の更新のみ行う
                    nodeToUpdate.isHidden = false
                    nodeToUpdate.position = position
                } else {
                    // GeoSphere
                    // Radius 球の半径で初期値は 1。
                    let sphereGeometry = SCNSphere(radius: 0.02)
                    // チェックすると三角ポリゴンを均等に麺が構成される。 初期値はfalse
                    sphereGeometry.isGeodesic = true
                    // 球体Color
                    sphereGeometry.firstMaterial?.diffuse.contents = UIColor.green
                    // ノードに球体ジオメトリを設定
                    let sphereNode = SCNNode(geometry: sphereGeometry)
                    // 表示位置設定
                    sphereNode.position = position
                    // ノードにname設定
                    sphereNode.name = jointName
                    // ルートノードに追加する
                    sceneView.scene.rootNode.addChildNode(sphereNode)
                }
            } else {
                if let nodeToHide = sceneView.scene.rootNode.childNode(withName: jointName, recursively: false) {
                    nodeToHide.isHidden = true
                }
            }
        }
    }
}
