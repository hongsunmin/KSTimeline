//
//  KSTimelineView.swift
//  KSTimeline
//
//  Created by Shih on 24/11/2017.
//  Copyright © 2017 kenshih. All rights reserved.
//

import UIKit

@objc public protocol KSTimelineDelegate: NSObjectProtocol {
    
    func timelineStartScroll(_ timeline: KSTimelineView)
    
    func timelineEndScroll(_ timeline: KSTimelineView)
    
    func timeline(_ timeline: KSTimelineView, didScrollTo date: Date)
    
}

@objc public protocol KSTimelineDatasource: NSObjectProtocol {
    
    func numberOfEvents(_ timeline: KSTimelineView, dateOfSource date: Date) -> Int
    
    func event(_ timeline: KSTimelineView, dateOfSource date: Date, at index: Int) -> KSTimelineEvent
    
}

@objcMembers public class KSTimelineEvent: NSObject {
    
    public var start: Date
    
    public var end: Date
    
    public var duration: Double
    
    public var videoURL: URL?
    
    public init(start: Date, end: Date, duration: Double, videoURL: URL?) {
        
        self.start = start
        
        self.end = end
        
        self.duration = duration
        
        self.videoURL = videoURL
        
        super.init()
        
    }
        
}

extension UIScreen {
    
    func widthOfSafeArea() -> CGFloat {
        
        guard let rootView = UIApplication.shared.keyWindow else { return 0 }
        
        if #available(iOS 11.0, *) {
            
            let leftInset = rootView.safeAreaInsets.left
            
            let rightInset = rootView.safeAreaInsets.right
            
            return rootView.bounds.width - leftInset - rightInset
            
        } else {
            
            return rootView.bounds.width
            
        }
        
    }
    
    func heightOfSafeArea() -> CGFloat {
        
        guard let rootView = UIApplication.shared.keyWindow else { return 0 }
        
        if #available(iOS 11.0, *) {
            
            let topInset = rootView.safeAreaInsets.top
            
            let bottomInset = rootView.safeAreaInsets.bottom
            
            return rootView.bounds.height - topInset - bottomInset
            
        } else {
            
            return rootView.bounds.height
            
        }
        
    }
    
}

enum KSTimelineScrollDirection {
    case Left, Right, None
}

@IBDesignable @objcMembers open class KSTimelineView: UIView {
    
    public var delegate: KSTimelineDelegate?
    
    public var datasource: KSTimelineDatasource?
    
    public var basedDate: Date!
    
    public var currentDate: Date!
    
    public var isScrollingLocked = false

    public let contentView = InfiniteScrollView()
    
    public var minDate: Date?
    
    public var maxDate: Date!
    
    public var rulerWidth: CGFloat = 375 {
        
        didSet {
            
            guard self.rulerWidth != oldValue else { return }
            
            self.contentView.rulerView.frame.size = CGSize(
                width: self.rulerWidth * round(self.scale),
                height: self.contentView.rulerView.frame.height
            )
            
        }
        
    }
    
    let currentIndicator: CAShapeLayer = CAShapeLayer()
    
    var pinchGesture: UIPinchGestureRecognizer!
    
    var lastScale: CGFloat = 24.0
    
    var scale: CGFloat = 24.0
    
    var isPinching = false
    
    var lastContentOffsetX: CGFloat?
    
    @IBInspectable var contentWidth: CGFloat = 2400
    
    @IBInspectable var rulerBackgroundColor: UIColor = UIColor.white
    
    @IBInspectable var rulerEventColor: UIColor = UIColor.blue
    
    @IBInspectable var rulerTimeColor: UIColor = UIColor.black
    
    // MARK: Public Methods
    
