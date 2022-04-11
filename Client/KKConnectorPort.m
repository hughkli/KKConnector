//
//  KKConnectorPort.m
//  KKConnectorClient
//
//  Created by likai123 on 2020/11/13.
//

#import "KKConnectorPort.h"

@implementation KKConnectorSimulatorPort

- (NSString *)description {
    return [NSString stringWithFormat:@"number:%@", @(self.portNumber)];
}

@end

@implementation KKConnectorUSBPort

- (NSString *)description {
    return [NSString stringWithFormat:@"number:%@, deviceID:%@, connectedChannel:%@", @(self.portNumber), self.deviceID, self.connectedChannel];
}

@end
