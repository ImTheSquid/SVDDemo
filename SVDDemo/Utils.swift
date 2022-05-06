//
//  Utils.swift
//  SVDDemo
//
//  Created by Jack Hogan on 5/3/22.
//

import Foundation
import AppKit
import SwiftImage
import LASwift

func flattenWithMatrix(imageData: Data, pixelFilter: ImagePixelType) -> (Data, Matrix) {
    var image = Image<RGB<UInt8>>(data: imageData)!
    
    var vectors = [Vector](repeating: Vector(repeating: 0, count: image.height), count: image.width)
    
    for x in image.xRange {
        for y in image.yRange {
            var value = 0.0
            let pixel = image.pixelAt(x: x, y: y)!
            switch pixelFilter {
            case .all:
                fatalError("Can't get matrix for all colors")
            case .red:
                value = Double(pixel.red)
                image[x, y].green = 0
                image[x, y].blue = 0
            case .blue:
                value = Double(pixel.blue)
                image[x, y].green = 0
                image[x, y].red = 0
            case .green:
                value = Double(pixel.green)
                image[x, y].red = 0
                image[x, y].blue = 0
            }
            vectors[x][y] = value / Double(UInt8.max)
        }
    }
    
    return (image.jpegData(compressionQuality: 1.0)!, Matrix(vectors))
}

func combine(red: Data, green: Data, blue: Data) -> Data {
    let redImage = Image<RGB<UInt8>>(data: red)!
    let greenImage = Image<RGB<UInt8>>(data: green)!
    let blueImage = Image<RGB<UInt8>>(data: blue)!
    
    var pixels = [RGB<UInt8>]()
    pixels.reserveCapacity(redImage.width * redImage.height)
    
    for y in redImage.yRange {
        for x in redImage.xRange {
            pixels.append(RGB<UInt8>(red: redImage.pixelAt(x: x, y: y)!.red, green: greenImage.pixelAt(x: x, y: y)!.green, blue: blueImage.pixelAt(x: x, y: y)!.blue))
        }
    }
    
    let reconstructed = Image<RGB<UInt8>>(width: redImage.width, height: redImage.height, pixels: pixels)
    
    return reconstructed.jpegData(compressionQuality: 1.0)!
}

func matrixFromImage(imageData: Data, pixelFilter: ImagePixelType) -> Matrix {
    let image = Image<RGB<UInt8>>(data: imageData)!
    
    var vectors = [Vector](repeating: Vector(repeating: 0, count: image.height), count: image.width)
    
    for x in image.xRange {
        for y in image.yRange {
            var value = 0.0
            let pixel = image.pixelAt(x: x, y: y)!
            switch pixelFilter {
            case .all:
                fatalError("Can't get matrix for all colors")
            case .red:
                value = Double(pixel.red)
            case .blue:
                value = Double(pixel.blue)
            case .green:
                value = Double(pixel.green)
            }
            
            // Set value and normalize
            vectors[x][y] = value / Double(UInt8.max)
        }
    }
    
    return Matrix(vectors)
}

func calculateSVDImage(matrix: Matrix, modes: Int) -> Data {
    let (U, S, V) = svd(matrix)
    
    for zeroDiag in modes..<min(S.rows, S.cols) {
        S[zeroDiag, zeroDiag] = 0
    }
    
    let new = U * S * transpose(V)
    let img = Image<RGB<UInt8>>(width: matrix.cols, height: matrix.rows, pixels: new.flatMap { Array($0) }.map{ RGB(gray: UInt8(max(min($0, 1), 0) * Double(UInt8.max))) }).rotated(byDegrees: 90).xReversed()
    
    return img.jpegData(compressionQuality: 1.0)!
}
