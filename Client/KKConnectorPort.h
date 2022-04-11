//
//  KKConnectorPort.h
//  KKConnectorClient
//
//  Created by likai123 on 2020/11/13.
//

#import <Foundation/Foundation.h>

@class PTChannel;

@interface KKConnectorSimulatorPort : NSObject

@property(nonatomic, assign) int portNumber;

@property(nonatomic, strong) PTChannel *connectedChannel;

@end

@interface KKConnectorUSBPort : NSObject

@property(nonatomic, assign) int portNumber;

@property(nonatomic, strong) NSNumber *deviceID;

@property(nonatomic, strong) PTChannel *connectedChannel;

@end
