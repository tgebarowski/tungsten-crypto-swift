//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

import XCTest

import TungstenCrypto

class SessionBuilderTest : XCTestCase {

    let mockedSessionStore = MockedSessionStore()
    
    let mockedInitKeyStore = MockedInitKeyStore()
    
    let mockedSignedInitKeyStore = MockedSignedInitKeyStore()
    
    let mockedIdentityKeyStore = MockedIdentityKeyStore()
    
    var target: SessionBuilder! = nil
    
    let keyAgreement: KeyAgreement = SodiumKeyAgreement()
    
    override func setUp() {
        super.setUp()
        
        target = SessionBuilder(sessionStore: mockedSessionStore, initKeyStore: mockedInitKeyStore, signedInitKeyStore: mockedSignedInitKeyStore, identityKeyStore: mockedIdentityKeyStore, recipientId: "kmalmur", deviceId: "1")
    }
    
    func testCircle() throws {
        //given
        let theirIdentityKey = KeyPair(privateKey: "042764c97296509cd179b91a973a9dbec30a764be35203e615f789de38146bd8655a8848ca88b51222dde40c9db256ab4a32aba67896dd7bc6b36a293a137661".hexStringToByteArray(), publicKey: "655a8848ca88b51222dde40c9db256ab4a32aba67896dd7bc6b36a293a137661".hexStringToByteArray())
        let signedInitKey = "ec3c61175b0a52881ef6be96f6e85f81ef2d73c863cbd87548da0e9470d6202a".hexStringToByteArray()
        let initKeyPublic = "ed9fcec51017e8b20a53f412d5d3d43e82273848054a7b2f3eb7cb4236f038aa".hexStringToByteArray()
        
        let ourIdentityKeyPair = KeyPair(privateKey: "cf4913cf910a3df1254f81747cd718ee7d8b21bbfa60fef0f8c9b3d74d333efa0c5425d6c4d8359aeb3a7bd72d307f73b6a0d0872b28f1459a09f66703d1859a".hexStringToByteArray(), publicKey: "0c5425d6c4d8359aeb3a7bd72d307f73b6a0d0872b28f1459a09f66703d1859a".hexStringToByteArray())
        mockedIdentityKeyStore.identity = ourIdentityKeyPair
        
        let signature = keyAgreement.sign(data: signedInitKey, keyPair: theirIdentityKey)
        
        let initKeyBundle = InitKeyBundle(registrationId: "10", deviceId: "11", initKeyId: 2, initKeyPublic: initKeyPublic, signedInitKeyPublic: signedInitKey, signedInitKeyId: "3", signedInitKeySignature: signature, identityKey: theirIdentityKey.publicKey)
        
        mockedIdentityKeyStore.saveRemoteIdentity(initKeyBundle.identityKey, recipientId: "kmalmur", deviceId: "11")
        
        //when
        try target.processInitKeyBundle(initKeyBundle)
        
        //then
        
        
    }
}
