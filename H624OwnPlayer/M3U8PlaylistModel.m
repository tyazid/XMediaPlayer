//
//  M3U8Parser.m
//  M3U8Kit
//
//  Created by Oneday on 13-1-11.
//  Copyright (c) 2013年 0day. All rights reserved.
//

 #import "M3U8PlaylistModel.h"

#import "NSString+m3u8.h"
#define INDEX_PLAYLIST_NAME @"index.m3u8"

#define PREFIX_MAIN_MEDIA_PLAYLIST @"main_media_"
#define PREFIX_AUDIO_PLAYLIST @"x_media_audio_"
#define PREFIX_SUBTITLES_PLAYLIST @"x_media_subtitles_"
//#define LOG

@interface M3U8PlaylistModel()

@property (nonatomic, strong) NSString *URL;


//@property (nonatomic, strong) M3U8ExtXStreamInf *currentXStreamInf;

//@property (nonatomic, strong) M3U8MediaPlaylist *mainMediaPl;
//@property (nonatomic, strong) M3U8MediaPlaylist *audioPl;
//@property (nonatomic, strong) M3U8MediaPlaylist *subtitlePl;

@end

@implementation M3U8PlaylistModel

- (id)initWithURL:(NSString *)URL error:(NSError **)error {
    
    NSString *str = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:URL] encoding:NSUTF8StringEncoding error:error];
    if (*error) {
        NSLog(@"ERR IN MDL");
        return nil;
    }
    
    return [self initWithString:str baseURL:URL error:error];
}

- (id)initWithString:(NSString *)string baseURL:(NSString *)URL error:(NSError **)error {
    
    if (NO == [string isExtendedM3Ufile]) {
        //  *error = [NSError errorWithDomain:@"M3U8PlaylistModel" code:-998 userInfo:@{NSLocalizedDescriptionKey:@"The content is not a m3u8 playlist"}];
        NSLog(@"!!!!!!!!!!!!!! NO == [string isExtendedM3Ufile]");
        return nil;
    }
    
    if (self = [super init]) {
        @try {
            
            
            
            if ([string isMasterPlaylist]) {
                self.URL = URL;
                self.masterPlaylist = [[M3U8MasterPlaylist alloc] initWithContent:string baseURL:URL];
                self.masterPlaylist.name = INDEX_PLAYLIST_NAME;
                M3U8ExtXStreamInfList* streamList = self.masterPlaylist.xStreamList;
                
                //   _nbVariant =self.masterPlaylist.xStreamList.count;
                NSMutableArray< M3U8MediaPlaylist *> * muttable = [NSMutableArray arrayWithCapacity:self.masterPlaylist.xStreamList.count];
                for (int v=0; v<streamList.count; v++) {
                    M3U8ExtXStreamInf *inf =[streamList xStreamInfAtIndex:v];
                    NSError *ero;
                    NSURL *m3u8URL = [NSURL URLWithString:inf.m3u8URL];
                    
                    muttable[v]= [[M3U8MediaPlaylist alloc] initWithContentOfURL:m3u8URL
                                                                            type:M3U8MediaPlaylistTypeMedia
                                                                       andFormat:[streamList xStreamInfAtIndex:v]
                                                                           error:&ero];
                    //m3u8URL
                    
                    muttable[v].name = [NSString stringWithFormat:@"%@%d.m3u8", PREFIX_MAIN_MEDIA_PLAYLIST,v];
                    if (ero) {
                        NSLog(@"Get main media playlist failed, error: %@", ero);
                        return Nil;
                    }
                    
                }
                _playLists=[NSArray arrayWithArray:muttable];
                
                muttable=Nil;
              //  _svqMap = [self buildSvqMap];
                
                
            } else if ([string isMediaPlaylist]) {
                _playLists = @[[[M3U8MediaPlaylist alloc] initWithContent:string type:M3U8MediaPlaylistTypeMedia baseURL:self.URL]];
                //_nbVariant = 1;
                // self.mainMediaPl.name = INDEX_PLAYLIST_NAME;
            }
            
        } @catch (NSException *exception) {
            NSLog(@"Error creating model:%@",exception);
            self=Nil;
        } @finally {
            
        }
        /////////
    }
    NSLog(@"!!!!!!!!!!!!!! MODEL CTOR OK %p",self);
    
    return self;
} 
- (NSUInteger)nbVariant{
    return [self playLists]? [[self playLists]count]: 0;
}
- (NSSet *)allAlternativeURLStrings {
    NSMutableSet *allAlternativeURLStrings = [NSMutableSet set];
    M3U8ExtXStreamInfList *xsilist = self.masterPlaylist.alternativeXStreamInfList;
    for (int index = 0; index < xsilist.count; index ++) {
        M3U8ExtXStreamInf *xsinf = [xsilist xStreamInfAtIndex:index];
        [allAlternativeURLStrings addObject:xsinf.m3u8URL];
    }
    
    return allAlternativeURLStrings;
}


