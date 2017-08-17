//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import "AESCBCSymmetricCipher.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCryptor.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>

@implementation AESCBCSymmetricCipher

- (NSData *)generateKey {
    uint8_t buf[kCCKeySizeAES256];
    SecRandomCopyBytes(kSecRandomDefault, kCCKeySizeAES256, buf);
    return [NSData dataWithBytes:buf length:sizeof(buf)];
}

-(NSData *)generateIV {
    uint8_t buf[kCCBlockSizeAES128];
    SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, buf);
    return [NSData dataWithBytes:buf length:sizeof(buf)];
}

-(NSData *)encryptWithData:(NSData *)data key:(NSData *)key iv:(NSData *)iv error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    NSAssert(data, @"Missing data to encrypt");
    NSAssert([key length] == kCCKeySizeAES256, @"AES key should be 256 bits");
    NSAssert((iv == nil) || ([iv  length] == kCCBlockSizeAES128), @"AES-CBC IV should be 128 bits");
    
    size_t bufferSize           = [data length] + kCCBlockSizeAES128;
    void* buffer                = malloc(bufferSize);
    
    size_t bytesEncrypted    = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          [key bytes], [key length],
                                          [iv bytes],
                                          [data bytes], [data length],
                                          buffer, bufferSize,
                                          &bytesEncrypted);
    
    if (cryptStatus == kCCSuccess){
        NSData *data = [NSData dataWithBytes:buffer length:bytesEncrypted];
        free(buffer);
        
        return data;
    } else{
        free(buffer);
        *error = [NSError errorWithDomain:CryptoErrors.domain code:CryptoErrors.cipherException userInfo:@{NSLocalizedDescriptionKey: @"We encountered an issue while encrypting."}];
        return nil;
    }
}

-(NSData *)decryptWithData:(NSData *)data key:(NSData *)key iv:(NSData *)iv error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    size_t bufferSize           = [data length] + kCCBlockSizeAES128;
    void* buffer                = malloc(bufferSize);
    
    size_t bytesDecrypted    = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          [key bytes], [key length],
                                          [iv bytes],
                                          [data bytes], [data length],
                                          buffer, bufferSize,
                                          &bytesDecrypted);
    
    if (cryptStatus == kCCSuccess) {
        NSData *plaintext = [NSData dataWithBytes:buffer length:bytesDecrypted];
        free(buffer);
        
        return plaintext;
    } else{
        free(buffer);
        *error = [NSError errorWithDomain:CryptoErrors.domain code:CryptoErrors.cipherException userInfo:@{NSLocalizedDescriptionKey: @"We encountered an issue while decrypting."}];
        return  nil;
    }
}

@end
