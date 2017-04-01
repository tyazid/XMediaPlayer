//
//  H264Reader.m
//  XMediaPlayer
//
//  Created by tyazid on 24/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "H264Reader.h"
#import "XPUtil.h"
//#define H264_READER_DBG
#define  PPS 8
#define  SPS 7
#define  IFRAME 5
#define  FRAME 1
#define  SEI 1
#define  ANY_FRAME -1

#define FPS 25

#define  MAX_SPS_SIZE 32
#define  MAX_PPS_SIZE 256
#define  NALU_PARSE_SIZE (3)
#define FRAME_CFG_PATTERN "%ld-%ld-%lf"



#define  NALU_ID_MASK 0x1F
#define set_parm(parm,data,offset,size,error)  if( (parm = malloc(size )))\
memcpy (parm, &data[offset], size);

#define free_parm(parm) if(parm) {free(parm); parm=NULL;}
#define dump_Parm(data,offset,size, msg) do{ \
NSLog(msg); NSLog(@"~~~~~~~~~~~>>>> FRAME OFFSET : %lu, L:%lu",(unsigned long)offset,(unsigned long)size);\
for (int n=offset; n<(offset+size); n++) {\
NSLog(@" %x",data[n]);\
}}while(NO)

@class ExtractedFrame;
@class CMSampleBufferRefHandler;


@interface H264Reader ()
@property BOOL firstBuffer;
@property (strong)  NSMutableArray<ExtractedFrame*>* bigData;
@property (nonatomic, assign) CMVideoFormatDescriptionRef formatDesc;
 -(BOOL)getNextNalu:(ExtractedFrame*)frame
       withType   : (NSInteger*)type
      fromOffset  :(NSUInteger)from
      frameOffset :(NSUInteger *)frame
      frameLenght :(NSUInteger *)lenght;
//-(BOOL)configWithStreamHeader: (NSUInteger*)newOffset;
-(BOOL) createPpsAndSpsParameter:(NSData*)spsData  withSpsOffset:(NSUInteger)spsOffset withSpsSize:(NSUInteger)spsSize  andPpsData:(NSData*)ppsData  withPpsoffset:(NSUInteger)ppsOffset withPpsSize:(NSUInteger)ppsSize;
 //-(void)render:(CMSampleBufferRef)sampleBuffer andPts:(NSUInteger)pts andFps:(double)fps;
-(void)render:(CMSampleBufferRef)sampleBuffer andPts:(NSUInteger)pts andDts:(NSUInteger)dts andFps:(double)fps basetime:(NSUInteger)base;
//-(void)feedWithConf: (NSUInteger)frameSize frameOffset:(NSUInteger)offset andPts:(NSUInteger)pts andFps:(double)fps;
-(void)feedWithConf: (ExtractedFrame* )conf baseTime:(NSUInteger)time;
-(void)feedRawData: (NSMutableArray<ExtractedFrame*>*)data;
-(void)feedWithConfSub: (ExtractedFrame* )conf baseTime:(NSUInteger)time offsetF:(NSUInteger)frameOffset frameLenght:(NSUInteger)lenght;

@end

@interface  ExtractedFrame : NSObject
@property (strong)  NSMutableData* data;
@property  NSUInteger pts,dts;
@property double fps;
@end

@implementation ExtractedFrame
-(instancetype) init {
    if(self = [super init])
    {
        [self setData:[NSMutableData new]];
    }
    return self;
}

@end




@implementation H264Reader


NSMutableArray* timeLine;
CMSampleTimingInfo * frameTimingInfo;

static const uint8_t NALU_ID[NALU_PARSE_SIZE]={/*0,*/0x00,0x00,0x01};
static const uint8_t NALU_ID4[NALU_PARSE_SIZE+1]={0x00,0x00,0x00,0x01};



-(id)init {
    if(self = [super init])
    {
        _type = H264_TYPE;
        frameTimingInfo = Nil;
        _consumeFrame = Nil;
        
        return self;
    }
    return Nil;
}

