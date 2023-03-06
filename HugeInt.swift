import Foundation

enum HugeIntError: Error {
    case ArithmeticOverflowError
    case AccuracyLossError
}

struct HugeInt: CustomStringConvertible, Equatable, Comparable {
    var fraction:Int
    var exponent:UInt

    // initializer

    init(fromInt n:Int) {
        (self.fraction, self.exponent) = (n, 0)
    }

    init(fromDouble origin:Double) {
        var past1 = 0.0
        var past2 = 0.0
        var n = origin
        var e:UInt = 0
        while (n / 10 - floor(n / 10) == 0) {
            n /= 10
            e += 1
            past2 = past1
            past1 = n - floor(n)
        }
        (self.fraction, self.exponent) = (Int(n), e)
    }

    init(fraction:Int, exponent:UInt) {
        (self.fraction, self.exponent) = (fraction, exponent)
    }

    // CustomStringConvertible protocol methods

    var description: String {
        var result = ""
        result += "\(self.fraction)"
        if (self.exponent > 0) {
            result += "e\(self.exponent)"
        }
        return result
    }

    // Equatable protocol methods

    static func ==(lhs: HugeInt, rhs: HugeInt) -> Bool {
        let tmpLhs = lhs.normalized()
        let tmpRhs = rhs.normalized()
        return tmpLhs.fraction == tmpRhs.fraction && tmpLhs.exponent == tmpRhs.exponent
    }

    // Comparable protocol methods

    public static func <(lhs: HugeInt, rhs: HugeInt) -> Bool {
        let (tmpLhs, tmpRhs) = HugeInt.commonized(lhs, rhs)
        return tmpLhs.fraction < tmpRhs.fraction
    }

    public static func <=(lhs: HugeInt, rhs: HugeInt) -> Bool {
        let (tmpLhs, tmpRhs) = HugeInt.commonized(lhs, rhs)
        return tmpLhs.fraction <= tmpRhs.fraction
    }

    public static func >=(lhs: HugeInt, rhs: HugeInt) -> Bool {
        let (tmpLhs, tmpRhs) = HugeInt.commonized(lhs, rhs)
        return tmpLhs.fraction >= tmpRhs.fraction
    }

    public static func >(lhs: HugeInt, rhs: HugeInt) -> Bool {
        let (tmpLhs, tmpRhs) = HugeInt.commonized(lhs, rhs)
        return tmpLhs.fraction > tmpRhs.fraction
    }

    // others

    func normalized() -> HugeInt {
        var result = self
        while (result.fraction % 10 == 0 && result.fraction != 0) {
            result.fraction /= 10
            result.exponent += 1
        }
        if (result.fraction == 0) {
            result.exponent = 0
        }
        return result
    }

    static func commonized(_ a:HugeInt, _ b:HugeInt) -> (HugeInt, HugeInt) {
        var resA = a
        var resB = b
        while (resA.exponent > resB.exponent) {
            resA.fraction *= 10
            resA.exponent -= 1
        }
        while (resA.exponent < resB.exponent) {
            resB.fraction *= 10
            resB.exponent -= 1
        }
        return (resA, resB)
    }
}

let Na = HugeInt(fromDouble: 6.022e23) // Avogadro constant
print("Na = \(Na)")

let Tp = HugeInt(fromDouble: 1.416e32) // Planck temperature
print("Tp = \(Tp)")

let (Na2, Tp2) = HugeInt.commonized(Na, Tp)
print("Na2 = \(Na2)")
print("Tp2 = \(Tp2)")

print("(Na == Tp) = \(Na == Tp)")
print("(Tp == Tp2) = \(Tp == Tp2)")

print("(Na < Tp) = \(Na < Tp)")
print("(Na > Tp) = \(Na > Tp)")
