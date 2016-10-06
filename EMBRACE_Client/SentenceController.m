//
//  SentenceController.m
//  EMBRACE
//
//  Created by James Rodriguez on 8/10/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "SentenceController.h"
#import "Translation.h"
#import "SolutionStepController.h"

@implementation SentenceController
@synthesize mvc;
@synthesize pageContext;
@synthesize stepContext;
@synthesize sentenceContext;
@synthesize manipulationContext;
@synthesize conditionSetup;
@synthesize bookImporter;
@synthesize bookTitle;
@synthesize chapterTitle;
@synthesize manipulationView;
@synthesize animatingObjects;

-(id)initWithController:(ManipulationViewController *) superMvc {
    self = [super init];
    
    if (self) {
        //Create loacl Pointers to needed classes, variables and properties within mvc
        self.mvc = superMvc;
        self.pageContext = mvc.pageContext;
        self.stepContext = mvc.stepContext;
        self.sentenceContext = mvc.sentenceContext;
        self.conditionSetup = mvc.conditionSetup;
        self.manipulationContext = mvc.manipulationContext;
        self.bookImporter = mvc.bookImporter;
        self.bookTitle = mvc.bookTitle;
        self.chapterTitle = mvc.chapterTitle;
        self.manipulationView = mvc.manipulationView;
        self.animatingObjects = mvc.animatingObjects;
    }
    
    return self;
}

/*
 * Gets the number of steps for the current sentence and sets the current step to 1.
 * Performs steps automatically if needed. Step is complete if it's a non-action sentence.
 */
- (void)setupCurrentSentence {
    stepContext.currentStep = 1;
    manipulationContext.stepNumber = stepContext.currentStep;
    stepContext.stepsComplete = FALSE;
    
    //Get number of steps for current sentence
    if (conditionSetup.appMode == ITS && [sentenceContext.pageSentences count] > 0) {
        if (sentenceContext.currentSentence > 0) {
            stepContext.numSteps = [[[sentenceContext.pageSentences objectAtIndex:sentenceContext.currentSentence - 1] solutionSteps] count];
            
            //Set current complexity based on senten ce
            mvc.currentComplexity = [[sentenceContext.pageSentences objectAtIndex:sentenceContext.currentSentence - 1] complexity];
        }
        else {
            stepContext.numSteps = 0; //sentence 0 is the title, so it has no steps
        }
    }
    else {
        if (conditionSetup.condition == CONTROL) {
            stepContext.numSteps = [stepContext.PMSolution getNumStepsForSentence:sentenceContext.currentSentence];
        }
        else if (conditionSetup.condition == EMBRACE) {
            if (conditionSetup.currentMode == PM_MODE) {
                //NOTE: Currently hardcoded because The Best Farm Solutions-MetaData.xml is different format from other stories
                if ([bookTitle rangeOfString:@"The Best Farm"].location != NSNotFound) {
                    stepContext.numSteps = [stepContext.PMSolution getNumStepsForSentence:sentenceContext.currentIdea];
                }
                else {
                    stepContext.numSteps = [stepContext.PMSolution getNumStepsForSentence:sentenceContext.currentSentence];
                }
            }
            else if (conditionSetup.currentMode == IM_MODE) {
                stepContext.numSteps = [stepContext.IMSolution getNumStepsForSentence:sentenceContext.currentSentence];
            }
        }
    }
    
    //If it is an action sentence, perform its solution steps if necessary
    if ([self.manipulationView isActionSentence:sentenceContext.currentSentence]) {
        [mvc performAutomaticSteps];
    }
    else {
        [[ServerCommunicationController sharedInstance] logLoadStep:stepContext.currentStep ofType:NULL_TXT context:manipulationContext];
        
        stepContext.stepsComplete = TRUE; //no steps to complete for non-action sentence
    }
    
    mvc.startTime = [NSDate date]; //for page statistics
}

/* Sets up the appearance of the current sentence by highlighting it as blue (if it is an action sentence)
 * or as black (if it is a non-action sentence).
 */
- (void)setupCurrentSentenceColor {
    
    [self.manipulationView setupCurrentSentenceColor:sentenceContext.currentSentence condition:conditionSetup.condition
                                             andMode:conditionSetup.currentMode];
}

/*
 * Set the current sentence number, text, type, appearance and associated solution steps. (creations solutions for vocab pages)
 */
