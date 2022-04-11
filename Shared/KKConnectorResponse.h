//
//  KKConnectorResponse.h
//  KKConnectorServer
//
//  Created by 李凯 on 2020/11/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKConnectorResponse : NSObject <NSSecureCoding>

@property(nonatomic, assign) int totalSize;
@property(nonatomic, assign) int thisSize;

@property(nonatomic, assign) BOOL hasError;
@property(nonatomic, assign) int errorCode;
@property(nonatomic, copy, nullable) NSString *errorDescription;

@property(nonatomic, strong, nullable) NSObject *body;

@end

NS_ASSUME_NONNULL_END
