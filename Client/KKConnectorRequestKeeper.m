//
//  KKConnectorRequestKeeper.m
//  KKConnectorClient
//
//  Created by likai123 on 2020/11/13.
//

#import "KKConnectorRequestKeeper.h"
#import "KKConnectorRequestKeeper.h"

@implementation KKConnectorRequestKeeper

- (void)resetTimeoutCount {
    [self endTimeoutCount];
    if (self.timeoutInterval > 0) {
        [self performSelector:@selector(_handleTimeout) withObject:nil afterDelay:self.timeoutInterval];
    } else {
        NSAssert(NO, @"timeoutInterval 为 0");
    }
}

- (void)endTimeoutCount {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)_handleTimeout {
    if (self.timeoutBlock) {
        self.timeoutBlock(self);
    }
}

@end
