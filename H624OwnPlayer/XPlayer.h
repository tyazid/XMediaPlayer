//
//  XPlayer.h
//  XMediaPlayer
//
//  Created by tyazid on 26/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XPUtil.h"
#import "XPCore.h"


@protocol XPlayerDelegate;

@interface XPlayer : NSObject
typedef NS_ENUM(NSInteger, XPlayerState) {
    STATE_IDLE, STATE_BUFFERING, STATE_READY, STATE_ENDED
};
@property  id<XPlayerDelegate> playerDelegate ;
@property BOOL loopMode;

@property (readonly) BOOL playing;
@property (readonly) XPlayerState playbackState;
@property BOOL stalled;
@property (readonly) NSTimeInterval duration;

@property BOOL playWhenReady;
-(void)prepare:(NSString*)baseUrl asset:(NSString*)assetUrl;
-(void) startPlay;
-(void) stopPlay;
-(void) pause:(BOOL)stalled;
-(void)tearDown;

-(void)loop;//restart from start pos
-(BOOL)isSupportedUrl:(NSString*)url;
-(NSTimeInterval)playerPosition;
-(void)setMediaConsumer :(id<MediaConsumer>) mediaConsumer;
-(id<MediaConsumer>)getMediaConsumerForType :(MediaConsumerType) type;
-(SupportedMediaType) getCurrentMediaType;
-(void)setExtraConfiguration:(NSDictionary*)config;


@end



/**
 * XPlayer state transition CB
 */

@protocol XPlayerDelegate <NSObject>
/**
 * Called when the player starts or stops loading the source.
 *
 * @param isLoading Whether the source is currently being loaded.
 */
@optional
-(void) onLoadingChanged:(BOOL) isLoading;

/**
 * Called when the value returned from either {@link #getPlayWhenReady()} or
 * {@link #getPlaybackState()} changes.
 *
 * @param playWhenReady Whether playback will proceed when ready.
 * @param playbackState One of the {@code STATE} constants defined in the {@link ExoPlayer}
 *     interface.
 */
@optional
-(void) onPlayerStateChanged:(BOOL)isReady state:(XPlayerState) playbackState;

/**
 * Called when timeBase  has been refreshed.
 *
 * @param timeBase The latest timeBase .
 */
@optional
-(void) onTimeBaseChanged:(NSTimeInterval)timeBase totalDuration:(NSTimeInterval)duration;

/**
 * Called when an error occurs. The playback state will transition to {@link #STATE_IDLE}
 * immediately after this method is called. The player instance can still be used, and
 * {@link #release()} must still be called on the player should it no longer be required.
 *
 * @param error The error.
 */
@optional
-(void) onPlayerError:(NSString*) error;

@optional
-(void) onPlayerReleased;


@end
