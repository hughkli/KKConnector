//
//  KKConnectorResponse.m
//  KKConnectorServer
//
//  Created by 李凯 on 2020/11/10.
//

#import "KKConnectorResponse.h"

@implementation KKConnectorResponse

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.totalSize = [coder decodeIntForKey:@"totalSize"];
        self.thisSize = [coder decodeIntForKey:@"thisSize"];
        self.hasError = [coder decodeBoolForKey:@"hasError"];
        self.errorCode = [coder decodeIntForKey:@"errorCode"];
        self.errorDescription = [coder decodeObjectForKey:@"errorDescription"];
        self.body = [coder decodeObjectForKey:@"body"];
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:self.totalSize forKey:@"totalSize"];
    [coder encodeInt:self.thisSize forKey:@"thisSize"];
    [coder encodeBool:self.hasError forKey:@"hasError"];
    [coder encodeInt:self.errorCode forKey:@"errorCode"];
    [coder encodeObject:self.errorDescription forKey:@"errorDescription"];
    [coder encodeObject:self.body forKey:@"body"];
}

@end
