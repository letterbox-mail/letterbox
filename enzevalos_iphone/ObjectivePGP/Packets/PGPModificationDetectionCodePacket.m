//
//  Copyright (c) Marcin Krzyżanowski. All rights reserved.
//
//  THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY
//  INTERNATIONAL COPYRIGHT LAW. USAGE IS BOUND TO THE LICENSE AGREEMENT.
//  This notice may not be removed from this file.
//

//  MDC

#import "PGPModificationDetectionCodePacket.h"
#import "NSData+PGPUtils.h"
#import "PGPMacros+Private.h"
#import "PGPFoundation.h"

#import <CommonCrypto/CommonCrypto.h>

NS_ASSUME_NONNULL_BEGIN

@interface PGPModificationDetectionCodePacket ()

@property (nonatomic, readwrite) NSData *hashData;

@end

@implementation PGPModificationDetectionCodePacket

- (instancetype)initWithData:(NSData *)data {
    if (self = [self init]) {
        self->_hashData = [data pgp_SHA1];
    }
    return self;
}

- (PGPPacketTag)tag {
    return PGPModificationDetectionCodePacketTag; // 19
}

- (NSUInteger)parsePacketBody:(NSData *)packetBody error:(NSError * __autoreleasing _Nullable *)error {
    NSUInteger position = [super parsePacketBody:packetBody error:error];

    // 5.14.  Modification Detection Code Packet (Tag 19)
    NSAssert(packetBody.length == CC_SHA1_DIGEST_LENGTH, @"A Modification Detection Code packet MUST have a length of 20 octets");

    self->_hashData = [packetBody subdataWithRange:(NSRange){position, CC_SHA1_DIGEST_LENGTH}];
    position = position + self.hashData.length;

    return position;
}

- (nullable NSData *)export:(NSError * __autoreleasing _Nullable *)error {
    return [PGPPacket buildPacketOfType:self.tag withBody:^NSData * {
        return [self.hashData subdataWithRange:(NSRange){0, CC_SHA1_DIGEST_LENGTH}]; // force limit to 20 octets
    }];
}

#pragma mark - isEqual

- (BOOL)isEqual:(id)other {
    if (self == other) { return YES; }
    if ([super isEqual:other] && [other isKindOfClass:self.class]) {
        return [self isEqualToDetectionCodePacket:other];
    }
    return NO;
}

- (BOOL)isEqualToDetectionCodePacket:(PGPModificationDetectionCodePacket *)packet {
    return PGPEqualObjects(self.hashData, packet.hashData);
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = [super hash];
    result = prime * result + self.hashData.hash;
    return result;
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(nullable NSZone *)zone {
    let _Nullable duplicate = PGPCast([super copyWithZone:zone], PGPModificationDetectionCodePacket);
    if (!duplicate) {
        return nil;
    }

    duplicate.hashData = self.hashData;
    return duplicate;
}

@end

NS_ASSUME_NONNULL_END
