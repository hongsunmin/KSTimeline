//
//  String+DrawingAdditions.swift
//  KSTimeline
//
//  Created by hongsunmin on 2020/03/09.
//  Copyright © 2020 kenshih. All rights reserved.
//

import Foundation

extension String {
    
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        
        let fontAttributes = [NSAttributedString.Key.font: font]
        
        let size = self.size(withAttributes: fontAttributes)
        
        return size.width
        
    }
    
    func heightOfString(usingFont font: UIFont) -> CGFloat {
        
        let fontAttributes = [NSAttributedString.Key.font: font]
        
        let size = self.size(withAttributes: fontAttributes)
        
        return size.height
        
    }
    
    func sizeOfString(usingFont font: UIFont) -> CGSize {
        
        let fontAttributes = [NSAttributedString.Key.font: font]
        
        return self.size(withAttributes: fontAttributes)
        
    }
    
}
