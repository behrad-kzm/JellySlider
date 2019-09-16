//
//  BezierView.swift
//  BEKApps.com
//
//  Created by Kyle Zaragoza on 6/27/16.
//  Modified by Behrad Kazemi on 9/14/19.
//  Copyright © 2019 Behrad Kazemi. All rights reserved.
//

import UIKit
import SpriteKit
import RxSwift

public class JellySlider: UIControl {
	
	// MARK: - Public Properties
	/// Closure called when user changes value
	
	public var onValueChange: ((_ value: Float) -> Void)?
	public var progress: Float = 0.0 {
		didSet {
			
			if progress == value {
				return
			}
			let trackLength = bounds.width - 2*edgeBoundaryPadding
			let touchMinusBoundary = CGFloat(progress) * trackLength
			let destinationBubbleCenterX = touchMinusBoundary + edgeBoundaryPadding
			bubbleHidden = true
			touchPositionX = acceptableXPosition(x: destinationBubbleCenterX)
			bubbleCenterX = acceptableXPosition(x: destinationBubbleCenterX)
			
			// move down bubble overlay
			positionOverlayInTrack()
			
			// show particle
			// sprite kit uses gl coordinate space, we must flip
			let particleY = 2*maxBubbleRadius + 0.1*trackHeight
			skScene.addChild(splashParticle(center: CGPoint(x: bubbleCenterX, y: skView.bounds.height-particleY), color: trackColor))
			
		}
	}
	/// Current value of slider. (ranges: 0-100)
	private var value: Float {
		let trackLength = bounds.width - 2*edgeBoundaryPadding
		let touchMinusBoundary = bubbleCenterX - edgeBoundaryPadding
		return Float(touchMinusBoundary/trackLength)
	}
	/// Color of track.
	public var trackColor: UIColor = .black {
		didSet {
			shapeLayer.fillColor = trackColor.cgColor
		}
	}
	
	// MARK: - Private Properties
	/// Determines start dragging point
	private var startDraggingX: CGFloat = 0.0
	/// Determines if bubble is showing above the track.
	private var bubbleHidden = true
	/// The max radius allowed (bubble radius is adjusted w/ force touch)
	private let maxBubbleRadius: CGFloat = 32
	/// The min radius allowed (bubble radius is adjusted w/ force touch)
	private let minBubbleRadius: CGFloat = 16
	/// Height of bubble peeking out of track when collapsed.
	private let peekingBubbleHeight: CGFloat = 3
	/// Radius of bubble when shown above the track.
	private var bubbleRadius: CGFloat = 16
	/// Height of track.
	private let trackHeight: CGFloat = 8
	/// Padding extended to the height of the view, to allow some leniency to touch handling.
	private let bottomTouchPadding: CGFloat = 0
	/// Padding used on either side of the track to restrict bubble from popping off track.
	// TODO: adjust curves of end caps when bubble extends to edge
	private var edgeBoundaryPadding: CGFloat {
		let trackRadius = trackHeight/2
		let minPadding = max(trackRadius, minBubbleRadius) + 10
		return minPadding
	}
	/// Touch position from touch handling event, protects againts `bubbleCenterX` being outside of the track.
	private var touchPositionX: CGFloat = 58 {
		didSet {
			let lerpX = abs((bubbleCenterX - touchPositionX)) * 0.18
			if touchPositionX < bubbleCenterX {
				bubbleCenterX = acceptableXPosition(x: bubbleCenterX - lerpX)
			} else {
				bubbleCenterX = acceptableXPosition(x: bubbleCenterX + lerpX)
			}
		}
	}

