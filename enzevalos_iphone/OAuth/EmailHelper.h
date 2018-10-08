//
//  EmailHelper.h
//  enzevalos_iphone
//
//  Created by Joscha on 29.01.18.
//  Copyright © 2018 fu-berlin.
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>

@interface EmailHelper : NSObject

+ (EmailHelper *)singleton;

@property(nonatomic, strong, nullable) id<OIDAuthorizationFlowSession> currentAuthorizationFlow;
@property(nonatomic, nullable) GTMAppAuthFetcherAuthorization *authorization;

- (void)doEmailLoginIfRequiredOnVC:(UIViewController*)vc completionBlock:(dispatch_block_t)completionBlock;
- (void)checkIfAuthorizationIsValid:(void (^)(BOOL authorized))completionBlock;

@end
