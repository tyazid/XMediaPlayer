//
//  M3U8MediaPlaylist.h
//  M3U8Kit
//
//  Created by Sun Jin on 3/26/14.
//  Copyright (c) 2014 Jin Sun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "M3U8SegmentInfoList.h"
#import "M3U8ExtXStreamInf.h"
#import "NSString+m3u8.h"
typedef enum {
    M3U8MediaPlaylistTypeMedia = 0,     // The main media stream playlist.
    M3U8MediaPlaylistTypeSubtitle = 1,  // EXT-X-SUBTITLES TYPE=SUBTITLES
    M3U8MediaPlaylistTypeAudio = 2,     // EXT-X-MEDIA TYPE=AUDIO
    M3U8MediaPlaylistTypeVideo = 3      // EXT-X-MEDIA TYPE=VIDEO
} M3U8MediaPlaylistType;

@interface M3U8MediaPlaylist : NSObject

@property (nonatomic, strong) NSString *name;

@property (readonly, nonatomic, strong) NSString *version;

@property (readonly, nonatomic, copy) NSString *originalText;
@property (readonly, nonatomic, strong) NSString *baseURL;

@property (readonly, nonatomic, strong) M3U8SegmentInfoList *segmentList;

@property (nonatomic) M3U8MediaPlaylistType type;   // -1 by default
@property (readonly, nonatomic, strong) M3U8ExtXStreamInf* format;
- (instancetype)initWithContent:(NSString *)string type:(M3U8MediaPlaylistType)type baseURL:(NSString *)baseURL;
- (instancetype)initWithContentOfURL:(NSURL *)url type:(M3U8MediaPlaylistType)type error:(NSError **)error;
- (instancetype)initWithContentOfURL:(NSURL *)url type:(M3U8MediaPlaylistType)type andFormat:(M3U8ExtXStreamInf*) format error:(NSError **)error;

- (NSArray *)allSegmentURLs;

@end
