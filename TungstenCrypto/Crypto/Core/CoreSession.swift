//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

public class CoreSession: NSObject {
    
    public class func initialize(_ session: SessionState, sessionVersion: Int, aliceParameters parameters: AliceCryptoParameters) throws {
        let keyAgreement = CryptoToolkit.sharedInstance.configuration.keyAgreement
        
        let sendingCoreKey = keyAgreement.generateKeyPair()
        try initialize(session, sessionVersion: sessionVersion, aliceParameters: parameters, senderCoreKey: sendingCoreKey)
    }
    
    public class func initialize(_ session: SessionState, sessionVersion: Int, bobParameters parameters: BobCryptoParameters) throws {
        session.version = sessionVersion
        let rkck = try dheKeyAgreement(parameters: parameters)
        
        session.initalizedState = SessionStateInitializedData(remoteIdentityKey: parameters.theirIdentityKey,
                                                              localIdentityKey: parameters.ourIdentityKeyPair.publicKey,
                                                              rootKey: rkck.rootKey,
                                                              sendingChain: SendingChain(chainKey: rkck.chainKey, senderCoreKeyPair: parameters.ourCoreKey))
    }
    
    private class func initialize(_ session: SessionState, sessionVersion: Int, aliceParameters parameters: AliceCryptoParameters, senderCoreKey: KeyPair) throws {
        session.version = sessionVersion
        let rkck = try dheKeyAgreement(parameters: parameters)
        let sendingChain = try rkck.rootKey.createChain(theirEphemeral: parameters.theirCoreKey, ourEphemeral: senderCoreKey)
        
        session.initalizedState = SessionStateInitializedData(remoteIdentityKey: parameters.theirIdentityKey,
                                                              localIdentityKey: parameters.ourIdentityKeyPair.publicKey,
                                                              rootKey: sendingChain.rootKey,
                                                              sendingChain: SendingChain(chainKey: sendingChain.chainKey, senderCoreKeyPair: senderCoreKey))
        session.addReceiverChain(parameters.theirCoreKey, chainKey: rkck.chainKey)
        
    }
    
    private class func dheResult(masterKey: Data) throws -> RKCK {
        let keyDerivation = CryptoToolkit.sharedInstance.configuration.keyDerivation
        
        guard let info = "E6@?J4=2'`A{RwwC".data(using: .utf8) else {
            fatalError("Unable to generate data from string")
        }
        
        let secrets = try keyDerivation.deriveKey(seed: masterKey, info: info, salt: Data(bytes: [0,0,0,0]))
        
        return RKCK(rootKey: RootKey(data: secrets.cipherKey),
                    chainKey: ChainKey(key: secrets.macKey, index: 0))
    }
    
    private class func dheKeyAgreement(parameters: CryptoParameters) throws -> RKCK {
        let keyAgreement = CryptoToolkit.sharedInstance.configuration.keyAgreement
        
        var masterKey = Data()
        masterKey.append(discontinuityBytes())
        
        if let aliceParameters = parameters as? AliceCryptoParameters {
            masterKey.append(try keyAgreement.sharedSecred(from: aliceParameters.theirSignedInitKey, keyPair: aliceParameters.ourIdentityKeyPair))
            masterKey.append(try keyAgreement.sharedSecred(from: aliceParameters.theirIdentityKey, keyPair: aliceParameters.ourBaseKey))
            masterKey.append(try keyAgreement.sharedSecred(from: aliceParameters.theirSignedInitKey, keyPair: aliceParameters.ourBaseKey))
            if let theirOneTimeInitKey = aliceParameters.theirOneTimeInitKey {
                masterKey.append(try keyAgreement.sharedSecred(from: theirOneTimeInitKey, keyPair: aliceParameters.ourBaseKey))
            }
        } else if let bobParameters = parameters as? BobCryptoParameters {
            masterKey.append(try keyAgreement.sharedSecred(from: bobParameters.theirIdentityKey, keyPair: bobParameters.ourSignedInitKey))
            masterKey.append(try keyAgreement.sharedSecred(from: bobParameters.theirBaseKey, keyPair: bobParameters.ourIdentityKeyPair))
            masterKey.append(try keyAgreement.sharedSecred(from: bobParameters.theirBaseKey, keyPair: bobParameters.ourSignedInitKey))
            if let ourOneTimeInitKey = bobParameters.ourOneTimeInitKey {
                masterKey.append(try keyAgreement.sharedSecred(from: bobParameters.theirBaseKey, keyPair: ourOneTimeInitKey))
            }
        } else {
            fatalError("Parameters type not supported")
        }
        
        return try dheResult(masterKey: masterKey)
    }
    
    private class func discontinuityBytes() -> Data {
        var discontinuity = Data()
        let byte: UInt8 = 0xFF
        
        for _ in 0..<32 {
            discontinuity.append(byte)
        }
        
        return discontinuity
    }
}
