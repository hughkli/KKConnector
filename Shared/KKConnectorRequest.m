//
//  KKConnectorRequest.m
//  KKConnectorServer
//
//  Created by 李凯 on 2020/11/10.
//

#import "KKConnectorRequest.h"

@implementation KKConnectorRequest

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.header = [coder decodeObjectForKey:@"header"];
        self.body = [coder decodeObjectForKey:@"body"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.header forKey:@"header"];
    [coder encodeObject:self.body forKey:@"body"];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end
