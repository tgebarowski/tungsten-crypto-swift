//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (crypto_AES)

- (nullable NSData *)crypto_AES256EncryptedDataWithKey:(NSData *)key;
- (nullable NSData *)crypto_AES256EncryptedDataWithKey:(NSData *)key iv:(nullable NSData *)iv;

- (nullable NSData *)crypto_AES256DecryptedDataWithKey:(NSData *)key;
- (nullable NSData *)crypto_AES256DecryptedDataWithKey:(NSData *)key iv:(nullable NSData *)iv;


+ (NSData *)crypto_AES256GenerateInitializationVector;
+ (NSString *)crypto_AES256GenerateBase64EncodedInitializationVector;

+ (NSData *)crypto_AES256GenerateKey;
+ (NSString *)crypto_AES256GenerateBase64EncodedKey;

@end

NS_ASSUME_NONNULL_END
