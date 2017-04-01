//
//  NSString+m3u8.m
//  M3U8Kit
//
//  Created by Oneday on 13-1-11.
//  Copyright (c) 2013年 0day. All rights reserved.
//

#import "NSString+m3u8.h"
 

#import "M3U8TagsAndAttributes.h"

@implementation NSString (m3u8)

/**
 The Extended M3U file format defines two tags: EXTM3U and EXTINF.  An
 Extended M3U file is distinguished from a basic M3U file by its first
 line, which MUST be #EXTM3U.
 
 reference url:http://tools.ietf.org/html/draft-pantos-http-live-streaming-00
 */
- (BOOL)isExtendedM3Ufile {
    return [self hasPrefix:M3U8_EXTM3U];
}

- (BOOL)isMasterPlaylist {
    BOOL isM3U = [self isExtendedM3Ufile];
    if (isM3U) {
        NSRange r1 = [self rangeOfString:M3U8_EXT_X_STREAM_INF];
        NSRange r2 = [self rangeOfString:M3U8_EXT_X_I_FRAME_STREAM_INF];
        if (r1.location != NSNotFound || r2.location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isMediaPlaylist {
    BOOL isM3U = [self isExtendedM3Ufile];
    if (isM3U) {
        NSRange r = [self rangeOfString:M3U8_EXTINF];
        if (r.location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}


@end
