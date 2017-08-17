//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import "SodiumKeyAgreement.h"
#import <TungstenCrypto/TungstenCrypto-Swift.h>
#import "sodium.h"

@implementation SodiumKeyAgreement

-(KeyPair *)generateKeyPair {
    unsigned char ed25519_pk[crypto_sign_ed25519_PUBLICKEYBYTES];
    unsigned char ed25519_skpk[crypto_sign_ed25519_SECRETKEYBYTES];
    
    crypto_sign_ed25519_keypair(ed25519_pk, ed25519_skpk);
    
    return [[KeyPair alloc]initWithPrivateKey:[NSData dataWithBytes:ed25519_skpk length:crypto_sign_ed25519_SECRETKEYBYTES]
                                    publicKey:[NSData dataWithBytes:ed25519_pk length:crypto_sign_ed25519_PUBLICKEYBYTES]];
}
    
-(NSData *)sharedSecredFrom:(NSData *)publicKey keyPair:(KeyPair *)keyPair {
    unsigned char client_secretkey[crypto_box_SECRETKEYBYTES];
    unsigned char peer_publickey[crypto_box_PUBLICKEYBYTES];
    unsigned char sharedkey[crypto_scalarmult_BYTES];
    
    //Peer public key edwards -> montgomery
    if(crypto_sign_ed25519_pk_to_curve25519(peer_publickey, publicKey.bytes) != 0) {
        return nil;
    }
    
    //Local keypair edwards -> montgomery
    crypto_sign_ed25519_sk_to_curve25519(client_secretkey, keyPair.privateKey.bytes);
    
    if(crypto_scalarmult(sharedkey, client_secretkey, peer_publickey) != 0) {
        return  nil;
    }
    
    return [NSData dataWithBytes:sharedkey length:crypto_generichash_BYTES];
}
    
-(NSData *)signWithData:(NSData *)data keyPair:(KeyPair *)keyPair {
    unsigned char sig[crypto_sign_BYTES];
    crypto_sign_detached(sig, NULL, data.bytes, data.length, keyPair.privateKey.bytes);
    
    return [NSData dataWithBytes:sig length:crypto_sign_BYTES];
}
    
-(BOOL)verifyWithSignature:(NSData *)signature publicKey:(NSData *)publicKey data:(NSData *)data {
    return crypto_sign_verify_detached(signature.bytes, data.bytes, data.length, publicKey.bytes) == 0;
}
    
@end