	/// Center position of the bubble. Updates UI on update.
	private var bubbleCenterX: CGFloat = 58 {
		didSet {
			// use newly generated path
			shapeLayer.path = path()
			
			// move bubble overlay
			let circleCenter = CGPoint(x: bubbleCenterX, y: 2*maxBubbleRadius - bubbleRadius)
			let circleWidth = bubbleRadius*1.2
			
			// we don't need to animate if already floating above the track (not hidden)
			let propertyChanges = {
				self.bubbleOverlay.bounds = CGRect(x: 0, y: 0, width: circleWidth, height: circleWidth)
				self.bubbleOverlay.position = circleCenter
				self.bubbleOverlay.cornerRadius = circleWidth/2
			}
			if bubbleOverlay.position.y < 2*maxBubbleRadius {
				CATransaction.begin()
				CATransaction.setValue(true, forKey: kCATransactionDisableActions)
				propertyChanges()
				CATransaction.commit()
			} else {
				propertyChanges()
			}
			// update listener
			onValueChange?(value)
		}
	}
	/// Layer which draws the bezier path to screen.
	private let shapeLayer: CAShapeLayer = {
		let layer = CAShapeLayer()
		layer.fillColor = UIColor.black.cgColor
		return layer
	}()
	/// Layer which is overlayed on bubble, for visual use only.
	private let bubbleOverlay: CALayer = {
		let layer = CALayer()
		layer.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
		layer.cornerRadius = 8
		layer.backgroundColor = UIColor(white: 1, alpha: 0.35).cgColor
		return layer
	}()
	/// Sprite Kit view used for particles.
	private lazy var skView: SKView = { [unowned self] in
		let view = SKView(frame: self.bounds)
		view.backgroundColor = .clear
		view.isUserInteractionEnabled = false
		return view
		}()
	/// Sprite Kit scene used for particles.
	private lazy var skScene: SKScene = { [unowned self] in
		let scene = SKScene(size: CGSize(width: self.bounds.width, height: self.bounds.height + 1000))
		scene.backgroundColor = .clear
		return scene
		}()
	
	
	// MARK: - Init
	
	override public init(frame: CGRect) {
		super.init(frame: frame)
		// add sprite kit
		skView.frame = bounds
		addSubview(skView)
		skView.presentScene(skScene)
		// track layer
		shapeLayer.backgroundColor = UIColor.clear.cgColor
		layer.addSublayer(shapeLayer)
		shapeLayer.path = path()
		// bubble center layer
		shapeLayer.addSublayer(bubbleOverlay)
		// setup default location
		positionOverlayInTrack()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		
		fatalError("init(coder:) has not been implemented")
	}
	
	
	// MARK: - Animation
	
	private func animationIntoTrackAtPosition(x: CGFloat, withDuration: Double = 0.2) {
		// animate path into track
		let animation = CABasicAnimation(keyPath: "path")
		animation.duration = withDuration
		animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
		shapeLayer.add(animation, forKey: "pathAnimation")
		bubbleHidden = true
		touchPositionX = acceptableXPosition(x: x)
		bubbleCenterX = acceptableXPosition(x: x)
		
		// move down bubble overlay
		positionOverlayInTrack()

		// show particle
		// sprite kit uses gl coordinate space, we must flip
		let particleY = 2*maxBubbleRadius + 0.1*trackHeight
		skScene.addChild(splashParticle(center: CGPoint(x: bubbleCenterX, y: skView.bounds.height - particleY), color: trackColor))
		progress = value
	}
	
	private func positionOverlayInTrack() {
		let circleCenter = CGPoint(x: bubbleCenterX, y: 2*maxBubbleRadius + 0.5*trackHeight - 0.5*peekingBubbleHeight)
		bubbleOverlay.bounds = CGRect(x: 0, y: 0, width: 0.75*trackHeight, height: 0.75*trackHeight)
		bubbleOverlay.cornerRadius = bubbleOverlay.bounds.height/2
		bubbleOverlay.position = circleCenter
	}
	
	
	// MARK: - Path generation
	
