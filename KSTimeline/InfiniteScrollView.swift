//
//  InfiniteScrollView.swift
//  StreetScroller
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/7/14.
//
//
/*
     File: InfiniteScrollView.h
     File: InfiniteScrollView.m
 Abstract: This view tiles UILabel instances to give the effect of infinite scrolling side to side.
  Version: 1.2

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

 Copyright (C) 2013 Apple Inc. All Rights Reserved.

 */

import UIKit

public class RulerViewAdapter: NSObject {
    
    var adapter: InfiniteScrollView?
    
    public var frame: CGRect {
        
        didSet {
            
            guard let adapter = self.adapter else { return }
            
            guard !self.frame.size.equalTo(oldValue.size) else { return }
            
            var left: CGFloat?
            
            let sortedViews = adapter.rulerViews.sorted(by: { (left, right) in return left.frame.minX <= right.frame.minX })
            
            for view in sortedViews {
                
                view.frame.size = self.frame.size
                
                if left != nil {
                    
                    var point: CGPoint = view.frame.origin
                    
                    point.x = left!
                    
                    view.frame.origin = point
                    
                }
                
                left = view.frame.maxX
            }
            
        }
        
    }
    
    var dataSource: KSTimelineRulerEventDataSource? {
        
        didSet {
            
            guard let adapter = self.adapter else { return }
            
            for view in adapter.rulerViews {
                
                view.dataSource = self.dataSource
                
            }
            
        }
        
    }
    
    var colorDataSource: KSTimelineRulerColorDataSource? {
        
        didSet {
            
            guard let adapter = self.adapter else { return }
            
            for view in adapter.rulerViews {
                
                view.colorDataSource = self.colorDataSource
                
            }
            
        }
        
    }
    
    override init() {
        
        self.frame = CGRect.init()
        
        super.init()
        
    }
    
    public func setNeedsDisplay() {
        
        guard let adapter = self.adapter else { return }
        
        for view in adapter.rulerViews {
            
            view.setNeedsDisplay()
            
        }
        
    }
    
}

@objc protocol InfiniteScrollDelegate: NSObjectProtocol {
    
    func relocate()
    
}

@objcMembers
@IBDesignable open class InfiniteScrollView: UIScrollView, UIScrollViewDelegate {
    
    private var visibleRulerViews: [KSTimelineRulerView] = []
    
    private let rulerViewContainerView: UIView = UIView()
    
    public var rulerView: RulerViewAdapter = RulerViewAdapter()
    
    public var rulerViews: [KSTimelineRulerView]  {
        
        get {
            
            return visibleRulerViews
            
        }
        
    }
    
    override open var contentSize: CGSize {
        
        didSet {
            
            guard !self.contentSize.equalTo(oldValue) else { return }
            
            let containerViewCenter: CGPoint = self.rulerViewContainerView.center
            
            self.rulerViewContainerView.frame.size = self.contentSize
            
            if self.contentSize.height == oldValue.height {
                
                self.rulerViewContainerView.center = containerViewCenter
                
            }
            
        }
        
    }
    
