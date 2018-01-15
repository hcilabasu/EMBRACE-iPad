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
//
//    //Remove old epub files. This is for debugging purposes only.
//    if(DEBUG) {
//        NSError *error = nil;
//        NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:&error];
//        if (error == nil) {
//            for (NSString *path in directoryContents) {
//                //EPUB files are located in a folder called "ASU"
//                if ([path isEqualToString:@"ASU"]) {
//                    NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:path];
//                    BOOL removeSuccess = [fileManager removeItemAtPath:fullPath error:&error];
//                    if (!removeSuccess) {
//                        NSLog(@"could not remove files in document directory");
//                    }
//                }
//            }
//        }
//    }
    
    //Strings used for copying epub files
    NSString* filePath;
    NSString* newPath;
    NSString* filename;
    
    /* //NOTE: Currently we are only using bestFarm.epub and circulatory.epub
    //Copy the farm.epub file from the app bundle to the application support directory
    filePath = [[NSBundle mainBundle] pathForResource:@"farm" ofType:@"epub"];
    newPath = [documentsDirectory stringByAppendingPathComponent:@"/ASU/IntroToFarm"];
    
    [fileManager createDirectoryAtPath:newPath  withIntermediateDirectories:YES attributes:nil error:nil];
    
    filename = [@"/" stringByAppendingString:[filePath lastPathComponent]];
    newPath = [newPath stringByAppendingString:filename];
    [fileManager copyItemAtPath:filePath toPath:newPath error:nil];*/
    
    
    //Copy the monkey.epub file from the app bundle to the application support directory
    filePath = [[NSBundle mainBundle] pathForResource:@"monkey" ofType:@"epub"];
    newPath = [documentsDirectory stringByAppendingPathComponent:@"/ASU/IntroTo1Monkey"];
    
    [fileManager createDirectoryAtPath:newPath  withIntermediateDirectories:YES attributes:nil error:nil];
    
    filename = [@"/" stringByAppendingString:[filePath lastPathComponent]];
    newPath = [newPath stringByAppendingString:filename];
    [fileManager copyItemAtPath:filePath toPath:newPath error:nil];
    
    //Copy the bestFarm.epub file from the app bundle to the application support directory
    filePath = [[NSBundle mainBundle] pathForResource:@"bestFarm" ofType:@"epub"];
    newPath = [documentsDirectory stringByAppendingPathComponent:@"/ASU/IntroToBestFarm"];
    
    [fileManager createDirectoryAtPath:newPath  withIntermediateDirectories:YES attributes:nil error:nil];
    
    filename = [@"/" stringByAppendingString:[filePath lastPathComponent]];
    newPath = [newPath stringByAppendingString:filename];
    [fileManager copyItemAtPath:filePath toPath:newPath error:nil];
    
    //Copy the house.epub file from the app bundle to the application support directory*/
    filePath = [[NSBundle mainBundle] pathForResource:@"house" ofType:@"epub"];
    newPath = [documentsDirectory stringByAppendingPathComponent:@"/ASU/IntroToHouse"];
    
    [fileManager createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    filename = [@"/" stringByAppendingString:[filePath lastPathComponent]];
    newPath = [newPath stringByAppendingString:filename];
    [fileManager copyItemAtPath:filePath toPath:newPath error:nil];
    
    //Copy the circulatory.epub file from the app bundle to the application support directory
    filePath = [[NSBundle mainBundle] pathForResource:@"circulatory" ofType:@"epub"];
    newPath = [documentsDirectory stringByAppendingPathComponent:@"/ASU/IntroToCirculatory"];
    
    [fileManager createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    filename = [@"/" stringByAppendingString:[filePath lastPathComponent]];
    newPath = [newPath stringByAppendingString:filename];
    [fileManager copyItemAtPath:filePath toPath:newPath error:nil];
    
    //Copy the disasters.epub file from the app bundle to the application support directory
    filePath = [[NSBundle mainBundle] pathForResource:@"disasters" ofType:@"epub"];
    newPath = [documentsDirectory stringByAppendingPathComponent:@"/ASU/IntroToDisasters"];
    
    [fileManager createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    filename = [@"/" stringByAppendingString:[filePath lastPathComponent]];
    newPath = [newPath stringByAppendingString:filename];
    [fileManager copyItemAtPath:filePath toPath:newPath error:nil];
    
    //Copy the bottled.epub file from the app bundle to the application support directory
    filePath = [[NSBundle mainBundle] pathForResource:@"bottled" ofType:@"epub"];
    newPath = [documentsDirectory stringByAppendingPathComponent:@"/ASU/IntroToBottledJoy"];
    
    [fileManager createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    filename = [@"/" stringByAppendingString:[filePath lastPathComponent]];
    newPath = [newPath stringByAppendingString:filename];
    [fileManager copyItemAtPath:filePath toPath:newPath error:nil];
    
    filePath = [[NSBundle mainBundle] pathForResource:@"physics" ofType:@"epub"];
    newPath = [documentsDirectory stringByAppendingPathComponent:@"/ASU/IntroToPhysics"];
    
    [fileManager createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    filename = [@"/" stringByAppendingString:[filePath lastPathComponent]];
    newPath = [newPath stringByAppendingString:filename];
    [fileManager copyItemAtPath:filePath toPath:newPath error:nil];
    
    filePath = [[NSBundle mainBundle] pathForResource:@"celebration" ofType:@"epub"];
    newPath = [documentsDirectory stringByAppendingPathComponent:@"/ASU/IntroToCelebration"];
    
    [fileManager createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    filename = [@"/" stringByAppendingString:[filePath lastPathComponent]];
    newPath = [newPath stringByAppendingString:filename];
    [fileManager copyItemAtPath:filePath toPath:newPath error:nil];
    
    filePath = [[NSBundle mainBundle] pathForResource:@"native" ofType:@"epub"];
    newPath = [documentsDirectory stringByAppendingPathComponent:@"/ASU/IntroToNative"];
     [fileManager createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    filename = [@"/" stringByAppendingString:[filePath lastPathComponent]];
    newPath = [newPath stringByAppendingString:filename];
    [fileManager copyItemAtPath:filePath toPath:newPath error:nil];
    
    
    
    filePath = [[NSBundle mainBundle] pathForResource:@"festivals" ofType:@"epub"];
    newPath = [documentsDirectory stringByAppendingPathComponent:@"/ASU/IntroTFF"];
    [fileManager createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:nil];
    filename = [@"/" stringByAppendingString:[filePath lastPathComponent]];
    newPath = [newPath stringByAppendingString:filename];
    [fileManager copyItemAtPath:filePath toPath:newPath error:nil];
    
    
    return YES;
}

@end
