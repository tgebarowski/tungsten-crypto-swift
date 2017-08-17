//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class SecretMessage: NSObject, CipherMessage {
    
    private(set) public var version: Int
    
    private(set) public var senderCoreKey: Data
    private(set) public var previousCounter: Int
    private(set) public var counter: Int
    private(set) public var cipherText: Data
    private(set) public var serialized: Data
    
    public init(version: Int, macKey: Data, senderCoreKey: Data, counter: Int, previousCounter: Int, cipherText: Data, senderIdentityKey: Data, receiverIdentityKey: Data) {
        self.version = version
        self.senderCoreKey = senderCoreKey
        self.previousCounter = previousCounter
        self.counter = counter
        self.cipherText = cipherText
        self.serialized = Data()
        super.init()

        let messageSerialization = CryptoToolkit.sharedInstance.configuration.messageSerialization
        
        let versionByte = Serialization.byteHigh(from: version, lowValue: Constants.CURRENT_VERSION)
        let message = messageSerialization.encodeMessage(message: self)
        
        var serialized = Data([versionByte])
        serialized.append(message)
        
        let hmac = Serialization.mac(with: senderIdentityKey.prependKeyType(), receiverIdentityKey: receiverIdentityKey.prependKeyType(), macKey: macKey, serialized: serialized)
        
        CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO][MAC][MESSAGE] Created mac during encryption with params:\n senderIdentityKey - %@ \n receiverIdentityKey - %@ \n, macKey - %@ \n mac result - %@",
        senderIdentityKey as NSData,
        receiverIdentityKey as NSData,
        macKey as NSData,
        hmac as NSData))
        
        serialized.append(hmac)
        
        self.serialized = serialized
    }
    
    public required init(data: Data) throws {
        guard data.count > (1 + Serialization.MAC_LENGTH) else {
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.invalidMessageException, userInfo: [NSLocalizedDescriptionKey: "Message size is too short to have content"])
        }
        
        let version = data[0]
        let messageAndMac = Data(data[1..<data.count])        
        let message = Data(messageAndMac[0..<(messageAndMac.count - Serialization.MAC_LENGTH)])
        
        guard Serialization.highBits(from: version) >= Constants.MINIMUM_SUPPORTED_VERSION else {
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.legacyMessageException, userInfo: [NSLocalizedDescriptionKey: "Message was sent with an unsupported version of the protocol."])
        }
        
        guard Serialization.highBits(from: version) <= Constants.CURRENT_VERSION else {
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.invalidMessageException, userInfo: [NSLocalizedDescriptionKey: "Unknown Version."])
        }
        
        let messageSerialization = CryptoToolkit.sharedInstance.configuration.messageSerialization
        
        let secretMessageContainer = try messageSerialization.decodeMessage(data: message)
        
        
        guard let cipherText = secretMessageContainer.cipherText,
            let counter = secretMessageContainer.counter?.intValue,
            let coreKey = secretMessageContainer.coreKey else {
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.invalidMessageException, userInfo: [NSLocalizedDescriptionKey: "Incomplete message"])
        }
        
        self.serialized = data
        self.senderCoreKey = try coreKey.removeKeyType()
        self.version = Serialization.highBits(from: version)
        self.counter = counter
        self.previousCounter = secretMessageContainer.previousCounter?.intValue ?? 0
        self.cipherText = cipherText
    }
    
    public func verifyMac(senderIdentityKey: Data, receiverIdentityKey: Data, macKey: Data) throws {
        let data = serialized[0..<(self.serialized.count - Serialization.MAC_LENGTH)]
        let theirMac = serialized[data.count..<(data.count+Serialization.MAC_LENGTH)]
        let ourMac = Serialization.mac(with: senderIdentityKey.prependKeyType(), receiverIdentityKey: receiverIdentityKey.prependKeyType(), macKey: macKey, serialized: Data(data))
        
        CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO][MAC][MESSAGE] Will verify mac during decryption with params:\n senderIdentityKey - %@ \n receiverIdentityKey - %@ \n, macKey - %@ \n theirMac - %@ \n ourMac - %@",
                                                   senderIdentityKey as NSData,
                                                   receiverIdentityKey as NSData,
                                                   macKey as NSData,
                                                   Data(theirMac) as NSData,
                                                   ourMac as NSData
                                                   ))
        
        guard Data(theirMac).timeConstantIsEqual(to: ourMac) else {
            CryptoToolkit.sharedInstance.configuration.logging?.log(message: "[CRYPTO][MAC][MESSAGE] mac verification failed")
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.invalidMessageException, userInfo: [NSLocalizedDescriptionKey: "Bad Mac!", CryptoErrors.badMacUserInfoKey: NSNumber(value: true) ])
        }
    }
}