- (void) setupSentencesForPage {
    sentenceContext.totalSentences = (int)[self.manipulationView totalSentences];
    
    //Get the id number of the first sentence on the page and set it equal to the current sentence number.
    //Because the PMActivity may have multiple pages, the first sentence on the page is not necessarily sentence 1.
    //   Ex. Page 1 may start at sentence 1, but page 2 may start at sentence 4.
    //   Thus, the first sentence on page 2 is sentence 4, not 1.
    //This is also to make sure we access the solution steps for the correct sentence.
    sentenceContext.currentSentence = (int)[self.manipulationView getIdForSentence:0];
    
    sentenceContext.currentSentenceText = [self.manipulationView getCurrentSentenceAt:sentenceContext.currentSentence];
    
    manipulationContext.sentenceNumber = sentenceContext.currentSentence;
    manipulationContext.sentenceText = sentenceContext.currentSentenceText;
    manipulationContext.manipulationSentence = [self isManipulationSentence:sentenceContext.currentSentence];
    [[ServerCommunicationController sharedInstance] logLoadSentence:sentenceContext.currentSentence withText:sentenceContext.currentSentenceText manipulationSentence:manipulationContext.manipulationSentence context:manipulationContext];
    
    //Dynamically reads the vocabulary words on the vocab page and creates and adds solutionsteps
    if ([pageContext.currentPageId rangeOfString:DASH_INTRO].location != NSNotFound) {
        [mvc.ssc createVocabSolutionsForPage];
    }
    
    //Remove any PM specific sentence instructions
    if(conditionSetup.currentMode == IM_MODE || conditionSetup.condition == CONTROL) {
        [self.manipulationView removePMInstructions:sentenceContext.totalSentences];
    }
    
    //Set up current sentence appearance and solution steps
    [self setupCurrentSentence];
    [self setupCurrentSentenceColor];
}

/*
 * Checks whether the specified sentence number requires physical or imagine manipulation
 */
- (BOOL)isManipulationSentence:(NSInteger)sentenceNumber {
    BOOL isManipulationSentence = false;
    
    //Get the sentence class
    NSString *sentenceClass = [self.manipulationView getSentenceClass:sentenceNumber];
    if ([sentenceClass containsString: @"sentence actionSentence"] || ([sentenceClass containsString: @"sentence IMactionSentence"] && conditionSetup.condition == EMBRACE && conditionSetup.currentMode == IM_MODE)) {
        isManipulationSentence = true;
    }
    
    return isManipulationSentence;
}

- (void)colorSentencesUponNext {
    
    [self.manipulationView colorSentencesUponNext:sentenceContext.currentSentence
                                        condition:conditionSetup.condition
                                          andMode:conditionSetup.currentMode];
}

/*
 *  Converts the passed in sentence text into english using the setence text as the key to the
 *  Translation dictionary
 */
- (NSString *)getEnglishTranslation:(NSString *)sentence {
    NSObject *englishTranslations = [[Translation translationWordsSpanish]objectForKey:sentence];
    
    if (englishTranslations != nil && [englishTranslations isKindOfClass:[NSArray class]]) {
        NSArray *englishTranslationsArray = ((NSArray *)englishTranslations);
        return [englishTranslationsArray objectAtIndex:0];
    }
    else if(englishTranslations != nil && [englishTranslations isKindOfClass:[NSString class]])
    {
        NSString *englishTranslationsString = ((NSString *) englishTranslations);
        return englishTranslationsString;
    }
    else
        return NULL_TXT;
}

/*
 *  Converts the passed in sentence text into spanish using the setence text as the key to the
 *  Translation dictionary
 */
- (NSString *)getSpanishTranslation:(NSString *)sentence {
    NSObject *englishTranslations = [[Translation translationWords]objectForKey:sentence];
    
    if (englishTranslations != nil && [englishTranslations isKindOfClass:[NSArray class]]) {
        NSArray *englishTranslationsArray = ((NSArray *)englishTranslations);
        return [englishTranslationsArray objectAtIndex:0];
    }
    else if(englishTranslations != nil && [englishTranslations isKindOfClass:[NSString class]])
    {
        NSString *englishTranslationsString = ((NSString *) englishTranslations);
        return englishTranslationsString;
    }
    else
        return NULL_TXT;
}

@end
