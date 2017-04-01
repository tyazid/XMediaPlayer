//
//  TrackSelector.m
//  XMediaPlayer
//
//  Created by tyazid on 29/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "TrackSelector.h"
#import "ABRKeys.h"
@interface TrackSelector()
@property (strong,readonly) M3U8PlaylistModel* model;
@property (strong,readonly) DefaultBandwidthMeter* meter;
@property (strong, readonly) XPBlockingQueue* q;
//-(Svqn*)findInSvqMap : (M3U8ExtXStreamInf *)format  segNumber:(NSUInteger)segmentNumber;
//#define _Used_NSComparisonResult_To_Sort_StreamList_ NSOrderedDescending
@property (strong) NSMutableArray<NSString*>* f2mpl;

-(void) pushStat: (ABRStat*)stat;

@end
@implementation TrackSelector

BOOL svqSupport;
-(instancetype)initWithModel: (M3U8PlaylistModel*)model andBandWidthMeter: (DefaultBandwidthMeter*)meter
 {
   if(self = [super init]   )
   {
       _model = model;
       _delta=_vqnThreshold=_bandwidthFraction=0.f;
       _meter=meter;
       _length = _model&&   // check and throw if needed
       _model.masterPlaylist&&
       _model.masterPlaylist.xStreamList?  [_model.masterPlaylist.xStreamList count] : 0;
       _selectedIndex = [self determineIdealSelectedIndex:NAN];
       _q=[[XPBlockingQueue alloc] init];
    //   svqSupport =(_model && _model.svqMap && _model.svqMap.count) ? YES : NO;
       _smartAbrMode=NO;
   }
    return self;
  }

-(double)getDelta
{
    	return svqSupport && _smartAbrMode ?   (float)[ self delta ] : 0.f;
}

-(NSUInteger) playlisIndex:(M3U8ExtXStreamInf *) format{
    return   [  _model.masterPlaylist.xStreamList indexOf:format];
}
-(BOOL) supportSmartSelection {
 
    return svqSupport && _smartAbrMode;
}

-(BOOL)continueLoadSegs:(NSTimeInterval)bufferedDurationSec :(BOOL)loading
{
    NSUInteger bufferedDurationUs = (NSUInteger)(bufferedDurationSec * 1000);
    M3U8ExtXStreamInf* currentFormat =[self selectedFormat];
    M3U8ExtXStreamInf* maxFormat=  [_model.masterPlaylist.xStreamList xStreamInfAtIndex: [self determineMaxBitrateIndex]];
    M3U8ExtXStreamInf* minFormat=  [_model.masterPlaylist.xStreamList xStreamInfAtIndex: [self determineMinBitrateIndex]];
    M3U8ExtXStreamInf* midleFormat=[_model.masterPlaylist.xStreamList xStreamInfAtIndex: (_length - 1) / 2];
  

    
    NSUInteger comparewith = 0;
    
    if(currentFormat.bandwidth > midleFormat.bandwidth){
        comparewith = labs(currentFormat.bandwidth - maxFormat.bandwidth) <
        labs(currentFormat.bandwidth - midleFormat.bandwidth)?
        CACHING_MIN_DURATION_FOR_QUALITY_INCREASE_MS : DEFAULT_MEDIUM_DURATION_FOR_QUALITY_MS;
    }
    
    else{  comparewith =  labs(currentFormat.bandwidth - minFormat.bandwidth) <
        labs(currentFormat.bandwidth - midleFormat.bandwidth)?
        DEFAULT_MAX_DURATION_FOR_QUALITY_DECREASE_MS : DEFAULT_MEDIUM_DURATION_FOR_QUALITY_MS;
      }
    /*
    NSLog(@"-- CONTINUE LOAD(%ld,%ld,%ld;%ld) ? buff =%ld  , mx:%ld ==> CONT== %i",currentFormat.bandwidth,maxFormat.bandwidth,minFormat.bandwidth,midleFormat.bandwidth,
          bufferedDurationUs, comparewith, (bufferedDurationUs < comparewith) ? YES : NO);*/
    return (bufferedDurationUs < comparewith) ? YES : NO;
    
 }

-(M3U8ExtXStreamInf*) selectedFormat
{
    return [_model.masterPlaylist.xStreamList xStreamInfAtIndex: _selectedIndex ];
}