    public func scrollToDate(date: Date) {
        
        let hour = Calendar.current.component(.hour, from: date)
        
        let minute = Calendar.current.component(.minute, from: date)
        
        let second = Calendar.current.component(.second, from: date)
        
        let contentWidth = self.contentView.rulerView.frame.width
        
        let unit_hour_width = contentWidth / 24.0
        
        let unit_minute_width = unit_hour_width / 60.0
        
        let unit_second_width = unit_minute_width / 60.0
        
        let newOffset = (unit_hour_width * CGFloat(hour)) + (unit_minute_width * CGFloat(minute)) + (unit_second_width * CGFloat(second))
        
        let pointOfScroll = self.contentView.convert(CGPoint(x: newOffset, y: 0), from: self.contentView.rulerViews.first)
        
        let delegate = self.contentView.delegate
        
        self.contentView.delegate = nil;
        
        UIView.performWithoutAnimation {
            
            self.contentView.contentOffset = CGPoint(x: pointOfScroll.x + self.bounds.width / 2 - (self.bounds.width - contentWidth), y: 0)
            
        }

        self.contentView.delegate = delegate;
        
        if self.contentView.isDecelerating {
            
            self.lastContentOffsetX = nil
            
            return
            
        } else {
            
            self.lastContentOffsetX = self.contentView.contentOffset.x
            
        }
    
        self.currentDate = date
        
        self.basedDate = self.currentDate
        
        self.contentView.rulerView.setNeedsDisplay()
        
    }
    
    override open func draw(_ rect: CGRect) {
        
        super.draw(rect)
        
        self.backgroundColor = UIColor.clear
        
    }
    
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
    
    override open func layoutSubviews() {
        
        super.layoutSubviews()
        
        self.contentView.setNeedsDisplay()
        
        let x = (self.bounds.size.width / 2)
        
        let y = CGFloat(0)
        
        let width = CGFloat(10)
        
        let height = self.bounds.height
        
        let frame = CGRect(x: x, y: y, width: width, height: height)
                
        self.currentIndicator.frame = frame
        
    }
    
    open override func setNeedsDisplay() {
        
        super.setNeedsDisplay()
        
        self.contentView.rulerView.setNeedsDisplay()
        
    }
    
    func commonInit() {
        
        let now = Date()
        
        self.basedDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: now)
        
        self.currentDate = self.basedDate
        
        self.maxDate = Calendar.current.date(byAdding: .day, value: 1, to: self.basedDate)
        
        self.setupView()
        
