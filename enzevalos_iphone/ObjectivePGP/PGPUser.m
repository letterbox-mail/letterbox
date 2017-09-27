//
//  PGPUser.m
//  ObjectivePGP
//
//  Created by Marcin Krzyzanowski on 15/05/14.
//  Copyright (c) 2014 Marcin Krzyżanowski. All rights reserved.
//

#import "PGPUser.h"
#import "PGPPartialKey.h"
#import "PGPPublicKeyPacket.h"
#import "PGPSignaturePacket.h"
#import "PGPUserAttributePacket.h"
#import "PGPUserIDPacket.h"
#import "PGPMacros+Private.h"
#import "PGPFoundation.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PGPUser

- (instancetype)initWithUserIDPacket:(PGPUserIDPacket *)userPacket {
    PGPAssertClass(userPacket, PGPUserIDPacket);

    if (self = [super init]) {
        _userIDPacket = userPacket;
    }
    return self;
}

- (NSString *)userID {
    return self.userIDPacket.userID;
}

- (NSArray *)otherSignatures {
    if (!_otherSignatures) {
        _otherSignatures = [NSArray array];
    }
    return _otherSignatures;
}

- (NSArray *)revocationSignatures {
    if (!_revocationSignatures) {
        _revocationSignatures = [NSArray array];
    }
    return _revocationSignatures;
}

- (NSArray *)selfCertifications {
    if (!_selfCertifications) {
        _selfCertifications = [NSArray array];
    }
    return _selfCertifications;
}

- (PGPUserIDPacket *)userIDPacket {
    if (!_userIDPacket) {
        NSAssert(false, @"wat?");
        // build userIDPacket
    }
    return _userIDPacket;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@", [super description], self.userID];
}

- (NSArray<PGPPacket *> *)allPackets {
    let arr = [NSMutableArray<PGPPacket *> array];

    if (self.userIDPacket) {
        [arr addObject:self.userIDPacket]; // TODO: || [arr addObject:self.userAttribute]
    }

    for (id packet in self.revocationSignatures) {
        [arr addObject:packet];
    }

    for (id packet in self.selfCertifications) {
        [arr addObject:packet];
    }

    for (id packet in self.otherSignatures) {
        [arr addObject:packet];
    }

    return arr;
}

// TODO:
// User.prototype.getValidSelfCertificate = function(primaryKey) {
//    if (!this.selfCertifications) {
//        return null;
//    }
//    var validCert = [];
//    for (var i = 0; i < this.selfCertifications.length; i++) {
//        if (this.isRevoked(this.selfCertifications[i], primaryKey)) {
//            continue;
//        }
//        if (!this.selfCertifications[i].isExpired() &&
//            (this.selfCertifications[i].verified ||
//             this.selfCertifications[i].verify(primaryKey, {userid: this.userId || this.userAttribute, key: primaryKey}))) {
//                validCert.push(this.selfCertifications[i]);
//            }
//    }
//    // most recent first
//    validCert = validCert.sort(function(a, b) {
//        a = a.created;
//        b = b.created;
//        return a>b ? -1 : a<b ? 1 : 0;
//    });
//    return validCert[0];
//};

// Returns the most significant (latest valid) self signature of the user
- (nullable PGPSignaturePacket *)validSelfCertificate:(PGPPartialKey *)key {
    if (self.selfCertifications.count == 0) {
        return nil;
    }

    NSMutableArray *certs = [NSMutableArray array];
    for (PGPSignaturePacket *signature in self.selfCertifications) {
        // TODO: check for revocation

        if (signature.isExpired) {
            continue;
        }
        [certs addObject:signature];
        // This only worked as verify wasn't implemented correctly
        // TODO: find a better solution
        //
        //        // (this is the craziest thing I ever seen today)
        //        NSError *error;
        //        [signature verifyData:nil withKey:key signingKeyPacket:(PGPPublicKeyPacket *)key.primaryKeyPacket userID:self.userID error:&error];
        //        //BOOL status = [signature verifyData:nil withKey:key signingKeyPacket:(PGPPublicKeyPacket *)key.primaryKeyPacket userID:self.userID error:&error];
        //        //if (!status) {
        //        //    NSLog(@"ObjectivePGP: %@",error);
        //        //}
        //        //NSAssert(status == YES,@"not verified");
        //
        //        if (status == YES) {
        //            [certs addObject:signature];
        //        }
    }

    [certs sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        let sig1 = PGPCast(obj1, PGPSignaturePacket);
        let sig2 = PGPCast(obj2, PGPSignaturePacket);
        if (sig1.creationDate && sig2.creationDate) {
            return [PGPNN(sig1.creationDate) compare:PGPNN(sig2.creationDate)];
        }
        return NSOrderedSame;
    }];

    return [certs firstObject];
}

#pragma mark - isEqual

- (BOOL)isEqual:(id)other {
    if (self == other) { return YES; }
    if ([other isKindOfClass:self.class]) {
        return [self isEqualToUser:other];
    }
    return NO;
}

- (BOOL)isEqualToUser:(PGPUser *)other {
    return PGPEqualObjects(self.userID,other.userID) &&
           PGPEqualObjects(self.userAttribute,other.userAttribute) &&
           PGPEqualObjects(self.selfCertifications,other.selfCertifications) &&
           PGPEqualObjects(self.otherSignatures,other.otherSignatures) &&
           PGPEqualObjects(self.revocationSignatures,other.revocationSignatures) &&
           PGPEqualObjects(self.userIDPacket,other.userIDPacket);
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;

    result = prime * result + self.userID.hash;
    result = prime * result + self.userAttribute.hash;
    result = prime * result + self.selfCertifications.hash;
    result = prime * result + self.otherSignatures.hash;
    result = prime * result + self.revocationSignatures.hash;
    result = prime * result + self.userIDPacket.hash;

    return result;
}

@end

NS_ASSUME_NONNULL_END
