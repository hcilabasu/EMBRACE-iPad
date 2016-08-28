//
//  PlayAudioFile.m
//  EMBRACE
//
//  Created by James Rodriguez on 10/21/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "PlayAudioFile.h"
#import "ServerCommunicationController.h"

@interface PlayAudioFile()<AVAudioPlayerDelegate>

@property (nonatomic, strong) NSMutableArray *audioQueue;

@end


@implementation PlayAudioFile
@synthesize syn;
@synthesize PmviewController;
@synthesize audioPlayer;
@synthesize audioPlayerAfter;
@synthesize audioDuration;
@synthesize audioAfterDuration;

-(void)initPlayer: (NSString*) audioFilePath
{
    NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], audioFilePath];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    NSError *error;
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&error];
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:soundFileURL options:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], AVURLAssetPreferPreciseDurationAndTimingKey, nil]];
    self.audioDuration = CMTimeGetSeconds(asset.duration);
}

/* Plays text-to-speech audio in a given language in a certain time */
-(void)playWordAudioTimed:(NSTimer *) wordAndLang {
    NSDictionary *wrapper = (NSDictionary *)[wordAndLang userInfo];
    NSString * obj1 = [wrapper objectForKey:@"Key1"];
    NSString * obj2 = [wrapper objectForKey:@"Key2"];
    
    AVSpeechUtterance *utteranceEn = [[AVSpeechUtterance alloc]initWithString:obj1];
    utteranceEn.rate = AVSpeechUtteranceMaximumSpeechRate/7;
    utteranceEn.voice = [AVSpeechSynthesisVoice voiceWithLanguage:obj2];
    NSLog(@"Sentence: %@", obj1);
    NSLog(@"Volume: %f", utteranceEn.volume);
    [syn speakUtterance:utteranceEn];
}

/* Plays an audio file after a given time defined in the timer call*/
-(void)playAudioFileTimed:(NSTimer *) path {
    NSDictionary *wrapper = (NSDictionary *)[path userInfo];
    NSString * obj1 = [wrapper objectForKey:@"Key1"];
    
    NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], obj1];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    NSError *audioError;
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&audioError];
    self.audioPlayerAfter = nil;
    
    if (self.audioPlayer == nil)
    {
        NSLog(@"%@",[audioError description]);
    }
    else
    {
        [self.audioPlayer prepareToPlay];
        [self.audioPlayer play];
    }
}

/* Plays an audio file at a given path */
-(BOOL) playAudioFile:(UIViewController*) viewController : (NSString*) path {
    
    self.PmviewController = viewController;
    [viewController.view setUserInteractionEnabled:NO];
    
    [self initPlayer:path];
    self.audioPlayerAfter = nil;
    self.audioPlayer.delegate = self;
    
    if (self.audioPlayer == nil)
    {
        [PmviewController.view setUserInteractionEnabled:YES];
        return false;
    }
    else
    {
        [self.audioPlayer prepareToPlay];
        [self.audioPlayer play];
        return true;
    }
}

-(void) stopPlayAudioFile
{
    [self.audioPlayer stop];
    [self.audioPlayerAfter stop];
    self.audioPlayer = nil;
    self.audioPlayerAfter = nil;
}


- (void)playAudioInSequence:(NSArray *)audioList :(UIViewController *)controller {
    
    // Return if there is already a queue working
    if ([self.audioQueue count] > 0) {
        return;
    }
    
    self.PmviewController = controller;
    NSMutableArray *array = [NSMutableArray array];
    for (NSString *path in audioList) {
        NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], path];
        NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
        [array addObject:soundFileURL];
    }
    self.audioQueue = array;
    [self playNextAudio];
}

- (void)playNextAudio {
    
    if ([self.audioQueue count] > 0) {
        
        NSURL *soundFileURL = [self.audioQueue objectAtIndex:0];
        NSError *audioError;

        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&audioError];
        self.audioPlayer.delegate = self;
        self.audioPlayerAfter = nil;
        
        if (self.audioPlayer == nil) {
            self.audioQueue = nil;
            NSLog(@"Audio error %@",[audioError description]);
            [PmviewController.view setUserInteractionEnabled:YES];
        }
        else {
            [PmviewController.view setUserInteractionEnabled:NO];
            [self.audioPlayer prepareToPlay];
            AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:soundFileURL options:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], AVURLAssetPreferPreciseDurationAndTimingKey, nil]];
            self.audioDuration = CMTimeGetSeconds(asset.duration);
            [self.audioPlayer play];
            [self.audioQueue removeObjectAtIndex:0];
        }
    }
    else
    {
        [PmviewController.view setUserInteractionEnabled:YES];
    }
}


