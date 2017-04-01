//
//  XPUtil.m
//  XMediaPlayer
//
//  Created by tyazid on 26/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "XPUtil.h"
#include <math.h>
#import "M3U8Kit.h"
#define CONCAT_URL_PATTERN @"%@%@"

 NSNumber * YES_N  ;
 NSNumber * NO_N;
@implementation XPUtil
+(void)initTools{
 YES_N=[NSNumber numberWithBool:YES];
 NO_N=[NSNumber numberWithBool:NO];

}
 +(MediaConsumerType) toMediaConsumerType:(MediaReaderType)rtype
{
    NSParameterAssert(([[NSArray arrayWithObjects:
                         [NSNumber numberWithInteger:H264_TYPE],
                         [NSNumber numberWithInteger:H263_TYPE],
                         [NSNumber numberWithInteger:MPEG1VIDEO_TYPE],
                         [NSNumber numberWithInteger:MPEG4_TYPE], nil]
                        containsObject:[NSNumber numberWithInteger:rtype]]));
    switch (rtype) {
        case AAC_TYPE:
        case AC3_TYPE:
            return AUDIO_CONSUMER;
            
        case H263_TYPE:
        case H264_TYPE:
        case MPEG1VIDEO_TYPE:
        case MPEG2VIDEO_TYPE:
        case MPEG4_TYPE:
            return VIDEO_CONSUMER;
        case TXT_TYPE:
            return TEXT_CONSUMER;
            
    }
    return -1;//should never occure.
}
+(NSTimeInterval)systemUpTime
{
    return [[NSProcessInfo processInfo] systemUptime];
}
+(XTimer)startTimer:(double)interval  dispatch:(dispatch_block_t)block
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);///prior set  , later ??
    
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

+(void)cancelTimer:(XTimer)timer{
    if (timer) {
        dispatch_source_cancel(timer);
        timer = nil;
    }
}

+(NSString*)concatUrl:(NSString*)baseUrl asset:(NSString*)assetUrl
{
    
    if(baseUrl && assetUrl)
        return [NSString stringWithFormat:CONCAT_URL_PATTERN,baseUrl,assetUrl];
    return Nil;
}

+(SupportedMediaType) isSupportedURL:(NSString *)url
{
    
    if([url.lowercaseString hasSuffix:@"m3u8"])
        return ABR_MEDIA;
    return NOT_SUPPORTED_MEDIA;
}
@end



/** Blocking Q*/

@interface XPBlockingQueue()
@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, strong) NSCondition *lock;
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic) BOOL awaiting, interupted;

@end



@implementation XPBlockingQueue

- (id)init
{
    self = [super init];
    if (self)
    {
        self.queue = [[NSMutableArray alloc] init];
        self.lock = [[NSCondition alloc] init];
        self.dispatchQueue = dispatch_queue_create("xplayer.blockingQ", DISPATCH_QUEUE_SERIAL);
        self.awaiting = self.interupted = NO;
    }
    return self;
}

- (void)enqueue:(id)object
{
    [_lock lock];
    [_queue addObject:object];
    [_lock signal];
    [_lock unlock];
}
-(void)interrupt //weak up 
{
    [_lock lock];
    self.interupted = YES;
    [_lock signal];
    [_lock unlock];
 
}

-(id) peek
{
    __block id object;
    dispatch_sync(_dispatchQueue, ^{
        [_lock lock];
        object = (_queue.count == 0)?Nil:[_queue objectAtIndex:0];       
         [_lock unlock];
    });
return object;
}

- (id)dequeue
{
    __block id object;
    dispatch_sync(_dispatchQueue, ^{
        [_lock lock];
        while (_queue.count == 0 && !self.interupted)
        {
            self.awaiting = YES;
            [_lock wait];
        }
        self.awaiting = NO;

        if(self.interupted)
            object = Nil;
        else {
            object = [_queue objectAtIndex:0];
            [_queue removeObjectAtIndex:0];
        }
        
        [_lock unlock];
    });
    
    if(self.interupted){
        self.interupted = NO;
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:@"XPBlockingQueue interrupted in dequeue"
                                     userInfo:nil];
      }

    return object;
}




-(BOOL)containsObject:(id)object
{
    BOOL contains = NO;
    [_lock lock];
    contains =_queue && [_queue containsObject:object];
     [_lock unlock];
    return contains;

}
-(void) clear{
    [_lock lock];
     [_queue  removeAllObjects];
    [_lock unlock];

}
-(BOOL)containsObjectWithCond:(checkCondition)condition{
    BOOL contains = NO;
    [_lock lock];
    for (id obj in _queue){
        if(condition(obj)){
            contains = YES;
            break;
        }
    }
    [_lock unlock];
    return contains;
}

