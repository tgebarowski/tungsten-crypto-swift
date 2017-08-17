//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

extension Data {
    func timeConstantIsEqual(to data: Data) -> Bool {
        guard self.count == data.count else {
            return false
        }
        
        var areEqual = true
        for i in 0..<self.count {
            areEqual = areEqual && (self[i] == data[i])
        }
        
        return areEqual
    }
}
