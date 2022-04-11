//
//  PTChannel+KKConnectorClient.h
//  KKConnectorClient
//
//  Created by likai123 on 2020/11/13.
//

#import "PTChannel.h"

@class KKConnectorRequestKeeper;

@interface PTChannel (KKConnector)

/// 已经发送但尚未收到全部回复的请求
@property(nonatomic, strong) NSMutableArray<KKConnectorRequestKeeper *> *keepers;

- (KKConnectorRequestKeeper *)queryKeeperWithTag:(uint32_t)tag;

- (KKConnectorRequestKeeper *)queryKeeperWithHeader:(NSString *)header;

@end
