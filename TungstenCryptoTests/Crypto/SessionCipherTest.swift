//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation
import XCTest
import TungstenCrypto

class SessionCipherTest : XCTestCase {
    
    var mockedSessionStore: MockedSessionStore! = nil
    
    var mockedInitKeyStore: MockedInitKeyStore! = nil
    
    var mockedSignedInitKeyStore: MockedSignedInitKeyStore! = nil
    
    var mockedIdentityKeyStore: MockedIdentityKeyStore! = nil
    
    var target: SessionCipher! = nil
    
    let keyAgreement: KeyAgreement = SodiumKeyAgreement()
    
    let deviceBIdentityKey = KeyPair(privateKey: "042764c97296509cd179b91a973a9dbec30a764be35203e615f789de38146bd8655a8848ca88b51222dde40c9db256ab4a32aba67896dd7bc6b36a293a137661".hexStringToByteArray(), publicKey: "655a8848ca88b51222dde40c9db256ab4a32aba67896dd7bc6b36a293a137661".hexStringToByteArray())
    
    let deviceAIdentityKeyPair = KeyPair(privateKey: "cf4913cf910a3df1254f81747cd718ee7d8b21bbfa60fef0f8c9b3d74d333efa0c5425d6c4d8359aeb3a7bd72d307f73b6a0d0872b28f1459a09f66703d1859a".hexStringToByteArray(), publicKey: "0c5425d6c4d8359aeb3a7bd72d307f73b6a0d0872b28f1459a09f66703d1859a".hexStringToByteArray())
    
    let signedInitKeyKeyPair = KeyPair(privateKey: "811548df7b3965e40a45e9f357146a8e908548644b6b64b9bd0ea74658d831f7b6b30a018e2d2c8e8a77b089c9e3561a70dc02e373c04a3f97a8240d9c91143e".hexStringToByteArray(), publicKey: "b6b30a018e2d2c8e8a77b089c9e3561a70dc02e373c04a3f97a8240d9c91143e".hexStringToByteArray())
    
    let initKeyKeyPair = KeyPair(privateKey: "dc5d445537af01712bde86ccc4a2ed5251ecd8f4ed62b784623d597ba3d7a98c0f72b44ea290e38c63e1e2184b44a2def3235a8f6b9064bba5f7e7ebaf3b09fe".hexStringToByteArray(), publicKey: "0f72b44ea290e38c63e1e2184b44a2def3235a8f6b9064bba5f7e7ebaf3b09fe".hexStringToByteArray())
    
    override func setUp() {
        super.setUp()
        
        mockedSessionStore = MockedSessionStore()
        mockedInitKeyStore = MockedInitKeyStore()
        mockedSignedInitKeyStore = MockedSignedInitKeyStore()
        mockedIdentityKeyStore = MockedIdentityKeyStore()
    }
    
    //Device A sends initKeyMessage to Device B
    func testEncryption() throws {
        //given
        
        mockedIdentityKeyStore.identity = deviceAIdentityKeyPair
        
        initTargetForDevice("deviceB", "2")
        _ = try initSessionFor("deviceB", "2")
        
        //when
        let result = try target.encrypt(paddedMessage: "010203040506070809".hexStringToByteArray())
        
        //NOTE the result cannot be compared to any predefined value as the result is based on random key generator. 
        // the purpose of this test is to check if the encryption doesn't fail and also to get the result value to be used in the second test
        _ = result.serialized.toHexString()
    }
    
