//
//  PGPBigNum.h
//  ObjectivePGP
//
//  Created by Marcin Krzyzanowski on 26/06/2017.
//  Copyright © 2017 Marcin Krzyżanowski. All rights reserved.
//

#import "PGPBigNum.h"
#import "PGPMacros.h"
#import <openssl/bn.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PGPBigNum ()

@property (nonatomic, readonly) BIGNUM *bignumRef;

PGP_EMPTY_INIT_UNAVAILABLE;

- (instancetype)initWithBIGNUM:(BIGNUM *)bignumRef;

@end

NS_ASSUME_NONNULL_END
