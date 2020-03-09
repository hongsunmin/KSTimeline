//
//  Date+Formatter.swift
//  KSTimeline
//
//  Created by hongsunmin on 2020/03/09.
//  Copyright © 2020 kenshih. All rights reserved.
//

import Foundation

extension Date {
    
    func string(dateFormatter: DateFormatter) -> String {
        
        return dateFormatter.string(from: self)
        
    }
    
}
