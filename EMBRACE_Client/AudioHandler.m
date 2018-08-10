//
//  AudioHandler.m
//  EMBRACE
//
//  Created by Shang Wang on 3/19/18.
//  Copyright © 2018 Andreea Danielescu. All rights reserved.
//

#import "AudioHandler.h"
#import "ManipulationViewController.h"
#import "NSString+MD5.h"
#import "ActivitySequenceController.h"
#import "ConditionSetup.h"
#import "LibraryViewController.h"
@implementation AudioHandler
@synthesize parentManipulaitonCtr;
//TODO: Use this in method playCurrentSentenceAudio
- (NSString *)fileNameForCurrentSentence {
    
    NSString *sentenceAudioFile = nil;
    NSLog(@"sentenceContext.currentSentence %ld sentenceContext.currentIdea %ld pageContext.currentPageId %@", parentManipulaitonCtr.sentenceContext.currentSentence,parentManipulaitonCtr.sentenceContext.currentIdea,parentManipulaitonCtr.pageContext.currentPageId);
    
    NSLog(@"Sentence text: %@ - %@ ", parentManipulaitonCtr.sentenceContext.currentSentenceText, [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]);
    
    //If we are on the first or second manipulation page of Why We Breathe, play the audio of the current sentence
    if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"Why We Breathe"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:PM1] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM3])) {
        if ((parentManipulaitonCtr.conditionSetup.language == BILINGUAL)) {
            sentenceAudioFile = [NSString stringWithFormat:@"CPQR%ld.m4a", parentManipulaitonCtr.sentenceContext.currentSentence];
        }
        else {
            sentenceAudioFile = [NSString stringWithFormat:@"CWWB%ld.m4a", parentManipulaitonCtr.sentenceContext.currentSentence];
        }
    }
    
    //If we are on the first or second manipulation page of Disasters Intro, play the current sentence
    if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"Introduction to Natural Disasters"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:@"PM"] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2])) {
        if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL) {
            sentenceAudioFile = [NSString stringWithFormat:@"DisastersIntroS%ldS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
        }
        
    }
    
    //If we are on the first or second manipulation page of The Moving Earth, play the current sentence
    if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"The Moving Earth"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:PM1] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM3])) {
        if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL) {
            sentenceAudioFile = [NSString stringWithFormat:@"TheMovingEarthS%ldS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
        }
        else {
            sentenceAudioFile = [NSString stringWithFormat:@"TheMovingEarthS%dE.mp3", [parentManipulaitonCtr currentSentenceAudioIndex]];
        }
    }
    
    //If we are on the first or second manipulation page of The Naughty Monkey, play the current sentence
    if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:PM1] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM3]) && parentManipulaitonCtr.sentenceContext.currentSentence != 1) {
        if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL && parentManipulaitonCtr.sentenceContext.currentSentence < 8) {
            sentenceAudioFile = [NSString stringWithFormat:@"TheNaughtyMonkeyS%ldS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence - 2];
        }
        else {
            sentenceAudioFile = [NSString stringWithFormat:@"TheNaughtyMonkeyS%ldS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence - 2 ];
        }
    }
    
    
    // Use hash value of the sentence to find the audio file.
    if ([parentManipulaitonCtr.bookTitle isEqualToString:@"A Celebration to Remember" ]) {
        if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL && [parentManipulaitonCtr.pageContext.currentPageId.lowercaseString containsString:@"story1"]) {
            sentenceAudioFile = [NSString stringWithFormat:@"KeyIngredientsS%ldS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
        }
        else {
            sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
        }
        
    } else if ([parentManipulaitonCtr.bookTitle isEqualToString:@"Bottled Up Joy" ]) {
        if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL) {
            sentenceAudioFile = [NSString stringWithFormat:@"TheLuckyStoneS%ldS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
        }
        else {
            sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
        }
        
    } else if ([parentManipulaitonCtr.bookTitle isEqualToString:@"How Objects Move" ]) {
        
        if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL &&( [parentManipulaitonCtr.pageContext.currentPageId containsString:PM1] ||
                                                    [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2])) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"HowDoObjectsMoveS%ldS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
        }
        else {
            sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
        }
        
    } else if ([parentManipulaitonCtr.bookTitle isEqualToString:@"Native American Homes" ]) {
        
        //If we are on the first or second manipulation page of The Navajo Hogan, play the current sentence
        if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"The Navajo Hogan"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:PM1] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM3])) {
            if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"TheNavajoHoganS%ldS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
            }
        }
        
        //If we are on the first or second manipulation page of Native Intro, play the current sentence
        if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"Introduction to Native American Homes"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:@"PM"] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2])) {
            if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"NativeIntroS%ldS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
            }
        }
        
    } else if ([parentManipulaitonCtr.bookTitle isEqualToString:@"The Lopez Family Mystery"]) {
        
        if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL && [parentManipulaitonCtr.chapterTitle isEqualToString:@"The Lopez Family"] ) {
            sentenceAudioFile = [NSString stringWithFormat:@"TheLopezFamilyS%ldS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
        }
        else {
            sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
        }
        
        
    } else if ([parentManipulaitonCtr.bookTitle isEqualToString:@"The Best Farm"]) {
        
        if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL && [parentManipulaitonCtr.chapterTitle isEqualToString:@"The Contest"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:PM1] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2])) {
            sentenceAudioFile = [NSString stringWithFormat:@"BFEC%ld.m4a", parentManipulaitonCtr.sentenceContext.currentSentence];
        }
        else {
            sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
        }
        
        
    }   else if ([parentManipulaitonCtr.bookTitle isEqualToString:@"Natural Disasters"]) {
        
        if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL) {
            //If we are on the first or second manipulation page of Disasters Intro, play the current sentence
            if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"Introduction to Natural Disasters"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:@"PM"] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2])) {
                sentenceAudioFile = [NSString stringWithFormat:@"DisastersIntroS%ldS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
            } else if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"The Moving Earth"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:PM1] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM3])) {
                sentenceAudioFile = [NSString stringWithFormat:@"TheMovingEarthS%ldS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
            } else {
                sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
            }
        }
        else {
            sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
        }
    }
    
    if (sentenceAudioFile == nil || [sentenceAudioFile isEqualToString:@""]) {
        sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
    }
    return sentenceAudioFile;
}