-(void)startStream
{
#ifdef H264_READER_DBG
    NSLog(@">>>>>>>>>Start of stream ==> reset ctx" );
#endif
    _timeUs=NSUIntegerMax;//so not set yet.
    _bigData=Nil;
    timeLine=Nil;
    if(frameTimingInfo)
        free (frameTimingInfo);
    frameTimingInfo = Nil;
    if(timeLine)
        [timeLine removeAllObjects];
    else
        timeLine =  [NSMutableArray new] ;
    
    
}
-(void)endStream
{
#ifdef H264_READER_DBG
    NSLog(@">>>>>>>>>End of stream ==> start consume" );
#endif
    //start now playing
    
    dispatch_queue_t queue = dispatch_queue_create("xplayer", NULL);
    dispatch_async(queue, ^{
        
        frameTimingInfo = malloc(sizeof(CMSampleTimingInfo));
        
        
        [self feedRawData:[self bigData]];
        //switch state
    });
}





-(void) setFrameConf:(NSUInteger) pts withdts:(NSUInteger) dts  withFps:(double)fps{
    _timeUs = pts;
    NSString *entry =[NSString stringWithFormat: [NSString stringWithUTF8String:FRAME_CFG_PATTERN] ,(unsigned long)pts,dts,fps];
    [timeLine addObject:entry];
#ifdef H264_READER_DBG
    NSLog(@">>>>> CFG STR (PTS-DTS-FPS-POS) => %@\n",entry);
#endif
}


-(void) signalNewFrame:(NSUInteger)frameNumber
{
#ifdef H264_READER_DBG

    NSLog(@">>>>> NEW FRAME STARTED ........ %lu\n", (unsigned long)frameNumber);
#endif
    
    if (![self bigData])
        [self setBigData:[NSMutableArray new]];
    [[self bigData] addObject:[ExtractedFrame new ]];
    if ( [timeLine count] == [[self bigData]count] )
    {
        
        NSUInteger pts,dts;
        double fps;
        sscanf([[timeLine lastObject] UTF8String], FRAME_CFG_PATTERN, &pts,&dts,&fps);
        [[self bigData]lastObject].dts=dts;
        [[self bigData]lastObject].pts=pts;
        [[self bigData]lastObject].fps=fps;
        //[[self bigData]lastObject]
 #ifdef H264_READER_DBG
         NSLog(@"#### set frame pts dts fps ........ %lu // %lu\n", (unsigned long)frameNumber,[[self bigData]lastObject].dts);
#endif

        
    }
#ifdef H264_READER_DBG

      NSLog(@"<<<<<<<< NEW FRAME STARTED ........ %lu\n", (unsigned long)frameNumber);
#endif
  
    
}


-(void) setPacket:(const char*) ptr withOffset:(NSUInteger)offset andSize:(NSUInteger)size isFirst:(BOOL)first

{
    //serach for Nalu3 oun 4
#ifdef H264_READER_DBG
    //// NSLog(@">>>>>>>>>H264 setPacket Reader withOffset:%lu, size:%lu Bigdata last obj:%@",offset,(long)size,o);
#endif
    //NALU_ID
    NSUInteger fixedOffset = offset;
    if(first)
    {
        for (  fixedOffset=offset; fixedOffset<(offset + size); fixedOffset++)
            if(memcmp(&ptr[fixedOffset], NALU_ID, NALU_PARSE_SIZE)==0)
                break;
        if(fixedOffset == (offset + size))
        {
            NSLog(@"------->>>>> setPacket unable to find nalu header.");
            return;
        }
        /*
        NSLog(@"------->>>>> OK offset fixed to %lu  NSDATA :%lu// nb nalu:%lu",fixedOffset,  [[self bigData]lastObject].data.length ,
              [[self bigData] count]);
        printf("-----> 8xHEX ::: ");
        for (int hex=fixedOffset; hex<fixedOffset+8;hex++) {
            printf("%x:",0xff&ptr[hex]);
        }
        printf("\n");*/
    }
    [ [[self bigData]lastObject].data appendBytes: (const void *)&ptr[fixedOffset]  length:size-fixedOffset];
    
    if(first){
        /*
        int8_t test[8];
        [ [[self bigData]lastObject].data getBytes:test length:8];
        printf("-----> 8xDATA-HEX ::: ");
        for (int hex=0; hex<8;hex++) {
            printf("%x:",0xff&test[hex]);
        }
        printf("\n");*/
    }
    
}

/*****************************************/
/********************feedRawData********************/
/*****************************************/


