//
//  MediaStream.m
//  XMediaPlayer
//
//  Created by tyazid on 22/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaStream.h"

@implementation MediaStream
-(id)initWithData:(NSData *)dataIn andType:(MediaStreamType)typeIn
{
  //  VToolBox* vv = [VToolBox new];
    NSParameterAssert(dataIn);
    NSParameterAssert(([[NSArray arrayWithObjects:
                         [NSNumber numberWithInteger:MediaStreamAACType],
                         [NSNumber numberWithInteger:MediaStreamAC3Type],
                         [NSNumber numberWithInteger:MediaStreamH264Type],nil]
                         containsObject:[NSNumber numberWithInteger:typeIn]]));
    if(self = [super init]) {
        NSLog(@" type %ld",(long)typeIn);
                switch (typeIn) {
                case MediaStreamAACType :
                case MediaStreamAC3Type :
                    _category= MediaAudio;
                    break;
                case MediaStreamH264Type :
                    _category= MediaVideo;
                    break;
             }
            _data=dataIn;
            _type=typeIn;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"MediaStream: data.size=%lu stream.type =%ld stream.category=%ld",
            (unsigned long)[[self data] length], (long)[self type] , (long)[self category] ];
}
@end
