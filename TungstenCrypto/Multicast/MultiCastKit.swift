//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class MultiCastKit: NSObject {
    
    private(set) public var cryptoStore: MulticastCryptoStore
    
    public init(cryptoStore: MulticastCryptoStore) {
        self.cryptoStore = cryptoStore
    }
    
    // TUN-3887
    public func forceEncryptValue(_ value: String, forUserWithInitKeysBundles initKeyBundles: [CryptoInitKeysBundle]) throws -> [MulticastEncryptedItem] {
        let encryptionResult = try self.encryptValue(value, forUserWithInitKeysBundles: initKeyBundles)
        var encryptedItems: [MulticastEncryptedItem] = encryptionResult.succeed.flatMap { (_, item) -> MulticastEncryptedItem? in
            return item
        }
        
        encryptedItems.append(contentsOf: encryptionResult.failed.flatMap { (key, error) -> MulticastEncryptedItem? in
            return MulticastEncryptedItem(encryptedValue: CryptoErrors.keyEncryptionError(error: error), deviceMulticastId: key)
        })
        
        return encryptedItems
    }
    
    public func encryptValue(_ value: String, forUserWithInitKeysBundles initKeyBundles: [CryptoInitKeysBundle]) throws -> EncryptionResults {
        var encryptedItems: [String: MulticastEncryptedItem] = [:]
        var errorDicts: [String: Error] = [:]
        
        for publicInitKeysBundle in initKeyBundles {
            var usedRandomPublicInitKey = false
            do {    
                if !cryptoStore.containsSession(publicInitKeysBundle.userId, deviceId: publicInitKeysBundle.deviceId) {
                    guard !publicInitKeysBundle.initKeys.isEmpty else {
                        errorDicts[publicInitKeysBundle.deviceId] = NSError.errorForEmptyListOfInitKeys()
                        continue
                    }
                    
                    let rand = abs(RandomGenerator.random()) %  publicInitKeysBundle.initKeys.count
                    let randomPublicInitKey = publicInitKeysBundle.initKeys[rand]
                    usedRandomPublicInitKey = true
                    
                    CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "\n\n[CRYPTO][INITKEY] Picked init key with:\n id: %d\n public key: %@\n of user with id (profile id): %@\n device id: %@\n\n",
                                                                                            randomPublicInitKey.identifier,
                                                                                            randomPublicInitKey.publicKey as NSData,
                                                                                            publicInitKeysBundle.userId,
                                                                                            publicInitKeysBundle.deviceId))
                    
                    let deviceSessionBuilder = SessionBuilder(sessionStore: self.cryptoStore,
                                                              recipientId: publicInitKeysBundle.userId,
                                                              deviceId: publicInitKeysBundle.deviceId)
                    
                    let lockQueue = DispatchQueue(label: "com.tungstenapp.TungstenCrypto.encryptValue.1")
                    try lockQueue.sync {
                        try deviceSessionBuilder.processInitKeyBundle(InitKeyBundle(registrationId: publicInitKeysBundle.deviceId,
                                                                                deviceId: publicInitKeysBundle.deviceId,
                                                                                initKeyId: randomPublicInitKey.identifier,
                                                                                initKeyPublic: randomPublicInitKey.publicKey,
                                                                                signedInitKeyPublic: publicInitKeysBundle.signedInitKeyPublic,
                                                                                signedInitKeyId: publicInitKeysBundle.signedInitKeyId,
                                                                                signedInitKeySignature: publicInitKeysBundle.signedInitKeySignature ,
                                                                                identityKey: publicInitKeysBundle.identityKey))
                        
                    }
                    
                    guard cryptoStore.containsSession(publicInitKeysBundle.userId, deviceId: publicInitKeysBundle.deviceId) else {
                        errorDicts[publicInitKeysBundle.deviceId] = NSError.errorForNoSessionNoSecretMessage()
                        continue
                    }
                }
                
                let deviceSessionCipher = SessionCipher(sessionStore: cryptoStore,
                                                        recipientId: publicInitKeysBundle.userId,
                                                        deviceId: publicInitKeysBundle.deviceId)
                
                let lockQueue = DispatchQueue(label: "com.tungstenapp.TungstenCrypto.encryptValue.2")
                
                let deviceEncryptedEncryptionKeyMessage = try lockQueue.sync {
                    try deviceSessionCipher.encrypt(paddedMessage: value.data(using: .utf8)!)
                }
                
                let encryptedValue = deviceEncryptedEncryptionKeyMessage.serialized.base64EncodedString()
                let encryptedItem = MulticastEncryptedItem(encryptedValue: encryptedValue, deviceMulticastId: publicInitKeysBundle.deviceId)
                
                encryptedItems[publicInitKeysBundle.deviceId] = encryptedItem
            } catch {
                CryptoToolkit.sharedInstance.configuration.logging?.log(message: "An exception: \(error) occured while trying to encrypt a message to a device: \(publicInitKeysBundle.deviceId)")
                
                if !MultiCastKit.isErrorMappable(error: error) {
                    throw error
                }
                
                if usedRandomPublicInitKey {
                    self.cryptoStore.deleteSessionForContact(publicInitKeysBundle.userId, deviceId: publicInitKeysBundle.deviceId)
                }
                errorDicts[publicInitKeysBundle.deviceId] = MultiCastKit.mapError(error: error)
            }
        }
        
        return EncryptionResults(succeed: encryptedItems, failed: errorDicts)
    }
    
    public func decryptUserItemFromEncryptedItems(_ encryptedItems: [MulticastEncryptedItem], senderId: String, senderDeviceId: String, initializationVector: String?) throws -> MulticastDecryptedItem {
        
        let logger = CryptoToolkit.sharedInstance.configuration.logging
        let lockQueue = DispatchQueue(label: "com.tungstenapp.TungstenCrypto.decrypt.1")
        return try lockQueue.sync {

            guard senderDeviceId != self.cryptoStore.deviceId else {
                throw NSError.errorForMessageSentFromCurrentDevice()
            }
            
            guard let pickedEncryptedItem = encryptedItems.first(where: { $0.deviceMulticastId == cryptoStore.deviceId }) else {
                throw NSError.errorForMessageNotMeantForCurrentDevice()
            }
        
            guard let cipherTextBody = Data(base64Encoded: pickedEncryptedItem.encryptedValue) else {
                throw NSError.errorForUnableToDecryptMessage()
            }
            
            let ourInitKeyConsumedBySender: InitKeyRecord?
            let message: CipherMessage
            if let initMessage = try? InitKeySecretMessage(data: cipherTextBody) {
                message = initMessage

                ourInitKeyConsumedBySender = cryptoStore.loadInitKey(initMessage.initKeyID)
                if ourInitKeyConsumedBySender == nil {
                    // Init key has already been used.
                    // It could be used by:
                    // sender of the current message - sender can send multiple init key messages to the same recipient (normal situation) or
                    // someone else - in this case it's NOT possible to establish the session
                    logger?.log(message: String(format: "[CRYPTO][INITKEY] Init key with id:\n %d \n not found in crypto store! Someone's already picked it.", initMessage.initKeyID))
                    
                    guard cryptoStore.containsSession(senderId, deviceId: senderDeviceId) else {
                        // It's not another init key message from the sender who previously used the init key
                        // The init key has been used by other user, it's NOT possible to establish the session
                        logger?.log(message: String(format: "\n\n[CRYPTO][INITKEY] Session with sender not found. Other user picked init key with id:%d\n\n", initMessage.initKeyID))
                        throw NSError.errorForInitKeyFromMessageNotFound()
                    }
                }
            } else {
                message = try SecretMessage(data: cipherTextBody)
                ourInitKeyConsumedBySender = nil
            }
            
            let decryptedValue: String
            do {
                let lockQueue = DispatchQueue(label: "com.tungstenapp.TungstenCrypto.decrypt.2")
                let decryptedData = try lockQueue.sync {
                    return try SessionCipher(sessionStore: cryptoStore, recipientId: senderId, deviceId: senderDeviceId).decrypt(cipherMessage: message)
                }
                guard let utf8Decoded = String(data: decryptedData, encoding: .utf8) else {
                    throw NSError.errorForUnableToDecryptMessagePayload()
                }
                decryptedValue = utf8Decoded
            } catch {
                if !MultiCastKit.isErrorMappable(error: error) {
                    throw error
                }
                throw MultiCastKit.mapError(error: error)
            }
            
            if let ourInitKeyConsumedBySender = ourInitKeyConsumedBySender {
                self.cryptoStore.removeInitKey(ourInitKeyConsumedBySender.id)
            }
            
            return MulticastDecryptedItem(decryptedValue: decryptedValue,
                                          encryptionInitializationVector: initializationVector,
                                          consumedInitKeyId: ourInitKeyConsumedBySender?.id)
        }
    }
 
    public func messageHeaderDictionary(senderId: String,
                                        encryptionInitializationVector: String,
                                        encryptionKey: String,
                                        recipientsInitKeysBundles initKeysBundles: [CryptoInitKeysBundle]) throws -> MultiCastMessageHeader {
        
        let lockQueue = DispatchQueue(label: "com.tungstenapp.TungstenCrypto.messageHeaderDictionary")
        return try lockQueue.sync {
           
            let encryptedKeys = try forceEncryptValue(encryptionKey,
                             forUserWithInitKeysBundles: initKeysBundles)
        
            return MultiCastMessageHeader(senderId: senderId,
                                          senderDeviceId: self.cryptoStore.deviceId,
                                          initializationVector: encryptionInitializationVector,
                                          keys: encryptedKeys)
        }
    }
    
    public func messagePayload(text: String, encryptionInitializationVector: String, encryptionKey: String) -> String? {
        guard   let textData = text.data(using: .utf8),
                let encryptionKeyData = Data(base64Encoded: encryptionKey),
                let initializationVectorData = Data(base64Encoded: encryptionInitializationVector) else {
                return nil
        }
        
        let symmetricCipher = CryptoToolkit.sharedInstance.configuration.symmetricCipher
        
        guard let encryptedMessageTextData = try? symmetricCipher.encrypt(data: textData, key: encryptionKeyData, iv: initializationVectorData) else {
            return nil
        }
        return encryptedMessageTextData.base64EncodedString()
    }
    
    public func processMessage(messageHeader: MultiCastMessageHeader, encryptedPayload: String) throws -> MulticastMessageProcessingResult {
        let symmetricCipher = CryptoToolkit.sharedInstance.configuration.symmetricCipher
        
        let decryptedItem = try self.decryptUserItemFromEncryptedItems(messageHeader.keys,
                                               senderId: messageHeader.senderId,
                                               senderDeviceId: messageHeader.senderDeviceId,
                                               initializationVector: messageHeader.initializationVector)
        
        let decryptedKey = decryptedItem.decryptedValue
        
        guard
            let iv = Data(base64Encoded: messageHeader.initializationVector),
            let decryptedKeyData = Data(base64Encoded: decryptedKey),
            let encryptedPayloadData = Data(base64Encoded: encryptedPayload),
            let decryptedPayloadData = try? symmetricCipher.decrypt(data: encryptedPayloadData, key: decryptedKeyData, iv: iv),
            let decryptedPayload = String(bytes: decryptedPayloadData, encoding: .utf8)
        else {
            throw NSError.errorForUnableToDecryptMessagePayload()
        }
        
        return MulticastMessageProcessingResult(decryptedPayload: decryptedPayload,
                                                encryptionInitializationVector: messageHeader.initializationVector,
                                                encryptionKey: decryptedKey,
                                                consumedInitKeyId: decryptedItem.consumedInitKeyId)
    }
    
    public static func isErrorMappable(error: Error) -> Bool {
        let nsError = error as NSError
        
        let supprotedExceptions = [
            CryptoErrors.untrustedIdentityKeyException,
            CryptoErrors.invalidKeyIdException,
            CryptoErrors.invalidKeyException,
            CryptoErrors.noSessionException,
            CryptoErrors.invalidMessageException,
            CryptoErrors.cipherException,
            CryptoErrors.duplicateMessageException,
            CryptoErrors.legacyMessageException,
            CryptoErrors.invalidVersionException,
            CryptoErrors.sessioNotInitializedErrorCode
        ]
        
        return nsError.domain == CryptoErrors.domain && supprotedExceptions.contains(nsError.code)
    }
    
    public static func mapError(error: Error) -> Error {
        let nsError = error as NSError
        
        if  nsError.domain == CryptoErrors.domain && nsError.code == CryptoErrors.duplicateMessageException {
            return NSError.errorForDuplicatedMessage()
        }
        
        return NSError.errorForUnderlyingCryptoMessageDecryptionError(error: (error as NSError))
    }    
}
