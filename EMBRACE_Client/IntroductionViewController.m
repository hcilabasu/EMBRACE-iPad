//
//  IntroductionController.m
//  EMBRACE
//
//  Created by Jonatan Lemos Zuluaga (Student) on 6/18/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "IntroductionViewController.h"
#import "Book.h"
#import "ContextualMenuDataSource.h"
#import "PieContextualMenu.h"
#import "Translation.h"


@implementation IntroductionViewController

@synthesize buildHTMLStringClass;
@synthesize playAudioFileClass;
@synthesize STEPS_TO_SWITCH_LANGUAGES_EMBRACE;
@synthesize STEPS_TO_SWITCH_LANGUAGES_CONTROL;
@synthesize introductions;
@synthesize performedActions;
@synthesize lastStep;
@synthesize currentIntroStep;
@synthesize nextIntro;
@synthesize totalIntroSteps;
@synthesize allowInteractions;
@synthesize vocabularies;
@synthesize currentVocabStep;
@synthesize currentVocabSteps;
@synthesize totalVocabSteps;
@synthesize sameWordClicked;
@synthesize vocabAudio;
@synthesize currentAudio;
@synthesize languageString;

NSMutableArray* currentIntroSteps; //Stores the introduction steps for the current chapter
NSUInteger currentIntroStep; //Current step in the introduction
NSTimer* timer; //Controls the timing of the audio file that is playing

// Create an instance of  ConditionSetup
ConditionSetup *conditionSetup;

- (id)init {
    self = [super init];
    
    if (self) {
        buildHTMLStringClass = [[BuildHTMLString alloc]init];
        playAudioFileClass = [[PlayAudioFile alloc]init];
        conditionSetup = [[ConditionSetup alloc] init];
        STEPS_TO_SWITCH_LANGUAGES_CONTROL = 11;
        STEPS_TO_SWITCH_LANGUAGES_EMBRACE = 12;
        languageString = @"E";
    }
    
    return self;
}

-(void) startIntroduction {
    NSLog(@"IntroductionController.startIntroduction starting introduction");
}

//add comments
-(void) loadFirstPageIntroduction: (InteractionModel *) model : (NSString *) chapterTitle
{
    //Introduction setup
    currentIntroStep = 1;

    //Load the introduction data
    introductions = [model getIntroductions];
    
    //Get the steps for the introduction of the current chapter
    currentIntroSteps = [introductions objectForKey:chapterTitle];
    totalIntroSteps = [currentIntroSteps count];
}

//add comments
-(void)loadFirstPageVocabulary:(InteractionModel *)model :(NSString *)chapterTitle{

    //Vocabulary setup
    currentVocabStep = 1;
    lastStep =1; //lastStep = 1;
    
    //Load the vocabulary data
    vocabularies = [model getVocabularies];
    
    //Get the vocabulary steps (words) for the current story
    currentVocabSteps = [vocabularies objectForKey:chapterTitle];
    totalVocabSteps = [currentVocabSteps count];
}

