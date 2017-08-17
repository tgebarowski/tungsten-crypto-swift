//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

import XCTest

import TungstenCrypto

class KeyDerivationTest: XCTestCase {
    
    var target: KeyDerivation = HMACKDFKeyDerivation()
    
    func testHmac() {
        //given
        let pkData = "973909a0fcb3c65af34671560e2c22a70e92ba918a79f737d1e8e76eaf2013ad".hexStringToByteArray()
        let publicKey = "ade6534000f19ca53fe96537494e5ecd37b1d618ce4621e4cd9207f8d8ecce16".hexStringToByteArray()
        let expectedMac = "40d735b823c173ffc25fd25286a9b91d4a1001dcdca3ce371a24dbb0312603a9"
        
        //when
        let result = target.hmac(seed: pkData, key: publicKey)
        //then
        XCTAssertEqual(expectedMac, result.toHexString())
    }
    
    func testFullHmac(){
        //given
        let senderIdentityKey = "973909a0fcb3c65af34671560e2c22a70e92ba918a79f737d1e8e76eaf2013ad".hexStringToByteArray()
        let receiverIdentityKey = "0c5425d6c4d8359aeb3a7bd72d307f73b6a0d0872b28f1459a09f66703d1859a".hexStringToByteArray()
        let macKey = "ade6534000f19ca53fe96537494e5ecd37b1d618ce4621e4cd9207f8d8ecce16".hexStringToByteArray()
        let data = "5c69c3a0c410080e6fa37d86a7bf25aadd5870547948466f6a22e8ee88952067".hexStringToByteArray()
        
        let expectedMac = "76baadb612d3d5772d56bcac3312552480e0c22fe816442d35c65a0ad1032497"
        
        //when
        let result = target.hmac(senderIdentityKey: senderIdentityKey, receiverIdentityKey: receiverIdentityKey, macKey: macKey, serialized: data)
        
        //then
        XCTAssertEqual(expectedMac, result.toHexString())
    }
    
    func testKeyDeriviation() throws{
        //given
        let senderIdentityKey = "973909a0fcb3c65af34671560e2c22a70e92ba918a79f737d1e8e76eaf2013ad".hexStringToByteArray()
        let receiverIdentityKey = "0c5425d6c4d8359aeb3a7bd72d307f73b6a0d0872b28f1459a09f66703d1859a".hexStringToByteArray()
        let macKey = "ade6534000f19ca53fe96537494e5ecd37b1d618ce4621e4cd9207f8d8ecce16".hexStringToByteArray()
        
        let expectedMac = "81a253cd4644aafff4c4da941ca650030a274850aa6f268c0fc9b5127bb02931"
        let expectedKey = "b17f4d56ad888558ee7e0b7974a0d96caf0d4f6115874a05520789206407f6cb"
        let expectedIv = "46c9316e5e9df3c32f372d7ac856c18b"
        
        //when
        let result = try target.deriveKey(seed: senderIdentityKey, info: receiverIdentityKey, salt: macKey)
        
        //then
    
        XCTAssertEqual(expectedMac, result.macKey.toHexString())
        XCTAssertEqual(expectedKey, result.cipherKey.toHexString())
        XCTAssertEqual(expectedIv, result.iv.toHexString())
    }
    
    func testKeyDeriviationNoSalt() throws{
        //given
        let senderIdentityKey = "973909a0fcb3c65af34671560e2c22a70e92ba918a79f737d1e8e76eaf2013ad".hexStringToByteArray()
        let receiverIdentityKey = "0c5425d6c4d8359aeb3a7bd72d307f73b6a0d0872b28f1459a09f66703d1859a".hexStringToByteArray()
    
        let expectedMac = "85f423da45cfde8dabca548ac7085ee0249c5611100bdccc53818aa26e1d12cf"
        let expectedKey = "a2a44b72527e59a44d63ad1049cb248e035ecb604e6221a18f7460241f475c4d"
        let expectedIv = "a8c9b96f88881d36800fd68c33033df4"
        
        //when
        let result = try target.deriveKey(seed: senderIdentityKey, info: receiverIdentityKey, salt: Data(bytes: [0,0,0,0]))
    
        //then
        XCTAssertEqual(expectedMac, result.macKey.toHexString())
        XCTAssertEqual(expectedKey, result.cipherKey.toHexString())
        XCTAssertEqual(expectedIv, result.iv.toHexString())
    }
}
