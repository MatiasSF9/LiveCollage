//
//  ColorCube.swift
//  ColorCube
//
//  Created by Matias Fernandez on 2016/11/27.
//  Credits to Apple and SO translation: https://stackoverflow.com/questions/27695134/get-cicolorcube-filter-working-in-swift
//
import Foundation

#if os(macOS)
    import AppKit
    public typealias Image = NSImage
#elseif os(iOS)
    import UIKit
    public typealias Image = UIImage
#endif

public enum ColorCube {
    
    enum Dimension: Int {
        case four = 4 /// A very small color cube. May exhibit posterization.
        case sixteen = 16 /// This size is good enough for many applications using noisy or lower-quality input.
        case sixtyFour = 64 /// Higher quality. There is rarely a need to go beyond this setting.
        case twoHundredFiftySix = 256 /// Excessive quality. Image is 4096x4096 and almost 35MB.
    }
    
    static func colorCubeFilterForChromaKey(valueFilter: Float) -> CIFilter {
        
//        let hueRange: Float = 60 // degrees size pie shape that we want to replace
//        let minHueAngle: Float = (hueAngle - hueRange/2.0) / 360
//        let maxHueAngle: Float = (hueAngle + hueRange/2.0) / 360
        
        let size = 64
        var cubeData = [Float](repeating: 0, count: size * size * size * 4)
        var rgb: [Float] = [0, 0, 0]
        var hsv: (h : Float, s : Float, v : Float)
        var offset = 0
        
        for z in 0 ..< size {
            rgb[2] = Float(z) / Float(size) // blue value
            for y in 0 ..< size {
                rgb[1] = Float(y) / Float(size) // green value
                for x in 0 ..< size {
                    
                    rgb[0] = Float(x) / Float(size) // red value
                    hsv = ColorCube.RGBtoHSV(r: rgb[0], g: rgb[1], b: rgb[2])
                    let alpha : Float = hsv.v > valueFilter ? 1.0 : 0.0
//                    let alpha: Float = (hsv.h > minHueAngle && hsv.h < maxHueAngle) ? 0 : 1.0
                    
                    cubeData[offset] = rgb[0] * alpha
                    cubeData[offset + 1] = rgb[1] * alpha
                    cubeData[offset + 2] = rgb[2] * alpha
                    cubeData[offset + 3] = alpha
                    offset += 4
                }
            }
        }
        let b = cubeData.withUnsafeBufferPointer { Data(buffer: $0) }
        let data = b as NSData
        
        let colorCube = CIFilter(name: "CIColorCube", withInputParameters: [
            "inputCubeDimension": size,
            "inputCubeData": data
            ])
        return colorCube!
    }
    
    static func RGBtoHSV(r : Float, g : Float, b : Float) -> (h : Float, s : Float, v : Float) {
        var h : CGFloat = 0
        var s : CGFloat = 0
        var v : CGFloat = 0
        let col = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
        col.getHue(&h, saturation: &s, brightness: &v, alpha: nil)
        return (Float(h), Float(s), Float(v))
    }
    
}

