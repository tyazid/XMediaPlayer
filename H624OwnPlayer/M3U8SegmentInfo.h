//
//  M3U8SegmentInfo.h
//  M3U8Kit
//
//  Created by Oneday on 13-1-11.
//  Copyright (c) 2013年 0day. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class M3U8SegmentInfo
 @abstract This is the class indicates #EXTINF:<duration>,<title> + media in m3u8 file
 

@format  #EXTINF:<duration>,<title>

#define M3U8_EXTINF                         @"#EXTINF:"
 
#define M3U8_EXTINF_DURATION                @"DURATION"
#define M3U8_EXTINF_TITLE                   @"TITLE"
#define M3U8_EXTINF_URI                     @"URI"
 

 */

@interface M3U8SegmentInfo : NSObject

@property (readonly, nonatomic) NSTimeInterval duration;
@property (readonly, nonatomic) NSTimeInterval startTime;
@property (readonly, nonatomic) NSUInteger number;


@property (readonly, nonatomic) NSString *URI;
@property (readonly, nonatomic) NSString *mediaPlayListURL;


- (instancetype)initWithDictionary:(NSDictionary *)dictionary andStartTime:(NSTimeInterval)startTime withNumber:(NSUInteger)number mediaPlayList:(NSString*)plUrl;
- (NSString *)mediaURL;
@end
