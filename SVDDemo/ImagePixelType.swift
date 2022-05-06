//
//  ImagePixelType.swift
//  SVDDemo
//
//  Created by Jack Hogan on 5/3/22.
//

import Foundation
import SwiftUI

enum ImagePixelType{
    case all, red, blue, green
    
    var color: Color {
        switch self {
        case .all:
            return .white
        case .red:
            return .red
        case .blue:
            return .blue
        case .green:
            return .green
        }
    }
}
