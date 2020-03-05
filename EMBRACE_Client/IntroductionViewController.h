//
//  IntroductionController.h
//  EMBRACE
//
//  Created by Jonatan Lemos Zuluaga (Student) on 6/18/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PieContextualMenuDelegate.h"
#import "EbookImporter.h"
#import "Book.h"
#import "BuildHTMLString.h"
#import "PlayAudioFile.h"
#import "ConditionSetup.h"

//This enum defines the action types that exist in every intro or vocab step
typedef enum Action {
    SELECTION,
    EXP_ACTION,
    INPUT
} Action;

@interface IntroductionViewController : UIViewController <UIGestureRecognizerDelegate, UIScrollViewDelegate>{}

@property (nonatomic, strong) BuildHTMLString *buildHTMLStringClass;
@property (nonatomic, strong) PlayAudioFile *playAudioFileClass;
@property (nonatomic) int STEPS_TO_SWITCH_LANGUAGES_EMBRACE;
@property (nonatomic) int STEPS_TO_SWITCH_LANGUAGES_CONTROL;
@property (nonatomic) BOOL allowInteractions; //TRUE if objects can be manipulated; FALSE otherwise
@property (nonatomic) NSArray *performedActions; //Store the information of the current step

//Introduction properties
@property (nonatomic) NSMutableDictionary *introductions;//Stores the instances of the introductions from metadata.xml
@property (nonatomic) NSInteger lastStep; //Used to store the most recent intro step
@property (nonatomic) NSInteger currentIntroStep;//Current step in the introduction
@property (nonatomic, strong) NSString *nextIntro; //Used to store the most recent intro step
@property (nonatomic) NSUInteger totalIntroSteps; //Stores the total number of introduction steps for the current chapter

//Vocabulary properties
@property (nonatomic, strong) NSMutableDictionary *vocabularies; //Stores the instances of the vocabs from metadata.xml
@property (nonatomic) NSUInteger currentVocabStep; //Stores the index of the current vocab step
@property (nonatomic, strong) NSMutableArray *currentVocabSteps; //Stores the vocab steps for the current chapter
@property (nonatomic) NSUInteger totalVocabSteps; //Stores the total number of vocab steps for the current chapter
@property (nonatomic) BOOL sameWordClicked; //Defines if a word has been clicked or not
@property (nonatomic,strong) NSString *vocabAudio; //Used to store the next vocab audio file to be played
@property (nonatomic, strong) NSString *currentAudio; //Used to store the current vocab audio file to be played
@property (nonatomic,strong) NSString *languageString; //Defines the languange to be used 'E' for English 'S' for Spanish

- (id)initWithParams:(PlayAudioFile *)audplayer :(BuildHTMLString *)buildStringClass :(ConditionSetup *) conditionSetupClass;
- (void)startIntroduction;
- (void)loadFirstPageIntroduction:(InteractionModel *)model :(NSString *)chapterTitle;
- (void)loadFirstPageVocabulary:(InteractionModel *)model :(NSString *)chapterTitle;
- (NSArray *)loadIntroStep:(UIWebView *)bookView :(UIViewController *)pmviewController :(NSUInteger)currentSentence;
- (NSArray *)loadVocabStep:(UIWebView *)bookView :(UIViewController *)pmviewController :(NSUInteger)currentSentence :(NSString *)chapterTitle;

@end
