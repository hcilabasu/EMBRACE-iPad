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
#import "Statistics.h"

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
    if(stepContext.currentStep < 0){
        stepContext.currentStep = abs(stepContext.currentStep);
    }
    else{
        stepContext.currentStep = 1;
    }
    manipulationContext.stepNumber = stepContext.currentStep;
    stepContext.stepsComplete = FALSE;
    stepContext.numAttempts = 0;
    
    //Get number of steps for current sentence
    if (conditionSetup.appMode == ITS && [sentenceContext.pageSentences count] > 0) {
        stepContext.numSyntaxErrors = 0;
        stepContext.numVocabErrors = 0;
        stepContext.numUsabilityErrors = 0;
        
        if (sentenceContext.currentSentence > 0) {
            stepContext.numSteps = [[[sentenceContext.pageSentences objectAtIndex:sentenceContext.currentSentence - 1] solutionSteps] count];
            
            //Set current complexity based on sentence
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
            if (conditionSetup.currentMode == ITSPM_MODE && [pageContext.currentPageId rangeOfString:DASH_INTRO].location == NSNotFound) {
                stepContext.numSteps = [stepContext.ITSPMSolution getNumStepsForSentence:sentenceContext.currentIdea];
            }
            else if(conditionSetup.currentMode == ITSPM_MODE && [pageContext.currentPageId rangeOfString:DASH_INTRO].location != NSNotFound){
                stepContext.numSteps = [stepContext.ITSPMSolution getNumStepsForSentence:sentenceContext.currentSentence];
            }
            else if(conditionSetup.currentMode == PM_MODE){
                stepContext.numSteps = [stepContext.PMSolution getNumStepsForSentence:sentenceContext.currentSentence];
            }
            else if (conditionSetup.currentMode == IM_MODE) {
                stepContext.numSteps = [stepContext.IMSolution getNumStepsForSentence:sentenceContext.currentSentence];
            }
            else if (conditionSetup.currentMode == ITSIM_MODE && [pageContext.currentPageId containsString:DASH_INTRO] == NSNotFound) {
                stepContext.numSteps = [stepContext.ITSIMSolution getNumStepsForSentence:sentenceContext.currentIdea];
            }
            else if (conditionSetup.currentMode == ITSIM_MODE && [pageContext.currentPageId containsString:DASH_INTRO] != NSNotFound) {
                stepContext.numSteps = [stepContext.ITSIMSolution getNumStepsForSentence:sentenceContext.currentSentence];
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
}

/* Sets up the appearance of the current sentence by highlighting it as blue (if it is an action sentence)
 * or as black (if it is a non-action sentence).
 */
- (void)setupCurrentSentenceColor {
    //
    [self.manipulationView setupCurrentSentenceColor:sentenceContext.currentSentence condition:conditionSetup.condition
                                             andMode:conditionSetup.currentMode bookTitle:bookTitle];
}

/*
 * Set the current sentence number, text, type, appearance and associated solution steps. (creations solutions for vocab pages)
 */
- (void)setupSentencesForPage {
    sentenceContext.totalSentences = (int)[self.manipulationView totalSentences];
    
    //Dynamically reads the vocabulary words on the vocab page and creates and adds solutionsteps
    if ([pageContext.currentPageId rangeOfString:DASH_INTRO].location != NSNotFound) {
        [mvc.ssc createVocabSolutionsForPage];
    }
    else {
        if (conditionSetup.condition != CONTROL) {
            mvc.allowInteractions = TRUE;
            
            if ((conditionSetup.appMode == ITS && conditionSetup.useKnowledgeTracing && ![chapterTitle isEqualToString:@"The Naughty Monkey"] && !(conditionSetup.language == BILINGUAL && [pageContext.currentPageId.lowercaseString containsString:@"story1"])) &&
                
                !(conditionSetup.language == BILINGUAL && [pageContext.currentPageId.lowercaseString containsString:@"story0"] && [chapterTitle isEqualToString:@"Introduction to Native American Homes"])&&
                
                !( [pageContext.currentPageId.lowercaseString containsString:@"story0"] && [chapterTitle isEqualToString:@"Introduction to Natural Disasters"])) {
                
                mvc.currentComplexityLevel = [[ITSController sharedInstance] getCurrentComplexity];
                [self.manipulationView removeAllSentences];
                [self addSentencesWithComplexity:mvc.currentComplexityLevel];
            }
        }
    }
    
    if(!conditionSetup.isOnDemandVocabEnabled && [pageContext.currentPageId rangeOfString:DASH_INTRO].location == NSNotFound){
        [self.manipulationView removeAllAudibleTags];
    }
    
    sentenceContext.totalSentences = (int)[self.manipulationView totalSentences];
    
    //Get the id number of the first sentence on the page and set it equal to the current sentence number.
    //Because the PMActivity may have multiple pages, the first sentence on the page is not necessarily sentence 1.
    //   Ex. Page 1 may start at sentence 1, but page 2 may start at sentence 4.
    //   Thus, the first sentence on page 2 is sentence 4, not 1.
    //This is also to make sure we access the solution steps for the correct sentence.
    sentenceContext.currentSentence = (int)[self.manipulationView getIdForSentence:0];
    
    sentenceContext.currentSentenceText = [self.manipulationView getCurrentSentenceAt:sentenceContext.currentSentence];
    
    manipulationContext.sentenceNumber = sentenceContext.currentSentence;
    manipulationContext.sentenceComplexity = [self getComplexityOfCurrentSentence];
    manipulationContext.sentenceText = sentenceContext.currentSentenceText;
    manipulationContext.manipulationSentence = [self isManipulationSentence:sentenceContext.currentSentence];
    [[ServerCommunicationController sharedInstance] logLoadSentence:sentenceContext.currentSentence withComplexity:manipulationContext.sentenceComplexity withText:sentenceContext.currentSentenceText manipulationSentence:manipulationContext.manipulationSentence context:manipulationContext];
    
    //Remove any PM specific sentence instructions
    if(conditionSetup.currentMode == IM_MODE || conditionSetup.currentMode == ITSIM_MODE || conditionSetup.condition == CONTROL) {
        [self.manipulationView removePMInstructions:sentenceContext.totalSentences];
    }
    
    //Set up current sentence appearance and solution steps
    [self setupCurrentSentence];
    [self setupCurrentSentenceColor];
}

- (void)addSentencesWithComplexity:(EMComplexity)complexity {
    Language tempLang = conditionSetup.language;
    
    if (conditionSetup.language != ENGLISH) {
        tempLang = conditionSetup.language;
        conditionSetup.language = ENGLISH;
    }
    
    Chapter *chapter = [mvc.book getChapterWithTitle:chapterTitle]; //get current chapter
    
    conditionSetup.language = tempLang;
    
    ITSPhysicalManipulationActivity *ITSPMActivity;
    ITSImagineManipulationActivity *ITSIMActivity;
    NSMutableArray *alternateSentences;
    if (conditionSetup.currentMode == ITSPM_MODE) {
        ITSPMActivity = (ITSPhysicalManipulationActivity *)[chapter getActivityOfType:ITSPM_MODE]; //get PM Activity from chapter
        alternateSentences = [[ITSPMActivity alternateSentences] objectForKey:pageContext.currentPageId]; //get alternate sentences for current page
    } else if (conditionSetup.currentMode == ITSIM_MODE) {
        ITSIMActivity = (ITSImagineManipulationActivity *)[chapter getActivityOfType:ITSIM_MODE]; //get PM Activity from chapter
        alternateSentences = [[ITSIMActivity alternateSentences] objectForKey:pageContext.currentPageId]; //get alternate sentences for current page
    }
    
    
    // Underlined vocabulary includes chapter vocabulary and vocabulary from solution steps
    NSMutableSet *vocabulary = [[NSMutableSet alloc] initWithArray:[[chapter vocabulary] allKeys]];
    [vocabulary unionSet:[chapter getVocabularyFromSolutions]];
    
    int sentenceNumber = 1; //used for assigning sentence ids
    int previousIdeaNum = 0; //used for making sure same idea does not get repeated
    
    NSMutableArray *ideaNums;
    if(conditionSetup.currentMode == ITSPM_MODE){
        ideaNums = [stepContext.ITSPMSolution getIdeaNumbers]; //get list of idea numbers on the page
    } else if(conditionSetup.currentMode == ITSIM_MODE){
        ideaNums = [stepContext.ITSIMSolution getIdeaNumbers]; //get list of idea numbers on the page
    }
    
    sentenceContext.pageSentences = [NSMutableArray array];
    //Add alternate sentences associated with each idea
    for (NSNumber *ideaNum in ideaNums) {
        if ([ideaNum intValue] > previousIdeaNum) {
            BOOL foundIdea = false; //flag to check if there is a sentence with the specified complexity for the idea number
            
            //Create an array to hold sentences that will be added to the page
            NSMutableArray *sentencesToAdd = [[NSMutableArray alloc] init];
            
            //Look for alternate sentences that match the idea number and complexity
            for (AlternateSentence *altSent in alternateSentences) {
                /*
                int complexityToInt=10;
                if(EM_Easy==complexity){
                    complexityToInt=1;
                }else if (EM_Complex==complexity){
                    complexityToInt=2;
                }*/
                
                if ([[[altSent ideas] objectAtIndex:0] isEqualToNumber:ideaNum] && [altSent complexity] == complexity) {
                    foundIdea = true;
                    [sentencesToAdd addObject:altSent];
                    previousIdeaNum = [[[altSent ideas] lastObject] intValue];
                }
            }
            
            //If a sentence with the specified complexity was not found for the idea number, look for a
            //sentence with complexity level 2
            if (!foundIdea) {
                for (AlternateSentence *altSent in alternateSentences) {
                    if ([[[altSent ideas] objectAtIndex:0] isEqualToNumber:ideaNum] && [altSent complexity] == 10) {
                        foundIdea = true;
                        [sentencesToAdd addObject:altSent];
                        previousIdeaNum = [[[altSent ideas] lastObject] intValue];
                    }
                }
            }
            
            for (AlternateSentence *sentenceToAdd in sentencesToAdd) {
                [self.manipulationView addSentence:sentenceToAdd withSentenceNumber:sentenceNumber andVocabulary:vocabulary];
                sentenceNumber++;
                
                //Add alternate sentence to array
                [sentenceContext.pageSentences addObject:sentenceToAdd];
            }
        }
    }
}

/*
 * Checks whether the specified sentence number requires physical or imagine manipulation
 */
- (BOOL)isManipulationSentence:(NSInteger)sentenceNumber {
    BOOL isManipulationSentence = false;
    
    //Get the sentence class
    NSString *sentenceClass = [self.manipulationView getSentenceClass:sentenceNumber];
    if ([sentenceClass containsString: @"sentence actionSentence"] || ([sentenceClass containsString: @"sentence IMactionSentence"] && conditionSetup.condition == EMBRACE && (conditionSetup.currentMode == IM_MODE || conditionSetup.currentMode == ITSIM_MODE))) {
        isManipulationSentence = true;
    }
    
    return isManipulationSentence;
}

- (NSInteger)getComplexityOfCurrentSentence {
    NSInteger complexity = 0; // No complexity
    
    if ([[sentenceContext pageSentences] count] > 0 && sentenceContext.currentSentence > 0 && sentenceContext.currentSentence <= [[sentenceContext pageSentences] count]) {
        AlternateSentence *currentSentence = [sentenceContext.pageSentences objectAtIndex:sentenceContext.currentSentence - 1];
        complexity = [currentSentence complexity];
    }
    
    return complexity;
}

- (void)colorSentencesUponNext:(NSString*)BookTitle {
    
    [self.manipulationView colorSentencesUponNext:sentenceContext.currentSentence
                                        condition:conditionSetup.condition
                                          andMode:conditionSetup.currentMode
                                        bookTitle:BookTitle];
}

- (void)colorSentencesUponBack:(NSString*)BookTitle {
    
    [self.manipulationView colorSentencesUponBack:sentenceContext.currentSentence
                                        condition:conditionSetup.condition
                                          andMode:conditionSetup.currentMode
                                        bookTitle:BookTitle];
}

/*
 *  Converts the passed in sentence text into english using the sentence text as the key to the
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
