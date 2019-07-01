struct Size<T: Numeric> {
    let width: T
    let height: T
}

extension Size where T: Comparable & SignedInteger {
    internal func forEach(_ callback: (Point2D<T>) -> Void) {
        for x in stride(from: 0, to: width, by: 1) {
            for y in stride(from: 0, to: height, by: 1) {
                callback(Point2D(x: x, y: y))
            }
        }
    }
}
