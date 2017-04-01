//
//  XPlayerLayer.h
//  XMediaPlayer
//
//  Created by tyazid on 26/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
#import "XPCore.h"
#import "XPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface XPlayerLayer : AVSampleBufferDisplayLayer<MediaConsumer,XPlayerDelegate>


@property (nonatomic, readonly) MediaConsumerType type;


/*{
@private
    XPlayer		*_playerLayer;
}*/
/*-(instancetype) init __attribute__((unavailable("init not available")));*/
 -(void)enqueueSampleBuffer:(CMSampleBufferRef)buffer at: (NSUInteger) pts withDts:(NSUInteger) dts andFps:(double) fps consumerBaseTime:(NSUInteger)time;
/*!
 
	@abstract		Returns an instance of XPlayerLayer to display the visual output of the specified XPlayer.
	@result		An instance of XPlayerLayer.
 */
- (instancetype )initLayerWithPlayer:(XPlayer *)player andBounds:(CGRect) bounds  withWaitingAnimSupport:(BOOL)anim;

- (void)setupTimebase : (NSUInteger) ms;
/*!
	@property		player
	@abstract		Indicates the instance of XPlayer for which the XPlayerLayer displays visual output
 */
@property (nonatomic, retain, nullable) XPlayer *player;

 /*!
 @property		readyForDisplay
 @abstract		Boolean indicating that the first video frame has been made ready for display for the current item of the associated XPlayer.
 @discusssion	Use this property as an indicator of when best to show or animate-in an XPlayerLayer into view.
 An XPlayerLayer may be displayed, or made visible, while this propoerty is NO, however the layer will not have any
 user-visible content until the value becomes YES.
 This property remains NO for an XPlayer currentItem whose AVAsset contains no enabled video tracks.
 */
@property(nonatomic, readonly, getter=isReadyForDisplay) BOOL readyForDisplay;

/*!
	@property		videoRect
	@abstract		The current size and position of the video image as displayed within the receiver's bounds.
 */


-(void)releasePlayerLayer;

-(void)setBounds:(CGRect)bounds  withWaitingAnimSupport:(BOOL)anim;

-(void) setPlayer:(XPlayer *)player;

@end

NS_ASSUME_NONNULL_END
