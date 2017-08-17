//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

import Foundation

import XCTest

import TungstenCrypto

class AdvancedSessionCipherTest : XCTestCase {
    
    let deviceBIdentityKeyPair = KeyPair(privateKey: "042764c97296509cd179b91a973a9dbec30a764be35203e615f789de38146bd8655a8848ca88b51222dde40c9db256ab4a32aba67896dd7bc6b36a293a137661".hexStringToByteArray(), publicKey: "655a8848ca88b51222dde40c9db256ab4a32aba67896dd7bc6b36a293a137661".hexStringToByteArray())
    
    let deviceAIdentityKeyPair = KeyPair(privateKey: "cf4913cf910a3df1254f81747cd718ee7d8b21bbfa60fef0f8c9b3d74d333efa0c5425d6c4d8359aeb3a7bd72d307f73b6a0d0872b28f1459a09f66703d1859a".hexStringToByteArray(), publicKey: "0c5425d6c4d8359aeb3a7bd72d307f73b6a0d0872b28f1459a09f66703d1859a".hexStringToByteArray())
    
    let signedInitKeyKeyPair = KeyPair(privateKey: "811548df7b3965e40a45e9f357146a8e908548644b6b64b9bd0ea74658d831f7b6b30a018e2d2c8e8a77b089c9e3561a70dc02e373c04a3f97a8240d9c91143e".hexStringToByteArray(), publicKey: "b6b30a018e2d2c8e8a77b089c9e3561a70dc02e373c04a3f97a8240d9c91143e".hexStringToByteArray())
    
    let initKeyKeyPair = KeyPair(privateKey: "dc5d445537af01712bde86ccc4a2ed5251ecd8f4ed62b784623d597ba3d7a98c0f72b44ea290e38c63e1e2184b44a2def3235a8f6b9064bba5f7e7ebaf3b09fe".hexStringToByteArray(), publicKey: "0f72b44ea290e38c63e1e2184b44a2def3235a8f6b9064bba5f7e7ebaf3b09fe".hexStringToByteArray())
    
    var deviceA: MockedDevice!
    var deviceB: MockedDevice!
    
    override func setUp() {
        super.setUp()
        
        deviceA = MockedDevice(RemoteAddress("deviceA", "1"), deviceAIdentityKeyPair)
        deviceB = MockedDevice(RemoteAddress("deviceB", "2"), deviceBIdentityKeyPair, signedInitKeyKeyPair, initKeyKeyPair)
        
    }
    
    //Device A sends initKeyMessage to Device B
    func testEncryption() throws{
        let sessionCipher = deviceA.createCipherForDevice(deviceB.deviceAddress)
        deviceA.initSessionFor(deviceB.deviceAddress, deviceB.getPublicInitKeyBundle())
        
        let result = try sessionCipher.encrypt(paddedMessage: "010203040506070809".hexStringToByteArray())
        
        //NOTE the result cannot be compared to any predefined value as the result is based on random key generator.
        // the purpose of this test is to check if the encryption doesn't fail and also to get the result value to be used in the second test
        // let text = result.data.toHexString()
        
        
        XCTAssertEqual(187, result.serialized.count) // NOTE FOR ANDROID: bit differe because of initKey being string in swift and int in kotlin
    }
    
    //Device B decrypts predefined initKeyMessage from Device A (generated from testEncryption test)
    
    func testDecryptionOfInitKeyMessage() throws{
        //given
        let sessionCipher = deviceB.createCipherForDevice(deviceA.deviceAddress)
        let serializedMessage = "3308d20f122105daedac6f1e1b61cf1ffb16744e9b8d5ba4e909d260c81e3d50869cb54563d3c41a21050c5425d6c4d8359aeb3a7bd72d307f73b6a0d0872b28f1459a09f66703d1859a2253330a2105c61c789084fe96624db3f771233e3924d20074a3657caf5e9debbc6ae50cc4c1100018002219eee1a67c39df234f89e9b511410d7e47b6f40a902a64164d4fe6468941ae5e014c8bee94255d876d482a0431303031320431303032261bceefe9d5de6d50f3d0e64b8d2785"
        
        //when
        let result = try decryptInitMessageData(sessionCipher, serializedMessage.hexStringToByteArray())
        
        //then
        XCTAssertEqual("010203040506070809", result.toHexString())
    }
    
    //Device B receives initKeyMessage from Device A
    
