//
//  M3U8SegmentInfo.m
//  M3U8Kit
//
//  Created by Oneday on 13-1-11.
//  Copyright (c) 2013年 0day. All rights reserved.
//

#import "M3U8SegmentInfo.h"
#import "M3U8TagsAndAttributes.h"
#import "M3U8Kit-Prefix.pch"

@interface M3U8SegmentInfo()
@property (nonatomic, strong) NSDictionary *dictionary;
@end

@implementation M3U8SegmentInfo

- (instancetype)initWithDictionary:(NSDictionary *)dictionary andStartTime:(NSTimeInterval)startTime withNumber:(NSUInteger)number mediaPlayList:(NSString*)plUrl{
    if (self = [super init]) {
        _dictionary = dictionary;
        _startTime=startTime;
        _number = number;
        _mediaPlayListURL=plUrl;
    }
    return self;
}

- (NSString *)baseURL {
    return self.dictionary[M3U8_BASE_URL];
}

- (NSString *)mediaURL {
    NSURL *baseURL = [NSURL URLWithString:self.baseURL];
    return [[NSURL URLWithString:self.URI relativeToURL:baseURL] absoluteString];
}

- (NSTimeInterval)duration {
    return [self.dictionary[M3U8_EXTINF_DURATION] doubleValue];
}

- (NSString *)URI {
    return self.dictionary[M3U8_EXTINF_URI];
}



-(NSString *)description {
    return [NSString stringWithFormat: @"M3U8SegmentInfo:start-time=%lf, duration:%lf mediaUrl:%@",
            [self startTime],[self duration] , [self mediaURL]];
}
 @end
