//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

struct Serialization {
    
    static let MAC_LENGTH = 16
    
    static func highBits(from byte: UInt8) -> Int {
        return Int((byte & 0xFF) >> UInt8(4))
    }
    
    static func lowBits(from byte: UInt8) -> Int {
        return Int(byte & 0xF)
    }
    
    static func byteHigh(from highValue: Int, lowValue: Int) -> UInt8 {
        return UInt8((highValue << 4 | lowValue) & 0xFF)
    }
    
    static func mac(with identityKey: Data, receiverIdentityKey: Data, macKey: Data, serialized: Data) -> Data {
        let keyDeriviation = CryptoToolkit.sharedInstance.configuration.keyDerivation
        
        var hmac = keyDeriviation.hmac(senderIdentityKey: identityKey, receiverIdentityKey: receiverIdentityKey, macKey: macKey, serialized: serialized)
        
        let retData = Data(hmac[0..<MAC_LENGTH])
        return retData
    }
}