	private func path() -> CGPath {
		let xMax = bounds.width
		let trackRadius = trackHeight/2
		let bezierPath = UIBezierPath()
		let bubbleYMax = 2*maxBubbleRadius
		let bubbleYMin = bubbleYMax - 2*bubbleRadius
		let bubbleYMid = bubbleYMin + bubbleRadius
		
		// left end of track
		bezierPath.move(to: CGPoint(x: trackRadius, y: bubbleYMax))
		bezierPath.addCurve(to: CGPoint(x: 0, y: bubbleYMax+trackRadius),
												controlPoint1: CGPoint(x: trackRadius, y: bubbleYMax),
												controlPoint2: CGPoint(x: 0, y: bubbleYMax))
		
		bezierPath.addCurve(to: CGPoint(x: trackRadius, y: bubbleYMax+trackHeight),
												controlPoint1: CGPoint(x: 0, y: bubbleYMax+trackRadius),
												controlPoint2: CGPoint(x: 0, y: bubbleYMax+trackHeight))
		
		// bottom edge
		bezierPath.addLine(to: CGPoint(x: xMax-trackRadius, y: bubbleYMax+trackHeight))
		
		// right end of track
		bezierPath.addCurve(to: CGPoint(x: xMax, y: bubbleYMax+trackRadius),
												controlPoint1: CGPoint(x: xMax, y: bubbleYMax+trackHeight),
												controlPoint2: CGPoint(x: xMax, y: bubbleYMax+trackRadius))
		
		bezierPath.addCurve(to: CGPoint(x: xMax-trackRadius, y: bubbleYMax),
												controlPoint1: CGPoint(x: xMax, y: bubbleYMax),
												controlPoint2: CGPoint(x: xMax-trackRadius, y: bubbleYMax))
		
		// bubble
		if bubbleHidden {
			let maxRight = bubbleCenterX + minBubbleRadius
			let maxLeft = bubbleCenterX - minBubbleRadius
			let pointCount = 2
			let increment = (maxRight - maxLeft)/CGFloat(pointCount)
			bezierPath.addLine(to: CGPoint(x: xMax-trackRadius, y: bubbleYMax))
			bezierPath.addCurve(to: CGPoint(x: maxRight, y: bubbleYMax),
													controlPoint1: CGPoint(x: xMax-trackRadius, y: bubbleYMax),
													controlPoint2: CGPoint(x: maxRight, y: bubbleYMax))
			bezierPath.addCurve(to: CGPoint(x: maxRight-increment, y: bubbleYMax-peekingBubbleHeight),
													controlPoint1: CGPoint(x: maxRight-peekingBubbleHeight, y: bubbleYMax),
													controlPoint2: CGPoint(x: maxRight-increment+peekingBubbleHeight*2, y: bubbleYMax-peekingBubbleHeight))
			
			bezierPath.addCurve(to: CGPoint(x: maxLeft, y: bubbleYMax),
													controlPoint1: CGPoint(x: maxRight-increment-peekingBubbleHeight*2, y: bubbleYMax-peekingBubbleHeight),
													controlPoint2: CGPoint(x: maxLeft+peekingBubbleHeight, y: bubbleYMax))
			bezierPath.addLine(to: CGPoint(x: trackRadius, y: bubbleYMax))
		} else {
			let innerPointDepth = bubbleRadius*0.285714286
			let outerControlPointDepth = bubbleRadius*0.642857143
			let innerControlPointDepth = bubbleRadius*0.928571429
			bezierPath.addLine(to: CGPoint(x: bubbleCenterX+bubbleRadius-innerPointDepth, y: bubbleYMax))
			bezierPath.addCurve(to: CGPoint(x: bubbleCenterX+bubbleRadius, y: bubbleYMid),
													controlPoint1: CGPoint(x: bubbleCenterX+bubbleRadius-innerControlPointDepth, y: bubbleYMax),
													controlPoint2: CGPoint(x: bubbleCenterX+bubbleRadius, y: bubbleYMid+outerControlPointDepth))
			bezierPath.addCurve(to: CGPoint(x: bubbleCenterX, y: bubbleYMin),
													controlPoint1: CGPoint(x: bubbleCenterX+bubbleRadius, y: bubbleYMin),
													controlPoint2: CGPoint(x: bubbleCenterX, y: bubbleYMin))
			bezierPath.addCurve(to: CGPoint(x: bubbleCenterX-bubbleRadius, y: bubbleYMid),
													controlPoint1: CGPoint(x: bubbleCenterX, y: bubbleYMin),
													controlPoint2: CGPoint(x: bubbleCenterX-bubbleRadius, y: bubbleYMin))
			bezierPath.addCurve(to: CGPoint(x: bubbleCenterX-bubbleRadius+innerPointDepth, y: bubbleYMax),
													controlPoint1: CGPoint(x: bubbleCenterX-bubbleRadius, y: bubbleYMid+outerControlPointDepth),
													controlPoint2: CGPoint(x: bubbleCenterX-bubbleRadius+innerControlPointDepth, y: bubbleYMax))
		}
		// close path
		bezierPath.addLine(to: CGPoint(x: trackRadius, y: bubbleYMax))
		return bezierPath.cgPath
	}
	
	
	// MARK: - Particles
	
