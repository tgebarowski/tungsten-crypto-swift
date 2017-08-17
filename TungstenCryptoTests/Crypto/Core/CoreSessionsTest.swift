//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

import XCTest

@testable import TungstenCrypto

class CoreSessionsTest: XCTestCase {
    
    let keyAgreement: KeyAgreement = SodiumKeyAgreement()
    
    var mockedKeyAgreement: MockedKeyAgreement! = nil
    
    override func setUp() {
        super.setUp()
        
        mockedKeyAgreement = MockedKeyAgreement(realObject: keyAgreement)
        
        CryptoToolkit.sharedInstance.cleanup()
        try? CryptoToolkit.sharedInstance.setup(CryptoConfigurationBuilder.init()
            .setKeyAgreement(mockedKeyAgreement)
            .build()
        )
    }
    
    override func tearDown() {
        super.tearDown()
        
        CryptoToolkit.sharedInstance.cleanup()
    }

    func testShouldInitSessionStateForAlice() throws {
        //given
        let sessionState = SessionState()
        
        let mockedKeyPair = KeyPair(privateKey: "042764c97296509cd179b91a973a9dbec30a764be35203e615f789de38146bd8655a8848ca88b51222dde40c9db256ab4a32aba67896dd7bc6b36a293a137661".hexStringToByteArray(), publicKey: "655a8848ca88b51222dde40c9db256ab4a32aba67896dd7bc6b36a293a137661".hexStringToByteArray())
        
        mockedKeyAgreement.nextKeyPair = mockedKeyPair
        
        let ourIdentityKeyPair = KeyPair(privateKey: "811548df7b3965e40a45e9f357146a8e908548644b6b64b9bd0ea74658d831f7b6b30a018e2d2c8e8a77b089c9e3561a70dc02e373c04a3f97a8240d9c91143e".hexStringToByteArray(), publicKey: "b6b30a018e2d2c8e8a77b089c9e3561a70dc02e373c04a3f97a8240d9c91143e".hexStringToByteArray())
        
        let theirIdentityKeyPublic = "ec3c61175b0a52881ef6be96f6e85f81ef2d73c863cbd87548da0e9470d6202a".hexStringToByteArray()
        let theirSignedInitKeyPublic = "ed9fcec51017e8b20a53f412d5d3d43e82273848054a7b2f3eb7cb4236f038aa".hexStringToByteArray()
        let theirOneTimePasswordInitKeyPublic = "5e61d54a7a87900ee347a5b0cf54efbbf215d42f6a0fc9955ce915679884f82a".hexStringToByteArray()
        let theirCoreKey = "64fe4847645f7d8b8aaa1dd5e11259733401c07351bd52b7ce1146db0d1dd40c".hexStringToByteArray()
        let ourBaseKey = KeyPair(privateKey: "dc5d445537af01712bde86ccc4a2ed5251ecd8f4ed62b784623d597ba3d7a98c0f72b44ea290e38c63e1e2184b44a2def3235a8f6b9064bba5f7e7ebaf3b09fe".hexStringToByteArray(), publicKey: "0f72b44ea290e38c63e1e2184b44a2def3235a8f6b9064bba5f7e7ebaf3b09fe".hexStringToByteArray())
        
        let params = AliceCryptoParameters(identityKey: ourIdentityKeyPair,
                                           theirIdentityKey: theirIdentityKeyPublic,
                                           ourBaseKey: ourBaseKey,
                                           theirSignedInitKey: theirSignedInitKeyPublic,
                                           theirOneTimeInitKey: theirOneTimePasswordInitKeyPublic,
                                           theirCoreKey: theirCoreKey
            
        )
        
        //when
        try CoreSession.initialize(sessionState, sessionVersion: 3, aliceParameters: params)
        
        //then
        XCTAssertEqual(3, sessionState.version)
        
        XCTAssertNotNil(sessionState.initalizedState)
        
        XCTAssertEqual("ec3c61175b0a52881ef6be96f6e85f81ef2d73c863cbd87548da0e9470d6202a", sessionState.initalizedState?.remoteIdentityKey.toHexString())
        XCTAssertEqual("b6b30a018e2d2c8e8a77b089c9e3561a70dc02e373c04a3f97a8240d9c91143e", sessionState.initalizedState?.localIdentityKey.toHexString())
        XCTAssertEqual("62d9d3a46193547e7c0b36b7d916c33639a2d1ae5d3449e88493b0abbc8717c7", sessionState.initalizedState?.rootKey.keyData.toHexString())
        XCTAssertEqual(0, sessionState.initalizedState?.senderChainKey.index)
        XCTAssertEqual("129df4af65700a6258f2a650e650453b4024a45397ea1c616b7a1fcaa4bf07ed", sessionState.initalizedState?.senderChainKey.key.toHexString())
        XCTAssertEqual("042764c97296509cd179b91a973a9dbec30a764be35203e615f789de38146bd8655a8848ca88b51222dde40c9db256ab4a32aba67896dd7bc6b36a293a137661", sessionState.initalizedState?.senderCoreKeyPair.privateKey.toHexString())
        XCTAssertEqual("655a8848ca88b51222dde40c9db256ab4a32aba67896dd7bc6b36a293a137661", sessionState.initalizedState?.senderCoreKeyPair.publicKey.toHexString())
        
        XCTAssertNotNil(sessionState.receiverChain(theirCoreKey))
        XCTAssertEqual(0, sessionState.receiverChain(theirCoreKey)?.index)
        XCTAssertEqual("d179e1690df48f11638e36fed5273ae1fe51c3a7dc0510317fc20cd59d712bb9", sessionState.receiverChain(theirCoreKey)?.chain.chainKey.key.toHexString())
        XCTAssertEqual(0, sessionState.receiverChain(theirCoreKey)?.chain.chainKey.index)
    }
    