-(void)feedRawData: (NSMutableArray<ExtractedFrame*>*)bigData
{
    @autoreleasepool {
        _formatDesc = NULL;
        NSUInteger offset=0,size=0;
        NSUInteger pendingPpsSps[4]={NSUIntegerMax,NSUIntegerMax,NSUIntegerMax,NSUIntegerMax};
        ExtractedFrame *ppsFrame, *spsFrame;
        NSInteger anyNal = ANY_FRAME;
        BOOL pps=NO, sps=NO;
        BOOL spspps=NO;
        NSUInteger timeBase= NSUIntegerMax;
        //1st step search for config pps sps:
        if([self consumeCB])
            [ [self consumeCB]startConsume];
        [self setFirstBuffer:YES];
        
        BOOL donePPS = NO, doneSPS=NO;
         while (!sps || !pps) {
            if(!sps && ! doneSPS)
                anyNal = SPS;
            else
                if(!pps && !donePPS)
                    anyNal = PPS;
                else break;
#ifdef H264_READER_DBG
         
                NSLog(@"~~~~~~~~ LOKING FOR NAL : %lu",anyNal);
#endif
             for (ExtractedFrame* frame  in bigData) {
                if([self getNextNalu:frame withType:&anyNal fromOffset:0 frameOffset:&offset frameLenght:&size])
                  switch (anyNal) {
                        case SPS:
#ifdef H264_READER_DBG

                            NSLog(@"~~~~~~~~ SPS FND NALU");
#endif
                            sps=YES;
                            spsFrame = frame;
                            pendingPpsSps[0] =offset;
                            pendingPpsSps[1] =size;
                            
                            break;
                        case PPS:
#ifdef H264_READER_DBG

                          NSLog(@"~~~~~~~~ PPS FND nalu");
#endif
                            pps=YES;
                            ppsFrame=frame;
                            pendingPpsSps[2] =offset;
                            pendingPpsSps[3] =size;
                            break;
  
                    }
             
                 if ((anyNal == SPS && sps ) || (anyNal == PPS && pps ))
                     break; //for
             }
              if (anyNal == SPS  )
                  doneSPS = YES;
              else if (anyNal == PPS  )
                  donePPS = YES;
             
             
            
        
        }
        
        if(pps && sps )
        {
            spspps= [self createPpsAndSpsParameter: spsFrame.data
                                     withSpsOffset: pendingPpsSps[0]
                                       withSpsSize: pendingPpsSps[1]
                                        andPpsData:ppsFrame.data
                                     withPpsoffset: pendingPpsSps[2]
                                       withPpsSize: pendingPpsSps[3]];
            
        }
      
        
    /*    for (ExtractedFrame* frame  in bigData) {
             if(!sps)
                anyNal = SPS;
            else
                if(!pps)
                    anyNal = PPS;
            NSLog(@"~~~~~~~~ LOKING FOR NAL : %lu",anyNal);
            if(!(pps && sps) &&
               [self getNextNalu:frame withType:&anyNal fromOffset:0 frameOffset:&offset frameLenght:&size])
            {
                switch (anyNal) {
                    case SPS:
                      NSLog(@"~~~~~~~~ SPS FND NALU");

                        sps=YES;
                        spsFrame = frame;
                        pendingPpsSps[0] =offset;
                        pendingPpsSps[1] =size;
                        
                        break;
                    case PPS:
                       NSLog(@"~~~~~~~~ PPS FND nalu");

                        pps=YES;
                        ppsFrame=frame;
                        pendingPpsSps[2] =offset;
                        pendingPpsSps[3] =size;
                        break;
                }
            }
            if(pps && sps && !spspps)
            {
              spspps= [self createPpsAndSpsParameter: spsFrame.data
                                 withSpsOffset: pendingPpsSps[0]
                                   withSpsSize: pendingPpsSps[1]
                                    andPpsData:ppsFrame.data
                                 withPpsoffset: pendingPpsSps[2]
                                   withPpsSize: pendingPpsSps[3]];
                
                break;
            }
            
        }*/
        
        if(!spspps)
        {
            NSLog(@"~~~~~~~~ FEED DATA CFG KO");
             SEND_NOTIFICATION_MSG(PLAY_FAILLURE_MSG_KEY, @"H264Reader was not aible to resolve SPS and PPS");

            return;
        }
        
        for (ExtractedFrame* frame  in bigData)
            timeBase=MIN(timeBase, [frame pts]);
        
        NSLog(@"~~~~~~~~   DATA CFG OK && TimeBase=%lu",(unsigned long)timeBase);
        //every think is ready to stat playing
         for (ExtractedFrame* frame  in bigData) {
             anyNal = ANY_FRAME;
            offset=0;
            size=0;
           // NSLog(@"~~~~~~~~ INSPECT FRAME %d,",++f);
                  //[self getNextNalu:frame withType:&anyNal fromOffset:0 frameOffset:&offset frameLenght:&size]
       //  while ( [self getNextNalu000:frame withType:&anyNal fromOffset:(offset+size ) frameOffset:&offset frameLenght:&size]) {
          //      NSLog(@"~~~~~~~~ FRAME %d conains nalu :%lu ",f,anyNal);
            //    anyNal=ANY_FRAME;
               
               
               [self feedWithConf:frame baseTime:timeBase ];
               

         //   }

        //   NSLog(@"~~~~~~~~ FEED DATA DONE");
            
            

            
        }
        if([self consumeCB])
            [ [self consumeCB]endConsume];
        #ifdef H264_READER_DBG
       NSLog(@"~~~~~~~~ FEED DATA DONE");
#endif
    }
}



