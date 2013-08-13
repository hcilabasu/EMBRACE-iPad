//
//  AppDelegate.m
//  EMBRACE_Client
//
//  Created by Andreea Danielescu on 4/25/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    //Get the documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // Create this path in the app sandbox (it doesn't exist by default)
    NSFileManager *fileManager = [NSFileManager defaultManager];

    //Remove old epub files. This is for debugging purposes only.
    if(DEBUG) {
        NSError *error = nil;
        NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:&error];
        if (error == nil) {
            for (NSString *path in directoryContents) {
                NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:path];
                BOOL removeSuccess = [fileManager removeItemAtPath:fullPath error:&error];
                if (!removeSuccess) {
                    NSLog(@"could not remove files in document directory");
                }
            }
        }
    }
    
    // Copy the farm.epub file from the app bundle to the application support directory
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"farm" ofType:@"epub"];
    NSString *newPath = [documentsDirectory stringByAppendingPathComponent:@"/ASU/IntroToFarm"];
    
    [fileManager createDirectoryAtPath:newPath  withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString* filename = [@"/" stringByAppendingString:[filePath lastPathComponent]];
    newPath = [newPath stringByAppendingString:filename];
    [fileManager copyItemAtPath:filePath toPath:newPath error:nil];
    
    //Copy the house.epub file from the app bundle to the application support directory
    filePath = [[NSBundle mainBundle] pathForResource:@"house" ofType:@"epub"];
    newPath = [documentsDirectory stringByAppendingPathComponent:@"/ASU/IntroToHouse"];
    
    [fileManager createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    filename = [@"/" stringByAppendingString:[filePath lastPathComponent]];
    newPath = [newPath stringByAppendingString:filename];
    [fileManager copyItemAtPath:filePath toPath:newPath error:nil];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
