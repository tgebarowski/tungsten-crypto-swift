//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class SessionBuilder: NSObject {
    
    private let currentVersion = 3
    
    private var recipientId: String
    private var deviceId: String

    private var sessionStore: SessionStore
    private var initKeyStore: InitKeyStore
    private var signedInitKeyStore: SignedInitKeyStore
    private var identityStore: IdentityKeyStore
    
    public init(sessionStore: SessionStore, initKeyStore: InitKeyStore, signedInitKeyStore: SignedInitKeyStore, identityKeyStore: IdentityKeyStore, recipientId: String, deviceId: String) {
        self.sessionStore = sessionStore
        self.initKeyStore = initKeyStore
        self.signedInitKeyStore = signedInitKeyStore
        self.identityStore = identityKeyStore
        self.recipientId = recipientId
        self.deviceId = deviceId
    }
    
    public convenience init(sessionStore: CryptoStore, recipientId: String, deviceId: String) {
        self.init(sessionStore: sessionStore, initKeyStore: sessionStore, signedInitKeyStore: sessionStore, identityKeyStore: sessionStore, recipientId: recipientId, deviceId: deviceId)
    }
    
    public func processInitKeyBundle(_ initKeyBundle: InitKeyBundle) throws {
        let theirIdentityKey = try initKeyBundle.identityKey.removeKeyType()
        let theirSignedInitKey = try initKeyBundle.signedInitKeyPublic.removeKeyType()
        
        CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO] Processing initKey bundle for their identity key: %@", theirIdentityKey.debugDescription))
        
        if !self.identityStore.isTrustedIdentityKey(theirIdentityKey, recipientId: self.recipientId, deviceId: initKeyBundle.deviceId) {
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.untrustedIdentityKeyException, userInfo: [NSLocalizedDescriptionKey: "Identity key is not valid"])
        }
        
        let keyAgreement = CryptoToolkit.sharedInstance.configuration.keyAgreement
        
        if !keyAgreement.verify(signature: initKeyBundle.signedInitKeySignature, publicKey: theirIdentityKey, data: initKeyBundle.signedInitKeyPublic) {
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.invalidKeyException, userInfo: [NSLocalizedDescriptionKey: "Key is not  validly signed"])
        }
        
        let sessionRecord = self.sessionStore.loadSession(self.recipientId, deviceId: initKeyBundle.deviceId)
        let ourBaseKey = keyAgreement.generateKeyPair()
        let theirOneTimeInitKey = try initKeyBundle.initKeyPublic.removeKeyType()
        let theirOneTimeInitKeyId = initKeyBundle.initKeyId
        let theirSignedInitKeyId = initKeyBundle.signedInitKeyId
        
        let parameters = AliceCryptoParameters(identityKey: self.identityStore.identityKeyPair(),
                                                theirIdentityKey: theirIdentityKey,
                                                ourBaseKey: ourBaseKey,
                                                theirSignedInitKey: theirSignedInitKey,
                                                theirOneTimeInitKey: theirOneTimeInitKey,
                                                theirCoreKey: theirSignedInitKey)
        
        if !sessionRecord.isFresh {
            CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO] Archiving current session with sender chain key: %@ index: %d",
                                                       (sessionRecord.sessionState.initalizedState?.senderChainKey.key as NSData?) ?? "",
                                                       sessionRecord.sessionState.initalizedState?.senderChainKey.index ?? 0))
            sessionRecord.archiveCurrentState()
        }
        

        try CoreSession.initialize(sessionRecord.sessionState, sessionVersion: currentVersion, aliceParameters: parameters)
        sessionRecord.sessionState.setPendingInitKey(theirOneTimeInitKeyId, signedInitKeyId: theirSignedInitKeyId, baseKey: ourBaseKey.publicKey)
        sessionRecord.sessionState.localRegistrationId = self.identityStore.localRegistrationId()
        sessionRecord.sessionState.remoteRegistrationId = initKeyBundle.registrationId
        sessionRecord.sessionState.aliceBaseKey = ourBaseKey.publicKey
        
        self.sessionStore.storeSession(self.recipientId, deviceId: self.deviceId, session: sessionRecord)
        self.identityStore.saveRemoteIdentity(theirIdentityKey, recipientId: self.recipientId, deviceId: initKeyBundle.deviceId)
    }
    
    public func processInitKeySecretMessage(_ message: InitKeySecretMessage, sessionRecord: SessionRecord, deviceId: String) throws -> NSNumber? {
        if let unsignedInitKeyId: Int = try self.processInitKeySecretMessage(message, sessionRecord: sessionRecord, deviceId: deviceId) {
            return NSNumber(integerLiteral: unsignedInitKeyId)
        } else {
            return nil
        }
    }
    
    public func processInitKeySecretMessage(_ message: InitKeySecretMessage, sessionRecord: SessionRecord, deviceId: String) throws -> Int? {
        let messageVersion = Int(message.version)
        let theirIdentityKey = try message.identityKey.removeKeyType()
        
        if !self.identityStore.isTrustedIdentityKey(theirIdentityKey, recipientId: self.recipientId, deviceId: deviceId) {
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.untrustedIdentityKeyException, userInfo: [NSLocalizedDescriptionKey: "There is a previously known identity key."])
        }
        
        var unSignedInitKeyId: Int? = nil
        
        switch messageVersion {
        case currentVersion:
            unSignedInitKeyId = try self.processInitKeyV3(message, withSession: sessionRecord)
        default:
            throw NSError(domain: CryptoErrors.domain, code: CryptoErrors.invalidVersionException, userInfo: [NSLocalizedDescriptionKey: "Trying to initialize with unknown version"])
        }
        
        self.identityStore.saveRemoteIdentity(theirIdentityKey, recipientId: self.recipientId, deviceId: deviceId)
        return unSignedInitKeyId
    }
    
    private func processInitKeyV3(_ message: InitKeySecretMessage, withSession sessionRecord: SessionRecord) throws -> Int {
        let baseKey = try message.baseKey.removeKeyType()
        
        if sessionRecord.hasSessionState(version: Int(message.version), baseKey: baseKey) {
            return -1
        }
        
        CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO] Processing initKey secret message for their identity key: %@", message.identityKey as NSData))
        let ourSignedInitKey = self.signedInitKeyStore.loadSignedInitKey(message.signedInitKeyId).keyPair
        let theirIdentityKey = try message.identityKey.removeKeyType()
        
        let params = BobCryptoParameters(identityKey: self.identityStore.identityKeyPair(),
                                          theirIdentityKey: theirIdentityKey,
                                          ourSignedInitKey: ourSignedInitKey,
                                          ourCoreKey: ourSignedInitKey,
                                          ourOneTimeInitKey: self.initKeyStore.loadInitKey(message.initKeyID)?.keyPair,
                                          theirBaseKey: baseKey)
        
        if !sessionRecord.isFresh {
            CryptoToolkit.sharedInstance.configuration.logging?.log(message: String(format: "[CRYPTO] Archiving current session with sender chain key: %@ index: %d",
                                                       (sessionRecord.sessionState.initalizedState?.senderChainKey.key as NSData?) ?? "",
                                                       sessionRecord.sessionState.initalizedState?.senderChainKey.index ?? 0))
            sessionRecord.archiveCurrentState()
        }
        
        try CoreSession.initialize(sessionRecord.sessionState, sessionVersion: Int(message.version), bobParameters: params)
        sessionRecord.sessionState.localRegistrationId = self.identityStore.localRegistrationId()
        sessionRecord.sessionState.remoteRegistrationId = message.registrationId
        sessionRecord.sessionState.aliceBaseKey = baseKey
        
        if message.initKeyID >= 0 && message.initKeyID != 0xffffff {
            return Int(message.initKeyID)
        } else {
            return -1
        }
    }
}
