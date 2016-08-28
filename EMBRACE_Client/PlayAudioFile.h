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

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) AVAudioPlayer *audioPlayerAfter; // Used to play sounds after the first audio player has finished playing
@property (nonatomic, strong) AVSpeechSynthesizer *syn;
@property (nonatomic, weak) UIViewController *PmviewController;
@property (nonatomic) Float64 audioDuration;
@property (nonatomic) Float64 audioAfterDuration;

- (void)initPlayer:(NSString *)audioFilePath;
- (void)playWordAudioTimed:(NSTimer *)wordAndLang;
- (void)playAudioFileTimed:(NSTimer *)path;
- (BOOL)playAudioFile:(UIViewController *)viewController :(NSString *)path;
- (BOOL)playAudioInSequence:(UIViewController*)viewController :(NSString *)path :(NSString*)path2;
- (void)stopPlayAudioFile;
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;
- (IBAction)playErrorNoise;
- (IBAction)playAutoCompleteStepNoise;
- (void)textToSpeech:(NSString *)text;
- (void)playAudioInSequence:(NSArray *)audioList :(UIViewController *)controller;
- (BOOL)isAudioLeftInSequence;

@end