- (NSString *)description {
    return [NSString stringWithFormat: @"H264Reader: nb.frame=%lu type =%ld timeUS=%lu consumeFnt:%@ set",
            [self bigData]?0:(unsigned long)[[self bigData] count],
            (long)[self type],(unsigned long)[self timeUs] , [self consumeFrame]?@"is" : @"not"];
}

/*****************************************/
/************render***********/
/*****************************************/


-(void)render:(CMSampleBufferRef)sampleBuffer andPts:(NSUInteger)pts andDts:(NSUInteger)dts andFps:(double)fps basetime:(NSUInteger)base
{
    static NSInteger clockBufferStart;
    
    if([self consumeFrame])
    {
 
        if([self firstBuffer])
        {
            [self setFirstBuffer:NO];
            
            clockBufferStart = -1;
        }
        if(clockBufferStart == -1 || (pts - clockBufferStart >=250))
           {
               SEND_NOTIFICATION_MSG(PLAYPOS_MSG_KEY,[NSNumber numberWithDouble:(double)(pts)/1000.f]);
               
               clockBufferStart = pts;
           }
        
        
        
 SEND_NOTIFICATION_MSG(BUFFERING_MSG_KEY,[NSNumber numberWithBool:NO]);
        
#ifdef H264_READER_DBG
        NSLog(@"~~~~~~~~~~~ RENDER FRAME IN DELEGATED CONSUMER.");
#endif
        [[self consumeFrame] consume:sampleBuffer at: pts withDts:dts andFps:fps consumerBaseTime:base ];
    }else
        
        NSLog(@"~~~~~~~~~~~ WARN:: RENDER FRAME NO DELEGATED CONSUMER WAS SET!!!");

}

/*
 
 
 //[self getNextNalu:frame withType:&anyNal fromOffset:0 frameOffset:&offset frameLenght:&size]
 //  while ( [self getNextNalu000:frame withType:&anyNal fromOffset:(offset+size ) frameOffset:&offset frameLenght:&size]) {
 //      NSLog(@"~~~~~~~~ FRAME %d conains nalu :%lu ",f,anyNal);
 //    anyNal=ANY_FRAME;
 */

/*****************************************/
/************feedWithFrame***********/
/*****************************************/


