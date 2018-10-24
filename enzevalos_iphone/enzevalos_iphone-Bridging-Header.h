//
//  enzevalos_iphone-Bridging-Header.h
//  enzevalos_iphone
//
//  Created by jakobsbode on 27.09.16.
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

#import <MailCore/MailCore.h>
#import <Onboard/OnboardingViewController.h>
#import <Onboard/OnboardingContentViewController.h>
#import <ObjectivePGP/ObjectivePGP.h>
#import <CommonCrypto/CommonHMAC.h>
#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>
#import <GTMSessionFetcher/GTMSessionFetcher.h>
#import "OAuth/EmailHelper.h"

// Making this funcion accessible 
@interface OIDAuthState (Auth)
- (BOOL)isTokenFresh;
@end
