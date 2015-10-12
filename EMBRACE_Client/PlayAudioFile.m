//
//  PlayAudioFile.m
//  EMBRACE
//
//  Created by James Rodriguez on 10/21/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "PlayAudioFile.h"
#import "ServerCommunicationController.h"


@implementation PlayAudioFile
@synthesize syn;
@synthesize PmviewController;

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
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&audioError];
    
    if (_audioPlayer == nil)
        NSLog(@"%@",[audioError description]);
    else
        [_audioPlayer play];
}

/* Plays an audio file at a given path */
-(void) playAudioFile:(UIViewController*) viewController : (NSString*) path {
    NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], path];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    NSError *audioError;
    
    PmviewController = [[UIViewController alloc] init];
    PmviewController = viewController;
    [viewController.view setUserInteractionEnabled:NO];
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&audioError];
    _audioPlayerAfter = nil;
    _audioPlayer.delegate = self;
    
    if (_audioPlayer == nil)
    {
        NSLog(@"%@",[audioError description]);
        [PmviewController.view setUserInteractionEnabled:YES];
    }
    else
        [_audioPlayer play];
}

/* Plays one audio file after the other */
-(void) playAudioInSequence: (UIViewController*) viewController : (NSString*) path :(NSString*) path2 {
    NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], path];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    NSError *audioError;
    
    NSString *soundFilePath2 = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], path2];
    NSURL *soundFileURL2 = [NSURL fileURLWithPath:soundFilePath2];
    
    PmviewController = [[UIViewController alloc] init];
    PmviewController = viewController;
    [viewController.view setUserInteractionEnabled:NO];
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&audioError];
    _audioPlayerAfter = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL2 error:&audioError];
    
    //may need to pass in which ever class is calling this function
    _audioPlayer.delegate = self;
    
    if (_audioPlayer == nil)
    {
        NSLog(@"%@",[audioError description]);
        [PmviewController.view setUserInteractionEnabled:YES];
    }
    else
        [_audioPlayer play];
}

/* Delegate for the AVAudioPlayer */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag  {
    
    [_audioPlayerAfter play];
    
    if(PmviewController != nil)
    {
        [PmviewController.view setUserInteractionEnabled:YES];
    }
}


#pragma mark - Responding to gestures
/*
 * Plays a noise for error feedback if the user performs a manipulation incorrectly
 */
-(IBAction) playErrorNoise: (NSString *) storyName : (NSString *) chapterFilePath : (NSString*) pageFilePath : (NSInteger) sentenceNumber : (NSString *) sentenceText : (NSInteger) stepNumber : (NSInteger) ideaNumber
{
   
    AudioServicesPlaySystemSound(1053);
    
    //Logging added by James for Error Noise
    [[ServerCommunicationController sharedManager] logComputerPlayAudio: @"Play Error Audio" : @"NULL" :@"Error Noise"  :storyName: chapterFilePath: pageFilePath:sentenceNumber: sentenceText: stepNumber: ideaNumber];
}

-(void) textToSpeech: (NSString *) text
{
    syn = [[AVSpeechSynthesizer alloc] init];
    AVSpeechUtterance *utteranceEn = [[AVSpeechUtterance alloc]initWithString:text];
    utteranceEn.rate = AVSpeechUtteranceMaximumSpeechRate/7;
    //utteranceEn.voice = [AVSpeechSynthesisVoice voiceWithLanguage:obj2];
    [syn speakUtterance:utteranceEn];
    
    //[[ServerCommunicationController sharedManager] logComputerPlayAudio: @"Play Audio" : @"TTS" :text:bookTitle :chapterTitle :currentPage:currentSentence :currentStep];
}

@end
