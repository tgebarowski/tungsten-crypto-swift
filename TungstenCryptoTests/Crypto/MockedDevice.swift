//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

import TungstenCrypto

class MockedDevice{
    
    var deviceAddress: RemoteAddress
    var identityKeyPair: KeyPair
    var signedInitKeyPair: KeyPair
    var initKeyKeyPair: KeyPair
    
    private let mockedSessionStore: MockedSessionStore = MockedSessionStore()
    private let mockedInitKeyStore: MockedInitKeyStore = MockedInitKeyStore()
    private let mockedSignedInitKeyStore: MockedSignedInitKeyStore = MockedSignedInitKeyStore()
    private let mockedIdentityKeyStore: MockedIdentityKeyStore = MockedIdentityKeyStore()
    
    private var signedInitKeyRecord: SignedInitKeyRecord
    private var initKeyRecord: InitKeyRecord
    
    
    init(_ deviceAddress: RemoteAddress, _ identityKeyPair: KeyPair, _ signedInitKeyPair: KeyPair, _ initKeyKeyPair: KeyPair) {
        
        self.deviceAddress = deviceAddress
        self.identityKeyPair = identityKeyPair
        self.signedInitKeyPair = signedInitKeyPair
        self.initKeyKeyPair = initKeyKeyPair
        
        mockedIdentityKeyStore.identity = identityKeyPair
        
        let initKeyNumber = Int(deviceAddress.deviceId)! + 2000
        
        initKeyRecord = InitKeyRecord(id: initKeyNumber, keyPair: initKeyKeyPair)
        mockedInitKeyStore.storeInitKey(initKeyNumber, initKeyRecord: initKeyRecord)
        
        let signature = CryptoToolkit.sharedInstance.configuration.keyAgreement.sign(data: signedInitKeyPair.publicKey, keyPair: identityKeyPair)
        
        signedInitKeyRecord = SignedInitKeyRecord(
            id: String(Int(deviceAddress.deviceId)! + 1000),
            keyPair: signedInitKeyPair,
            signature: signature,
            generatedAt: Date.distantFuture
        )
        
        mockedSignedInitKeyStore.storeSignedInitKey(signedInitKeyRecord.id, signedInitKeyRecord: signedInitKeyRecord)
    }
    
    convenience init(_ address: RemoteAddress) {
        let keyAgreement = CryptoToolkit.sharedInstance.configuration.keyAgreement
        
        self.init(address,
                  keyAgreement.generateKeyPair(),
                  keyAgreement.generateKeyPair(),
                  keyAgreement.generateKeyPair())
    }
    
    convenience init(_ address: RemoteAddress, _ identityKeyPair: KeyPair) {
        let keyAgreement = CryptoToolkit.sharedInstance.configuration.keyAgreement
        
        self.init(address,
                  identityKeyPair,
                  keyAgreement.generateKeyPair(),
                  keyAgreement.generateKeyPair())
    }
    
    func createCipherForDevice(_ address: RemoteAddress)-> SessionCipher {
        return SessionCipher(sessionStore: mockedSessionStore, initKeyStore: mockedInitKeyStore, signedInitKeyStore: mockedSignedInitKeyStore, identityKeyStore: mockedIdentityKeyStore, recipientId: address.recipientId, deviceId: address.deviceId)
    }
    
    func getPublicInitKeyBundle()-> CryptoInitKeysBundle {
        
        let publicInitKey = CryptoPublicInitKey(identifier: initKeyRecord.id, publicKey: initKeyRecord.keyPair.publicKey)
        
        return CryptoInitKeysBundle(signedInitKeyId: signedInitKeyRecord.id, deviceId: deviceAddress.deviceId, userId: deviceAddress.recipientId, signedInitKeyPublic: signedInitKeyRecord.keyPair.publicKey, signedInitKeySignature: signedInitKeyRecord.signature, identityKey: identityKeyPair.publicKey, initKeys: [publicInitKey])
    }
    
    func initSessionFor(_ address: RemoteAddress, _ publicInitKeysBundle: CryptoInitKeysBundle) {
        mockedIdentityKeyStore.saveRemoteIdentity(publicInitKeysBundle.identityKey, recipientId: address.recipientId, deviceId: address.deviceId)
        
        if (!mockedSessionStore.containsSession(publicInitKeysBundle.userId, deviceId: publicInitKeysBundle.deviceId)) {
            if (publicInitKeysBundle.initKeys.isEmpty) {
                return
            }
            let randomPublicInitKey = publicInitKeysBundle.initKeys[0]
            
            let deviceSessionBuilder = SessionBuilder(sessionStore: mockedSessionStore, initKeyStore: mockedInitKeyStore, signedInitKeyStore: mockedSignedInitKeyStore, identityKeyStore: mockedIdentityKeyStore, recipientId: publicInitKeysBundle.userId, deviceId: publicInitKeysBundle.deviceId)
            
            let bundle = InitKeyBundle(registrationId: publicInitKeysBundle.deviceId,
                                       deviceId: publicInitKeysBundle.deviceId,
                                       initKeyId: randomPublicInitKey.identifier,
                                       initKeyPublic: randomPublicInitKey.publicKey,
                                       signedInitKeyPublic: publicInitKeysBundle.signedInitKeyPublic,
                                       signedInitKeyId: publicInitKeysBundle.signedInitKeyId,
                                       signedInitKeySignature: publicInitKeysBundle.signedInitKeySignature,
                                       identityKey: publicInitKeysBundle.identityKey)
            
            try! deviceSessionBuilder.processInitKeyBundle(bundle)
        }
    }
}
