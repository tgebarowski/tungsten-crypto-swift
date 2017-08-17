//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class SessionStateInitializedData: NSObject {
    
    public var remoteIdentityKey: Data
    public var localIdentityKey: Data
    public var rootKey: RootKey
    fileprivate var sendingChain: SendingChain
    
    public var senderCoreKeyPair: KeyPair {
        return sendingChain.senderCoreKeyPair
    }
    
    public var senderChainKey: ChainKey {
        get {
            return sendingChain.chainKey
        }
        set {
            self.sendingChain.chainKey = newValue
        }
    }
    
    public init(remoteIdentityKey: Data, localIdentityKey: Data, rootKey: RootKey, sendingChain: SendingChain) {
        self.remoteIdentityKey = remoteIdentityKey
        self.localIdentityKey = localIdentityKey
        self.rootKey = rootKey
        self.sendingChain = sendingChain
    }
}

public class SessionState: NSObject, NSSecureCoding {
    
    private let maxReceivingChains = 5
    public var version: Int = 0
    public var initalizedState: SessionStateInitializedData? = nil
    
    public var remoteRegistrationId: String = ""
    public var localRegistrationId: String = ""
    public var aliceBaseKey: Data? = nil
    public var previousCounter: Int = 0
    
    
    fileprivate var receivingChains: [ReceivingChain] = []
    fileprivate(set) public var pendingInitKey: PendingInitKey? = nil
    
    public override init() {
        
    }
    
    public func receiverChain(_ senderCoreKey: Data) -> ChainAndIndex? {
        guard let index = self.receivingChains.index(where: { $0.senderCoreKey == senderCoreKey }) else {
            return nil
        }
        
        return ChainAndIndex(chain: self.receivingChains[index], index: index)
    }
    
    public func receiverChainKey(_ senderCoreKey: Data) -> ChainKey? {
        guard let receiverChain = self.receiverChain(senderCoreKey)?.chain as? ReceivingChain else {
            return nil
        }
        return ChainKey(key: receiverChain.chainKey.key, index: receiverChain.chainKey.index)
    }
    
    public func setReceiverChainKey(_ senderEphemeral: Data, chainKey nextChainKey: ChainKey) {
        guard let chainAndIndex = self.receiverChain(senderEphemeral),
            let chain = chainAndIndex.chain as? ReceivingChain else {
            return
        }
        
        let newChain = chain
        newChain.chainKey = nextChainKey
        
        self.receivingChains[Int(chainAndIndex.index)] = newChain
    }
    
    public func addReceiverChain(_ senderCoreKey: Data, chainKey: ChainKey) {
        let receivingChain = ReceivingChain(chainKey: chainKey, senderCoreKey: senderCoreKey)
        self.receivingChains.append(receivingChain)
        
        if (self.receivingChains.count > maxReceivingChains) {
            let countToRemove = self.receivingChains.count - maxReceivingChains
            self.receivingChains.removeFirst(countToRemove)
        }
    }
    
    public func removeMessageKeys(_ senderCoreKey: Data, counter: Int) -> MessageKeys? {
        let chainAndIndex = receiverChain(senderCoreKey)
        guard let receivingChain = chainAndIndex?.chain as? ReceivingChain else { return nil }
        
        return receivingChain.popMessageKeys(with: counter)
    }
    
    public func setReceiverChain(_ index: Int, updatedChain: ReceivingChain) {
        self.receivingChains[index] = updatedChain
    }
    
    public func setMessageKeys(_ senderCoreKey: Data, messageKeys: MessageKeys) {
        guard let chainAndIndex = self.receiverChain(senderCoreKey),
            let chain = chainAndIndex.chain as? ReceivingChain else { return }
        
        chain.addMessageKeys(messageKeys: messageKeys)
        self.setReceiverChain(Int(chainAndIndex.index), updatedChain: chain)
    }
    
    public func setPendingInitKey(_ initKeyId: Int, signedInitKeyId: String, baseKey: Data) {
        self.pendingInitKey = PendingInitKey(baseKey: baseKey, initKeyId: initKeyId, signedInitKeyId: signedInitKeyId)
    }
    
