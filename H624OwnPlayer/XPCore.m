//
//  XPCore.m
//  XMediaPlayer
//
//  Created by tyazid on 25/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XPCore.h"
#import "H264Reader.h"
@interface MediaReaderFactory ()

@end
@implementation MediaReaderFactory
+(id<MediaReader>)getMediaReader:(MediaReaderType)type
{
     
    NSParameterAssert(([[NSArray arrayWithObjects:
                         [NSNumber numberWithInteger:H264_TYPE],
                         [NSNumber numberWithInteger:H263_TYPE],
                         [NSNumber numberWithInteger:MPEG1VIDEO_TYPE],
                         [NSNumber numberWithInteger:MPEG4_TYPE], nil]
                        containsObject:[NSNumber numberWithInteger:type]]));

    switch (type) {
        case H264_TYPE:
            return [H264Reader new];
            break;
            
        default:
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[NSString stringWithFormat: @"-no MediaREader is available for type=%ld",(long)type]
                                         userInfo:nil];
            break;
    }
    
    

}
@end