// Loads the information of the currentIntroStep for the introduction
-(NSArray*) loadIntroStep: (UIWebView *) bookView : (NSUInteger) currentSentence{
 
    NSString* textEnglish;
    NSString* audioEnglish;
    NSString* textSpanish;
    NSString* audioSpanish;
    NSString* expectedSelection;
    NSString* expectedIntroAction;
    NSString* expectedIntroInput;
    NSString* underlinedVocabWord;
    NSString* wrapperObj1;
    
    allowInteractions = FALSE;
    
    //Get current step to be read
    IntroductionStep* currIntroStep = [currentIntroSteps objectAtIndex:currentIntroStep-1];
    expectedSelection = [currIntroStep expectedSelection];
    expectedIntroAction = [currIntroStep expectedAction];
    expectedIntroInput = [currIntroStep expectedInput];
    textEnglish = [currIntroStep englishText];
    audioEnglish = [currIntroStep englishAudioFileName];
    textSpanish = [currIntroStep spanishText];
    audioSpanish = [currIntroStep spanishAudioFileName];
    
    NSString* text = textEnglish;
    NSString* audio = audioEnglish;
    languageString = @"E";
    underlinedVocabWord = expectedIntroInput;
    
        // If the language condition for the app is BILINGUAL (English after Spanish) and the current intro step
        //is lower than the step number to switch languages, load the Spanish information for the step
        if ((conditionSetup.language == BILINGUAL) && currentIntroStep < STEPS_TO_SWITCH_LANGUAGES_EMBRACE && (conditionSetup.condition ==EMBRACE)) {
            text = textSpanish;
            audio = audioSpanish;
            languageString = @"S";
            underlinedVocabWord = [[Translation translationWords] objectForKey:expectedIntroInput];
            if (!underlinedVocabWord) {
                underlinedVocabWord = expectedIntroInput;
            }
        }
        else if ((conditionSetup.language ==BILINGUAL) && currentIntroStep < STEPS_TO_SWITCH_LANGUAGES_CONTROL && (conditionSetup.condition ==CONTROL)) {
            text = textSpanish;
            audio = audioSpanish;
            languageString = @"S";
            underlinedVocabWord = [[Translation translationWords] objectForKey:expectedIntroInput];
            if (!underlinedVocabWord) {
                underlinedVocabWord = expectedIntroInput;
            }
        }
    
    //Format text to load on the textbox
    NSString* formattedHTML = [buildHTMLStringClass buildHTMLString:text:expectedSelection:underlinedVocabWord:expectedIntroAction];
    NSString* addOuterHTML = [NSString stringWithFormat:@"setOuterHTMLText('%@', '%@')", @"s1", formattedHTML];
    [bookView stringByEvaluatingJavaScriptFromString:addOuterHTML];
    
    //Get the sentence class
    NSString* actionSentence = [NSString stringWithFormat:@"getSentenceClass(s%d)", currentSentence];
    NSString* sentenceClass = [bookView stringByEvaluatingJavaScriptFromString:actionSentence];
    
    //If it is an action sentence color it blue
    if ([sentenceClass  isEqualToString: @"sentence actionSentence"]) {
        if(![expectedIntroInput isEqualToString:@"next"]) {
            allowInteractions = TRUE;
        }
        NSString* colorSentence = [NSString stringWithFormat:@"setSentenceColor(s%d, 'blue')", currentSentence];
        [bookView stringByEvaluatingJavaScriptFromString:colorSentence];
    }
    
    //Play introduction audio
    [playAudioFileClass playAudioFile:audio];
    
    //Logging added by James for Introduction Audio
    //[[ServerCommunicationController sharedManager] logComputerPlayAudio: @"Play Introduction Audio" : languageString :audio :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu",(unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
    
    //DEBUG code to play expected action
    //NSString* actions = [NSString stringWithFormat:@"%@ %@ %@",expectedIntroAction,expectedIntroInput,expectedSelection];
    //[self playWordAudio:actions:@"en-us"];
    
    //The response audio file names are hard-coded for now
    if ([expectedIntroInput isEqualToString:@"next"]) {
        wrapperObj1 = @"TTNBTC.m4a";
    }
    else if ([expectedIntroInput isEqualToString:@"next"] && (conditionSetup.language ==BILINGUAL)) {
        wrapperObj1 = @"TEBNPC.m4a";
    }
    else if ([expectedSelection isEqualToString:@"word"]) {
        wrapperObj1 = @"BFCE_2B.m4a";
    }
    else if ([expectedSelection isEqualToString:@"word"] && (conditionSetup.language ==BILINGUAL)) {
        wrapperObj1 = @"BFCS_2B.m4a";
    }
    else if ([expectedIntroAction isEqualToString:@"move"]) {
        wrapperObj1 = @"BFEE_8.m4a";
    }
    else if ([expectedIntroAction isEqualToString:@"move"] && (conditionSetup.language ==BILINGUAL)) {
        wrapperObj1 = @"BFES_8.m4a";
    }
    
    //NSDictionary *wrapper = [NSDictionary dictionaryWithObjectsAndKeys:wrapperObj1, @"Key1", nil];
    //timer = [NSTimer scheduledTimerWithTimeInterval:17.5 target:self selector:@selector(playAudioFileTimed:) userInfo:wrapper repeats:YES];
    
    performedActions = [NSArray arrayWithObjects: expectedSelection, expectedIntroAction, expectedIntroInput, nil];
    
    return performedActions;
}