    func testShouldHande_AB() throws{
        //given
        let plainMessage = "010203040506070809"
        let sessionCipher1 = deviceA.createCipherForDevice(deviceB.deviceAddress)
        let sessionCipher2 = deviceB.createCipherForDevice(deviceA.deviceAddress)
        
        //when
        deviceA.initSessionFor(deviceB.deviceAddress, deviceB.getPublicInitKeyBundle())
        let encryptedData = try sessionCipher1.encrypt(paddedMessage: plainMessage.hexStringToByteArray())
        
        let decryptedData = try decryptInitMessage(sessionCipher2, encryptedData)
        
        //then
        XCTAssertEqual(plainMessage, decryptedData.toHexString())
    }
    
    func testShouldHandeLong_AB() throws{
        //given
        let plainMessage = "0c5425d6c4d8359aeb3a7bd72d307f73b6a0d0872b28f1459a09f66703d1859a"
        let sessionCipher1 = deviceA.createCipherForDevice(deviceB.deviceAddress)
        let sessionCipher2 = deviceB.createCipherForDevice(deviceA.deviceAddress)
        
        //when
        deviceA.initSessionFor(deviceB.deviceAddress, deviceB.getPublicInitKeyBundle())
        let encryptedData = try sessionCipher1.encrypt(paddedMessage: plainMessage.hexStringToByteArray())
        
        let decryptedData = try decryptInitMessage(sessionCipher2, encryptedData)
        
        //then
        XCTAssertEqual(plainMessage, decryptedData.toHexString())
    }
    