-(void)feedWithConf: (ExtractedFrame* )conf baseTime:(NSUInteger)time
{
    NSUInteger offset=0, size=0;
    NSInteger anyNal=ANY_FRAME;
    NSUInteger iframeoffset=0, iframesize=0;
    
  /*  while ( [self getNextNalu000:conf withType:&anyNal fromOffset:(offset+size ) frameOffset:&offset frameLenght:&size])

        if(anyNal==IFRAME) {
           // [self feedWithConfSub:conf baseTime:time offsetF:offset frameLenght:size];
            break;
        }else  an yNal=ANY_FRAME;
*/
        

    while ( [self getNextNalu000:conf withType:&anyNal fromOffset:(offset+size ) frameOffset:&offset frameLenght:&size]) {
        //      NSLog(@"~~~~~~~~ FRAME %d conains nalu :%lu ",f,anyNal);
        if(anyNal !=9)
        [self feedWithConfSub:conf baseTime:time offsetF:offset frameLenght:size];
        
        anyNal=ANY_FRAME;
    }
    
}
 -(void)feedWithConfSub: (ExtractedFrame* )conf baseTime:(NSUInteger)time offsetF:(NSUInteger)frameOffset frameLenght:(NSUInteger)lenght
{
    //  CMSampleBufferRefHandler* cfg;
    OSStatus status;
    CMSampleBufferRef sampleBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    size_t data_h_size=sizeof (uint32_t);
    uint8_t header[32];
    [conf.data getBytes:header length:32];
    size_t offset = frameOffset;// sizeof(header4);
    
    // if(memcmp(header, NALU_ID, NALU_PARSE_SIZE))
    //  offset=0;
    
    
    size_t data_size =data_h_size +lenght;
    uint8_t *data  = malloc(data_size);
    // /!\ htonl to convert the size to network byte order
    
    
    //  []
    if(!data)
    {
        NSLog(@"~~~~~~~ MEM ALLOC FAILED   ~~~~~~~~" );
        return  ;
    }
    uint32_t dataLength32 = htonl (lenght);
    
    [conf.data getBytes:&data[data_h_size] range:NSMakeRange( offset, lenght)];
    memcpy (data, &dataLength32,data_h_size);
    //ok my buffer is now ready !
    /*
    NSLog(@" ####FEED WITH FRAME offset : %lu",offset);
    printf("-----> 8xHEX ::: ");
    for (int hex=0; hex<24;hex++) {
        printf("%x:",data[hex]);
    }
    printf("\n");
    */
    // create a block buffer from the IDR NALU
    status = CMBlockBufferCreateWithMemoryBlock(NULL, data,  // memoryBlock to hold buffered data
                                                data_size,  // block length of the mem block in bytes.
                                                kCFAllocatorNull, NULL,
                                                0, // offsetToData
                                                data_size,   // dataLength of relevant bytes, starting at offsetToData
                                                0, &blockBuffer);
    
    //  create  sample buffer from the block buffer,
    if(status == noErr)
    {
#pragma Config Buffer
   CMSampleTimingInfo timingInfo =
        {
            .presentationTimeStamp =CMTimeMake(conf.pts, 1000),// CMTimeMake((uint64_t) pts,1000),
            .duration =  CMTimeMake(1000 ,conf.fps),
            .decodeTimeStamp = kCMTimeInvalid//CMTimeMake((uint64_t) conf.dts,1000)
        };
        frameTimingInfo[0] = timingInfo;
    }
    
    status = CMSampleBufferCreate(kCFAllocatorDefault,
                                  blockBuffer, YES, NULL, NULL,
                                  _formatDesc, 1, /*1*/1,  frameTimingInfo, 0,
                                  NULL/*&sampleSize*/, &sampleBuffer);
    if(status == noErr)
    {
        
        
        
       [self render:sampleBuffer andPts:conf.pts andDts: conf.dts andFps:conf.fps basetime:time];
    }
    
    CFRelease(blockBuffer);
#pragma -
    if(sampleBuffer)
        CFRelease(sampleBuffer);
    free (data);
}


