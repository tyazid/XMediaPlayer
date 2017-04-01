//
//  HttpDataSource.h
//  XMediaPlayer
//
//  Created by tyazid on 25/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XPCore.h"
@interface HttpDataSource : NSObject<MediaDataSource>
@property (nonatomic,readonly) NSURL* url;
@property (nonatomic,readonly) NSString* uri;
@property (readonly) DataSourceState state ;
@property (atomic,readonly) NSData * httpData;

@property (readonly) NSUInteger dataSize ;


-(instancetype) init __attribute__((unavailable("use initWithUri instead")));
-(instancetype)initWithUri: (NSString* )uri NS_DESIGNATED_INITIALIZER;

@end
