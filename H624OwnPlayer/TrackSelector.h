//
//  TrackSelector.h
//  XMediaPlayer
//
//  Created by tyazid on 29/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <Foundation/Foundation.h>
 #import "M3U8Kit.h"
#import "ABRStat.h"
#import "M3U8PlaylistModel.h"
#import "DefaultBandwidthMeter.h"

@interface TrackSelector : NSObject
@property   double delta,vqnThreshold,bandwidthFraction;
@property (readonly) NSUInteger selectedIndex;
@property BOOL smartAbrMode;
@property (readonly) M3U8ExtXStreamInf * selectedFormat;

@property (readonly) NSUInteger length;
-(instancetype) init __attribute__((unavailable("init not available")));
 -(NSUInteger) determineIdealSelectedIndex:(NSTimeInterval) nowSec;
-(NSUInteger) playlisIndex:(M3U8ExtXStreamInf *) format;
-(BOOL)supportSmartSelection;
// -(BOOL)setSmartSelectedChunkIndex:(NSUInteger)segmentIndex;
-(void)updateSelectedTrack:(NSTimeInterval) bufferedDurationSec;

-(BOOL)continueLoadSegs : (NSTimeInterval)bufferedDurationSec : (BOOL) loading;
-(NSUInteger)   determineMinBitrateIndex;
-(NSUInteger)  determineMaxBitrateIndex;
-(NSUInteger)  resolveSegIndex:(M3U8SegmentInfo*) previous playPos:(NSUInteger)playbackPositionUs
                      playlist:(M3U8MediaPlaylist*)mediaPlaylist  switched:(BOOL)switched;

-(ABRStat*)peekStat;
-(ABRStat*)pullStat;
-(double)getDelta;
-(instancetype)initWithModel: (M3U8PlaylistModel*)model andBandWidthMeter: (DefaultBandwidthMeter*)meter;//Meter


@end