-(void)feedWithConf_ORG: (ExtractedFrame* )conf baseTime:(NSUInteger)time
{
    //  CMSampleBufferRefHandler* cfg;
    OSStatus status;
    CMSampleBufferRef sampleBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    size_t data_h_size=sizeof (uint32_t);
     uint8_t header[32];
    [conf.data getBytes:header length:32];
    size_t offset = NALU_PARSE_SIZE;// sizeof(header4);
    
   // if(memcmp(header, NALU_ID, NALU_PARSE_SIZE))
      //  offset=0;
    

    
    size_t data_size =data_h_size +[conf.data length]-offset;
    uint8_t *data  = malloc(data_size);
    // /!\ htonl to convert the size to network byte order
    
    
    //  []
    if(!data)
    {
        NSLog(@"~~~~~~~ MEM ALLOC FAILED   ~~~~~~~~" );
        return  ;
    }
    uint32_t dataLength32 = htonl ([conf.data length]-offset);
    
    [conf.data getBytes:&data[data_h_size] range:NSMakeRange( offset, [conf.data length]-offset)];
    memcpy (data, &dataLength32,data_h_size);
    //ok my buffer is now ready !
    /*
    NSLog(@" ####FEED WITH FRAME offset : %lu",offset);
    printf("-----> 8xHEX ::: ");
    for (int hex=0; hex<24;hex++) {
        printf("%x:",data[hex]);
    }
    printf("\n");
    */
    // create a block buffer from the IDR NALU
    status = CMBlockBufferCreateWithMemoryBlock(NULL, data,  // memoryBlock to hold buffered data
                                                data_size,  // block length of the mem block in bytes.
                                                kCFAllocatorNull, NULL,
                                                0, // offsetToData
                                                data_size,   // dataLength of relevant bytes, starting at offsetToData
                                                0, &blockBuffer);
    
    //  create  sample buffer from the block buffer,
    if(status == noErr)
    {
#pragma Config Buffer
        
        CMSampleTimingInfo timingInfo =
        {
            .presentationTimeStamp =CMTimeMake(conf.pts  , 1000),// CMTimeMake((uint64_t) pts,1000),
            .duration =  CMTimeMake(1000 ,conf.fps),
            .decodeTimeStamp = kCMTimeInvalid//CMTimeMake((uint64_t) conf.dts,1000)
        };
        frameTimingInfo[0] = timingInfo;
    }
 
    status = CMSampleBufferCreate(kCFAllocatorDefault,
                                  blockBuffer, YES, NULL, NULL,
                                  _formatDesc, 1, /*1*/1,  frameTimingInfo, 0,
                                  NULL/*&sampleSize*/, &sampleBuffer);
    if(status == noErr)
    {
       
      //  [self render:sampleBuffer andPts:conf.pts andDts: conf.dts andFps:conf.fps basetime:time];
    }
    
    CFRelease(blockBuffer);
#pragma -
    if(sampleBuffer)
        CFRelease(sampleBuffer);
    free (data);
}


/*****************************************/
/**************createPpsAndSpsParameter******************/
/*****************************************/


-(BOOL) createPpsAndSpsParameter:(NSData*)spsData  withSpsOffset:
(NSUInteger)spsOffset withSpsSize:
(NSUInteger)spsSize  andPpsData:
(NSData*)ppsData  withPpsoffset:
(NSUInteger)ppsOffset withPpsSize:
(NSUInteger)ppsSize


