# InfiniteKSTimeline

InfiniteKSTimeline,
It was created by adding [StreetScroller-Swift](https://github.com/ooper-shlab/StreetScroller-Swift)'s [InfiniteScrollView](https://github.com/ooper-shlab/StreetScroller-Swift/blob/master/StreetScroller/InfiniteScrollView.swift) to [KSTimeline](https://github.com/KenShih522/KSTimeline).

InfiniteKSTimeline, written in swift, is a simple and customizable view which supports showing a series of events in infinite vertically time-sorted structure.

## Requirements
-  Swift 5

## Preview

### Demo1

 - adjust the time scale by pinch gesture<br />
 - display different time mode according to time scale<br />

<p align="center"> 
<img src="https://i.imgur.com/2rTvNMW.gif">
</p>

### Demo2

 - play next event automatically<br />
 - scroll to seek video<br />
 - press > to next video<br />
 - press < to previous video<br />
 
<p align="center"> 
<img src="https://i.imgur.com/uBbtaY1.gif">
</p>

## Usage

#### Delegate

```swift
@objc public protocol KSTimelineDelegate: NSObjectProtocol {
    
    func timelineStartScroll(_ timeline: KSTimelineView)
    
    func timelineEndScroll(_ timeline: KSTimelineView)
    
    func timeline(_ timeline: KSTimelineView, didScrollTo date: Date)
    
}
```

#### Datasource

```swift
@objc public protocol KSTimelineDatasource: NSObjectProtocol {
    
    func numberOfEvents(_ timeline: KSTimelineView, dateOfSource date: Date) -> Int
    
    func event(_ timeline: KSTimelineView, dateOfSource date: Date, at index: Int) -> KSTimelineEvent
    
}
```

#### KSTimelineEvent

```swift
@objc public class KSTimelineEvent: NSObject {
    
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
```

# Installation
you need to copy the content of the KSTimeline folder into your project
