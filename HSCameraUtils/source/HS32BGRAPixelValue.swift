import Foundation

public struct HS32BGRAPixelValue {
    public let blue: UInt8
    public let green: UInt8
    public let red: UInt8
    public let alpha: UInt8
    
    public init(blue: UInt8, green: UInt8, red: UInt8, alpha: UInt8) {
        self.blue = blue
        self.green = green
        self.red = red
        self.alpha = alpha
    }
    
    // ignores alpha value
    // reference: https://en.wikipedia.org/wiki/Luma_%28video%29
    public func asGrayScale() -> UInt8 {
        let floatValue: Float = Float(red) * 0.2989 + Float(green) * 0.5870 + Float(blue) * 0.1140
        return UInt8(exactly: clamp(floatValue, min: 0, max: 255).rounded()) ?? 0
    }
}