{
    OSStatus status;
    
    uint8_t *sps = malloc(spsSize);
    uint8_t *pps = malloc(ppsSize);
    
    
    if(!pps || !sps)
    {
        NSLog(@"~~~~~~~ MEM ALLOC FAILED   ~~~~~~~~" );
        free_parm(pps);
        free_parm(sps);
        return NO;
    }
    [spsData getBytes:sps range:NSMakeRange(spsOffset, spsSize)];
    [ppsData getBytes:pps range:NSMakeRange(ppsOffset, ppsSize)];
    
    
    // H264 parameters
    uint8_t*  parameterSetPointers[2] = {sps, pps};
    size_t parameterSetSizes[2] = {spsSize, ppsSize};

    
    if(_formatDesc){
        CFRelease(_formatDesc);
        _formatDesc=NULL;
    }
    
    
   // NSLog(@"~~~~~~~~~ CREATION of CMVideoFormatDescription spsOffset=%lu  spsSize:%lu, spsOffset:%lu ppsSize:%lu  ",spsOffset,spsSize,ppsOffset,ppsSize);
    
    
   // printf("~~~~~~~~~ CREATION of CMVideoFormatDescription HHHHHHHH SPS:");
   // for (int h=0;h<spsSize;h++) { //EX ::: 0:0:1:6:5:ff:ff:f3:
   //     printf("%x:",sps[h]);
   // }
   // printf("\n");
   // printf("~~~~~~~~~ CREATION of CMVideoFormatDescription HHHHHHHH PPS:");
  //  for (int h=0;h<ppsSize;h++) { //EX ::: 0:0:1:6:5:ff:ff:f3:
  //      printf("%x:",pps[h]);
  //  }
  //  printf("\n");
    status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2,
                                                                 (const uint8_t *const*)parameterSetPointers,
                                                                 parameterSetSizes,   4,
                                                                 &_formatDesc);
 #ifdef H264_READER_DBG
    NSLog(@"~~~~~~~~~ CREATION of CMVideoFormatDescription: %@", (status == noErr) ? @"successful!" : @"failed...");
 #endif
    free_parm(pps);
    free_parm(sps);
    
    if(status == noErr   ){
        
        
        return YES;
    }
    
    return NO;
}
-(BOOL)getNextNalu000:(ExtractedFrame*)nalu
        withType   :  (NSInteger*)type
       fromOffset  :(NSUInteger)from
       frameOffset :(NSUInteger *)frame
       frameLenght :(NSUInteger *)lenght
{
    NSUInteger read = from;
    NSUInteger searchOffset = NSIntegerMax ;
    NSUInteger searchSize=0;
    NSRange range;
    static NSData* magicStartData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        magicStartData = [NSData dataWithBytesNoCopy:(void*)NALU_ID length:3 freeWhenDone:!NO];
    });
    
    uint8_t nal_id;;
    
    
    while(YES){
        if(read>=[nalu.data length]  )
            break;
       // NSLog(@"----- will  search on  nalu from %d to %d",read,  [nalu.data length]);
        
        range = [nalu.data rangeOfData:magicStartData options:0 range:NSMakeRange(read, [nalu.data length]-read)];
      //  NSLog(@"-----ENTRY  fnd nalu at:%ld",range.location );

        if (range.location != NSNotFound) {
            //   NSLog(@"----- fnd nalu at %d / %d",range.location, range.length);
            read =range.location +NALU_PARSE_SIZE;
            
            if(searchOffset == NSIntegerMax) // 1st
                searchOffset = range.location ;// (NSUInteger)search - (NSUInteger)buffer;
            else
                searchSize = range.location - searchOffset;
            
            if(searchOffset != NSIntegerMax && searchSize!=0)
            {
                
                // TRACE_BUFF
                [nalu.data getBytes:(void*)&nal_id range:NSMakeRange(searchOffset + NALU_PARSE_SIZE, 1)];
                nal_id&=NALU_ID_MASK;
                
             //   NSLog(@"~~~~~~~~~~~~>>find NALU TYPE :%x / inType:%ld @ %lu Lenght : %lu",nal_id,*type,searchOffset ,*lenght );

                if( (!type) || (*type == ANY_FRAME)  || ( *type == nal_id) ){
                     //    if(*type == ANY_FRAME && nal_id!=IFRAME && nal_id!=FRAME)
                    //   {
                    //     accept = NO;
                    
                    // }
                         *frame  = searchOffset+NALU_PARSE_SIZE;
                        *lenght = searchSize-NALU_PARSE_SIZE;
                        if(type && *type == ANY_FRAME) *type=nal_id;
                        /*if(PPS == (buffer[searchOffset + NALU_PARSE_SIZE] & NALU_ID_MASK) || SPS == (buffer[searchOffset + NALU_PARSE_SIZE] & NALU_ID_MASK))*/
                    //   NSLog(@"~~~~~~~~~~~~Find NALU TYPE :%d @ %lu Lenght : %lu",nal_id, *frame ,*lenght );
                      return YES;
                    
                }
                searchOffset= range.location;//next nal start
                searchSize=0;
                //*type=ANY_FRAME;
             //   NSLog(@"~~~~~~~~~~~~searche now from    %lu\n",read);

            }
            
        }else  {
            
            
            
            if(searchOffset != NSIntegerMax && searchSize==0)
            {
                searchSize = [nalu.data length] - searchOffset ;
                //  TRACE_BUFF
                [nalu.data getBytes:(void*)&nal_id range:NSMakeRange(searchOffset + NALU_PARSE_SIZE, 1)];
                nal_id&=NALU_ID_MASK;
                
                if( (!type) || (*type == ANY_FRAME)  || ( *type == nal_id) ){
                   //   NSLog(@"~~~~~~~~~~~~Find  LASTNALU TYPE :%d @ %lu Lenght : %lu",nal_id,searchOffset ,*lenght );

                    *frame  = searchOffset+NALU_PARSE_SIZE;
                    *lenght = searchSize-NALU_PARSE_SIZE;
                    if(type && *type == ANY_FRAME) *type=nal_id;
                    /*if(PPS == (buffer[searchOffset + NALU_PARSE_SIZE] & NALU_ID_MASK) || SPS == (buffer[searchOffset + NALU_PARSE_SIZE] & NALU_ID_MASK))*/
                    //     NSLog(@"~~~~~~~~~~~~Find  LASTNALU TYPE :%d @ %lu Lenght : %lu",nal_id,searchOffset ,*lenght );
                     return YES;
                }
            }
            break;
            
            
            break; //EOS
        }
        
        
    }
    
    return NO;
}

