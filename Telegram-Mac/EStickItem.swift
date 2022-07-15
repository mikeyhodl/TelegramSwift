//
//  EStickItem.swift
//  Telegram-Mac
//
//  Created by keepcoder on 17/10/2016.
//  Copyright © 2016 Telegram. All rights reserved.
//

import Cocoa
import TGUIKit
class EStickItem: TableRowItem {
    
    override var height: CGFloat {
        return 30
    }
        
    override var stableId: AnyHashable {
        return _stableId
    }
    private let _stableId: AnyHashable
    
    let layout:(TextNodeLayout, TextNode)
    
    init(_ initialSize:NSSize, stableId: AnyHashable, segmentName:String) {
        self._stableId = stableId
        layout = TextNode.layoutText(maybeNode: nil,  NSAttributedString.initialize(string: segmentName.uppercased(), color: theme.colors.grayText, font: .medium(.short)), nil, 1, .end, NSMakeSize(.greatestFiniteMagnitude, .greatestFiniteMagnitude), nil, false, .left)
        super.init(initialSize)
    }
    
    override func viewClass() -> AnyClass {
        return EStickView.self
    }
}


private class EStickView: TableStickView {
    
    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        layerContentsRedrawPolicy = .onSetNeedsDisplay
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var backdorColor: NSColor {
        return theme.colors.background
    }

    override func set(item: TableRowItem, animated: Bool) {
        super.set(item: item, animated: animated)
        needsDisplay = true
    }
    
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        super.draw(layer, in: ctx)
        
        if header {
            ctx.setFillColor(theme.colors.border.cgColor)
            ctx.fill(NSMakeRect(0, frame.height - .borderSize, frame.width, .borderSize))
        }
        
        if let item = item as? EStickItem {
            var f = focus(item.layout.0.size)
//            f.origin.x = 20
            f.origin.y -= 1
            item.layout.1.draw(f, in: ctx, backingScaleFactor: backingScaleFactor, backgroundColor: backdorColor)
        }
    }
    
}