-(void)updateSelectedTrack:(NSTimeInterval)bufferedDurationSec
{
    NSUInteger bufferedDurationUs = (NSUInteger)(bufferedDurationSec * 1000.f);
    NSUInteger currentSelectedIndex =  _selectedIndex;
    M3U8ExtXStreamInf* currentFormat = [self selectedFormat];
    NSUInteger idealSelectedIndex =[self determineIdealSelectedIndex:NAN];
    M3U8ExtXStreamInf* idealFormat = [_model.masterPlaylist.xStreamList xStreamInfAtIndex:idealSelectedIndex ];
    if  (([idealFormat bandwidth] > [currentFormat bandwidth] && bufferedDurationUs < DEFAULT_MIN_DURATION_FOR_QUALITY_INCREASE_MS / 2 )
          ||
         ([idealFormat bandwidth] < [ currentFormat bandwidth] && bufferedDurationUs>DEFAULT_MAX_DURATION_FOR_QUALITY_DECREASE_MS))
        _selectedIndex = currentSelectedIndex;
    else
        _selectedIndex=idealSelectedIndex;
    

}

-(NSUInteger) determineIdealSelectedIndex:(NSTimeInterval) nowSec{

    NSInteger bitrateEstimate = [[self meter] getBitrateEstimate];
   // NSLog(@"-------------------------> bitrateEstimate : %ld",bitrateEstimate);
    double fraction = _bandwidthFraction<=0? DEFAULT_BANDWIDTH_FRACTION : _bandwidthFraction;
    fraction = MIN(1.f,fraction);
    NSInteger effectiveBitrate = (bitrateEstimate == [DefaultBandwidthMeter NO_ESTIMATE])?
                DEFAULT_MAX_INITIAL_BITRATE:(NSInteger) (bitrateEstimate * fraction);
    NSUInteger idx = 0;
    for (int i = 0; i < _length; i++) {
        if (isnan(nowSec)) {
            
            M3U8ExtXStreamInf* format =[_model.masterPlaylist.xStreamList xStreamInfAtIndex:i ];
            idx = i;
           // NSLog(@"---->>>> i:%ld fb:%lu effective:%lu ",i,[format bandwidth],effectiveBitrate);
              if ([format bandwidth] <= effectiveBitrate)
                break;
        }
    }
    
    return idx;
}
-(NSUInteger) determineMinBitrateIndex
{
 return  (_Used_NSComparisonResult_To_Sort_StreamList_ == NSOrderedDescending) ?
            ([_model.masterPlaylist.xStreamList count] - 1):0;
   
}

-(NSUInteger) determineMaxBitrateIndex
{
    return  (_Used_NSComparisonResult_To_Sort_StreamList_ == NSOrderedDescending) ?0:
    ([_model.masterPlaylist.xStreamList count] - 1);
    
}

