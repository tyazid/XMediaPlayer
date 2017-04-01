//
//  AppDelegate.h
//  H624OwnPlayer
//
//  Created by tyazid on 17/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
/////

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

