import Foundation

infix operator *&

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
        if self.isCapableOfInt() {
            return self.intString
        } else {
            return self.exponentString
        }
    }

    var rawString: String {
        var result = ""
        result += "\(self.fraction)"
        if (self.exponent > 0) {
            result += "e+\(self.exponent)"
        }
        return result
    }

    var intString: String {
        var result = ""
        result += "\(self.fraction)"
        for i in 0..<self.exponent {
            result += "0"
        }
        return result
    }

    var exponentString: String {
        var fr = Double(self.fraction)
        var ex = self.exponent
        var isMinus = false
        if fr < 0 {
            isMinus = true
            fr = -fr
        }
        while (fr >= 10) {
            fr /= 10.0
            ex += 1
        }
        let sign = isMinus ? "-" : ""
        return "\(sign)\(fr)e+\(ex)"
    }

    // Equatable protocol methods

    static func ==(lhs: HugeInt, rhs: HugeInt) -> Bool {
        let tmpLhs = lhs.normalized()
        let tmpRhs = rhs.normalized()
        return tmpLhs.fraction == tmpRhs.fraction && tmpLhs.exponent == tmpRhs.exponent
    }

    static func <(lhs: HugeInt, rhs: Int) -> Bool { return lhs == HugeInt(fromInt: rhs) }

    // Comparable protocol operator definitions

    static func <(lhs: HugeInt, rhs: HugeInt) -> Bool {
        let (tmpLhs, tmpRhs) = HugeInt.commonized(lhs, rhs)
        return tmpLhs.fraction < tmpRhs.fraction
    }

    static func <=(lhs: HugeInt, rhs: HugeInt) -> Bool {
        let (tmpLhs, tmpRhs) = HugeInt.commonized(lhs, rhs)
        return tmpLhs.fraction <= tmpRhs.fraction
    }

    static func >=(lhs: HugeInt, rhs: HugeInt) -> Bool {
        let (tmpLhs, tmpRhs) = HugeInt.commonized(lhs, rhs)
        return tmpLhs.fraction >= tmpRhs.fraction
    }

    static func >(lhs: HugeInt, rhs: HugeInt) -> Bool {
        let (tmpLhs, tmpRhs) = HugeInt.commonized(lhs, rhs)
        return tmpLhs.fraction > tmpRhs.fraction
    }

    // other operator definitions

    static func +(lhs: HugeInt, rhs: HugeInt) -> HugeInt {
        let (tmpLhs, tmpRhs) = HugeInt.commonized(lhs, rhs)
        let result = HugeInt(fraction: (tmpLhs.fraction + tmpRhs.fraction), exponent: tmpLhs.exponent)
        return result.normalized()
    }

    static func +(lhs: HugeInt, rhs: Int) -> HugeInt { return lhs + HugeInt(fromInt: rhs) }

    static func -(lhs: HugeInt, rhs: HugeInt) -> HugeInt {
        let (tmpLhs, tmpRhs) = HugeInt.commonized(lhs, rhs)
        let result = HugeInt(fraction: (tmpLhs.fraction - tmpRhs.fraction), exponent: tmpLhs.exponent)
        return result.normalized()
    }

    static func -(lhs: HugeInt, rhs: Int) -> HugeInt { return lhs - HugeInt(fromInt: rhs) }

    static func *(lhs: HugeInt, rhs: HugeInt) -> HugeInt {
        let result = HugeInt(fraction: (lhs.fraction * rhs.fraction), exponent: lhs.exponent + rhs.exponent)
        return result.normalized()
    }

    static func *(lhs: HugeInt, rhs: Int) -> HugeInt { 
        return HugeInt(fraction: lhs.fraction * rhs, exponent: lhs.exponent).normalized()
    }

    static func *&(lhs: HugeInt, rhs: HugeInt) -> HugeInt {
        var (tmpLhs, tmpRhs) = (lhs, rhs)
        while (tmpLhs.fraction > Int.max / tmpRhs.fraction) {
            if (tmpLhs.exponent > tmpRhs.exponent || (tmpLhs.exponent == tmpRhs.exponent && tmpLhs.fraction > tmpRhs.fraction)) {
                tmpLhs.fraction /= 10
                tmpLhs.exponent += 1
            } else {
                tmpRhs.fraction /= 10
                tmpRhs.exponent += 1
            }
        }
        let result = HugeInt(fraction: (tmpLhs.fraction * tmpRhs.fraction), exponent: tmpLhs.exponent + tmpRhs.exponent)
        return result.normalized()
    }

    static func /(lhs: HugeInt, rhs: HugeInt) -> HugeInt {
        var (tmpLhs, tmpRhs) = (lhs, rhs)
        while (tmpLhs.exponent > 0 && tmpRhs.exponent > 0) {
            tmpLhs.exponent -= 1
            tmpRhs.exponent -= 1
        }
        if tmpRhs.exponent == 0 {
            while (tmpLhs.exponent > 0 && (tmpLhs * 10).isCapableOfInt()) {
                tmpLhs.exponent -= 1
                tmpLhs.fraction *= 10
            }
            return HugeInt(fraction: tmpLhs.fraction / tmpRhs.fraction, exponent: tmpLhs.exponent).normalized()
        } else {
            while (!tmpLhs.isCapableOfInt() || !tmpRhs.isCapableOfInt()) {
                if tmpLhs.exponent > 0 {
                    tmpLhs.exponent -= 1
                } else {
                    tmpLhs.fraction /= 10
                }
                if tmpRhs.exponent > 0 {
                    tmpRhs.exponent -= 1
                } else {
                    tmpRhs.fraction /= 10
                }
            }
            return HugeInt(fromInt: try! tmpLhs.toInt() / tmpRhs.toInt()).normalized()
        }
    }

    static func /(lhs: HugeInt, rhs: Int) -> HugeInt { return lhs / HugeInt(fromInt: rhs) }

    static func ^(lhs: HugeInt, rhs: HugeInt) -> HugeInt {
        if rhs.exponent > 0 {
            let rhsOn10 = HugeInt(fraction: rhs.fraction, exponent: rhs.exponent - 1)
            let lhsPowerOfRhsOn10 = lhs ^ rhsOn10
            var result = HugeInt(fromInt: 1)
            for _ in 0..<10 {
                result = result *& lhsPowerOfRhsOn10
            }
            return result
        } else if rhs.fraction > 0 {
            var result = HugeInt(fromInt: 1)
            for _ in 1...rhs.fraction {
                result = result *& lhs
            }
            return result
        } else {
            return lhs
        }
    }

    // others

    func abs() -> HugeInt {
        if self.fraction < 0 {
            return HugeInt(fraction: -self.fraction, exponent:self.exponent)
        } else {
            return self
        }
    }

    func isCapableOfInt() -> Bool {
        var tmp = self
        var max = Int.max
        while tmp.exponent > 0 {
            tmp.exponent -= 1
            max /= 10
        }
        return tmp.abs() < HugeInt(fromInt: max)
    }

    func toInt() throws -> Int {
        var result = self.fraction
        if self.exponent > 0 {
            for _ in 1...self.exponent {
                if result > Int.max / 10 {
                    throw HugeIntError.ArithmeticOverflowError
                }
                result *= 10
            }
        }
        return result
    }

    static func factorial(of n:UInt) -> HugeInt {
        var result = HugeInt(fromInt: 1)
        if n == 0 {
            return result
        }
        for i in 1...n {
            let tmpResult = result *& HugeInt(fromInt: Int(i))
            result = tmpResult
        }
        return result
    }

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
print("Na = \(Na) = \(Na.rawString)")

