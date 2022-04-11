//
//  KKConnectorError.m
//  KKConnectorClient
//
//  Created by 李凯 on 2020/11/14.
//

#import "KKConnectorError.h"
#import "KKConnectorDefines.h"

@implementation KKConnectorError

+ (NSError *)inner {
    return [NSError errorWithDomain:KKConnectorErrorDomain code:KKConnectorError_Inner userInfo:nil];
}

+ (NSError *)noConnect {
    return [NSError errorWithDomain:KKConnectorErrorDomain code:KKConnectorError_NoConnect userInfo:nil];
}

+ (NSError *)repeatingCommand {
    return [NSError errorWithDomain:KKConnectorErrorDomain code:KKConnectorError_RepeatingCommand userInfo:nil];
}

+ (NSError *)requestTimeout {
    return [NSError errorWithDomain:KKConnectorErrorDomain code:KKConnectorError_RequestTimeout userInfo:nil];
}

+ (NSError *)protocolVersionNotMatched {
    return [NSError errorWithDomain:KKConnectorErrorDomain code:KKConnectorError_ProtocolVersionNotMatched userInfo:nil];
}

@end