- (NSString *)prefixOfSegmentNameInPlaylist:(M3U8MediaPlaylist *)playlist {
    NSString *prefix = nil;
    
    switch (playlist.type) {
        case M3U8MediaPlaylistTypeMedia:
            prefix = @"media_";
            break;
        case M3U8MediaPlaylistTypeAudio:
            prefix = @"audio_";
            break;
        case M3U8MediaPlaylistTypeSubtitle:
            prefix = @"subtitle_";
            break;
        case M3U8MediaPlaylistTypeVideo:
            prefix = @"video_";
            break;
            
        default:
            return @"";
            break;
    }
    return prefix;
}

- (NSString *)sufixOfSegmentNameInPlaylist:(M3U8MediaPlaylist *)playlist {
    NSString *prefix = nil;
    
    switch (playlist.type) {
        case M3U8MediaPlaylistTypeMedia:
        case M3U8MediaPlaylistTypeVideo:
            prefix = @"ts";
            break;
        case M3U8MediaPlaylistTypeAudio:
            prefix = @"aac";
            break;
        case M3U8MediaPlaylistTypeSubtitle:
            prefix = @"vtt";
            break;
            
        default:
            return @"";
            break;
    }
    return prefix;
}

- (NSArray *)segmentNamesForPlaylist:(M3U8MediaPlaylist *)playlist {
    
    NSString *prefix = [self prefixOfSegmentNameInPlaylist:playlist];
    NSString *sufix = [self sufixOfSegmentNameInPlaylist:playlist];
    NSMutableArray *names = [NSMutableArray array];
    
    NSArray *URLs = playlist.allSegmentURLs;
    NSUInteger count = playlist.segmentList.count;
    NSUInteger index = 0;
    for (int i = 0; i < count; i ++) {
        M3U8SegmentInfo *inf = [playlist.segmentList segmentInfoAtIndex:i];
        index = [URLs indexOfObject:inf.mediaURL];
        NSString *n = [NSString stringWithFormat:@"%@%lu.%@", prefix, (unsigned long)index, sufix];
        [names addObject:n];
    }
    return names;
}


- (void)saveMediaPlaylist:(M3U8MediaPlaylist *)playlist toPath:(NSString *)path error:(NSError **)error {
    if (nil == playlist) {
        return;
    }
    NSString *mainMediaPlContext = playlist.originalText;
    if (mainMediaPlContext.length == 0) {
        return;
    }
    
    NSArray *names = [self segmentNamesForPlaylist:playlist];
    for (int i = 0; i < playlist.segmentList.count; i ++) {
        M3U8SegmentInfo *sinfo = [playlist.segmentList segmentInfoAtIndex:i];
        mainMediaPlContext = [mainMediaPlContext stringByReplacingOccurrencesOfString:sinfo.URI withString:names[i]];
    }
    NSString *mainMediaPlPath = [path stringByAppendingPathComponent:playlist.name];
    BOOL success = [mainMediaPlContext writeToFile:mainMediaPlPath atomically:YES encoding:NSUTF8StringEncoding error:error];
    if (NO == success) {
        if (NULL != error) {
            NSLog(@"M3U8Kit Error: failed to save mian media playlist to file. error: %@", *error);
        }
        return;
    }
}

- (NSString *)indexPlaylistName {
    return INDEX_PLAYLIST_NAME;
}

@end