	/// Sprite Kit particle shown after bubble dips back down into the track.
	private let particle: SKEmitterNode = {
		// we have to load everything from JellySlider bundle since we're now in a framework
		let particlePath = Bundle.main.url(forResource: "SplashParticle", withExtension: "sks")!
		
		let particleData = try! Data(contentsOf: particlePath)

		let particle = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(particleData) as! SKEmitterNode
		let particleImage = UIImage(named: "spark.png")!
		particle.particleTexture = SKTexture(image: particleImage)
		particle.particleColorBlendFactor = 1
		particle.particleColorSequence = nil
		particle.numParticlesToEmit = 4
		return particle
	}()
	
	private func splashParticle(center: CGPoint, color: UIColor) -> SKEmitterNode {
		let particleCopy = particle.copy() as! SKEmitterNode
		particleCopy.particleColor = color
		particleCopy.position = center
		return particleCopy
	}
	
	
	// MARK: - Layout
	
	override public func layoutSubviews() {
		skView.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height-bottomTouchPadding)
		skScene.size = skView.bounds.size
		shapeLayer.frame = bounds
	}
	
	override public func sizeThatFits(_ size: CGSize) -> CGSize {
		return CGSize(width: size.width, height: 2*maxBubbleRadius + trackHeight + bottomTouchPadding)
	}
	
	private func acceptableXPosition(x: CGFloat) -> CGFloat {
		return min(max(x, edgeBoundaryPadding), bounds.width - edgeBoundaryPadding)
	}
	
	override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		let newArea = CGRect(
			x: self.bounds.origin.x - 8.0,
			y: self.bounds.origin.y - 8.0,
			width: self.bounds.size.width + 32.0,
			height: self.bounds.size.height + 32.0
		)
		return newArea.contains(point)
	}
	
	// MARK: - Touch handling
	override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesBegan(touches, with: event)

		if let touch = touches.first {
			let location = touch.location(in: self)
			startDraggingX = location.x
			let animation = CASpringAnimation(keyPath: "path")
			animation.duration = 0.35
			animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
			shapeLayer.add(animation, forKey: "pathAnimation")
			bubbleHidden = false
			startDraggingX = location.x

			touchPositionX = bubbleCenterX
		}
	}
	
	override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesMoved(touches, with: event)
		
		if let touch = touches.first {
			// check if we have force touch, adjust bubble radius to match force
			if traitCollection.forceTouchCapability == .available {
				let forceValue = min(6, max(1, touch.force))
				let normalForceValue = (forceValue-1)/5
				let additionalValue = normalForceValue * (maxBubbleRadius - minBubbleRadius)
				bubbleRadius = minBubbleRadius + additionalValue
			}
			// update our touch position
			let location = touch.location(in: self)
			
			touchPositionX = touchPositionX + (location.x - startDraggingX)
			startDraggingX = location.x

		}
	}

	override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesEnded(touches, with: event)

		if let touch = touches.first {
			let location = touch.location(in: self)
			
			if location.x == startDraggingX{
				animationIntoTrackAtPosition(x: location.x)
			}else {
				animationIntoTrackAtPosition(x: bubbleCenterX)
			}
		}
		sendActions(for: .valueChanged)
	}
	
	override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesCancelled(touches, with: event)
		animationIntoTrackAtPosition(x: bubbleCenterX)
		sendActions(for: .valueChanged)
	}
}
