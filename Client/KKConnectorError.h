//
//  KKConnectorError.h
//  KKConnectorClient
//
//  Created by 李凯 on 2020/11/14.
//

#import <Foundation/Foundation.h>

@interface KKConnectorError : NSObject

+ (NSError *)inner;
+ (NSError *)noConnect;
+ (NSError *)repeatingCommand;
+ (NSError *)requestTimeout;
+ (NSError *)protocolVersionNotMatched;

@end