    public func clearPendingInitKey() {
        self.pendingInitKey = nil
    }
    
    //MARK: - NSSecureCoding
    
    private static let kCoderVersion          = "kCoderVersion"
    private static let kCoderAliceBaseKey     = "kCoderAliceBaseKey"
    private static let kCoderRemoteIDKey      = "kCoderRemoteIDKey"
    private static let kCoderLocalIDKey       = "kCoderLocalIDKey"
    private static let kCoderPreviousCounter  = "kCoderPreviousCounter"
    private static let kCoderRootKey          = "kCoderRoot"
    private static let kCoderLocalRegID       = "kCoderLocalRegID"
    private static let kCoderRemoteRegID      = "kCoderRemoteRegID"
    private static let kCoderReceiverChains   = "kCoderReceiverChains"
    private static let kCoderSendingChain     = "kCoderSendingChain"
    private static let kCoderPendingInitKey    = "kCoderPendingInitKey"
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard let remoteRegistrationId = aDecoder.decodeObject(forKey: SessionState.kCoderRemoteRegID) as? String,
            let localRegistrationId = aDecoder.decodeObject(forKey: SessionState.kCoderLocalRegID) as? String else {
                return nil
        }
        
        if let remoteIdentityKey = aDecoder.decodeObject(forKey: SessionState.kCoderRemoteIDKey) as? Data,
            let localIdentityKey = aDecoder.decodeObject(forKey: SessionState.kCoderLocalIDKey) as? Data,
            let rootKey = aDecoder.decodeObject(forKey: SessionState.kCoderRootKey) as? RootKey,
            let sendingChain = aDecoder.decodeObject(forKey: SessionState.kCoderSendingChain) as? SendingChain {
            self.initalizedState = SessionStateInitializedData(remoteIdentityKey: remoteIdentityKey, localIdentityKey: localIdentityKey, rootKey: rootKey, sendingChain: sendingChain)
        } else {
            self.initalizedState = nil
        }
        self.version = aDecoder.decodeInteger(forKey: SessionState.kCoderVersion)
        
        self.aliceBaseKey = aDecoder.decodeObject(forKey: SessionState.kCoderAliceBaseKey) as? Data
        self.previousCounter = aDecoder.decodeInteger(forKey: SessionState.kCoderPreviousCounter)
        self.remoteRegistrationId = remoteRegistrationId
        self.localRegistrationId = localRegistrationId
        self.receivingChains = (aDecoder.decodeObject(forKey: SessionState.kCoderReceiverChains) as? [ReceivingChain]) ?? []
        self.pendingInitKey = aDecoder.decodeObject(forKey: SessionState.kCoderPendingInitKey) as? PendingInitKey
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(version, forKey: SessionState.kCoderVersion)
        aCoder.encode(aliceBaseKey, forKey: SessionState.kCoderAliceBaseKey)
        aCoder.encode(initalizedState?.remoteIdentityKey, forKey: SessionState.kCoderRemoteIDKey)
        aCoder.encode(initalizedState?.localIdentityKey, forKey: SessionState.kCoderLocalIDKey)
        aCoder.encode(previousCounter, forKey: SessionState.kCoderPreviousCounter)
        aCoder.encode(initalizedState?.rootKey, forKey: SessionState.kCoderRootKey)
        aCoder.encode(remoteRegistrationId, forKey: SessionState.kCoderRemoteRegID)
        aCoder.encode(localRegistrationId, forKey: SessionState.kCoderLocalRegID)
        aCoder.encode(initalizedState?.sendingChain, forKey: SessionState.kCoderSendingChain)
        aCoder.encode(receivingChains, forKey: SessionState.kCoderReceiverChains)
        aCoder.encode(pendingInitKey, forKey: SessionState.kCoderPendingInitKey)
    }
}

extension SessionState: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        self.encode(with: archiver)
        archiver.finishEncoding()
        
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data as Data)
        guard let sessionState = SessionState(coder: unarchiver) else {
            fatalError("NSSecureCoding error")
        }
        
        unarchiver.finishDecoding()
        return sessionState
    }
}