    func testShouldHandle_AB_BA() throws{
        //given
        let message1 = "010203040506070809"
        let message2 = "111213141516171819"
        
        let sessionCipher1 = deviceA.createCipherForDevice(deviceB.deviceAddress)
        let sessionCipher2 = deviceB.createCipherForDevice(deviceA.deviceAddress)
        
        //when
        deviceA.initSessionFor(deviceB.deviceAddress, deviceB.getPublicInitKeyBundle())
        let encryptedMessage1 = try sessionCipher1.encrypt(paddedMessage: message1.hexStringToByteArray())
        
        let decryptedMessage1 = try decryptInitMessage(sessionCipher2, encryptedMessage1)
        
        let encryptedMessage2 = try sessionCipher2.encrypt(paddedMessage: message2.hexStringToByteArray())
        
        let decryptedMessage2 = try decryptMessage(sessionCipher1, encryptedMessage2)
        
        //then
        XCTAssertEqual(message1, decryptedMessage1.toHexString())
        XCTAssertEqual(message2, decryptedMessage2.toHexString())
    }
    
    
    func testShouldHandle_AB_BA_AB() throws{
        //given
        let message1 = "010203040506070809"
        let message2 = "111213141516171819"
        let message3 = "3308d20f1221055234"
        
        let sessionCipher1 = deviceA.createCipherForDevice(deviceB.deviceAddress)
        let sessionCipher2 = deviceB.createCipherForDevice(deviceA.deviceAddress)
        deviceA.initSessionFor(deviceB.deviceAddress,
                               deviceB.getPublicInitKeyBundle())     //deviceA starts the session so it needs to process the InitKeyBundle of deviceB
        
        //when
        let encryptedMessage1 = try sessionCipher1.encrypt(paddedMessage: message1.hexStringToByteArray())
        
        let decryptedMessage1 = try decryptInitMessage(sessionCipher2, encryptedMessage1)
        
        let encryptedMessage2 = try sessionCipher2.encrypt(paddedMessage: message2.hexStringToByteArray())
        
        let decryptedMessage2 = try decryptMessage(sessionCipher1, encryptedMessage2)
        
        let encryptedMessage3 = try sessionCipher1.encrypt(paddedMessage: message3.hexStringToByteArray())
        
        let decryptedMessage3 = try decryptMessage(sessionCipher2, encryptedMessage3)
        
        //then
        XCTAssertEqual(message1, decryptedMessage1.toHexString())
        XCTAssertEqual(message2, decryptedMessage2.toHexString())
        XCTAssertEqual(message3, decryptedMessage3.toHexString())
    }
    
    
    func testShouldHandle_AB_AB_BA_AB() throws{
        //given
        let message1 = "010203040506070809"
        let message2 = "111213141516171819"
        let message3 = "3308d20f1221055234"
        let message4 = "331617181921055234"
        
        let sessionCipherA = deviceA.createCipherForDevice(deviceB.deviceAddress)
        let sessionCipherB = deviceB.createCipherForDevice(deviceA.deviceAddress)
        
        deviceA.initSessionFor(deviceB.deviceAddress,
                               deviceB.getPublicInitKeyBundle())     //deviceA starts the session so it needs to process the InitKeyBundle of deviceB
        
        //when
        let encryptedMessage1 = try sessionCipherA.encrypt(paddedMessage: message1.hexStringToByteArray())
        let encryptedMessage2 = try sessionCipherA.encrypt(paddedMessage: message2.hexStringToByteArray())
        
        let decryptedMessage1 = try decryptInitMessage(sessionCipherB, encryptedMessage1)
        
        let decryptedMessage2 = try decryptInitMessage(sessionCipherB, encryptedMessage2)
        
        let encryptedMessage3 = try sessionCipherB.encrypt(paddedMessage: message3.hexStringToByteArray())
        
        let decryptedMessage3 = try decryptMessage(sessionCipherA, encryptedMessage3)
        
        let encryptedMessage4 = try sessionCipherA.encrypt(paddedMessage: message4.hexStringToByteArray())
        
        let decryptedMessage4 = try decryptMessage(sessionCipherB, encryptedMessage4)
        
        //then
        XCTAssertEqual(message1, decryptedMessage1.toHexString())
        XCTAssertEqual(message2, decryptedMessage2.toHexString())
        XCTAssertEqual(message3, decryptedMessage3.toHexString())
        XCTAssertEqual(message4, decryptedMessage4.toHexString())
    }
    
    
    func testShouldHandleUnorderedInitKeyMessage_AB_AB_BA_AB() throws{
        //given
        let message1 = "010203040506070809"
        let message2 = "111213141516171819"
        let message3 = "3308d20f1221055234"
        let message4 = "331617181921055234"
        
        let sessionCipherA = deviceA.createCipherForDevice(deviceB.deviceAddress)
        let sessionCipherB = deviceB.createCipherForDevice(deviceA.deviceAddress)
        
        deviceA.initSessionFor(deviceB.deviceAddress,
                               deviceB.getPublicInitKeyBundle())     //deviceA starts the session so it needs to process the InitKeyBundle of deviceB
        
        //when
        let encryptedMessage1 = try sessionCipherA.encrypt(paddedMessage: message1.hexStringToByteArray())
        let encryptedMessage2 = try sessionCipherA.encrypt(paddedMessage: message2.hexStringToByteArray())
        
        let decryptedMessage2 = try decryptInitMessage(sessionCipherB, encryptedMessage2)
        
        let decryptedMessage1 = try decryptInitMessage(sessionCipherB, encryptedMessage1)
        
        let encryptedMessage3 = try sessionCipherB.encrypt(paddedMessage: message3.hexStringToByteArray())
        
        let decryptedMessage3 = try decryptMessage(sessionCipherA, encryptedMessage3)
        
        let encryptedMessage4 = try sessionCipherA.encrypt(paddedMessage: message4.hexStringToByteArray())
        
        let decryptedMessage4 = try decryptMessage(sessionCipherB, encryptedMessage4)
        
        //then
        XCTAssertEqual(message1, decryptedMessage1.toHexString())
        XCTAssertEqual(message2, decryptedMessage2.toHexString())
        XCTAssertEqual(message3, decryptedMessage3.toHexString())
        XCTAssertEqual(message4, decryptedMessage4.toHexString())
    }
    
    
    func testShouldHandleUnorderedMessage_AB_BA_AB_AB() throws{
        //given
        let message1 = "010203040506070809"
        let message2 = "111213141516171819"
        let message3 = "3308d20f1221055234"
        let message4 = "331617181921055234"
        
        let sessionCipherA = deviceA.createCipherForDevice(deviceB.deviceAddress)
        let sessionCipherB = deviceB.createCipherForDevice(deviceA.deviceAddress)
        
        deviceA.initSessionFor(deviceB.deviceAddress,
                               deviceB.getPublicInitKeyBundle())
        //deviceA starts the session so it needs to process the InitKeyBundle of deviceB
        
        //when
        let encryptedMessage1 = try sessionCipherA.encrypt(paddedMessage: message1.hexStringToByteArray())
        
        let decryptedMessage1 = try decryptInitMessage(sessionCipherB, encryptedMessage1)
        
        let encryptedMessage2 = try sessionCipherB.encrypt(paddedMessage: message2.hexStringToByteArray())
        
        let decryptedMessage2 = try decryptMessage(sessionCipherA, encryptedMessage2)
        
        let encryptedMessage3 = try sessionCipherA.encrypt(paddedMessage: message3.hexStringToByteArray())
        let encryptedMessage4 = try sessionCipherA.encrypt(paddedMessage: message4.hexStringToByteArray())
        
        let decryptedMessage4 = try decryptMessage(sessionCipherB, encryptedMessage4)
        let decryptedMessage3 = try decryptMessage(sessionCipherB, encryptedMessage3)
        
        //then
        XCTAssertEqual(message1, decryptedMessage1.toHexString())
        XCTAssertEqual(message2, decryptedMessage2.toHexString())
        XCTAssertEqual(message3, decryptedMessage3.toHexString())
        XCTAssertEqual(message4, decryptedMessage4.toHexString())
    }
    