    func testShouldInitSessionStateForBob() throws {
        //given
        let sessionState = SessionState()
    
        let ourIdentityKeyPair = KeyPair(privateKey: "811548df7b3965e40a45e9f357146a8e908548644b6b64b9bd0ea74658d831f7b6b30a018e2d2c8e8a77b089c9e3561a70dc02e373c04a3f97a8240d9c91143e".hexStringToByteArray(), publicKey: "b6b30a018e2d2c8e8a77b089c9e3561a70dc02e373c04a3f97a8240d9c91143e".hexStringToByteArray())
        
        let theirIdentityKeyPublic = "ec3c61175b0a52881ef6be96f6e85f81ef2d73c863cbd87548da0e9470d6202a".hexStringToByteArray()
        let theirBaseKey = "64fe4847645f7d8b8aaa1dd5e11259733401c07351bd52b7ce1146db0d1dd40c".hexStringToByteArray()
        let ourSignedInitKey = KeyPair(privateKey: "dc5d445537af01712bde86ccc4a2ed5251ecd8f4ed62b784623d597ba3d7a98c0f72b44ea290e38c63e1e2184b44a2def3235a8f6b9064bba5f7e7ebaf3b09fe".hexStringToByteArray(), publicKey: "0f72b44ea290e38c63e1e2184b44a2def3235a8f6b9064bba5f7e7ebaf3b09fe".hexStringToByteArray())
        
        let ourCoreKey = KeyPair(privateKey: "1ecb44797294ab00a1dc5bd522da14a78de9fe2b39554fb1abe393c45e5a730aade6534000f19ca53fe96537494e5ecd37b1d618ce4621e4cd9207f8d8ecce16".hexStringToByteArray(), publicKey: "5c69c3a0c410080e6fa37d86a7bf25aadd5870547948466f6a22e8ee88952067".hexStringToByteArray())
        
        let ourOneTimeInitKey = KeyPair(privateKey: "cf4913cf910a3df1254f81747cd718ee7d8b21bbfa60fef0f8c9b3d74d333efa0c5425d6c4d8359aeb3a7bd72d307f73b6a0d0872b28f1459a09f66703d1859a".hexStringToByteArray(), publicKey: "0c5425d6c4d8359aeb3a7bd72d307f73b6a0d0872b28f1459a09f66703d1859a".hexStringToByteArray())
        
        let params = BobCryptoParameters(identityKey: ourIdentityKeyPair,
                                           theirIdentityKey: theirIdentityKeyPublic,
                                           ourSignedInitKey: ourSignedInitKey,
                                           ourCoreKey: ourCoreKey,
                                           ourOneTimeInitKey: ourOneTimeInitKey,
                                           theirBaseKey: theirBaseKey
            
        )
        
        //when
        try CoreSession.initialize(sessionState, sessionVersion: 3, bobParameters: params)
        
        //then
        XCTAssertEqual(3, sessionState.version)
        
        XCTAssertNotNil(sessionState.initalizedState)
        
        XCTAssertEqual(theirIdentityKeyPublic.toHexString(), sessionState.initalizedState?.remoteIdentityKey.toHexString())
        XCTAssertEqual(ourIdentityKeyPair.publicKey.toHexString(), sessionState.initalizedState?.localIdentityKey.toHexString())
        XCTAssertEqual("745c875ccf2d711c3f436ed7991e00c3b1fa90f9516699c72bc2f2ff8737bcbf", sessionState.initalizedState?.rootKey.keyData.toHexString())
        XCTAssertEqual(0, sessionState.initalizedState?.senderChainKey.index)
        XCTAssertEqual("ff2f62c89f78ad61802c236b17c081352cab443cae7e223094bbdd27b57194d2", sessionState.initalizedState?.senderChainKey.key.toHexString())
        XCTAssertEqual("1ecb44797294ab00a1dc5bd522da14a78de9fe2b39554fb1abe393c45e5a730aade6534000f19ca53fe96537494e5ecd37b1d618ce4621e4cd9207f8d8ecce16", sessionState.initalizedState?.senderCoreKeyPair.privateKey.toHexString())
        XCTAssertEqual("5c69c3a0c410080e6fa37d86a7bf25aadd5870547948466f6a22e8ee88952067", sessionState.initalizedState?.senderCoreKeyPair.publicKey.toHexString())
    }
}

class MockedKeyAgreement : KeyAgreement{
    
    var realObject: KeyAgreement
    
    public var nextKeyPair: KeyPair?
    
    init(realObject: KeyAgreement) {
        self.realObject = realObject
        self.nextKeyPair = nil
    }
    
    func generateKeyPair() -> KeyPair {
        if(nextKeyPair != nil){
            let result = nextKeyPair!
            
            nextKeyPair = nil
            
            return result
        }
        
        assertionFailure()
        return realObject.generateKeyPair()
    }
    
    func sharedSecred(from publicKey: Data, keyPair: KeyPair) -> Data? {
        return try? realObject.sharedSecred(from: publicKey, keyPair: keyPair)
    }
    
    func sign(data: Data, keyPair: KeyPair) -> Data {
        return realObject.sign(data: data, keyPair: keyPair)
    }
    
    func verify(signature: Data, publicKey: Data, data: Data) -> Bool {
        return realObject.verify(signature: signature, publicKey: publicKey, data: data)
    }
}
