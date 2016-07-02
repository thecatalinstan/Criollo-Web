/**
 http://mythosil.hatenablog.com/entry/20111017/1318873155
 http://blog.dealforest.net/2012/03/ios-android-per-aes-crypt-connection/
 */

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (AES)

- (NSData *)AES128EncryptedDataWithKey:(NSString *)key;
- (NSData *)AES128DecryptedDataWithKey:(NSString *)key;
- (NSData *)AES128EncryptedDataWithKey:(NSString *)key iv:(NSString * _Nullable)iv;
- (NSData *)AES128DecryptedDataWithKey:(NSString *)key iv:(NSString * _Nullable)iv;

@end

NS_ASSUME_NONNULL_END