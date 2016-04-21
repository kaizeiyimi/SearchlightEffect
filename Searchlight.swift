//
//  SearchlightEffect.swift
//
//  Created by kaizei on 16/2/1.
//  Copyright © 2016年 kaizei. All rights reserved.
//

import UIKit

public struct SearchlightConfig {
    var lightColor = UIColor.whiteColor()
    var radius:(start: CGFloat, end: CGFloat)? = nil
    var speed = 120.0   // nagative moves R2L.
}

extension UIView {
    private struct AssociatedKeys {
        static var kSearchlightLayerKey = "kSearchlightLayerKey"
    }
    
    func xly_setSearchlight(config: SearchlightConfig? = SearchlightConfig()) {
        xly_removeSearchlight()
        maskView = snapshotViewAfterScreenUpdates(true)
        var config = config
        config?.radius = config?.radius ?? (bounds.height * 0.6, bounds.height * 1.8)
        
        let searchlightLayer = SearchlightLayer()
        searchlightLayer.config = config
        searchlightLayer.frame = CGRectMake(0, 0, config!.radius!.end * 2, bounds.height)
        searchlightLayer.position = CGPointMake(bounds.width / 2, bounds.height / 2)
        searchlightLayer.link.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        
        layer.addSublayer(searchlightLayer)
        searchlightLayer.setNeedsDisplay()
        
        objc_setAssociatedObject(self, &AssociatedKeys.kSearchlightLayerKey, searchlightLayer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func xly_removeSearchlight() {
        (objc_getAssociatedObject(self, &AssociatedKeys.kSearchlightLayerKey) as? CALayer)?.removeFromSuperlayer()
        objc_setAssociatedObject(self, &AssociatedKeys.kSearchlightLayerKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        maskView = nil
    }
}


final private class SearchlightLayer: CALayer {
    var config: SearchlightConfig!
    lazy var link: CADisplayLink = {
        let link = CADisplayLink(target: TargetWrapper(self), selector: #selector(linkFired(_:)))
        return link
    }()
    
    deinit {
        link.invalidate()
    }
    
    @objc func linkFired(link: CADisplayLink) {
        guard let superlayer = superlayer else { return }
        var nextX = self.position.x + CGFloat(link.duration * config.speed)
        let endRadius = config.radius!.end
        if nextX > superlayer.frame.width + endRadius {
            nextX = -config.radius!.end
        } else if nextX < -endRadius {
            nextX = superlayer.frame.width + config.radius!.end
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        var position = self.position
        position.x = nextX
        self.position = position
        CATransaction.commit()
    }
    
    override func drawInContext(ctx: CGContext) {
        let locations: [CGFloat] = [0, 1]
        let gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [config.lightColor.CGColor, UIColor.clearColor().CGColor], locations)
        let radius = config.radius!
        CGContextDrawRadialGradient(ctx, gradient, CGPointMake(bounds.midX, bounds.midY), radius.start, CGPointMake(bounds.midX, bounds.midY), radius.end, .DrawsBeforeStartLocation)
    }
}

final private class TargetWrapper: NSObject {
    weak var target: AnyObject?
    init(_ target: AnyObject) {
        self.target = target
    }
    
    private override func forwardingTargetForSelector(aSelector: Selector) -> AnyObject? {
        return target
    }
}