    var infiniteScrollDelegate: InfiniteScrollDelegate?
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.commonInit()
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.commonInit()
        
    }
    
    override open func prepareForInterfaceBuilder() {
        
        super.prepareForInterfaceBuilder()
        
        self.commonInit()
        
    }
    
    internal func commonInit() {
        
        self.addSubview(self.rulerViewContainerView)

        self.rulerViewContainerView.isUserInteractionEnabled = false
        
        // hide horizontal scroll indicator so our recentering trick is not revealed
        self.showsHorizontalScrollIndicator = false
        
        self.rulerView.adapter = self
        
        self.decelerationRate = UIScrollView.DecelerationRate.normal
        
    }
    
    
    //MARK: - Layout
    
    // recenter content periodically to achieve impression of infinite scrolling
    private func recenterIfNecessary() {
        
        let currentOffset = self.contentOffset
        
        let contentWidth = self.contentSize.width
        
        let centerOffsetX = (contentWidth - self.bounds.size.width) / 2.0
        
        let distanceFromCenter = abs(currentOffset.x - centerOffsetX)
        
        if distanceFromCenter > (contentWidth / 4.0) {
            
            let distanceNeedMove: (CGFloat) = centerOffsetX - currentOffset.x
            
            // move content by the same amount so it appears to stay still
            for label in self.visibleRulerViews {
                
                var center = self.rulerViewContainerView.convert(label.center, to: self)
                
                center.x += distanceNeedMove
                
                label.center = self.convert(center, to: self.rulerViewContainerView)
                
            }
            
            infiniteScrollDelegate?.relocate()
        }
        
    }
    
    override open func layoutSubviews() {
        
        super.layoutSubviews()
        
        self.recenterIfNecessary()
        
        // tile content in visible bounds
        let visibleBounds = self.convert(self.bounds, to: self.rulerViewContainerView)
        
        let minimumVisibleX = visibleBounds.minX
        
        let maximumVisibleX = visibleBounds.maxX
        
        self.tileLabelsFromMinX(minimumVisibleX, toMaxX: maximumVisibleX)
        
    }
    
    
    //MARK: - Label Tiling
    
    private func insertRulerView() -> KSTimelineRulerView {
        
        let label = KSTimelineRulerView(frame: CGRect(x: 0, y: 0, width: rulerView.frame.width, height: rulerView.frame.height))
        
        label.dataSource = rulerView.dataSource
        
        label.colorDataSource = rulerView.colorDataSource
        
        label.drawWave = true
        
        self.rulerViewContainerView.addSubview(label)
        
        return label
        
    }
    
    private func placeNewRulerViewOnRight(_ rightEdge: CGFloat) -> CGFloat {
        
        let label = self.insertRulerView()
        
        self.visibleRulerViews.append(label) // add rightmost label at the end of the array
        
        var frame = label.frame
        
        frame.origin.x = rightEdge
        
        frame.origin.y = self.rulerViewContainerView.bounds.size.height - frame.size.height
        
        label.frame = frame
        
        return frame.maxX
        
    }
    
    private func placeNewRulerViewOnLeft(_ leftEdge: CGFloat) -> CGFloat {
        
        let label = self.insertRulerView()
        
        self.visibleRulerViews.insert(label, at: 0) // add leftmost label at the beginning of the array

        var frame = label.frame
        
        frame.origin.x = leftEdge - frame.size.width
        
        frame.origin.y = self.rulerViewContainerView.bounds.size.height - frame.size.height
        
        label.frame = frame
        
        return frame.minX
        
    }
    
    private func tileLabelsFromMinX(_ minimumVisibleX: CGFloat, toMaxX maximumVisibleX: CGFloat) {
        
        // the upcoming tiling logic depends on there already being at least one label in the visibleLabels array, so
        // to kick off the tiling we need to make sure there's at least one label
        if self.visibleRulerViews.isEmpty {
            
            _ = self.placeNewRulerViewOnRight(minimumVisibleX)
            
        }
        
        // add labels that are missing on right side
        let lastRulerView = self.visibleRulerViews.last!
        
        var rightEdge = lastRulerView.frame.maxX
        
        while self.visibleRulerViews.count == 1 || rightEdge < maximumVisibleX {
            
            rightEdge = self.placeNewRulerViewOnRight(rightEdge)
            
        }
        
        // add labels that are missing on left side
        let firstRulerView = self.visibleRulerViews[0]
        
        var leftEdge = firstRulerView.frame.minX
        
        while leftEdge > minimumVisibleX {
            
            leftEdge = self.placeNewRulerViewOnLeft(leftEdge)
            
        }
        
        // remove labels that have fallen off right edge
        while let lastRulerView = self.visibleRulerViews.last, lastRulerView.frame.origin.x > maximumVisibleX {
            
            lastRulerView.removeFromSuperview()
            
            self.visibleRulerViews.removeLast()
            
        }
        
        // remove labels that have fallen off left edge
        while let firstRulerView = self.visibleRulerViews.first, firstRulerView.frame.maxX < minimumVisibleX {
            
            firstRulerView.removeFromSuperview()
            
            self.visibleRulerViews.removeFirst()
            
        }
        
    }
    
}