/*

-(Svqn*)findInSvqMap:(M3U8ExtXStreamInf *)format  segNumber:(NSUInteger)segmentNumber{

   NSArray<Svqn*>* array =  [[self model ]svqMap][format.m3u8URL];
    if(array)
        for (Svqn *svqn in array)
             if(svqn.index == segmentNumber)
                 return svqn;
     return Nil;
 }
 
-(BOOL)setSmartSelectedChunkIndex:(NSUInteger)segmentIndex{
    
    M3U8ExtXStreamInf* requestedformat =[self selectedFormat];
    if(requestedformat){
        Svqn* requestedSvqn = [self findInSvqMap:requestedformat segNumber:segmentIndex];
        if(!requestedSvqn)
            return NO;
        M3U8ExtXStreamInf* bestFormat =  [_model.masterPlaylist.xStreamList xStreamInfAtIndex: [self determineMaxBitrateIndex]];
        Svqn* topSvqn= [self findInSvqMap:bestFormat segNumber:segmentIndex];
        M3U8ExtXStreamInf* format;
        NSInteger choosedFormatIdx = -1;
        float lastDelta=0.f;
        float delta = [self smartAbrMode]?(float)[self getDelta] : 0.f;
        Svqn*  appliedSvqn = requestedSvqn;
        if(delta>0.f)
        {
            Svqn* fndi=Nil;
            float delta_i = 0.f;
            for (int i = 0; i < _length; i++) {
                format =  [_model.masterPlaylist.xStreamList xStreamInfAtIndex: i];
                if( format == requestedformat ) {
                    if(choosedFormatIdx == -1)
                        choosedFormatIdx = i;
                    continue;
                }
                fndi=[self findInSvqMap:format segNumber:requestedSvqn.segment.number];
                if(fndi &&  fndi.note>=[self vqnThreshold] &&fndi.segment.startTime == requestedSvqn.segment.startTime)
                {
                    delta_i = requestedSvqn.note - fndi.note;
                    if((fndi.note < requestedSvqn.note) &&
                       (delta_i <= delta) &&
                       (lastDelta ==0 || lastDelta<=delta_i))
                    {
                        appliedSvqn = fndi;
                        choosedFormatIdx=i;
                        lastDelta = delta_i;
                    }
                }
            }
        }
        M3U8ExtXStreamInf* appliedFormat=Nil;
        if(choosedFormatIdx == -1){
            choosedFormatIdx = _selectedIndex;
            appliedFormat    = [self selectedFormat];
            appliedSvqn      = requestedSvqn;
        }else {
        appliedFormat = [_model.masterPlaylist.xStreamList xStreamInfAtIndex:choosedFormatIdx];
        }

        
        if(_smartAbrMode){
      NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSString stringWithFormat:@"%lf",[topSvqn note]],MXNOTEKEY,
                              [NSString stringWithFormat:@"%lf",[requestedSvqn note]],RQNOTEKEY,
                              [NSString stringWithFormat:@"%lf",[appliedSvqn note]],APPNOTEKEY,
                              [NSString stringWithFormat:@"%lu",[bestFormat bandwidth]],MXBITRATE,
                              [NSString stringWithFormat:@"%lu",[requestedformat bandwidth]],RQBITRATE,
                              [NSString stringWithFormat:@"%lu",[appliedFormat bandwidth]],APPBITRATE,
                              [NSString stringWithFormat:@"%lu",[_meter getBitrateEstimate]],ESTBITRATE,
                              nil];
             ABRStat* stat = [[ABRStat alloc] initWithDictionary:dict];
             SEND_NOTIFICATION_MSG_GEN(NOTIFICATION_SMARTABR_CENTER_NAME,SVQN_STAT_EVENT_NAME,stat);
        }
        
        //SEND_NOTIFICATION_MSG_GEN(NAME,K,V)
        
        
 
     //   ABRStat* stat = [[ABRStat alloc] initWithDictionary:dict];
        
        
       //  [NSString stringWithFormat:@""];
 

    }

    return NO;
}
*/
-(ABRStat *)peekStat{
    return [[self q] peek];
}
-(ABRStat*)pullStat
{
    return [[self q] dequeue];
}

-(void)pushStat:(ABRStat *)stat
{
    [[self q] enqueue:stat];
}

-(NSUInteger)resolveSegIndex:(M3U8SegmentInfo *)previous playPos:(NSUInteger)playbackPositionUs playlist:(M3U8MediaPlaylist*)mediaPlaylist switched:(BOOL)switched
{
    if(previous && !switched){
        for (int i = 0; i<mediaPlaylist.segmentList.count; i++ ) {
            M3U8SegmentInfo*segment =[mediaPlaylist.segmentList segmentInfoAtIndex:i];
            if(segment.number > previous.number)
                return segment.number;
        }
        
    }else {
        NSTimeInterval start = switched && previous ? (previous.startTime + previous.duration + 1.f) : playbackPositionUs;
        for (int i = 0; i<mediaPlaylist.segmentList.count; i++ ) {
            M3U8SegmentInfo*segment =[mediaPlaylist.segmentList segmentInfoAtIndex:i];
            if( (start >= segment.startTime) &&
                  (start <= (segment.startTime + segment.duration )))
                    return segment.number;
            
        }
    }
    return NSUIntegerMax;
}
@end
/*
 -(NSUInteger) determineIdealSelectedIndex:(double) nowSec;
  -(BOOL)supportSmartSelection;
 -(void)setSvqDeltaNote:(float)delta;
 -(BOOL)setSmartSelectedChunkIndex:(NSUInteger)segmentIndex;
 -(ABRStat*)peekStat;
 -(ABRStat*)pullStat;
 */

