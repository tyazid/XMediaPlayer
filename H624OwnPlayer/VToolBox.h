//
//  VToolBox.h
//  XMediaPlayer
//
//  Created by tyazid on 24/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#ifndef VToolBox_h
#define VToolBox_h
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

#import "XPCore.h"

@interface VToolBox : NSObject<MediaReader>
typedef NS_ENUM(NSInteger, CodecId) {
    CODEC_H263_ID,
    CODEC_H264_ID,
    CODEC_MPEG1VIDEO_ID,
    CODEC_MPEG2VIDEO_ID,
    CODEC_MPEG4
    
};
-(BOOL) initToolBox:(CodecId)codec withWidth:(NSUInteger)width withHeight:(NSUInteger)height;

@end

#endif /* VToolBox_h */
