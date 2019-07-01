import Foundation

internal func normalize<T: FloatingPoint>(_ x: T, min: T, max: T) -> T {
  let clampedX = clamp(x, min: min, max: max)
  return (clampedX - min) / (max - min)
}

internal func clamp<T: FloatingPoint>(_ x: T, min xMin: T, max xMax: T) -> T {
  if x.isNaN {
    return xMin
  }
  if x == T.infinity {
    return xMax
  }
  if x == -T.infinity {
    return xMin
  }
  return max(min(x, xMax), xMin)
}

internal func clamp<T: SignedInteger>(_ x: T, min xMin: T, max xMax: T) -> T {
  return max(min(x, xMax), xMin)
}

internal func translate(_ point: Point2D<Int>, from fromSize: Size<Int>, to toSize: Size<Int>) -> Point2D<Int> {
  let widthRatio = Float(toSize.width) / Float(fromSize.width)
  let heightRatio = Float(toSize.height) / Float(fromSize.height)
  return Point2D(x: Int(Float(point.x) * widthRatio), y: Int(Float(point.y) * heightRatio))
}

internal func translate(_ size: Size<Int>, from fromSize: Size<Int>, to toSize: Size<Int>) -> Size<Int> {
  let widthRatio = Float(toSize.width) / Float(fromSize.width)
  let heightRatio = Float(toSize.height) / Float(fromSize.height)
  return Size(width: Int(Float(size.width) * widthRatio), height: Int(Float(size.height) * heightRatio))
}
