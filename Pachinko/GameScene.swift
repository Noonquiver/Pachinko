//
//  GameScene.swift
//  Pachinko
//
//  Created by Camilo Hernández Guerrero on 4/07/22.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var scoreLabel: SKLabelNode!
    var editLabel: SKLabelNode!
    var ballsLeftLabel: SKLabelNode!
    var balls = [String]()
    var ballsLeft = 5 {
        didSet {
            ballsLeftLabel.text = "Balls left: \(ballsLeft)"
        }
    }
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var editingMode = false {
        didSet {
            if editingMode {
                editLabel.text = "Done"
            }
            else {
                editLabel.text = "Edit"
            }
        }
    }
    
    override func didMove(to view: SKView) {
        performSelector(inBackground: #selector(loadBallsArray), with: nil)
        
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: 980, y: 700)
        addChild(scoreLabel)
        
        editLabel = SKLabelNode(fontNamed: "Chalkduster")
        editLabel.text = "Edit"
        editLabel.position = CGPoint(x: 80, y: 700)
        addChild(editLabel)
        
        ballsLeftLabel = SKLabelNode(fontNamed: "Chalkduster")
        ballsLeftLabel.text = "Balls left: 5"
        ballsLeftLabel.horizontalAlignmentMode = .right
        ballsLeftLabel.position = CGPoint(x: scoreLabel.position.x, y: scoreLabel.position.y - 68)
        addChild(ballsLeftLabel)
        
        for i in 0..<4 {
            if i % 2 == 0 {
                makeSlot(at: CGPoint(x: 128 + 256 * i, y: 0), isGood: true)
            } else {
                makeSlot(at: CGPoint(x: 128 + 256 * i, y: 0), isGood: false)
            }
        }
        
        for j in 0..<5 {
            makeBouncer(at: CGPoint(x: 256 * j, y: 0))
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let objects = nodes(at: location)
        
        if objects.contains(editLabel) {
            editingMode.toggle()
        } else {
            if editingMode {
                let size = CGSize(width: CGFloat.random(in: 16...128), height: 16)
                let box = SKSpriteNode(color: UIColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1), size: size)
                box.zRotation = CGFloat.random(in: 0...(.pi))
                box.position = location
                box.physicsBody = SKPhysicsBody(rectangleOf: box.size)
                box.physicsBody!.isDynamic = false
                box.name = "Obstacle"
                addChild(box)
            } else if ballsLeft > 0 {
                let ball = SKSpriteNode(imageNamed: balls.randomElement()!)
                ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width / 2)
                ball.physicsBody!.restitution = 0.4
                ball.physicsBody!.contactTestBitMask = ball.physicsBody!.collisionBitMask
                ball.position = location
                ball.position.y = 768
                ball.name = "Ball"
                
                let spin = SKAction.rotate(byAngle: .pi * 7, duration: 10)
                let spinForever = SKAction.repeatForever(spin)
                ball.run(spinForever)
                
                ballsLeft -= 1
                
                addChild(ball)
            }
        }
    }
    
    @objc func loadBallsArray() {
        let fileManager = FileManager.default
        let path = Bundle.main.resourcePath!
        let contents = try! fileManager.contentsOfDirectory(atPath: path)
        
        for content in contents {
            if content.hasPrefix("ball") {
                balls.append(content)
            }
        }
    }
    
    func makeBouncer(at position: CGPoint) {
        let bouncer = SKSpriteNode(imageNamed: "bouncer")
        bouncer.position = position
        bouncer.physicsBody = SKPhysicsBody(circleOfRadius: bouncer.size.width / 2)
        bouncer.physicsBody!.isDynamic = false
        addChild(bouncer)
    }
    
    func makeSlot(at position: CGPoint, isGood: Bool) {
        let slotBase: SKSpriteNode
        let slotGlow: SKSpriteNode
        
        if isGood {
            slotBase = SKSpriteNode(imageNamed: "slotBaseGood")
            slotGlow = SKSpriteNode(imageNamed: "slotGlowGood")
            slotBase.name = "Good"
        } else {
            slotBase = SKSpriteNode(imageNamed: "slotBaseBad")
            slotGlow = SKSpriteNode(imageNamed: "slotGlowBad")
            slotBase.name = "Bad"
        }
        
        slotBase.position = position
        slotGlow.position = position
        
        slotBase.physicsBody = SKPhysicsBody(rectangleOf: slotBase.size)
        slotBase.physicsBody!.isDynamic = false
        
        let spin = SKAction.rotate(byAngle: .pi, duration: 10)
        let spinForever = SKAction.repeatForever(spin)
        slotGlow.run(spinForever)
        
        addChild(slotBase)
        addChild(slotGlow)
    }
    
    func collision(between ball: SKNode, object: SKNode) {
        if object.name == "Good" {
            destroy(ball: ball)
            score += 1
            ballsLeft += 1
        } else if object.name == "Bad" {
            destroy(ball: ball)
            score -= 1
        } else if object.name == "Obstacle" {
            object.removeFromParent()
        }
    }
    
    func destroy(ball: SKNode) {
        if let fireParticles = SKEmitterNode(fileNamed: "FireParticles") {
            fireParticles.position = ball.position
            addChild(fireParticles)
        }
        
        ball.removeFromParent()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA.name == "Ball" {
            collision(between: nodeA, object: nodeB)
        } else if nodeB.name == "Ball" {
            collision(between: nodeB, object: nodeA)
        }
    }
}