        self.pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(KSTimelineView.pinch(gesture:)))

        self.contentView.addGestureRecognizer(self.pinchGesture)
        
        self.contentView.contentSize = CGSize(width: self.contentWidth * scale, height: self.bounds.height)
        
        self.contentView.rulerView.frame.size = CGSize(width: self.rulerWidth * scale, height: self.bounds.height)
        
        self.contentView.zoomScale = scale;
                                
    }
    
    @objc func pinch(gesture: UIPinchGestureRecognizer) {
        
        if gesture.state == .began {
            
            lastScale = gesture.scale
            
            self.isPinching = true
            
        }
        
        let kMaxScale: CGFloat = 50.0
        
        let kMinScale: CGFloat = 1.0
        
        let currentScale = max(min(gesture.scale * scale, kMaxScale), kMinScale)
        
        self.contentView.contentSize = CGSize(width: round(self.contentWidth * currentScale), height: self.bounds.size.height)

        self.contentView.rulerView.frame.size = CGSize(width: round(self.rulerWidth * currentScale), height: self.bounds.size.height)

        let hour = Calendar.current.component(.hour, from: self.currentDate)
        
        let minute = Calendar.current.component(.minute, from: self.currentDate)
        
        let second = Calendar.current.component(.second, from: self.currentDate)
        
        let contentWidth = self.contentView.rulerView.frame.width
        
        let unit_hour_width = contentWidth / 24.0
        
        let unit_minute_width = unit_hour_width / 60.0
        
        let unit_second_width = unit_minute_width / 60.0
        
        let newOffset = (unit_hour_width * CGFloat(hour)) + (unit_minute_width * CGFloat(minute)) + (unit_second_width * CGFloat(second))
        
        let pointOfScroll = self.contentView.convert(CGPoint(x: newOffset, y: 0), from: self.contentView.rulerViews.first)
        
        UIView.performWithoutAnimation {
            
            self.contentView.contentOffset = CGPoint(x: pointOfScroll.x - self.bounds.width / 2, y: 0)
            
        }
        
        self.contentView.rulerView.setNeedsDisplay()
        
        lastScale = currentScale
        
        if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            
            scale = currentScale
            
            self.isPinching = false
            
            self.lastContentOffsetX = self.contentView.contentOffset.x
            
        }
        
    }
    
    internal func setupView() {

        self.addSubview(self.contentView)
        
        self.contentView.delegate = self
        
        self.contentView.infiniteScrollDelegate = self;
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentView.rulerView.dataSource = self
        
        self.contentView.rulerView.colorDataSource = self
        
        self.contentView.rulerView.frame.size = CGSize(width: self.rulerWidth, height: self.bounds.size.height)
        
        self.addConstraint(NSLayoutConstraint(item: self.contentView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: self.contentView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: self.contentView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))

        self.addConstraint(NSLayoutConstraint(item: self.contentView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))

        self.contentView.bounces = false
        
        self.setupCurrentIndicator()
        
    }
    
    internal func setupCurrentIndicator() {
        
        let triangle = UIBezierPath()
        
        triangle.move(to: CGPoint(x: -5, y: 0))
        
        triangle.addLine(to: CGPoint(x: 5, y: 0))
        
        triangle.addLine(to: CGPoint(x: 0, y: 10))
        
        triangle.close()
        
        let line = CALayer()
        
        line.frame = CGRect(x: -0.5, y: 0, width: 1, height: self.bounds.height)
        
        line.backgroundColor = UIColor.red.cgColor
        
        self.currentIndicator.path = triangle.cgPath
        
        self.currentIndicator.fillColor = UIColor.red.cgColor
        
        self.currentIndicator.addSublayer(line)
        
        self.layer.addSublayer(self.currentIndicator)
        
    }

}

extension KSTimelineView: UIScrollViewDelegate {
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        self.delegate?.timelineStartScroll(self)
        
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard isPinching == false && isScrollingLocked == false else { return }
        
