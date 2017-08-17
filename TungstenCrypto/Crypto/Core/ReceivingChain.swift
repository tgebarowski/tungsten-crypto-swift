//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class ReceivingChain: NSObject, Chain {

    public var chainKey: ChainKey
    private(set) public var messageKeysList: [MessageKeys]
    private(set) public var senderCoreKey: Data

    public init(chainKey: ChainKey, senderCoreKey: Data) {
        self.chainKey = chainKey
        self.senderCoreKey = senderCoreKey
        self.messageKeysList = []
    }
    
    public func addMessageKeys(messageKeys: MessageKeys) {
        messageKeysList.append(messageKeys)
    }
    
    public func popMessageKeys(with counter: Int) -> MessageKeys? {
        guard let index = messageKeysList.index(where: { $0.index ==  counter}) else {
            return nil
        }
        
        let messageKeys = messageKeysList[index]
        messageKeysList.remove(at: index)
        return messageKeys
    }
    
    //MARK: - NSSecureCoding
    
    private static let kCoderChainKey = "kCoderChainKey"
    private static let kCoderSenderCore = "kCoderSenderCore"
    private static let kCoderMessageKeys   = "kCoderMessageKeys";
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard let senderCoreKey = aDecoder.decodeObject(forKey: ReceivingChain.kCoderSenderCore) as? Data,
            let chainKey = aDecoder.decodeObject(forKey: ReceivingChain.kCoderChainKey) as? ChainKey,
            let messageKeys = aDecoder.decodeObject(forKey: ReceivingChain.kCoderMessageKeys) as? [MessageKeys] else {
                return nil
        }
        self.init(chainKey: chainKey, senderCoreKey: senderCoreKey)
        self.messageKeysList = messageKeys
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(chainKey, forKey: ReceivingChain.kCoderChainKey)
        aCoder.encode(senderCoreKey, forKey: ReceivingChain.kCoderSenderCore)
        aCoder.encode(messageKeysList, forKey: ReceivingChain.kCoderMessageKeys)
    }

}
