//
//  M3U8SegmentInfoList.m
//  M3U8Kit
//
//  Created by Oneday on 13-1-11.
//  Copyright (c) 2013年 0day. All rights reserved.
//

#import "M3U8SegmentInfoList.h"

@interface M3U8SegmentInfoList ()

@property (nonatomic, strong) NSMutableArray *segmentInfoList;

@end

@implementation M3U8SegmentInfoList

- (id)init {
    if (self = [super init]) {
        self.segmentInfoList = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Getter && Setter
- (NSUInteger)count {
    return [self.segmentInfoList count];
}

#pragma mark - Public
- (void)addSegementInfo:(M3U8SegmentInfo *)segment {
    if (segment) {
        [self.segmentInfoList addObject:segment];
    }
}

- (M3U8SegmentInfo *)segmentInfoAtIndex:(NSUInteger)index {
    if (index >= [self.segmentInfoList count]){
         NSLog(@"%@",[NSThread callStackSymbols]);
    @throw   [NSException
              exceptionWithName:NSRangeException reason:[NSString stringWithFormat:@"i  M3U8SegmentInfoList segmentInfoAtIndex ndex:%lu, range:0-%lu",index,[self.segmentInfoList count]-1]
              userInfo:nil];
    }
    return [self.segmentInfoList objectAtIndex:index];
}
- (M3U8SegmentInfo *)segmentInfoWithNumber:(NSUInteger)number {
    for (M3U8SegmentInfo * s in _segmentInfoList) {
        if(s.number == number)
            return s;
    }
    return Nil;
}
- (NSString *)description {
    return [NSString stringWithFormat:@"%@", self.segmentInfoList];
}

@end