    //Device B receives initKeyMessage from Device B
    func testDecriptionOfInitKeyMessage() throws {
        //given
        initTargetForDevice("deviceA", "1")
        mockedIdentityKeyStore.identity = deviceBIdentityKey
        let serializedMessage = "33080e122105cf28f79b8434d71c16827281ab0ef85f1ae730e7b56f73aee3ae3dca71c413c91a21050c5425d6c4d8359aeb3a7bd72d307f73b6a0d0872b28f1459a09f66703d1859a2253330a210518b02165c0f1395630c0874a40716e51191ad24b7f729efcc5fbeb4c12fa6a78100018002219bf00080218b0ba0f50cc5e7baa6134f4fd2f3a19ff1b425e1e630e6d4de599228bec597c2674a1aa6c2a043130303132023130b815c8a1dbddeb49d66a877d5a3ccef7"
        
        let signature = keyAgreement.sign(data: signedInitKeyKeyPair.publicKey, keyPair: deviceBIdentityKey)
        
        let signedInitKeyRecord = SignedInitKeyRecord(id: "10",
                                                      keyPair: signedInitKeyKeyPair,
                                                      signature: signature,
                                                      generatedAt: Date.distantPast
        )
        
        mockedInitKeyStore.storeInitKey(14, initKeyRecord: InitKeyRecord(id: 14, keyPair: initKeyKeyPair))
        mockedSignedInitKeyStore.storeSignedInitKey("10", signedInitKeyRecord: signedInitKeyRecord)
        mockedIdentityKeyStore.saveRemoteIdentity(deviceAIdentityKeyPair.publicKey, recipientId: "deviceA", deviceId: "1")
        
        let initMessage = try InitKeySecretMessage(data: serializedMessage.hexStringToByteArray())
        
        //when
        let result = try target.decrypt(cipherMessage: initMessage)
        
        XCTAssertEqual("010203040506070809", result.toHexString())
    }
    
    func initSessionFor(_ user:String, _ deviceId: String) throws{

        let initKeyPublic = initKeyKeyPair.publicKey
        let initKeyInstance = CryptoPublicInitKey(identifier: 14, publicKey: initKeyPublic)
        
        mockedIdentityKeyStore.saveRemoteIdentity(deviceBIdentityKey.publicKey, recipientId: user, deviceId: deviceId)
        
        let signature = keyAgreement.sign(data: signedInitKeyKeyPair.publicKey, keyPair: deviceBIdentityKey)
        
        let publicInitKeysBundle = CryptoInitKeysBundle(signedInitKeyId: "10",
                                                        deviceId: deviceId,
                                                        userId: user,
                                                        signedInitKeyPublic: signedInitKeyKeyPair.publicKey,
                                                        signedInitKeySignature: signature,
                                                        identityKey: deviceBIdentityKey.publicKey,
                                                        initKeys: [initKeyInstance]
        )
        
        if !mockedSessionStore.containsSession(publicInitKeysBundle.userId, deviceId: publicInitKeysBundle.deviceId) {
            guard !publicInitKeysBundle.initKeys.isEmpty else {
                return
            }
            
            let randomPublicInitKey = publicInitKeysBundle.initKeys[0]
            
            
            let deviceSessionBuilder = SessionBuilder(sessionStore: mockedSessionStore,
                                                      initKeyStore: mockedInitKeyStore,
                                                      signedInitKeyStore: mockedSignedInitKeyStore,
                                                      identityKeyStore: mockedIdentityKeyStore,
                                                      recipientId: publicInitKeysBundle.userId,
                                                      deviceId: publicInitKeysBundle.deviceId)
            
            
            try deviceSessionBuilder.processInitKeyBundle(InitKeyBundle(registrationId: publicInitKeysBundle.deviceId,
                                                                        deviceId: publicInitKeysBundle.deviceId,
                                                                        initKeyId: randomPublicInitKey.identifier,
                                                                        initKeyPublic: randomPublicInitKey.publicKey,
                                                                        signedInitKeyPublic: publicInitKeysBundle.signedInitKeyPublic,
                                                                        signedInitKeyId: publicInitKeysBundle.signedInitKeyId,
                                                                        signedInitKeySignature: publicInitKeysBundle.signedInitKeySignature ,
                                                                        identityKey: publicInitKeysBundle.identityKey))
            
        }
        
    }
    
    func initTargetForDevice(_ user:String, _ deviceId: String){
        target = SessionCipher(sessionStore: mockedSessionStore, initKeyStore: mockedInitKeyStore, signedInitKeyStore: mockedSignedInitKeyStore, identityKeyStore: mockedIdentityKeyStore, recipientId: user, deviceId: deviceId)
    }
}
