//
//  KSTimelineRulerView.swift
//  KSTimeline
//
//  Created by Shih on 24/11/2017.
//  Copyright © 2017 kenshih. All rights reserved.
//

import UIKit

@objc protocol KSTimelineRulerEventDataSource: NSObjectProtocol {
    
    func numberOfEvents(_ ruler: KSTimelineRulerView) -> Int
    
    func timelineRuler(_ ruler: KSTimelineRulerView, eventAt index: Int) -> KSTimelineEvent
    
    func dateOfTimelineRuler(_ ruler: KSTimelineRulerView) -> Date

}

@objc protocol KSTimelineRulerColorDataSource: NSObjectProtocol {
    
    func backgroundColor(_ ruler: KSTimelineRulerView) -> UIColor
    
    func eventColor(_ ruler: KSTimelineRulerView) -> UIColor
    
    func timeColor(_ ruler: KSTimelineRulerView) -> UIColor
    
}

@IBDesignable open class KSTimelineRulerView: UIView {
    
    var dataSource: KSTimelineRulerEventDataSource?
    
    var colorDataSource: KSTimelineRulerColorDataSource?
    
    var drawWave: Bool = false {
        
        didSet {
            
            self.setNeedsDisplay()
            
        }
        
    }
    
    lazy var dateFormatter: DateFormatter = {
        
        var dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "MM월dd일"
        
        return dateFormatter
        
    }()
    
    internal func drawEvent(rect: CGRect) {
        
        guard let dataSource = self.dataSource else { return }
        
        guard let delegate = self.colorDataSource else { return }
                
        let numberOfEvents = dataSource.numberOfEvents(self)
        
        let padding = CGFloat(0)
        
        let contentWidth = self.bounds.width
                
        let unit_hour_width = contentWidth / 24
        
        let unit_minute_width = unit_hour_width / 60
        
        let unit_second_width = unit_minute_width / 60
        
        let unit_gap_height = CGFloat(25)
        
        let wave_height = self.bounds.height - unit_gap_height
        
        let background_color = delegate.backgroundColor(self)
        
        background_color.setFill()
        
        UIRectFill(CGRect(x: 0, y: rect.size.height - wave_height - unit_gap_height, width: contentWidth, height: wave_height))
        
        let event_color = delegate.eventColor(self)
        
        for index in 0..<numberOfEvents {
            
            let event = dataSource.timelineRuler(self, eventAt: index)
            
            let start_hour = Calendar.current.component(.hour, from: event.start)
            
            let start_minute = Double(Calendar.current.component(.minute, from: event.start))
            
            let start_second = Double(Calendar.current.component(.second, from: event.start))
            
            let end_hour = Calendar.current.component(.hour, from: event.end)
            
            let end_minute = Double(Calendar.current.component(.minute, from: event.end))
            
            let end_second = Double(Calendar.current.component(.second, from: event.end))
            
            let start_x = (unit_hour_width * CGFloat(start_hour)) + (unit_minute_width * CGFloat(start_minute)) + (unit_second_width * CGFloat(start_second)) + (padding / 2)

            let end_x = (unit_hour_width * CGFloat(end_hour)) + (unit_minute_width * CGFloat(end_minute)) + (unit_second_width * CGFloat(end_second)) + (padding / 2)
            
            event_color.setFill()
            
            UIRectFill(CGRect(x: start_x, y: rect.size.height - wave_height - unit_gap_height, width: end_x - start_x, height: wave_height))
            
        }
        
    }
    
    internal func drawRoundRect(rect: CGRect) {
        
        let context: CGContext = UIGraphicsGetCurrentContext()!
        
        context.saveGState()
        
        let clipPath: CGPath = UIBezierPath(roundedRect: rect, cornerRadius: 2).cgPath
        
        context.addPath(clipPath)
        
        context.setFillColor(UIColor.init(displayP3Red: 149 / 255, green: 149 / 255, blue: 149 / 255, alpha: 1).cgColor)
        
        context.closePath()
        
        context.fillPath()
        
        context.restoreGState()
        
    }

    override open func draw(_ rect: CGRect) {

        super.draw(rect)
        
        guard let dataSource = self.dataSource else { return }
        
        guard let delegate = self.colorDataSource else { return }
        
        if self.drawWave {
            
            self.drawEvent(rect: rect)
            
        }

        let contentWidth = self.bounds.width

        let unit_hour_width = contentWidth / 24

        let unit_minute_width = unit_hour_width / 6

        let unit_second_width = unit_minute_width / 5

        let unit_hour_height = self.bounds.height / 6

        let unit_minute_height = unit_hour_height / 2

        let unit_sec_height = unit_minute_height / 2

        let show_hour = unit_hour_width > 10 ? true : false

        let show_minute = unit_minute_width > 10 ? true : false

        let show_second = unit_second_width > 10 ? true : false

        let unit_gap_height = CGFloat(25)

        let extra_padding = CGFloat(0)
        
        let font = UIFont.systemFont(ofSize: 14)
        
        let calibration_color: UIColor = UIColor.init(displayP3Red: 17 / 255, green: 17 / 255, blue: 17 / 255, alpha: 1)
        
        let time_color = delegate.timeColor(self)
        
        let textFontAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: time_color,
            NSAttributedString.Key.paragraphStyle: NSParagraphStyle.default
        ]
        
        let text_size = "99:99".sizeOfString(usingFont: font)
        
        let text_width = text_size.width
        
        let text_height = text_size.height
        
        let text_padding = text_width * 2
        
