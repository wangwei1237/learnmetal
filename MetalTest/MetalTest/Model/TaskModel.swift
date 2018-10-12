//
//  TaskModel.swift
//  MetalTest
//
//  Created by wangwei on 2018/10/11.
//  Copyright © 2018 wangwei. All rights reserved.
//

import UIKit

class TaskModel: NSObject {
    var name:String      = ""
    var className:String = ""
    
    init(_ name:String, _ className:String) {
        self.name      = name
        self.className = className
    }
}