    func disabled_testShouldHandleMultipleChains() throws {
        //given
        let inputMessages = ["01", "02", "03", "04", "05", "06", "07"]
        
        
        let sessionCipherA = deviceA.createCipherForDevice(deviceB.deviceAddress)
        let sessionCipherB = deviceB.createCipherForDevice(deviceA.deviceAddress)
        
        deviceA.initSessionFor(deviceB.deviceAddress, deviceB.getPublicInitKeyBundle())
        deviceB.initSessionFor(deviceA.deviceAddress, deviceA.getPublicInitKeyBundle())
        
        //when
        let encryptedMessage1 = try sessionCipherA.encrypt(paddedMessage: inputMessages[0].hexStringToByteArray())
        let encryptedMessage2 = try sessionCipherA.encrypt(paddedMessage: inputMessages[1].hexStringToByteArray())
        let encryptedMessage3 = try sessionCipherA.encrypt(paddedMessage: inputMessages[2].hexStringToByteArray())
        
        let encryptedMessage4 = try sessionCipherB.encrypt(paddedMessage: inputMessages[3].hexStringToByteArray())
        let encryptedMessage5 = try sessionCipherB.encrypt(paddedMessage: inputMessages[4].hexStringToByteArray())
        
        let decryptedMessage3 = try decryptInitMessage(sessionCipherB, encryptedMessage3)
        let decryptedMessage5 = try decryptInitMessage(sessionCipherA, encryptedMessage5)
        
        let encryptedMessage6 = try sessionCipherA.encrypt(paddedMessage: inputMessages[5].hexStringToByteArray())
        let encryptedMessage7 = try sessionCipherB.encrypt(paddedMessage: inputMessages[6].hexStringToByteArray())
        
        let decryptedMessage2 = try decryptInitMessage(sessionCipherB, encryptedMessage2)
        let decryptedMessage1 = try decryptInitMessage(sessionCipherB, encryptedMessage1)
        let decryptedMessage4 = try decryptInitMessage(sessionCipherA, encryptedMessage4)
        let decryptedMessage6 = try decryptMessage(sessionCipherB, encryptedMessage6)
        let decryptedMessage7 = try decryptMessage(sessionCipherA, encryptedMessage7)
        
        //then
        XCTAssertEqual(decryptedMessage1.toHexString(), inputMessages[0])
        XCTAssertEqual(decryptedMessage2.toHexString(), inputMessages[1])
        XCTAssertEqual(decryptedMessage3.toHexString(), inputMessages[2])
        XCTAssertEqual(decryptedMessage4.toHexString(), inputMessages[3])
        XCTAssertEqual(decryptedMessage5.toHexString(), inputMessages[4])
        XCTAssertEqual(decryptedMessage6.toHexString(), inputMessages[5])
        XCTAssertEqual(decryptedMessage7.toHexString(), inputMessages[6])
    }
    
