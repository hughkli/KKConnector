//
//  PTChannel+KKConnectorClient.m
//  KKConnectorClient
//
//  Created by likai123 on 2020/11/13.
//

#import "PTChannel+KKConnector.h"
#import <Objc/runtime.h>
#import "KKConnectorRequestKeeper.h"

@implementation PTChannel (KKConnector)

static char kAssociatedObjectKey_KKConnector_PTChannelKeepers;
- (void)setKeepers:(NSMutableArray<KKConnectorRequestKeeper *> *)keepers {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_KKConnector_PTChannelKeepers, keepers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray<KKConnectorRequestKeeper *> *)keepers {
    id result = objc_getAssociatedObject(self, &kAssociatedObjectKey_KKConnector_PTChannelKeepers);
    return result;
}


- (KKConnectorRequestKeeper *)queryKeeperWithTag:(uint32_t)tag {
    for (KKConnectorRequestKeeper *keeper in self.keepers) {
        if (keeper.tag == tag) {
            return keeper;
        }
    }
    return nil;
}

- (KKConnectorRequestKeeper *)queryKeeperWithHeader:(NSString *)header {
    for (KKConnectorRequestKeeper *keeper in self.keepers) {
        if ([keeper.header isEqualToString:header]) {
            return keeper;
        }
    }
    return nil;
}

@end
