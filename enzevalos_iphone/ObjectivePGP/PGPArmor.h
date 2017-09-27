//
//  PGPArmor.h
//  ObjectivePGP
//
//  Created by Marcin Krzyzanowski on 18/05/14.
//  Copyright (c) 2014 Marcin Krzyżanowski. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PGPArmorType) {
    PGPArmorTypeMessage = 1,
    PGPArmorTypePublicKey = 2,
    PGPArmorTypeSecretKey = 3,
    PGPArmorTypeMultipartMessagePartXOfY = 4,
    PGPArmorTypeMultipartMessagePartX = 5,
    PGPArmorTypeSignature = 6,
    PGPArmorCleartextSignedMessage = 7, // TODO: -----BEGIN PGP SIGNED MESSAGE-----
};

NS_ASSUME_NONNULL_BEGIN

/// ASCII Armor message.
@interface PGPArmor : NSObject

+ (NSData *)armoredData:(NSData *)dataToArmor as:(PGPArmorType)armorType part:(NSUInteger)part of:(NSUInteger)ofParts;
+ (NSData *)armoredData:(NSData *)dataToArmor as:(PGPArmorType)armorType;

+ (nullable NSData *)readArmoredData:(NSString *)armoredString error:(NSError *__autoreleasing _Nullable *)error;

+ (BOOL)isArmoredData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
