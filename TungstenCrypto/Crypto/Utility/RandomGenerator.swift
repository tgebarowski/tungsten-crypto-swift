//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

struct RandomGenerator {
    static func random() -> Int {
        var data = Data(count: MemoryLayout<Int>.size)
        _ = data.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(kSecRandomDefault, data.count, mutableBytes)
        }
        var randomInt: Int = 0
        NSData(data: data).getBytes(&randomInt, length: MemoryLayout<Int>.size)
        return randomInt
    }
}
