//
//  MediaDataExtractor.m
//  XMediaPlayer
//
//  Created by tyazid on 26/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "MediaDataExtractor.h"
#import "XPUtil.h"
//#define  MEDIA_DATA_EXTRACTOR_DBG
@interface MediaDataExtractor()
@property  NSMutableDictionary<NSNumber*,id<MediaConsumer>>* consumers;
@end
@implementation MediaDataExtractor
BOOL dataAvailble;
id<MediaDataSource> myDatasource;
-(BOOL)extracted:(uint8_t*)buffer withSize:(NSUInteger)size{
    return YES;
}





-(void)seek:(NSUInteger)position{
}

-(BOOL)setData:(NSData*)data{
    
    
    dataAvailble = [self extracted:[data bytes] withSize:[data length]];
#ifdef MEDIA_DATA_EXTRACTOR_DBG
    NSLog(@"---> Media Data extractor AVAILABLE : %lu bytes",[data length]);
#endif
    
    return dataAvailble?YES:NO;
}

-(BOOL)setDataSource:(id<MediaDataSource>)dataSource {
    
    if(dataSource   && [ (myDatasource = dataSource) state] != FAILED)
    {
#ifdef MEDIA_DATA_EXTRACTOR_DBG
        NSLog(@"## TS EXTRACTOR :: DATA SOURCE PARM STATE : %ld ", (long)[myDatasource state]);
#endif
        if([(myDatasource = dataSource) state] == IDLE)
        {
            [myDatasource open:^(BOOL success, NSString *errMsg){
#ifdef MEDIA_DATA_EXTRACTOR_DBG
                NSLog(@" OPEN URL SUCCESS : %d, msg : %@",success, errMsg);
#endif
                if(success)
                {
                    //   uint8_t *bytes = (  uint8_t*)[data bytes];
                    NSUInteger lenght =[myDatasource dataSize] ;
                    uint8_t *bytes = (  uint8_t*)malloc(lenght);
#ifdef MEDIA_DATA_EXTRACTOR_DBG
                    NSLog(@" OPEN URL SUCCESS : DATA.L=%ld",(long)lenght);
#endif
                    
                    if(bytes)
                    {
                        if([myDatasource read:bytes withOffset:0 andSize:lenght] == lenght)
                        {
                            
                            dataAvailble = [self extracted:bytes withSize:lenght];
#ifdef MEDIA_DATA_EXTRACTOR_DBG
                            NSLog(@"---> Media Data extractor AVAILABLE : %lu bytes",lenght);
#endif
                            
                        }
                        free(bytes);
                        bytes = Nil;
                    }
                }
            }];
        }
        return YES;
    }
    return NO;
}



//must call init first
-(NSDictionary<NSNumber*,id<MediaReader>>*)getReaders{
    NSDictionary<NSNumber*,id<MediaReader>>* r = Nil;
    return r;
}

-(void)setMediaConsumer :(id<MediaConsumer>)mediaConsumer
{
    if(![self  consumers])
        [ self setConsumers: [NSMutableDictionary new]];
    [[self consumers ] setObject:mediaConsumer forKey:[NSNumber numberWithInteger:[mediaConsumer type]]];
}

-(BOOL)setConsumerFor:(id<MediaReader>)reader{
    dispatch_queue_t queue = dispatch_queue_create("xplayer", NULL);
    dispatch_async(queue, ^{
        //code to be executed in the background
        MediaConsumerType ctype = [XPUtil toMediaConsumerType:[reader type]];
        id<MediaConsumer> consumer;
        if([self  consumers] && (consumer = [[self  consumers] objectForKey:[NSNumber numberWithInteger:ctype]] ))
        {
            [reader setConsumeFrame:consumer];
            return  ;
        }
    });
    
    return YES;
    
}

@end