        var draw_hour_if_zero: Int = 0
        
        var draw_minute_if_zero: Int = 0
        
        calibration_color.setFill()

        if show_hour == true {
            
            var unit_hour_gap: Int = Int((text_width + text_padding) / unit_hour_width)
            
            if unit_hour_gap % 2 == 1 {
                
                unit_hour_gap -= 1
                
            }
            
            var unit_minute_gap: Int = Int((text_width + text_padding) / unit_minute_width)
            
            if unit_minute_gap % 2 == 1 {
                
                unit_minute_gap -= 1
                
            }

            for hour in 0...24 {

                let hour_x = CGFloat(hour) * unit_hour_width + extra_padding

                let hour_y = rect.size.height - unit_hour_height

                calibration_color.setFill()

                UIRectFill(CGRect(x: hour_x, y: hour_y - unit_gap_height, width: 1, height: unit_hour_height))

                if show_minute == true {

                    for minute in 0..<6 {

                        let minute_x = CGFloat(minute) * unit_minute_width

                        let minute_y = rect.size.height - unit_minute_height

                        calibration_color.setFill()

                        UIRectFill(CGRect(x: hour_x + minute_x, y: minute_y - unit_gap_height, width: 1, height: unit_minute_height))

                        if show_second == true {

                            for second in 0..<5 {

                                let second_x = CGFloat(second) * unit_second_width

                                let second_y = rect.size.height - unit_sec_height

                                calibration_color.setFill()

                                UIRectFill(CGRect(x: hour_x + minute_x + second_x, y: second_y - unit_gap_height, width: 1, height: unit_sec_height))

                            }

                        }
                        
                        if unit_minute_width > text_width {
                            
                            let text_x = hour_x + minute_x - (text_width / 2)
                            
                            let text_y = rect.size.height - unit_gap_height + ((unit_gap_height - text_height) / 2)
                            
                            if minute != 0 && draw_minute_if_zero == 0 {
                                
                                (String(format: "%02d:%02d", hour, minute*10) as NSString).draw(in: CGRect(x: text_x, y: text_y, width: text_width, height: text_height), withAttributes: textFontAttributes)
                                
                            }
                            
                            draw_minute_if_zero += 1
                            
                            if draw_minute_if_zero >= unit_minute_gap {
                                
                                draw_minute_if_zero = 0
                                
                            }
                        }

                    }

                }

                let text_y = rect.size.height - unit_gap_height + ((unit_gap_height - text_height) / 2)

                if draw_hour_if_zero == 0 {
                    
                    if hour == 0 {
                        
                        let date = dataSource.dateOfTimelineRuler(self)
                        
                        let date_text = date.string(dateFormatter: self.dateFormatter)
                        
                        let date_text_size = date_text.sizeOfString(usingFont: font)
                        
                        let date_text_width = date_text_size.width
                        
                        let text_x = hour_x - (date_text_width / 2)
                        
                        let rect_padding = CGFloat(2)
                        
                        self.drawRoundRect(rect: CGRect(x: text_x - rect_padding, y: text_y - rect_padding, width: date_text_width + rect_padding * 2, height: date_text_size.height + rect_padding * 2))
                        
                        (date_text as NSString).draw(in: CGRect(x: text_x, y: text_y, width: date_text_width, height: text_height), withAttributes: [
                            NSAttributedString.Key.font: font,
                            NSAttributedString.Key.foregroundColor: UIColor.white,
                            NSAttributedString.Key.paragraphStyle: NSParagraphStyle.default
                            ])
                        
                    } else if hour == 24 {
                        
                        let date = Calendar.current.date(byAdding: Calendar.Component.day, value: 1, to: dataSource.dateOfTimelineRuler(self))!
                        
                        let date_text = date.string(dateFormatter: self.dateFormatter)
                        
                        let date_text_size = date_text.sizeOfString(usingFont: font)
                        
                        let date_text_width = date_text_size.width
                        
                        let text_x = hour_x - (date_text_width / 2)
                        
                        let rect_padding = CGFloat(2)
                        
                        self.drawRoundRect(rect: CGRect(x: text_x - rect_padding, y: text_y - rect_padding, width: date_text_width + rect_padding * 2, height: date_text_size.height + rect_padding * 2))
                        
                        (date_text as NSString).draw(in: CGRect(x: text_x, y: text_y, width: date_text_width, height: text_height), withAttributes: [
                            NSAttributedString.Key.font: font,
                            NSAttributedString.Key.foregroundColor: UIColor.white,
                            NSAttributedString.Key.paragraphStyle: NSParagraphStyle.default
                            ])
                        
                    } else {
                        
                        let text_x = hour_x - (text_width / 2)
                        
                        (String(format: "%02d:00", hour) as NSString).draw(in: CGRect(x: text_x, y: text_y, width: text_width, height: text_height), withAttributes: textFontAttributes)
                    }
                }
                
                draw_hour_if_zero += 1
                
                if draw_hour_if_zero >= unit_hour_gap {
                    
                    draw_hour_if_zero = 0
                    
                }
                
            }

            calibration_color.setFill()

            UIRectFill(CGRect(x: extra_padding, y: rect.size.height - unit_gap_height, width: rect.size.width - extra_padding*2, height: 1))

        }
        
    }
    
    override open func layoutSubviews() {
        
        super.layoutSubviews()
        
        self.backgroundColor = UIColor.clear
                
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
    }
    
    override open func prepareForInterfaceBuilder() {
        
        super.prepareForInterfaceBuilder()
        
    }

}