/*
 *  Plays audio for the current sentence
 */
- (void)playCurrentSentenceAudio {
    
    //disable user interactions when preparing to play audio to prevent users from skipping audio
    [parentManipulaitonCtr.nextButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [parentManipulaitonCtr.view bringSubviewToFront:parentManipulaitonCtr.overlayView];
    [parentManipulaitonCtr.overlayView becomeFirstResponder];
    parentManipulaitonCtr.nextButton.alpha=0.7;
    [parentManipulaitonCtr disableUserInteraction];
    parentManipulaitonCtr.isAudioPlaying=YES;
    NSString *sentenceAudioFile = nil;
    NSLog(@"sentenceContext.currentSentence %d sentenceContext.currentIdea %d pageContext.currentPageId %@",
    parentManipulaitonCtr.sentenceContext.currentSentence,parentManipulaitonCtr.sentenceContext.currentIdea,parentManipulaitonCtr.pageContext.currentPageId);
    NSLog(@"Sentence text: %@ - %@ ", parentManipulaitonCtr.sentenceContext.currentSentenceText, [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]);
    
    
    //TODO: move chapter checks to new class or function
    //Only play sentence audio if system is reading or user made a syntax error
    if (parentManipulaitonCtr.conditionSetup.reader == SYSTEM || (parentManipulaitonCtr.conditionSetup.appMode == ITS && parentManipulaitonCtr.conditionSetup.useKnowledgeTracing && parentManipulaitonCtr.stepContext.numSyntaxErrors > 0)) {
        //If we are on the first or second manipulation page of The Contest, play the audio of the current sentence
        if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"The Contest"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:PM1] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2])) {
            //if ((conditionSetup.language == BILINGUAL)) {
            //START SHANG CODE
            if (1){
                //END SHANG CODE
                sentenceAudioFile = [NSString stringWithFormat:@"BFEC%d.m4a", parentManipulaitonCtr.sentenceContext.currentSentence];
            }
            else {
                /*START SHANG CODE*/
                //[chineseModel playSentence: (int)sentenceContext.currentSentence];
                int ttt=(int)parentManipulaitonCtr.sentenceContext.currentSentence;
                if(1==parentManipulaitonCtr.txtlanguageType&&ttt<6){
                    sentenceAudioFile = [NSString stringWithFormat:@"BFTCC%d.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
                }else{
                    sentenceAudioFile = [NSString stringWithFormat:@"BFTC%d.m4a", parentManipulaitonCtr.sentenceContext.currentSentence];
                }
                /*END SHANG CODE*/
            }
        }
        
        //If we are on the first or second manipulation page of Getting Ready, play the audio of the current sentence
        if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"Getting Ready"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:PM1] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2])) {
            sentenceAudioFile = [NSString stringWithFormat:@"GettingReadyS%dE.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of Who is the Best Animal?, play the audio of the current sentence
        if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"Who is the Best Animal?"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:PM1] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2])) {
            sentenceAudioFile = [NSString stringWithFormat:@"WhoIsTheBestAnimalS%dE.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of The Wise Owl, play the audio of the current sentence
        if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"The Wise Owl"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:PM1] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2])) {
            sentenceAudioFile = [NSString stringWithFormat:@"TheWiseOwlS%dE.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of Everyone Helps, play the audio of the current sentence
        if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"Everyone Helps"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:PM1] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2])) {
            sentenceAudioFile = [NSString stringWithFormat:@"EveryoneHelpsS%dE.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of The Best Farm Award, play the audio of the current sentence
        if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"The Best Farm Award"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:PM1] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2])) {
            sentenceAudioFile = [NSString stringWithFormat:@"TheBestFarmAwardS%dE.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of Why We Breathe, play the audio of the current sentence
        if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"Why We Breathe"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:PM1] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM3])) {
            if ((parentManipulaitonCtr.conditionSetup.language == BILINGUAL)) {
                sentenceAudioFile = [NSString stringWithFormat:@"CPQR%d.m4a", parentManipulaitonCtr.sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"CWWB%d.m4a", parentManipulaitonCtr.sentenceContext.currentSentence];
            }
        }
        
        
        
        
        //If we are on the first or second manipulation page of The Naughty Monkey, play the current sentence
        if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"The Naughty Monkey"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:PM1] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM3]) && parentManipulaitonCtr.sentenceContext.currentSentence != 1) {
            if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL && parentManipulaitonCtr.sentenceContext.currentSentence < 8) {
                sentenceAudioFile = [NSString stringWithFormat:@"TheNaughtyMonkeyS%dS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence - 2];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"TheNaughtyMonkeyS%dS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence - 2 ];
            }
        }
        
        
        
        
        // Use hash value of the sentence to find the audio file.
        if ([parentManipulaitonCtr.bookTitle isEqualToString:@"A Celebration to Remember" ]) {
            if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL && [parentManipulaitonCtr.pageContext.currentPageId.lowercaseString containsString:@"story1"] &&
                ![parentManipulaitonCtr.pageContext.currentPageId.lowercaseString containsString:@"intro"]) {
                
                sentenceAudioFile = [NSString stringWithFormat:@"KeyIngredientsS%dS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
            }
            
        } else if ([parentManipulaitonCtr.bookTitle isEqualToString:@"Bottled Up Joy" ]) {
            if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL && [parentManipulaitonCtr.pageContext.currentPageId.lowercaseString containsString:@"story1"] &&
                ![parentManipulaitonCtr.pageContext.currentPageId.lowercaseString containsString:@"intro"]) {
                sentenceAudioFile = [NSString stringWithFormat:@"TheLuckyStoneS%dS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
            }
            
        } else if ([parentManipulaitonCtr.bookTitle isEqualToString:@"How Objects Move" ]) {
            
            if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL && [parentManipulaitonCtr.pageContext.currentPageId.lowercaseString containsString:@"story1"] &&
                ![parentManipulaitonCtr.pageContext.currentPageId.lowercaseString containsString:@"intro"]) {
                sentenceAudioFile = [NSString stringWithFormat:@"HowDoObjectsMoveS%dS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
            }
            
        } else if ([parentManipulaitonCtr.bookTitle isEqualToString:@"Native American Homes" ]) {
            
        
            //If we are on the first or second manipulation page of The Navajo Hogan, play the current sentence
            if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"The Navajo Hogan"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:PM1] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM3])) {
                if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL && [parentManipulaitonCtr.pageContext.currentPageId.lowercaseString containsString:@"story1"]) {
                    sentenceAudioFile = [NSString stringWithFormat:@"TheNavajoHoganS%dS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
                }
                else {
                    sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
                }
            }
            
            //If we are on the first or second manipulation page of Native Intro, play the current sentence
            if ([parentManipulaitonCtr.chapterTitle isEqualToString:@"Introduction to Native American Homes"] && ([parentManipulaitonCtr.pageContext.currentPageId containsString:@"PM"] || [parentManipulaitonCtr.pageContext.currentPageId containsString:PM2])) {
                if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL && [parentManipulaitonCtr.pageContext.currentPageId.lowercaseString containsString:@"story1"]) {
                    sentenceAudioFile = [NSString stringWithFormat:@"NativeIntroS%dS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
                }
                
                if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL && [parentManipulaitonCtr.pageContext.currentPageId.lowercaseString containsString:@"story0"]) {
                    sentenceAudioFile = [NSString stringWithFormat:@"NativeIntroS%dS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
                }
                
                else {
                    sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
                }
            }
            
        } else if ([parentManipulaitonCtr.bookTitle isEqualToString:@"The Lopez Family Mystery"]) {
            
            if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL && [parentManipulaitonCtr.pageContext.currentPageId.lowercaseString containsString:@"story1"] &&
                ![parentManipulaitonCtr.pageContext.currentPageId.lowercaseString containsString:@"intro"]) {
                sentenceAudioFile = [NSString stringWithFormat:@"TheLopezFamilyS%dS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
            }
            
            
        } else if ([parentManipulaitonCtr.bookTitle isEqualToString:@"The Best Farm"]) {
            
            if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL && [parentManipulaitonCtr.chapterTitle isEqualToString:@"The Contest"] && ![parentManipulaitonCtr.pageContext.currentPageId.lowercaseString containsString:@"intro"]) {
                sentenceAudioFile = [NSString stringWithFormat:@"BFEC%d.m4a", parentManipulaitonCtr.sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
            }
            
        }  else if ([parentManipulaitonCtr.bookTitle isEqualToString:@"Natural Disasters"]) {
            
            if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL) {
                //If we are on the first or second manipulation page of Disasters Intro, play the current sentence
                if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL && [parentManipulaitonCtr.chapterTitle isEqualToString:@"Introduction to Natural Disasters"] && ![parentManipulaitonCtr.pageContext.currentPageId.lowercaseString containsString:@"intro"]) {
                    sentenceAudioFile = [NSString stringWithFormat:@"DisastersIntroS%dS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
                    
                } else if (parentManipulaitonCtr.conditionSetup.language == BILINGUAL && [parentManipulaitonCtr.chapterTitle isEqualToString:@"The Moving Earth"] && ![parentManipulaitonCtr.pageContext.currentPageId.lowercaseString containsString:@"intro"]) {
                    sentenceAudioFile = [NSString stringWithFormat:@"TheMovingEarthS%dS.mp3", parentManipulaitonCtr.sentenceContext.currentSentence];
                    
                } else {
                    sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
                }
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"%@.mp3", [parentManipulaitonCtr.sentenceContext.currentSentenceText MD5String]];
            }
        }
    }
    
    NSMutableArray *array = [NSMutableArray array];
    Chapter *chapter = [parentManipulaitonCtr.book getChapterWithTitle:parentManipulaitonCtr.chapterTitle];
    ScriptAudio *script = nil;
    NSString *introAudio = nil;
    LibraryViewController *vc = (LibraryViewController *)parentManipulaitonCtr.libraryViewController;
    ActivitySequenceController *seqController = vc.sequenceController;
    
    if (seqController && [seqController.sequences count] > 1) {
        ActivitySequence *seq = [seqController.sequences objectAtIndex:1];
        ActivityMode *mode = [seq getModeForChapter:parentManipulaitonCtr.chapterTitle];
        
        if ([parentManipulaitonCtr.pageContext.currentPageId containsString:DASH_INTRO] &&
            [parentManipulaitonCtr.pageContext.currentPageId containsString:@"story1"] &&
            ([parentManipulaitonCtr.chapterTitle isEqualToString:@"The Lucky Stone"] || [parentManipulaitonCtr.chapterTitle isEqualToString:@"The Lopez Family"])
            && [parentManipulaitonCtr.bookTitle containsString:seq.bookTitle]) {
            introAudio = @"splWordsIntro";
            
            [array addObject:[NSString stringWithFormat:@"%@.mp3",introAudio]];
            
            if (mode.language == BILINGUAL && mode.newInstructions) {
                introAudio = [NSString stringWithFormat:@"%@_S",introAudio];
                [array addObject:[NSString stringWithFormat:@"%@.mp3",introAudio]];
            }
        }
    }
    
    if ([ConditionSetup sharedInstance].condition == EMBRACE) {
        script = [chapter embraceScriptFor:[NSString stringWithFormat:@"%lu", (unsigned long)parentManipulaitonCtr.sentenceContext.currentSentence]];
    }
    else {
        script = [chapter controlScriptFor:[NSString stringWithFormat:@"%lu", (unsigned long)parentManipulaitonCtr.sentenceContext.currentSentence]];
    }
    //Shang: if it's first sentence of chapter, load instruction script
    if(parentManipulaitonCtr.shouldPlayInstructionAudio &&  1==parentManipulaitonCtr.sentenceContext.currentSentence){
        
        if ([ConditionSetup sharedInstance].condition == EMBRACE) {
            script = [chapter embraceScriptFor:[NSString stringWithFormat:@"%d", 0]];
        }
        else {
            script = [chapter controlScriptFor:[NSString stringWithFormat:@"%d", 0]];
        }
        
        
    }
    
    
    
    
    if (parentManipulaitonCtr.conditionSetup.newInstructions) {
        NSLog(@"New instructions should be played");
    }
    
    NSArray *preAudio = nil;
    NSArray *postAudio = nil;
    
    if ([ConditionSetup sharedInstance].language == ENGLISH) {
        preAudio = script.engPreAudio;
        postAudio = script.engPostAudio;
    }
    else {
        preAudio = script.bilingualPreAudio;
        postAudio = script.bilingualPostAudio;
    }
    
    if (preAudio != nil) {
        // Check if the preAudio is an introduction.
        // If it is an introduction, add appropriate extension
        if (preAudio.count == 1) {
            NSString *audio = [preAudio objectAtIndex:0];
            if ([audio containsString:INTRO]) {
                if ([ConditionSetup sharedInstance].condition == EMBRACE) {
                    if ([ConditionSetup sharedInstance].currentMode == PM_MODE || [ConditionSetup sharedInstance].currentMode == ITSPM_MODE) {
                        if ([ConditionSetup sharedInstance].reader == USER) {
                            audio = @"IntroDyadReads_PM";
                        } else {
                            audio = @"IntroIpadReads_PM";
                        }
                    } else {
                        if ([ConditionSetup sharedInstance].reader == USER) {
                            audio = @"IntroDyadReads_IM";
                        } else {
                            audio = @"IntroIpadReads_IM";
                        }
                    }
                } else {
                    if ([ConditionSetup sharedInstance].reader == USER) {
                        audio = @"IntroDyadReads_R";
                    } else {
                        audio = @"IntroIpadReads_R";
                    }
                }
                
                if (audio) {
                    NSString *spanishAudio = nil;
                    
                    // IntroIpadReads_IM does not have spanish audio.
                    if (![audio isEqualToString:@"IntroIpadReads_IM"] &&
                        [ConditionSetup sharedInstance].language == BILINGUAL &&
                        parentManipulaitonCtr.conditionSetup.newInstructions) {
                        spanishAudio = [NSString stringWithFormat:@"%@_S.mp3",audio];
                        
                    }
                    if ([parentManipulaitonCtr.bookTitle isEqualToString:@"Bottled Up Joy" ]) {
                        audio = @"IntroReadNextChapter";
                    }
                    audio = [NSString stringWithFormat:@"%@.mp3",audio];
                    preAudio = [NSArray arrayWithObjects: spanishAudio, nil];
                    
                }
            }
        }
        
        [array addObjectsFromArray:preAudio];
        
        for (NSString *preAudioFile in preAudio) {
            //Shang
            /*
             [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:[preAudioFile stringByDeletingPathExtension] inLanguage:[parentManipulaitonCtr.conditionSetup returnLanguageEnumtoString:[parentManipulaitonCtr.conditionSetup language]] ofType:PRESENTENCE_SCRIPT_AUDIO :manipulationContext];*/
        }
    }
    
    if (sentenceAudioFile != nil) {
        [array addObject:sentenceAudioFile];
        
        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:[sentenceAudioFile stringByDeletingPathExtension] inLanguage:[parentManipulaitonCtr.conditionSetup returnLanguageEnumtoString:[parentManipulaitonCtr.conditionSetup language]] ofType:SENTENCE_AUDIO :parentManipulaitonCtr.manipulationContext];
    }
    
    if (postAudio != nil) {
        [array addObjectsFromArray:postAudio];
        
        for (NSString *postAudioFile in postAudio) {
            [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:[postAudioFile stringByDeletingPathExtension] inLanguage:[parentManipulaitonCtr.conditionSetup returnLanguageEnumtoString:[parentManipulaitonCtr.conditionSetup language]] ofType:POSTSENTENCE_SCRIPT_AUDIO :parentManipulaitonCtr.manipulationContext];
        }
    }
    
    if ([array count] > 0) {
        [parentManipulaitonCtr.playaudioClass playAudioInSequence:array :self];
    }
    else {
        //there are no audio files to play so allow interactions
        
        [parentManipulaitonCtr.view setUserInteractionEnabled:YES];
        [parentManipulaitonCtr enableUserInteraction];
        parentManipulaitonCtr.isAudioPlaying=NO;
    }
}





@end

