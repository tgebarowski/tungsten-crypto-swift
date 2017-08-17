//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class SendingChain: NSObject, Chain {
    
    public var senderCoreKeyPair: KeyPair
    public var chainKey: ChainKey
    
    public init(chainKey: ChainKey, senderCoreKeyPair: KeyPair) {
        self.chainKey = chainKey
        self.senderCoreKeyPair = senderCoreKeyPair
    }
    
    //MARK: - NSSecureCoding
    
    private static let kCoderChainKey = "kCoderChainKey"
    private static let kCoderSenderCore = "kCoderSenderCore"
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard let senderCoreKeyPair = aDecoder.decodeObject(forKey: SendingChain.kCoderSenderCore) as? KeyPair,
            let chainKey = aDecoder.decodeObject(forKey: SendingChain.kCoderChainKey) as? ChainKey else {
                return nil
        }
        self.init(chainKey: chainKey, senderCoreKeyPair: senderCoreKeyPair)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(chainKey, forKey: SendingChain.kCoderChainKey)
        aCoder.encode(senderCoreKeyPair, forKey: SendingChain.kCoderSenderCore)
    }
}
