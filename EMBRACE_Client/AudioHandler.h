//
//  AudioHandler.h
//  EMBRACE
//
//  Created by Shang Wang on 3/19/18.
//  Copyright © 2018 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ManipulationViewController;
@class ActivitySequenceController;
@interface AudioHandler : NSObject
@property (nonatomic, strong) ManipulationViewController* parentManipulaitonCtr;
- (NSString *)fileNameForCurrentSentence;
- (void)playCurrentSentenceAudio;
@end