        guard let target_date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self.basedDate) else { return }
        
        var direction: KSTimelineScrollDirection = .None
        
        if self.lastContentOffsetX != nil {
            
            if self.lastContentOffsetX! > scrollView.contentOffset.x {
                
                direction = .Left
                
            } else if self.lastContentOffsetX! < scrollView.contentOffset.x {
                
                direction = .Right
                
            }
            
        }
        
        self.lastContentOffsetX = scrollView.contentOffset.x
        
        let ruler_width = self.contentView.rulerView.frame.width
        
        let unit_hour_width = ruler_width / 24
        
        let unit_minute_width = unit_hour_width / 60
        
        let unit_second_width = unit_minute_width / 60
        
        let timeline_x = self.bounds.width / 2
        
        var hour = Int(floor(timeline_x / unit_hour_width))
        
        var minute = Int(floor((timeline_x - (CGFloat(hour) * unit_hour_width)) / unit_minute_width))
        
        var second = Int(floor((timeline_x - (CGFloat(hour) * unit_hour_width) - (CGFloat(minute) * unit_minute_width)) / unit_second_width))
        
        for view in self.contentView.rulerViews {
            
            let point_in_view = self.convert(CGPoint(x: timeline_x, y: 0), to: view)
            
            if point_in_view.x >= 0 && point_in_view.x <= ruler_width {
                
                hour = Int(floor(point_in_view.x / unit_hour_width))
                
                minute = Int(floor((point_in_view.x - (CGFloat(hour) * unit_hour_width)) / unit_minute_width))
                
                second = Int(floor((point_in_view.x - (CGFloat(hour) * unit_hour_width) - (CGFloat(minute) * unit_minute_width)) / unit_second_width))
                
            }
            
        }
        
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        
        if let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: second, of: target_date) {
            
            let last_hour = Calendar.current.component(.hour, from: self.currentDate)
            
            self.currentDate = date
            
            if ((direction == .None && translation.x > 0) || direction == .Left) && hour > last_hour {
                
                self.currentDate = Calendar.current.date(byAdding: Calendar.Component.day, value: -1, to: self.currentDate)
                
            } else if ((direction == .None && translation.x < 0) || direction == .Right) && hour < last_hour {
                
                self.currentDate = Calendar.current.date(byAdding: Calendar.Component.day, value: 1, to: self.currentDate)
                
            }
            
            if direction == .None {
                
                self.contentView.rulerView.setNeedsDisplay()
                
            }
            
            self.basedDate = self.currentDate
            
        } else {
            
            self.currentDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: target_date)
            
        }
        
        self.delegate?.timeline(self, didScrollTo: self.currentDate)
        
        let is_min_date = translation.x > 0 && self.minDate != nil && self.currentDate < self.minDate!
        
        let is_max_date = translation.x < 0 && self.currentDate > maxDate
        
        if is_min_date {
            
            let point_in_view = self.contentView.convert(CGPoint(x: 0, y: 0), from: self.contentView.rulerViews.first)
            
            UIView.performWithoutAnimation {
                
                self.contentView.contentOffset = CGPoint(x: point_in_view.x + self.bounds.width / 2 - (self.bounds.width - ruler_width), y: 0)
                
            }
            
            self.contentView.rulerView.setNeedsDisplay()
            
        } else if is_max_date {
            
            let point_in_view = self.contentView.convert(CGPoint(x: 0, y: 0), from: self.contentView.rulerViews.first)
            
            let distance_day = Calendar.current.dateComponents([.day], from: self.currentDate, to: self.maxDate).day!
            
            UIView.performWithoutAnimation {
                
                let distance_from_ruler = ruler_width * CGFloat(distance_day)
                
                self.contentView.contentOffset = CGPoint(
                    x: point_in_view.x + self.bounds.width / 2 + distance_from_ruler - (self.bounds.width - ruler_width),
                    y: 0)
                
            }
            
            self.contentView.rulerView.setNeedsDisplay()
            
        }

    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let is_min_date = self.minDate != nil && self.currentDate <= self.minDate!
        
        let is_max_date = self.currentDate >= self.maxDate
        
        let ruler_width = contentView.rulerView.frame.width
        
        let point_in_view = contentView.convert(CGPoint(x: 0, y: 0), from: contentView.rulerViews.first)
        
        let timeline_x = self.bounds.width / 2
        
        var i = 0, ruler_index = 0
        
        for view in self.contentView.rulerViews {
            
            let point_in_view = self.convert(CGPoint(x: timeline_x, y: 0), to: view)
            
            if point_in_view.x >= 0 && point_in_view.x < ruler_width {
                
                ruler_index = i
                
            }
            
            i += 1
        }
        
        let distance_min_day = 1
        
        let distance_max_day = Calendar.current.dateComponents([.day], from: self.currentDate, to: self.maxDate).day!
        
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView.superview)

        if translation.x > 0 && is_min_date {
        
            targetContentOffset.pointee.x = point_in_view.x + self.bounds.width / 2 - (self.bounds.width - ruler_width)
            
        } else if translation.x < 0 && is_max_date {
            
            targetContentOffset.pointee.x = point_in_view.x + self.bounds.width / 2 - (self.bounds.width - ruler_width)
            
        } else {
            
            let translation = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
            
            if translation.x > 0 {
                
                if targetContentOffset.pointee.x < self.contentView.contentOffset.x - self.bounds.width {
                    
                    targetContentOffset.pointee.x = self.contentView.contentOffset.x - self.bounds.width
                    
                }
                
                if targetContentOffset.pointee.x < point_in_view.x + self.bounds.width / 2 + ruler_width * CGFloat(ruler_index) - ruler_width * CGFloat(distance_min_day) - (self.bounds.width - ruler_width) {

                    targetContentOffset.pointee.x = point_in_view.x + self.bounds.width / 2 + ruler_width * CGFloat(ruler_index) - ruler_width * CGFloat(distance_min_day) - (self.bounds.width - ruler_width)
                }
                
            } else {
                
                if targetContentOffset.pointee.x > self.contentView.contentOffset.x + self.bounds.width {
                    
                    targetContentOffset.pointee.x = self.contentView.contentOffset.x + self.bounds.width
                    
                }
                
                var distance_day = distance_max_day
                
                if distance_day == 0 {
                    
                    if self.currentDate < self.maxDate {

                        distance_day += 1
                    }
                    
                } else if distance_day > 1 {
                    
                    distance_day = 1
                }
                
                if targetContentOffset.pointee.x > point_in_view.x + self.bounds.width / 2 + ruler_width * CGFloat(ruler_index) - (self.bounds.width - ruler_width) {

                    targetContentOffset.pointee.x = point_in_view.x + self.bounds.width / 2 + ruler_width * CGFloat(ruler_index) - (self.bounds.width - ruler_width)

                }
                
            }
            
        }
        
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        if !decelerate {
            
            self.delegate?.timelineEndScroll(self)
            
        }
        
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        self.delegate?.timelineEndScroll(self)
        
    }
    
}