- (NSUInteger)count
{
    return [_queue count];
}

- (void)dealloc
{
    self.dispatchQueue = nil;
    self.queue = nil;
    self.lock = nil;
}

@end



@interface SlidingPercentile()

typedef NS_ENUM(NSInteger, SORT_ORDER) {
    SORT_ORDER_NONE ,
    SORT_ORDER_BY_VALUE,
    SORT_ORDER_BY_INDEX
};
typedef struct _Sample {
    NSInteger   index,weight;
    double value;
} Sample;



@property (atomic) NSMutableArray<NSData *>* samples;
  @property (nonatomic) SORT_ORDER currentSortOrder;
-(void)ensureSortedByOrder :(SORT_ORDER) order ;

@end

@implementation SlidingPercentile
  NSInteger currentSortOrder;
  NSInteger nextSampleIndex;
  NSInteger totalWeight;
  NSInteger recycledSampleCount;


 static const NSComparator INDEX_COMPARATOR = ^NSComparisonResult(id obj1, id obj2){
     NSInteger index1, index2;
     Sample s;
     [((NSData *)obj1) getBytes:&s length:sizeof(Sample)];
     index1=s.index;
     [((NSData *)obj2) getBytes:&s length:sizeof(Sample)];
     index2=s.index;
 
     
    if (index1 >index2)
        return (NSComparisonResult)NSOrderedDescending;
    if (index1 <index2)
        return (NSComparisonResult)NSOrderedAscending;

    return (NSComparisonResult)NSOrderedSame;
};

static const NSComparator VALUE_COMPARATOR = ^NSComparisonResult(id obj1, id obj2){
    NSInteger value1, value2;
    Sample s;
    [((NSData *)obj1) getBytes:&s length:sizeof(Sample)];
    value1=s.value;
    [((NSData *)obj2) getBytes:&s length:sizeof(Sample)];
     value2=s.value;
    
    if (value1 >value2)
        return (NSComparisonResult)NSOrderedDescending;
    if (value1 <value2)
        return (NSComparisonResult)NSOrderedAscending;
    
    return (NSComparisonResult)NSOrderedSame;
};


 -(instancetype)initWithMax: (NSUInteger)weight
{
    if(self = [super init]){
        _maxWeight = weight;
        _samples = [NSMutableArray new];
        _currentSortOrder = SORT_ORDER_NONE;
    }
    return self;
}
-(void)dealloc{
    _samples=Nil;
}
-(void)addSample:(NSUInteger)weight value:(double)value
{
    [self ensureSortedByOrder:SORT_ORDER_BY_INDEX];
    Sample newSample ;
    newSample.index=nextSampleIndex++;
    newSample.weight = weight;
    newSample.value = value;
    
     [[self samples]addObject:[NSData dataWithBytes:&newSample length:sizeof(Sample)]];
     totalWeight += weight;
     Sample oldestSample ;
    while (totalWeight > [self maxWeight]) {
        NSUInteger excessWeight = totalWeight - [self maxWeight];
        [[self samples][0] getBytes:&oldestSample length:sizeof(Sample)];
       
        if (oldestSample.weight <= excessWeight) {
            totalWeight -= oldestSample.weight;
            [ [self samples] removeObjectAtIndex:0];
          
        } else {
            oldestSample.weight -= excessWeight;
            totalWeight -= excessWeight;
        }
    }
    
}
-(double)getPercentile:(double) percentile
{
    [self ensureSortedByOrder:SORT_ORDER_BY_VALUE];
     double desiredWeight = percentile * totalWeight;
    int accumulatedWeight = 0;
    Sample currentSample;
    for (int i = 0; i < [[self samples] count]; i++) {
        [[self samples][i] getBytes:&currentSample length:sizeof(Sample)];

        accumulatedWeight += currentSample.weight;
        if (accumulatedWeight >= desiredWeight) {
            return currentSample.value;
        }
    }
    // Clamp to maximum value or NaN if no values.
    if([[self samples] count]==0)
        return NAN;
    [[self samples][[[self samples] count] - 1] getBytes:&currentSample length:sizeof(Sample)];

    return currentSample.value;
}


-(void)ensureSortedByOrder:(SORT_ORDER)order{
    
    if (currentSortOrder != SORT_ORDER_BY_INDEX) {
        [[self samples] sortUsingComparator:INDEX_COMPARATOR];
        currentSortOrder = SORT_ORDER_BY_INDEX;
    }else  if (currentSortOrder != SORT_ORDER_BY_VALUE) {
        [[self samples] sortUsingComparator:VALUE_COMPARATOR];
        currentSortOrder = SORT_ORDER_BY_VALUE;
    }
}

@end
