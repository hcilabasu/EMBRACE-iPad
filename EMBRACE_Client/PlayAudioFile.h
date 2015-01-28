//
//  PlayAudioFile.h
//  EMBRACE
//
//  Created by James Rodriguez on 10/21/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVFoundation/AVSpeechSynthesis.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface PlayAudioFile : NSObject

@property (strong) AVAudioPlayer *audioPlayer;
@property (strong) AVAudioPlayer *audioPlayerAfter; // Used to play sounds after the first audio player has finished playing
@property (nonatomic, strong) AVSpeechSynthesizer* syn;

-(void)playWordAudioTimed:(NSTimer *) wordAndLang;
-(void)playAudioFileTimed:(NSTimer *) path;
-(void) playAudioFile:(NSString*) path;
-(void) playAudioInSequence:(NSString*) path :(NSString*) path2;
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;
-(IBAction) playErrorNoise: (NSString *) bookTitle : (NSString *) chapterTitle : (NSString *) currentPage : (NSUInteger) currentSentence : (NSUInteger) currentStep;
-(void) textToSpeech: (NSString *) text;

@end