    //TUN-4795
    func testShouldSucceedInAConversationWith8Cycles() throws {
        
        //given
        let message1 = "010203040506070809"
        let message2 = "111213141516171819"
        let message3 = "3308d20f1221055234"
        
        let sessionCipherA = deviceA.createCipherForDevice(deviceB.deviceAddress)
        let sessionCipherB = deviceB.createCipherForDevice(deviceA.deviceAddress)
        
        deviceA.initSessionFor(deviceB.deviceAddress,
                               deviceB.getPublicInitKeyBundle())     //deviceA starts the session so it needs to process the InitKeyBundle of deviceB
        
        //when
        let encryptedMessage1 = try sessionCipherA.encrypt(paddedMessage: message1.hexStringToByteArray())
        let encryptedMessage2 = try sessionCipherA.encrypt(paddedMessage: message2.hexStringToByteArray())
        
        let decryptedMessage2 = try decryptInitMessage(sessionCipherB, encryptedMessage2)
        let decryptedMessage1 = try decryptInitMessage(sessionCipherB, encryptedMessage1)
        
        let encryptedMessage3 = try sessionCipherB.encrypt(paddedMessage: message3.hexStringToByteArray())
        let decryptedMessage3 = try decryptMessage(sessionCipherA, encryptedMessage3)
        
        XCTAssertEqual(message1, decryptedMessage1.toHexString())
        XCTAssertEqual(message2, decryptedMessage2.toHexString())
        XCTAssertEqual(message3, decryptedMessage3.toHexString())
        
        for i in 0..<100 {
            for j in 0..<2 {
                let message = "\(i) \(j)"
                if i % 2 == 0 {
                    let encryptedMessage = try sessionCipherA.encrypt(paddedMessage:  message.data(using: .utf8)!)
                    let decryptedMessage = try decryptMessage(sessionCipherB, encryptedMessage)
                    XCTAssertEqual(message, String(data: decryptedMessage, encoding: .utf8))
                } else {
                    let encryptedMessage = try sessionCipherB.encrypt(paddedMessage: message.data(using: .utf8)!)
                    let decryptedMessage = try decryptMessage(sessionCipherA, encryptedMessage)
                    XCTAssertEqual(message, String(data: decryptedMessage, encoding: .utf8))
                }
            }
        }
    }
    
    //TUN-4763
    func testShouldFailWhenInitMessageIsTemperedWith(){
        
        //given
        let message1 = "010203040506070809"
        let message2 = "111213141516171819"
        let fakeBaseKey = "0522693a21bd92b7e1ea0bf8902aef4e640b21a53853ff8043500355c39a3b778b"
        let fakeMacKey = "505b7e25a7c43a9f68db005c69db98d180d8d03c6ef50852d4afa7672607d31e"
        //<26d86909 4a2d7c63 c7af4726 5e53730c 5d053df1 6f286bc5 70895656 5a5e77f7>
        
        let sessionCipherA = deviceA.createCipherForDevice(deviceB.deviceAddress)
        let sessionCipherB = deviceB.createCipherForDevice(deviceA.deviceAddress)
        
        deviceA.initSessionFor(deviceB.deviceAddress,
                               deviceB.getPublicInitKeyBundle())     //deviceA starts the session so it needs to process the InitKeyBundle of deviceB
        
        let encryptedMessage1 = try! sessionCipherA.encrypt(paddedMessage: message1.hexStringToByteArray()) as! InitKeySecretMessage
        let _ = try! decryptInitMessage(sessionCipherB, encryptedMessage1)
        
        
        let encryptedMessage2 = try! sessionCipherA.encrypt(paddedMessage: message2.hexStringToByteArray()) as! InitKeySecretMessage
        //when
        let hackedMessage = InitKeySecretMessage(secretMessage: encryptedMessage2.message,
                                                   registrationId: encryptedMessage2.registrationId,
                                                   initKeyId: encryptedMessage2.initKeyID,
                                                   signedInitKeyId: encryptedMessage2.signedInitKeyId,
                                                   baseKey: fakeBaseKey.hexStringToByteArray(),
                                                   senderIdentityKey: encryptedMessage2.identityKey,
                                                   receiverIdentityKey: deviceB.identityKeyPair.publicKey.prependKeyType(),
                                                   macKey: fakeMacKey.hexStringToByteArray())
        
        //then
        do {
            let _ = try decryptInitMessage(sessionCipherB, hackedMessage)
            XCTAssertTrue(false, "Decryption should fail")
        } catch {
            
        }
    }
    
    func decryptInitMessage(_ cipher: SessionCipher, _ data: CipherMessage)throws -> Data {
        let message = try InitKeySecretMessage(data: data.serialized)
        return try cipher.decrypt(cipherMessage: message)
    }
    
    func decryptInitMessageData(_ cipher: SessionCipher, _ data: Data)throws -> Data {
        let message = try InitKeySecretMessage(data: data)
        return try cipher.decrypt(cipherMessage: message)
        
    }
    
    func decryptMessage(_ cipher: SessionCipher, _ data: CipherMessage)throws -> Data {
        let message = try SecretMessage(data: data.serialized)
        return try cipher.decrypt(cipherMessage: message)
    }
}
