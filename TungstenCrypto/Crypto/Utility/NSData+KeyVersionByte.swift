//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public extension NSData {
    
    func prependKeyType() -> NSData {
        return NSData(data: (self as Data).prependKeyType())
    }
    
    func removeKeyType() throws -> NSData {
        return NSData(data: try (self as Data).removeKeyType())
    }
}

public extension Data {
 
    fileprivate var DJB_TYPE: UInt8 {
        return 0x05
    }
    
    func prependKeyType() -> Data {
        guard count == 32 else {
            return self
        }
        
        var newBytes: [UInt8] = [DJB_TYPE]
        newBytes.append(contentsOf: Array(self))
        
        return Data(bytes: newBytes)
    }
    
    func removeKeyType() throws -> Data {
        guard count == 33 else {
            return self
        }
        
        if self[0] == DJB_TYPE {
            return self.subdata(in: Range(uncheckedBounds: (1, 33)))
        } else {
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.invalidKeyException, userInfo: [NSLocalizedDescriptionKey: "Key type is incorrect"])
        }
    }
}
