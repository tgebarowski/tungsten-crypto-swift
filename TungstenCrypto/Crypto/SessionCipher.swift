//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class SessionCipher: NSObject {
    
    private var recipientId: String
    private var deviceId: String
    private var sessionStore: SessionStore
    private var sessionBuilder: SessionBuilder
    private var initKeyStore: InitKeyStore
    
    public var remoteRegistrationId: String {
        let sessionRecord = self.sessionStore.loadSession(recipientId, deviceId: deviceId)
        return sessionRecord.sessionState.remoteRegistrationId
    }
    
    public var sessionVersion: Int {
        let sessionRecord = self.sessionStore.loadSession(recipientId, deviceId: deviceId)
        return sessionRecord.sessionState.version
    }
    
    public convenience init(sessionStore: CryptoStore, recipientId: String, deviceId: String) {
        self.init(sessionStore: sessionStore, initKeyStore: sessionStore, signedInitKeyStore: sessionStore, identityKeyStore: sessionStore, recipientId: recipientId, deviceId: deviceId)
    }
    
    public init(sessionStore: SessionStore, initKeyStore: InitKeyStore, signedInitKeyStore: SignedInitKeyStore, identityKeyStore: IdentityKeyStore, recipientId: String, deviceId: String) {
        self.recipientId = recipientId
        self.deviceId = deviceId
        self.sessionStore = sessionStore
        self.sessionBuilder = SessionBuilder(sessionStore: sessionStore, initKeyStore: initKeyStore, signedInitKeyStore: signedInitKeyStore, identityKeyStore: identityKeyStore, recipientId: recipientId, deviceId: deviceId)
        self.initKeyStore = initKeyStore
    }
    
    public func encrypt(paddedMessage: Data) throws -> CipherMessage {
        let sessionRecord = sessionStore.loadSession(recipientId, deviceId: deviceId)
        let session = sessionRecord.sessionState
        
        guard let initalizedSessionData = session.initalizedState else {
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.sessioNotInitializedErrorCode, userInfo: nil)
        }
        
        let chainKey = initalizedSessionData.senderChainKey
        let messageKeys = try chainKey.messageKeys()
        let senderCoreKey = initalizedSessionData.senderCoreKeyPair.publicKey
        let previousCounter = session.previousCounter
        let sessionVersion = session.version
    
        let symmetricCipher = CryptoToolkit.sharedInstance.configuration.symmetricCipher
        
        let ciphertextBody = try symmetricCipher.encrypt(data: paddedMessage, key: messageKeys.cipherKey, iv: messageKeys.iv)
        
        CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO][MESSAGE COUNTERS][NO VALID SESSIONS] Will create a secret message for\n local identity: %@;\n remote identity: %@;\n senderChainKey index: %i;\n senderChainKey: %@;\n messageKeys index: %i;\n senderCodeKey: %@;\n previousCounter: %i",
                                                   initalizedSessionData.localIdentityKey as NSData,
                                                   initalizedSessionData.remoteIdentityKey as NSData,
                                                   chainKey.index,
                                                   chainKey.key as NSData,
                                                   messageKeys.index,
                                                   (senderCoreKey as NSData?) ?? "",
                                                   previousCounter))
        
        let cipherMessage: CipherMessage
        let secretMessage = SecretMessage(version: sessionVersion,
                                                          macKey: messageKeys.macKey,
                                                          senderCoreKey: senderCoreKey.prependKeyType(),
                                                          counter: chainKey.index,
                                                          previousCounter: previousCounter,
                                                          cipherText: ciphertextBody,
                                                          senderIdentityKey: initalizedSessionData.localIdentityKey.prependKeyType(),
                                                          receiverIdentityKey: initalizedSessionData.remoteIdentityKey.prependKeyType())
        
        if let items = session.pendingInitKey {
            let localRegistrationId = session.localRegistrationId
            cipherMessage = InitKeySecretMessage(secretMessage: secretMessage,
                                                 registrationId: localRegistrationId,
                                                 initKeyId: items.initKeyId,
                                                 signedInitKeyId: items.signedInitKeyId,
                                                 baseKey: items.baseKey.prependKeyType(),
                                                 senderIdentityKey: initalizedSessionData.localIdentityKey.prependKeyType(),
                                                 receiverIdentityKey: initalizedSessionData.remoteIdentityKey.prependKeyType(),
                                                 macKey: messageKeys.macKey)
        } else {
            cipherMessage = secretMessage
        }
        
        initalizedSessionData.senderChainKey = chainKey.next()
        self.sessionStore.storeSession(self.recipientId, deviceId: self.deviceId, session: sessionRecord)
        
        return cipherMessage
    }
    
    public func decrypt(cipherMessage: CipherMessage) throws -> Data {
        if let initKeyMessage = cipherMessage as? InitKeySecretMessage {
            return try decryptInitKeySecretMessage(initKeyMessage)
        } else if let secretMessage = cipherMessage as? SecretMessage {
            return try decryptSecretMessage(secretMessage)
        } else {
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.messageDeserializationException, userInfo: [NSLocalizedDescriptionKey: "Unkown Message Format"])
        }
    }
    
    private func decryptInitKeySecretMessage(_ initKeySecretMessage: InitKeySecretMessage) throws -> Data {
        let sessionRecord = sessionStore.loadSession(recipientId, deviceId: deviceId)
        let unsignedInitKeyId: Int? = try sessionBuilder.processInitKeySecretMessage(initKeySecretMessage, sessionRecord: sessionRecord, deviceId: deviceId)
        
        let plaintext = try self.decryptWithSessionRecord(sessionRecord, cipherMessage: initKeySecretMessage)
        
        sessionStore.storeSession(recipientId, deviceId: deviceId, session: sessionRecord)
        if let unsignedInitKeyId = unsignedInitKeyId {
            initKeyStore.removeInitKey(unsignedInitKeyId);
        }
        return plaintext
    }
    
    private func decryptSecretMessage(_ secretMessage: SecretMessage) throws -> Data {
        if !sessionStore.containsSession(recipientId, deviceId: deviceId) {
            
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.noSessionException, userInfo: [NSLocalizedDescriptionKey: String(format: "No session for: %@, %d", recipientId, deviceId)])
        }
        
        let sessionRecord = sessionStore.loadSession(recipientId, deviceId: deviceId)
        let plainText = try decryptWithSessionRecord(sessionRecord, cipherMessage: secretMessage)
        
        sessionStore.storeSession(recipientId, deviceId: deviceId, session: sessionRecord)
        
        return plainText
    }
    
    private func extractMessage(_ cipherMessage: CipherMessage) throws -> SecretMessage {
        if let message = cipherMessage as? SecretMessage {
            return message
        } else if let initMessage = cipherMessage as? InitKeySecretMessage {
            return initMessage.message
        } else {
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.messageDeserializationException, userInfo: [NSLocalizedDescriptionKey: "Unkown Message Format"])
        }
    }
    
    private func decryptWithSessionRecord(_ sessionRecord: SessionRecord, cipherMessage: CipherMessage) throws -> Data {
        let message = try extractMessage(cipherMessage)
        let sessionState = sessionRecord.sessionState
        let previousStates = sessionRecord.previousStates
        var errors: [Error] = []

        //            /*
        //             Creating a copy of a SessionState because `decryptWithSessionState:secretMessage:` is mutating this object.
        //             In cases when decription fails we want to revert those changes. As there is not API to revert we are applying
        //             SessionState to sessionRecord only if decryption succeeds.
        //             Situation like this can happen in case of arrival of out-of-order message. If that message "belongs" to one of
        //             previous session states, not reverting changes in current state will cause InvalidSession next time message will
        //             be sent using this session.
        //             */
        
        do {
            guard let sessionStateCopy = sessionState.copy() as? SessionState else {
                fatalError("Session State Copy did not result in a SessionState object")
            }
            try verifyMessageIntegrity(sessionStateCopy, message: cipherMessage, senderCoreKey: message.senderCoreKey, counter: message.counter)
            let decryptedData = try decryptWithSessionState(sessionStateCopy, message: message)
            sessionRecord.replace(sessionState, with: sessionStateCopy)
            return decryptedData
        } catch {
            let nsError = error as NSError
            
            if nsError.domain == CryptoErrors.domain && nsError.code == CryptoErrors.invalidMessageException {
                errors.append(error)
            } else {
                throw error
            }
        }
        
        for previousState in previousStates {
            do {
                guard let previousStateCopy = previousState.copy() as? SessionState else {
                    fatalError("Session State Copy did not result in a SessionState object")
                }
                try verifyMessageIntegrity(previousStateCopy, message: cipherMessage, senderCoreKey: message.senderCoreKey, counter: message.counter)
                let decryptedData = try decryptWithSessionState(previousStateCopy, message: message)
                sessionRecord.replace(previousState, with: previousStateCopy)
                return decryptedData
            } catch {
                errors.append(error)
            }
        }
        
        throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.invalidMessageException, userInfo: [NSLocalizedDescriptionKey: "No valid sessions",
                                                                           CryptoErrors.innerErrorsUserInfoKey: errors])
    }
    
    private func verifyMessageIntegrity(_ sessionState: SessionState, message: CipherMessage, senderCoreKey: Data, counter: Int) throws {
        guard let sessionStateCopy = sessionState.copy() as? SessionState else {
               fatalError("Session State Copy did not result in a SessionState object")
        }
        
        guard let sessionInitializedData = sessionStateCopy.initalizedState else {
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.invalidMessageException, userInfo: [NSLocalizedDescriptionKey: "Uninitialized session!"])
        }
        let theirEphemeral = try senderCoreKey.removeKeyType()
        let chainKey = try self.getOrCreateChainKeys(sessionStateCopy, theirEphemeral: theirEphemeral)
        let messageKeys = try self.getOrCreateMessageKeysForSession(sessionStateCopy, theirEphemeral: theirEphemeral, chainKey: chainKey, counter: Int(counter))
        
        try message.verifyMac(senderIdentityKey: sessionInitializedData.remoteIdentityKey, receiverIdentityKey: sessionInitializedData.localIdentityKey, macKey: messageKeys.macKey)
    }
    
    private func decryptWithSessionState(_ sessionState: SessionState, message: SecretMessage) throws -> Data {
        
        guard let sessionInitializedData = sessionState.initalizedState else {
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.invalidMessageException, userInfo: [NSLocalizedDescriptionKey: "Uninitialized session!"])
        }
        
        guard message.version == sessionState.version else {
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.invalidMessageException, userInfo: [NSLocalizedDescriptionKey: String(format: "Got message version %d but was expecting %d", message.version, sessionState.version)])
        }
        
        let theirEphemeral = try message.senderCoreKey.removeKeyType()
        let counter = message.counter
        
        let chainKey = try self.getOrCreateChainKeys(sessionState, theirEphemeral: theirEphemeral)
        let messageKeys = try self.getOrCreateMessageKeysForSession(sessionState, theirEphemeral: theirEphemeral, chainKey: chainKey, counter: Int(counter))
        
        CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO][NO VALID SESSIONS] Will verify mac for %@", message.isKind(of: InitKeySecretMessage.self) ? "InitKeySecretMessage" : "SecretMessage"))
        
        CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO][NO VALID SESSIONS] Will verify mac for\n local idenity: %@;\n remote identity: %@;\n chainKey index: %i;\n chainKey: %@;\n messageKeys index: %i;\n senderCodeKey: %@;\n counter: %i",
          sessionInitializedData.localIdentityKey as NSData,
          sessionInitializedData.remoteIdentityKey as NSData,
          chainKey.index,
          chainKey.key as NSData,
          messageKeys.index,
          theirEphemeral as NSData,
          counter))
        
        
        let symmetricCipher = CryptoToolkit.sharedInstance.configuration.symmetricCipher
        let plainText = try symmetricCipher.decrypt(data: message.cipherText, key: messageKeys.cipherKey, iv: messageKeys.iv)
        
        sessionState.clearPendingInitKey ()
        return plainText
    }
    
    private func getOrCreateChainKeys(_ sessionState: SessionState, theirEphemeral: Data) throws -> ChainKey {
        if let chainKey = sessionState.receiverChainKey(theirEphemeral) {
            CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO][NO VALID SESSIONS] Retrieving reciever chain key for sender core key %@", theirEphemeral.debugDescription))
            return chainKey
        } else {
            guard let sessionInitializedData = sessionState.initalizedState else {
                throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.sessioNotInitializedErrorCode, userInfo: nil)
            }
            let keyAgreemenet = CryptoToolkit.sharedInstance.configuration.keyAgreement
            
            let rootKey = sessionInitializedData.rootKey
            let ourEphemeral = sessionInitializedData.senderCoreKeyPair
            let receiverChain = try rootKey.createChain(theirEphemeral: theirEphemeral, ourEphemeral: ourEphemeral)
            let ourNewEphemeral = keyAgreemenet.generateKeyPair()
            let senderChain = try receiverChain.rootKey.createChain(theirEphemeral: theirEphemeral, ourEphemeral: ourNewEphemeral)
            
            CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO][NO VALID SESSIONS] Creating receiver chain key for\n sender core key %@;\n root key: %@,\n receiver core key: %@;\n created receiver chain key: %@;\n creted receiver chain key index: %i;\n new receiver core key: %@;\n new sender chain key %@;\n new sender chain key index: %i",
                                                       theirEphemeral as NSData,
                                                       rootKey.keyData as NSData,
                                                       ourEphemeral.publicKey as NSData,
                                                       receiverChain.chainKey.key as NSData,
                                                       receiverChain.chainKey.index,
                                                       ourNewEphemeral.publicKey as NSData,
                                                       senderChain.chainKey.key as NSData,
                                                       senderChain.chainKey.index))
            
            sessionState.addReceiverChain(theirEphemeral, chainKey: receiverChain.chainKey)
            sessionState.previousCounter = max(sessionState.initalizedState!.senderChainKey.index - 1, 0)
            sessionState.initalizedState = SessionStateInitializedData(remoteIdentityKey: sessionInitializedData.remoteIdentityKey,
                                                                       localIdentityKey: sessionInitializedData.localIdentityKey,
                                                                       rootKey: senderChain.rootKey,
                                                                       sendingChain: SendingChain(chainKey: senderChain.chainKey, senderCoreKeyPair: ourNewEphemeral))
            
            return receiverChain.chainKey
        }
    }
    
    private func getOrCreateMessageKeysForSession(_ sessionState: SessionState, theirEphemeral: Data, chainKey: ChainKey, counter: Int) throws -> MessageKeys {
        if chainKey.index > counter {
            guard let messageKeys = sessionState.removeMessageKeys(theirEphemeral, counter: counter) else {
                CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO][MESSAGE COUNTERS] No message keys with counter %i. 'Received message with old counter exception will be thrown'", counter))
                throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.duplicateMessageException, userInfo: [NSLocalizedDescriptionKey: "Received message with old counter!"])
            }
            
            CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO][MESSAGE COUNTERS] Removing message keys with counter %i", counter))
            return messageKeys
        }
        
        if (chainKey.index - counter) > 2000 {
            throw NSError(domain: "Over 2000 messages into the future!", code: 0, userInfo: [:])
        }
        var chainKey = chainKey
        while chainKey.index < counter {
            let messageKeys = try chainKey.messageKeys()
            sessionState.setMessageKeys(theirEphemeral, messageKeys: messageKeys)
            chainKey = chainKey.next()
        }
        
        CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO][MESSAGE COUNTERS] Created message keys with counter %i", Int32(counter)))
        sessionState.setReceiverChainKey(theirEphemeral, chainKey: chainKey.next())
        return try chainKey.messageKeys()
    }
}
