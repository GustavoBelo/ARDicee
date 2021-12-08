//
//  ViewController.swift
//  ARDicee
//
//  Created by Gustavo Belo on 06/12/21.
//

import UIKit
import SceneKit
import ARKit 

class ViewController: UIViewController, ARSCNViewDelegate {
    
    private var diceArray = [SCNNode]()
    
    @IBOutlet var sceneView: ARSCNView!
    @IBAction func removeAllDice(_ sender: UIBarButtonItem) {
        diceArray.forEach { dice in
            dice.removeFromParentNode()
        }
    }
    @IBAction func rollAgain(_ sender: UIBarButtonItem) {
        rollAll()
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        rollAll()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //MARK: - Dice Rendering Methods
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            touchSucceded(touch)
        }
    }
    
    private func touchSucceded(_ touch: UITouch) {
        let touchLocation = touch.location(in: sceneView)
        guard let query = sceneView.raycastQuery(
            from: touchLocation,
            allowing: .existingPlaneInfinite,
            alignment: .any) else {return}
        
        let results = sceneView.session.raycast(query)
        if let hitResult = results.first{
            addDiceAndRoll(atLocation: hitResult)
        }
    }
    
    private func addDiceAndRoll(atLocation location: ARRaycastResult) {
        let diceScene = SCNScene(named: "art.scnassets/diceCollada.scn")!
        if let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true){
            diceNode.position = SCNVector3(
                x: location.worldTransform.columns.3.x,
                y: location.worldTransform.columns.3.y + diceNode.boundingSphere.radius,
                z: location.worldTransform.columns.3.z)
            diceArray.append(diceNode)
            sceneView.scene.rootNode.addChildNode(diceNode)
            
            roll(diceNode)
        }
    }
    
    private func roll(_ dice: SCNNode){
        let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        let randomZ = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        
        dice.runAction(
            SCNAction.rotateBy(
                x: CGFloat(randomX * 5),
                y: 0,
                z: CGFloat(randomZ * 5),
                duration: 0.8)
        )
    }
    
    private func rollAll() {
        diceArray.forEach{ dice in
            roll(dice)
        }
    }
    
    //MARK: - ARSCNViewDelegateMethods
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor){
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let planeNode = createPlane(with: planeAnchor)
        node.addChildNode(planeNode)
    }
    
    // MARK: - Plane Rendering Methods
    
    private func createPlane(with planeAnchor: ARPlaneAnchor) -> SCNNode{
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x),
                             height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
        
        plane.materials = [gridMaterial]
        planeNode.geometry = plane
        return planeNode
    }

}
