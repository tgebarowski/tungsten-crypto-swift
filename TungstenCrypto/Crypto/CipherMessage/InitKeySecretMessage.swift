//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class InitKeySecretMessage: NSObject, CipherMessage {
    
    private(set) public var registrationId: String
    private(set) public var version: Int
    private(set) public var initKeyID: Int
    private(set) public var signedInitKeyId: String
    private(set) public var baseKey: Data
    private(set) public var identityKey: Data
    private(set) public var message: SecretMessage
    private(set) public var serialized: Data

    public init(secretMessage: SecretMessage, registrationId: String, initKeyId: Int, signedInitKeyId: String, baseKey: Data, senderIdentityKey: Data, receiverIdentityKey: Data, macKey: Data) {
        self.registrationId = registrationId
        self.version = secretMessage.version
        self.initKeyID = initKeyId
        self.signedInitKeyId = signedInitKeyId
        self.baseKey = baseKey
        self.identityKey = senderIdentityKey
        self.message = secretMessage
        
        self.serialized = Data()
        super.init()
        
        let messageSerialization = CryptoToolkit.sharedInstance.configuration.messageSerialization

        let versionByte = Serialization.byteHigh(from: self.version, lowValue: Constants.CURRENT_VERSION)
        let message = messageSerialization.encodeInitKeyMessage(initKeyMessage: self)
        
        var serialized = Data([versionByte])
        serialized.append(message)
        
        let hmac = Serialization.mac(with: senderIdentityKey.prependKeyType(), receiverIdentityKey: receiverIdentityKey.prependKeyType(), macKey: macKey, serialized: serialized)
        
        CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO][MAC][INITMESSAGE] Created mac during encryption with params:\n senderIdentityKey - %@ \n receiverIdentityKey - %@ \n, macKey - %@ \n mac result - %@",
                                                                                senderIdentityKey as NSData,
                                                                                receiverIdentityKey as NSData,
                                                                                macKey as NSData,
                                                                                hmac as NSData))
        
        serialized.append(hmac)
        self.serialized = serialized
        
        CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO][MAC][INITMESSAGE] Created message serialized:\n%@",
                                                                                serialized as NSData))
    }
    
    public required init(data: Data) throws {
        CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO][MAC][INITMESSAGE] Received message serialized:\n%@",
                                                                                data as NSData))
        
        guard data.count > (1 + Serialization.MAC_LENGTH) else {
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.invalidMessageException, userInfo: [NSLocalizedDescriptionKey: "Init Message size is too short to have content"])
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
        let secretMessageContainer = try messageSerialization.decodeInitKeyMessage(data: message)
        
        guard
            let registrationId = secretMessageContainer.registrationId,
            let signedInitKeyId = secretMessageContainer.signedInitKeyId,
            let baseKey = secretMessageContainer.baseKey,
            let identityKey = secretMessageContainer.identityKey,
            let secretMessage =  secretMessageContainer.message else {
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.invalidMessageException, userInfo: [NSLocalizedDescriptionKey: "Incomplete Message"])
        }
        
        self.serialized = data
        self.version = Serialization.highBits(from: version)
        self.registrationId = registrationId
        
        if let initKeyId = secretMessageContainer.initKeyId {
            self.initKeyID = initKeyId.intValue
        } else {
            self.initKeyID = 0
        }
        
        self.signedInitKeyId = signedInitKeyId
        self.baseKey = baseKey
        
        self.identityKey = identityKey
        self.message = try SecretMessage(data: secretMessage)
    }
    
    public func verifyMac(senderIdentityKey: Data, receiverIdentityKey: Data, macKey: Data) throws {
        let data = serialized[0..<(self.serialized.count - Serialization.MAC_LENGTH)]
        let theirMac = serialized[data.count..<(data.count+Serialization.MAC_LENGTH)]
        let ourMac = Serialization.mac(with: senderIdentityKey.prependKeyType(), receiverIdentityKey: receiverIdentityKey.prependKeyType(), macKey: macKey, serialized: Data(data))
        
        CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO][MAC][INITMESSAGE] Will verify init key  mac during decryption with params:\n senderIdentityKey - %@ \n identityKey - %@ \n, macKey - %@ \n theirMac - %@ \n ourMac - %@",
                                                                                senderIdentityKey as NSData,
                                                                                receiverIdentityKey as NSData,
                                                                                macKey as NSData,
                                                                                Data(theirMac) as NSData,
                                                                                ourMac as NSData
        ))
        
        guard Data(theirMac).timeConstantIsEqual(to: ourMac) else {
            CryptoToolkit.sharedInstance.configuration.logging?.log(message: "[CRYPTO][MAC][INITMESSAGE] mac verification failed")
            try message.verifyMac(senderIdentityKey: senderIdentityKey, receiverIdentityKey: receiverIdentityKey, macKey: macKey)
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.invalidMessageException, userInfo: [NSLocalizedDescriptionKey: "Bad Mac!", CryptoErrors.badMacUserInfoKey: NSNumber(value: true) ])
        }
        
        try message.verifyMac(senderIdentityKey: senderIdentityKey, receiverIdentityKey: receiverIdentityKey, macKey: macKey)
    }
}
