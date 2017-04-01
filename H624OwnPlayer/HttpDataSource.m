//
//  HttpDataSource.m
//  XMediaPlayer
//
//  Created by tyazid on 25/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "HttpDataSource.h"
#define TIMEOUT 10
@interface HttpDataSource ()

@end
//-(instancetype)initWithUri: (NSString* )uri NS_DESIGNATED_INITIALIZER;

@implementation HttpDataSource
BOOL initializing;
NSUInteger dataPos;
-(instancetype)initWithUri:(NSString *)uri
{
    if(self = [super init])
    {
        _uri=uri;
        _url = [NSURL URLWithString:uri];
        _httpData=Nil;
        dataPos=_dataSize=0;
        _state = IDLE;
        if(!_url){
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[NSString stringWithFormat: @"cannot create url from %@",uri]
                                         userInfo:nil];
            return Nil;
        }
        initializing = NO;
    }
    return self;
}

-(void)close{
}
-(void)open:(DataSourceOpenCb)cb
{
    if(![self url]){
        cb(NO,@"no url is set");
        return;
    }

    NSMutableURLRequest* request =
    [[NSMutableURLRequest alloc] initWithURL:_url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:TIMEOUT];
    if(!request){
        cb(NO,@"not able de create request ");
        return;
    }
    _state = LOADING;

    NSLog(@"request  %@",request);
    
    NSLog(@"nsUrl  %@",_url);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *gettask  = [session dataTaskWithRequest:request completionHandler:
                                      ^(NSData *   data, NSURLResponse *   response, NSError *   error) {
                                          NSLog(@"GET COMPLETION ");
                                          
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              NSString* errormsg = nil;
                                              if(error){
                                                  NSLog(@"DISPATCH::GET ERROR  ");
                                                  errormsg=error.localizedDescription;
                                                  
                                              }else {
                                                  if ([response isKindOfClass:[NSHTTPURLResponse class]]){
                                                      NSHTTPURLResponse*http_response=(NSHTTPURLResponse*)response;
                                                      if([http_response statusCode]!= 200)
                                                      {
                                                          errormsg= [NSString stringWithFormat:@"Http error %ld ",(long)[http_response statusCode]];
                                                      }
                                                  }
                                              }
                                              if(errormsg){
                                                  if(cb){
                                                      cb(NO,errormsg);
                                                      _state = FAILED;

                                                  }
                                              } else {
                                                  NSLog(@"GET COMPLETION SUCESS Data L : %lu ", (unsigned long)[data length] );
                                                  _httpData =data;
                                                  _dataSize=[data length];
                                                  dataPos=0;
                                                _state = LOADED;
                                                  cb(YES,Nil);
                                              }
                                          });
                                      }  ];
    
    [gettask resume];

 }

-(NSInteger)read:(uint8_t*)buffer withOffset:(NSUInteger)offset andSize:(NSUInteger)size{
    return [ self read:buffer fromDataPosition:0 withOffset:offset andSize:size];
}

-(NSInteger)read:(uint8_t *)buffer fromDataPosition:(NSUInteger)dataPos withOffset:(NSUInteger)offset andSize:(NSUInteger)size
{
    if(_state != LOADED){
        NSLog(@"!!!!! data not avaialble");
        return -1;
    }

    NSInteger toRead = -1;
    if([self httpData]){
        if(dataPos <  [self dataSize]  ){
            toRead = MIN(size, [self dataSize] - dataPos);
            if ( toRead > 0 )
                [[self httpData] getBytes:(void *)&buffer[offset] range:NSMakeRange(dataPos, toRead) ];
        }
    }
    return toRead;
}


@end
