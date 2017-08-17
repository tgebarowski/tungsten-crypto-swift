//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import "NSData+crypto_AES.h"
#import <CommonCrypto/CommonCryptor.h>

@implementation NSData (crypto_AES)

- (nullable NSData *)crypto_AES256EncryptedDataWithKey:(NSData *)key
{
    return [self crypto_AES256EncryptedDataWithKey:key iv:nil];
}

- (nullable NSData *)crypto_AES256EncryptedDataWithKey:(NSData *)key iv:(nullable NSData *)iv
{
    return [self crypto_AES256Operation:kCCEncrypt key:key iv:iv];
}


- (nullable NSData *)crypto_AES256DecryptedDataWithKey:(NSData *)key
{
    return [self crypto_AES256DecryptedDataWithKey:key iv:nil];
}

- (nullable NSData *)crypto_AES256DecryptedDataWithKey:(NSData *)key iv:(nullable NSData *)iv
{
    return [self crypto_AES256Operation:kCCDecrypt key:key iv:iv];
}


+ (NSData *)crypto_AES256GenerateInitializationVector
{
    unsigned char buf[kCCBlockSizeAES128];
    SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, buf);
    return [NSData dataWithBytes:buf length:sizeof(buf)];
}

+ (NSString *)crypto_AES256GenerateBase64EncodedInitializationVector
{
    return [[NSData crypto_AES256GenerateInitializationVector] base64EncodedStringWithOptions:0];
}

+ (NSData *)crypto_AES256GenerateKey
{
    unsigned char buf[kCCKeySizeAES256];
    SecRandomCopyBytes(kSecRandomDefault, kCCKeySizeAES256, buf);
    return [NSData dataWithBytes:buf length:sizeof(buf)];
}

+ (NSString *)crypto_AES256GenerateBase64EncodedKey
{
    return [[NSData crypto_AES256GenerateKey] base64EncodedStringWithOptions:0];
}

#pragma - Private

- (NSData *)crypto_AES256Operation:(CCOperation)operation key:(NSData *)key iv:(NSData *)iv
{
    int keyLenght = kCCKeySizeAES256;
    int blockSize = kCCBlockSizeAES128;
    
    char keyPtr[keyLenght];
    bzero(keyPtr, keyLenght);
    [key getBytes:keyPtr length:keyLenght];
    
    char ivPtr[blockSize];
    bzero(ivPtr, blockSize);
    if (iv) {
        [iv getBytes:ivPtr length:blockSize];
    }
    
    NSUInteger dataLength = [self length];
    size_t bufferSize = dataLength + blockSize;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(operation,
                                          kCCAlgorithmAES,
                                          kCCOptionPKCS7Padding,
                                          keyPtr,
                                          keyLenght,
                                          ivPtr,
                                          [self bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}

@end
