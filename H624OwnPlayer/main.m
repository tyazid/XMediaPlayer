//
//  main.m
//  H624OwnPlayer
//
//  Created by tyazid on 17/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "HttpDataSource.h"
#import "TsExtractor.h"

int main(int argc, char * argv[]) {
    /*
    HttpDataSource* source = [[HttpDataSource alloc] initWithUri:@"http://10.60.61.224/avatar.ts"];
    TsExtractor* tsExtractor = [TsExtractor new];
    [tsExtractor setDataSource:source];
    
    */
    
   /* NSLog(@" DATA SRC : %lu", (unsigned long)[source dataSize]);
    [source open:^(BOOL success, NSString *errMsg){
        NSLog(@" OPEN URL SUCCESS : %d, msg : %@",success, errMsg);
    }];*/    @autoreleasepool {
       

        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