/* Plays one audio file after the other */
-(BOOL) playAudioInSequence: (UIViewController*) viewController : (NSString*) path :(NSString*) path2 {
   
        self.PmviewController = viewController;
        [PmviewController.view setUserInteractionEnabled:NO];
    
        NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], path];
        NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
        NSString *soundFilePath2 = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], path2];
        NSURL *soundFileURL2 = [NSURL fileURLWithPath:soundFilePath2];
    
        NSError *audioError1;
        NSError *audioError2;
    
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&audioError1];
        self.audioPlayerAfter = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL2 error:&audioError2];
        
        //may need to pass in which ever class is calling this function
        self.audioPlayer.delegate = self;
    
        if (self.audioPlayer == nil || self.audioPlayerAfter == nil)
        {
            NSLog(@"%@",[audioError1 description]);
            NSLog(@"%@",[audioError2 description]);
            self.audioPlayer = nil;
            self.audioPlayerAfter = nil;
            [PmviewController.view setUserInteractionEnabled:YES];
            return false;
        }
        else
        {
            [self.audioPlayer prepareToPlay];
            
            AVURLAsset *asset1 = [[AVURLAsset alloc] initWithURL:soundFileURL options:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], AVURLAssetPreferPreciseDurationAndTimingKey, nil]];
            self.audioDuration = CMTimeGetSeconds(asset1.duration);
            
            AVURLAsset *asset2 = [[AVURLAsset alloc] initWithURL:soundFileURL2 options:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], AVURLAssetPreferPreciseDurationAndTimingKey, nil]];
            self.audioAfterDuration = CMTimeGetSeconds(asset2.duration);
            
            [self.audioPlayer play];
            return true;
        }
}

/* Delegate for the AVAudioPlayer */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag  {
    
    if ([self.audioQueue count] > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,500000000), dispatch_get_main_queue(), ^{
            [self playNextAudio];
        });
        
    }
    else
    {
        //make sure we have an instance of the PMViewController
        if(PmviewController != nil)
        {
            //reenable user interaction after second audio file finishes playing if it exists otherwise just renable user interaction after first audio file finishes playing
            if (self.audioPlayerAfter != nil) {
                
                [self.audioPlayerAfter prepareToPlay];
                [self.audioPlayerAfter play];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,self.audioAfterDuration*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [PmviewController.view setUserInteractionEnabled:YES];
                });
            }
            else
            {
                [PmviewController.view setUserInteractionEnabled:YES];
            }
        }
    }
}

/* Checks if audioPlayer and audioPlayerAfter is current playing audio */
- (BOOL) isAudioLeftInSequence
{
    if ((self.audioPlayer != Nil && self.audioPlayerAfter != nil) &&
        (self.audioPlayer.isPlaying || self.audioPlayerAfter.isPlaying))
    {
        return true;
    }
    else
    {
        return false;
    }
}

#pragma mark - Responding to gestures

/*
 * Plays a noise for error feedback if the user performs a manipulation incorrectly
 */
- (IBAction)playErrorNoise {
    AudioServicesPlaySystemSound(1053);
}

- (IBAction)playAutoCompleteStepNoise {
    AudioServicesPlaySystemSound(1054);
}

- (void)textToSpeech:(NSString *)text {
    syn = [[AVSpeechSynthesizer alloc] init];
    AVSpeechUtterance *utteranceEn = [[AVSpeechUtterance alloc]initWithString:text];
    utteranceEn.rate = AVSpeechUtteranceMaximumSpeechRate/7;
    //utteranceEn.voice = [AVSpeechSynthesisVoice voiceWithLanguage:obj2];
    [syn speakUtterance:utteranceEn];
}

@end