extension KSTimelineView: KSTimelineRulerEventDataSource {
    
    func numberOfEvents(_ ruler: KSTimelineRulerView) -> Int {
        
        guard let datasource = self.datasource else { return 0 }
        
        let date = self.dateOfTimelineRuler(ruler)
        
        return datasource.numberOfEvents(self, dateOfSource: date)
        
    }
    
    func timelineRuler(_ ruler: KSTimelineRulerView, eventAt index: Int) -> KSTimelineEvent {
        
        let date = self.dateOfTimelineRuler(ruler)
        
        return self.datasource!.event(self, dateOfSource: date, at: index)
    }
    
    func dateOfTimelineRuler(_ ruler: KSTimelineRulerView) -> Date {
        
        let ruler_width = self.contentView.rulerView.frame.width
        
        let timeline_x = self.bounds.width / 2
        
        let point_in_view = self.convert(CGPoint(x: timeline_x, y: 0), to: ruler)
        
        let hour = Calendar.current.component(.hour, from: self.currentDate)
        
        if point_in_view.x < 0 || (point_in_view.x == 0 && hour == 23) {
            
            return Calendar.current.date(byAdding: Calendar.Component.day, value: 1 + abs(Int(point_in_view.x / ruler_width)), to: self.currentDate)!
            
        } else if point_in_view.x > ruler_width || (point_in_view.x == ruler_width && hour == 0) {
            
            return Calendar.current.date(byAdding: Calendar.Component.day, value: -abs(Int(point_in_view.x / ruler_width)), to: self.currentDate)!
        }
        
        return self.currentDate
        
    }
    
}

extension KSTimelineView: KSTimelineRulerColorDataSource {
    
    func backgroundColor(_ ruler: KSTimelineRulerView) -> UIColor {
        
        return self.rulerBackgroundColor
        
    }
    
    func eventColor(_ ruler: KSTimelineRulerView) -> UIColor {
        
        return self.rulerEventColor
        
    }
    
    func timeColor(_ ruler: KSTimelineRulerView) -> UIColor {
        
        return self.rulerTimeColor
        
    }
    
}

extension KSTimelineView: InfiniteScrollDelegate {
    
    func relocate() {
        
        self.scrollToDate(date: self.currentDate)
        
    }
    
}