//introduction: move to introduction class
-(NSArray*) loadVocabStep: (UIWebView *) bookView : (NSUInteger) currentSentence :(NSString *) chapterTitle {
        NSString* text;
        NSString* audio;
        NSString* expectedSelection;
        NSString* expectedIntroAction;
        NSString* expectedIntroInput;
        NSString* wrapperObj1;
        NSString* nextAudio;
        NSInteger stepNumber;
        NSString* nextIntroInput;
        NSString* audioSpanish;
        NSString* nextAudioSpanish;
    
       sameWordClicked = false;
    
        //Get current step to be read
        VocabularyStep* currVocabStep = [currentVocabSteps objectAtIndex:currentVocabStep-1];
        expectedSelection = [currVocabStep expectedSelection];
        expectedIntroAction = [currVocabStep expectedAction];
        expectedIntroInput = [currVocabStep expectedInput];
        text = [currVocabStep englishText];
        audio = [currVocabStep englishAudioFileName];
        stepNumber = [currVocabStep wordNumber];
        audioSpanish = [currVocabStep spanishAudioFileName];
        lastStep = stepNumber;
        // && (stepNumber & 1) alternates between true and false
        if(((conditionSetup.language ==BILINGUAL)) && (stepNumber & 1)) {
            currentAudio = audioSpanish;
        }
        else {
            currentAudio = audio;
        }
    
        if([chapterTitle isEqualToString:@"The Contest"] || [chapterTitle isEqualToString:@"Why We Breathe"]) {
            //Get next step to be read
            VocabularyStep* nextVocabStep = [currentVocabSteps objectAtIndex:currentVocabStep];
            nextAudio = [nextVocabStep englishAudioFileName];
            nextAudioSpanish = [nextVocabStep spanishAudioFileName];
            nextIntroInput = [nextVocabStep expectedInput];
            // && (stepNumber & 1) alternates between true and false
            if((conditionSetup.language ==BILINGUAL) && (stepNumber & 1)) {
                vocabAudio = nextAudioSpanish;
            }
            else {
               vocabAudio = nextAudio;
            }
            nextIntro = nextIntroInput;
        }
    
        // If we are ont the first step (1) or the last step (9) which do not correspond to words
        //play the corresponding intro or outro audio
        if (currentVocabStep == 1 && ([chapterTitle isEqualToString:@"The Contest"] || [chapterTitle isEqualToString:@"Why We Breathe"])) {
            if((conditionSetup.language ==BILINGUAL)) {
                [playAudioFileClass playAudioFile:audioSpanish];
            } else {
                //Play introduction audio
                [playAudioFileClass playAudioFile:audio];
            }
    
            //Logging added by James for Word Audio
    //        [[ServerCommunicationController sharedManager] logComputerPlayAudio: @"Play Step Audio" : @"E" :audio  :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu",(unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
        }
    
        if((conditionSetup.condition ==CONTROL)){
            if (currentVocabStep == totalVocabSteps-2 && ([chapterTitle isEqualToString:@"The Contest"] || [chapterTitle isEqualToString:@"Why We Breathe"])) {
                if((conditionSetup.language == BILINGUAL)) {
                    [playAudioFileClass playAudioFile:nextAudioSpanish];
                } else {
                    //Play introduction audio
                    [playAudioFileClass playAudioFile:nextAudio];
                }
                currentVocabStep++;
            }
        }
    
        if((conditionSetup.condition ==EMBRACE)){
            if (currentVocabStep == totalVocabSteps-2 && ([chapterTitle isEqualToString:@"The Contest"] || [chapterTitle isEqualToString:@"Why We Breathe"])) {
    
                currentVocabStep++;
                //Get next step to be read
                VocabularyStep* nextVocabStep = [currentVocabSteps objectAtIndex:currentVocabStep];
                nextAudio = [nextVocabStep englishAudioFileName];
                nextAudioSpanish = [nextVocabStep spanishAudioFileName];
                nextIntroInput = [nextVocabStep expectedInput];
                nextIntro = nextIntroInput;
    
                if((conditionSetup.language ==BILINGUAL)) {
                    [playAudioFileClass playAudioFile:nextAudioSpanish];
                } else {
                    //Play introduction audio
                    [playAudioFileClass playAudioFile:nextAudio];
                }
            }
        }
    
        //Switch the language every step for the translation
    //    if ([languageString isEqualToString:@"S"]) {
    //        languageString = @"E";
    //    }
    //    else {
    //        languageString = @"S";
    //    }
    
        //The response audio file names are hard-coded for now
        if ([expectedIntroInput isEqualToString:@"next"]) {
            wrapperObj1 = @"TTNBTC.m4a";
        }
        else if ([expectedIntroInput isEqualToString:@"next"] && (conditionSetup.language ==BILINGUAL)) {
            wrapperObj1 = @"TEBNPC.m4a";
        }
    
        //The wrapper is a dictionary that stores the name of the file and a key.
        //It is used to pass this information to the timer as one of its parameters.
        //NSDictionary *wrapper = [NSDictionary dictionaryWithObjectsAndKeys:wrapperObj1, @"Key1", nil];
        //timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(playAudioFileTimed:) userInfo:wrapper repeats:YES];
    
        performedActions = [NSArray arrayWithObjects: expectedSelection, expectedIntroAction, expectedIntroInput, nil];
    
        return performedActions;
}

@end