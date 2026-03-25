//
//  Item.swift
//  ScreenShot&Clipboard
//
//  Created by 原神高手 on 3/24/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
