//
//  KKConnectorRequest.h
//  KKConnectorServer
//
//  Created by 李凯 on 2020/11/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKConnectorRequest : NSObject <NSSecureCoding>

@property(nonatomic, copy) NSString *header;

@property(nonatomic, strong, nullable) id body;

@end

NS_ASSUME_NONNULL_END
