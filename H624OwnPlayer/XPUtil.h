//
//  XPUtil.h
//  XMediaPlayer
//
//  Created by tyazid on 26/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XPCore.h"

//BOOL
#define BUFFERING_MSG_KEY           "notif.buffering.key"
#define PLAYPOS_MSG_KEY             "notif.player.pos"
#define PLAYER_TEARED_DOWN_MSG_KEY  "notif.player.teardown"
#define PLAY_FAILLURE_MSG_KEY       "notif.player.failled"
#define PLAY_EOS_MSG_KEY             "notif.player.eos"
#define XPL_NOTIF_CENTER_NAME        @"XplayertNotification"

#define REGISTER_NOTIFICATION_RECEIVER_GEN(NAME)    [[NSNotificationCenter defaultCenter] addObserver:self \
                                                    selector:@selector(receiveXplayertNotification:) \
                                                    name:NAME object:nil]

#define SEND_NOTIFICATION_MSG_GEN(NAME,K,V)   ({ NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys: V,[NSString stringWithUTF8String:K],nil]; \
                                                [[NSNotificationCenter defaultCenter] postNotificationName: NAME object:nil userInfo:userInfo];})





#define REGISTER_NOTIFICATION_RECEIVER     REGISTER_NOTIFICATION_RECEIVER_GEN(XPL_NOTIF_CENTER_NAME)
#define UNREGISTER_NOTIFICATION_RECEIVER    [[NSNotificationCenter defaultCenter] removeObserver:self]
#define SEND_NOTIFICATION_MSG(K,V)  SEND_NOTIFICATION_MSG_GEN(XPL_NOTIF_CENTER_NAME,K,V)


#define RECEIVE_NOTIFICATION_METHOD_IN  - (void)receiveXplayertNotification:(NSNotification *) notification{


#define GET_RECEIVED_NOTIFICATION_VALUE(TYPE,KEY, VALUE) \
        NSDictionary *userInfo = notification.userInfo;\
        TYPE *VALUE = [userInfo objectForKey:[NSString stringWithUTF8String:KEY]]

#define RECEIVE_NOTIFICATION_METHOD_OUT }

FOUNDATION_EXPORT NSNumber * YES_N;
FOUNDATION_EXPORT NSNumber * NO_N;

 
typedef NS_ENUM(NSInteger, SupportedMediaType) {
    ABR_MEDIA, NOT_SUPPORTED_MEDIA
};
@interface XPUtil : NSObject



typedef BOOL (^checkCondition)(id);
typedef dispatch_source_t XTimer;
+(XTimer)startTimer :(double) interval dispatch:(dispatch_block_t) block;
+(void)  cancelTimer : (XTimer) timer;
+(NSTimeInterval)systemUpTime;
+(MediaConsumerType) toMediaConsumerType : (MediaReaderType) rtype;
+(SupportedMediaType)isSupportedURL:(NSString*)url;
+(NSString*)concatUrl:(NSString*)baseUrl asset:(NSString*)assetUrl;
-(instancetype) init __attribute__((unavailable("init not available for util class")));

@end

/**
 *Blocking Q.
 */

@interface XPBlockingQueue : NSObject
/**
 * Enqueues an object to the queue.
 * @param object Object to enqueue
 */
- (void)enqueue:(id)object;
/**
 * Dequeues an object from the queue.  This method will block.
 */
- (id)dequeue;
-(id)peek;
- (NSUInteger)count;
-(BOOL)containsObject:(id)object;
-(BOOL)containsObjectWithCond:(checkCondition)condition;
-(void) clear;
//
-(void)interrupt;
@end

/**
 * A listener of data transfer events.
 */
@protocol TransferListener <NSObject>
-(void) onTransferStart:(id) source;
-(void) onBytesTransferred:(id) source transferred:(NSUInteger)bytes;
-(void) onTransferEnd:(id) source;
@end

//TransferListener

/**
 * Calculate any percentile over a sliding window of weighted values. A maximum weight is
 * configured. Once the total weight of the values reaches the maximum weight, the oldest value is
 * reduced in weight until it reaches zero and is removed. This maintains a constant total weight,
 * equal to the maximum allowed, at the steady state.
 * <p>
 * This class can be used for bandwidth estimation based on a sliding window of past transfer rate
 * observations. This is an alternative to sliding mean and exponential averaging which suffer from
 * susceptibility to outliers and slow adaptation to step functions.
 *
 * @see <a href="http://en.wikipedia.org/wiki/Moving_average">Wiki: Moving average</a>
 * @see <a href="http://en.wikipedia.org/wiki/Selection_algorithm">Wiki: Selection algorithm</a>
 */
@interface SlidingPercentile : NSObject
@property (readonly)NSUInteger maxWeight;
-(instancetype) init __attribute__((unavailable("init not available")));
-(instancetype)initWithMax: (NSUInteger)weight;
/**
 * Adds a new weighted value.
 *
 * @param weight The weight of the new observation.
 * @param value The value of the new observation.
 */
-(void)addSample:(NSUInteger)weight value:(double)value;
/**
 * Computes a percentile by integration.
 *
 * @param percentile The desired percentile, expressed as a fraction in the range (0,1].
 * @return The requested percentile value or {@link Float#NaN} if no samples have been added.
 */
-(double)getPercentile:(double) percentile;


@end


#define MXNOTEKEY   @"svq.max.note"
#define RQNOTEKEY   @"svq.req.note"
#define APPNOTEKEY  @"svq.app.note"
#define MXBITRATE   @"svq.max.br"
#define RQBITRATE   @"svq.req.br"
#define APPBITRATE  @"svq.app.br"
#define ESTBITRATE  @"svq.est.br"
#define APPSEGKEY   @"svq.app.seg"
#define RQSEGKEY    @"svq.req.seg"
#define TOPSEGKEY   @"svq.max.seg"

//SlidingPercentile