-(BOOL)getNextNalu:(ExtractedFrame*)nalu
       withType   :  (NSInteger*)type
      fromOffset  :(NSUInteger)from
      frameOffset :(NSUInteger *)frame
      frameLenght :(NSUInteger *)lenght
{
    NSUInteger read = from;
    NSUInteger searchOffset = NSIntegerMax ;
    NSUInteger searchSize=0;
    NSRange range;
    static NSData* magicStartData = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        magicStartData = [NSData dataWithBytesNoCopy:(void*)NALU_ID length:3 freeWhenDone:NO];
 
    });
    uint8_t nal_id;
    while(YES){
        if(read>=[nalu.data length] )
            break;
      //   NSLog(@"---S-- will search on  nalu from %lu to %lu",read,  [nalu.data length]);
        
        
        range = [nalu.data  rangeOfData:magicStartData options:0 range:NSMakeRange(read, [nalu.data  length]-read)];
        
        if (range.location != NSNotFound) {
             //  NSLog(@"---S-- fnd nalu at %d / %d",range.location, range.length);
            read =range.location +NALU_PARSE_SIZE;
            
            if(searchOffset == NSIntegerMax) // 1st
                searchOffset = range.location ;// (NSUInteger)search - (NSUInteger)buffer;
            else
                searchSize = range.location - searchOffset;
            
            if(searchOffset != NSIntegerMax && searchSize!=0)
            {
               
                
                // TRACE_BUFF
                char dummy[1];
// [nalu.data at]
                [nalu.data  getBytes:(void*)dummy range:NSMakeRange(searchOffset + NALU_PARSE_SIZE, 1)];
                ///  printf("%x:",0xff&dummy[0]);
                  nal_id =dummy[0] &NALU_ID_MASK;
                
  
 
                if( (!type) || (*type == ANY_FRAME)  || ( *type == nal_id) ){
                    BOOL accept = YES;
                  
                    if(accept){
                        *frame  = searchOffset+NALU_PARSE_SIZE;
                        *lenght = searchSize-NALU_PARSE_SIZE;
                        if(type && *type == ANY_FRAME) *type=nal_id;
                        /*if(PPS == (buffer[searchOffset + NALU_PARSE_SIZE] & NALU_ID_MASK) || SPS == (buffer[searchOffset + NALU_PARSE_SIZE] & NALU_ID_MASK))*/
                      //   uint8_t dump[*lenght];
                       // [nalu.data getBytes:dump range:NSMakeRange(searchOffset + NALU_PARSE_SIZE, *lenght)];
                        return YES;
                    }
                }
                searchOffset=range.location;//next nal start
                searchSize=0;
            }
            
        }else {
            if(searchOffset != NSIntegerMax && searchSize==0)
            {
                searchSize = [nalu.data  length] - searchOffset ;
                //  TRACE_BUFF
                [nalu.data  getBytes:(void*)&nal_id range:NSMakeRange(searchOffset + NALU_PARSE_SIZE, 1)];
                nal_id&=NALU_ID_MASK;
                
                if( (!type) || (*type == ANY_FRAME)  || ( *type == nal_id) ){
                    *frame  = searchOffset+NALU_PARSE_SIZE;
                    *lenght = searchSize-NALU_PARSE_SIZE;
                    if(type && *type == ANY_FRAME) *type=nal_id;
                    /*if(PPS == (buffer[searchOffset + NALU_PARSE_SIZE] & NALU_ID_MASK) || SPS == (buffer[searchOffset + NALU_PARSE_SIZE] & NALU_ID_MASK))*/
                   // NSLog(@"~~~~~~~~~~~~Find  LASTNALU TYPE :%d @ %lu Lenght : %lu",nal_id,searchOffset ,*lenght );
                    return YES;
                }
            }
            break;//End of nalu
            
        }
        
        
    }
    
    return NO;
}



/*****************************************/
/*****************************************/
/*****************************************/



@end
#undef set_parm
#undef free_parm
#undef dump_Parm
