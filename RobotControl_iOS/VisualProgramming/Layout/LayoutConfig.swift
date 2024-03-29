//
//  LayoutConfig.swift
//  RobotControl_iOS
//
//  Created by luolun on 2017/6/6.
//  Copyright © 2017年 Aaron. All rights reserved.
//

import UIKit

class LayoutConfig: NSObject {
    let viewAnimationDuration = 0.3
    
    let blockCornerRadius: CGFloat = 8
    let notchWidth: CGFloat = 30
    let notchHeight: CGFloat = 10
    
    let leadingXEdgeOffset = 8
    
    let minBlockWidth: CGFloat = 60
    
    let minBlockInputSize: CGSize = CGSize(width: 100, height: 60)
    let minStatementIndent: CGFloat = 30
    
    let connectingDistance: CGFloat = 45
    
    let font = UIFont.systemFont(ofSize: 14)
}