let Tp = HugeInt(fromDouble: 1.416e32) // Planck temperature
print("Tp = \(Tp) = \(Tp.rawString)")

let (Na2, Tp2) = HugeInt.commonized(Na, Tp)
print("Na2 = \(Na2) = \(Na2.rawString)")
print("Tp2 = \(Tp2) = \(Tp2.rawString)")

print("(Na == Tp) = \(Na == Tp)")
print("(Tp == Tp2) = \(Tp == Tp2)")

print("(Na < Tp) = \(Na < Tp)")
print("(Na > Tp) = \(Na > Tp)")

print("Na + Tp = \(Na + Tp2)")
print("Na - Tp = \(Na - Tp2)")
print("Na * 2 = \(Na * 2)")
print("Na * Tp = \(Na * Tp)")
print("Na / Tp = \(Na / Tp)")
print("Tp / Na = \(Tp / Na)")
print("Na / 2 = \(Na / 2)")

for i:Int in 0...100 {
    let fr = HugeInt.factorial(of: UInt(i))
    print("\(i)! = \(fr)")
}

let two = HugeInt(fromInt: 2)
for i:Int in 0...100 {
    let pw = two ^ HugeInt(fromInt: i)
    print("2 ^ \(i) = \(pw)")
}

print(";")
print(";")
print(";")
print(";")
print(";")
print(";")
print(";")
print(";")
print(";")
print(";")
