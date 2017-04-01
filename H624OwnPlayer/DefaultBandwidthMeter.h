//
//  AbrBandwidthMeter.h
//  XMediaPlayer
//
//  Created by tyazid on 29/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <Foundation/Foundation.h>

 
#import <Foundation/Foundation.h>
#import "XPUtil.h"
@interface DefaultBandwidthMeter : NSObject<BandwidthMeter, TransferListener>
@property (atomic) id<BandwidthMeterListener> listener;
+ (NSInteger)NO_ESTIMATE;
-(instancetype)initWithMax: (NSUInteger)maxWeight andListener : (id<BandwidthMeterListener>) listener;
-(NSUInteger)getStreamCount;
@end
