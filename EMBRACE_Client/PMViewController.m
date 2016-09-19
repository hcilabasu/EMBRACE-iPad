//
//  PMViewController.m
//  eBookReader
//
//  Created by Andreea Danielescu on 2/12/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "PMViewController.h"
#import "ContextualMenuDataSource.h"
#import "PieContextualMenu.h"
#import "Translation.h"
#import "ServerCommunicationController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "ConditionSetup.h"
#import "IntroductionViewController.h"
#import "Statistics.h"
#import "LibraryViewController.h"
#import "ManipulationContext.h"
#import "NSString+HTML.h"

#import "ITSController.h"
#import "ManipulationAnalyser.h"

#import "PMView.h"


@interface PMViewController ()<PMViewDelegate> {
    NSString *currentPage; //Current page being shown, so that the next page can be requested
    NSString *currentPageId; //Id of the current page being shown
    NSString *actualPage; //Stores the address of the current page we are at
    
    NSUInteger currentSentence; //Active sentence to be completed
    NSString *currentSentenceText; //Text of current sentence
    NSUInteger currentIdea; //Current idea number to be completed
    NSUInteger totalSentences; //Total number of sentences on this page
    NSMutableArray *pageSentences; //AlternateSentences on current page
    NSString *actualWord; //Stores the current word that was clicked
    NSString *previousStep;
    
    BOOL chooseComplexity; //True if using alternate sentences
    NSMutableDictionary *pageStatistics;
    NSUInteger currentComplexity; //Complexity level of current sentence
    NSDate *startTime;
    NSDate *endTime;
    
    PhysicalManipulationSolution *PMSolution; //PM solution steps for current chapter
    ImagineManipulationSolution *IMSolution; //IM solution steps for current chapter
    NSUInteger numSteps; //Number of steps for current sentence
    NSUInteger currentStep; //Active step to be completed
    BOOL stepsComplete; //True if all steps have been completed for a sentence
    NSUInteger maxAttempts; // Maximum number of attempts user can make before system automatically performs step
    NSUInteger numAttempts; // Number of attempts user has made for current step
    
    InteractionModel *model;
    ConditionSetup *conditionSetup;
    ManipulationContext *manipulationContext;
    
    InteractionRestriction useSubject; //Determines which objects the user can manipulate as the subject
    InteractionRestriction useObject; //Determines which objects the user can interact with as the object
    
    NSString *movingObjectId; //Object currently being moved
    NSString *collisionObjectId; //Object the moving object was moved to
    NSString *separatingObjectId; //Object identified when pinch gesture performed
    NSMutableDictionary *currentGroupings;
    Relationship *lastRelationship; //Stores the most recent relationship between objects used
    NSMutableArray *allRelationships; //Stores an array of all relationships which is populated in getPossibleInteractions
    NSMutableDictionary *animatingObjects;
    BOOL containsAnimatingObject;
    BOOL movingObject; //True if an object is currently being moved
    BOOL separatingObject; //True if two objects are currently being ungrouped
    
    BOOL panning;
    BOOL pinching;
    BOOL pinchToUngroup; //True if pinch gesture is used to ungroup
    
    BOOL replenishSupply; //True if object should reappear after disappearing
    BOOL allowSnapback; //True if objects should snap back to original location upon error
    BOOL pressedNextLock; // True if user pressed next, and false after next function finishes execution
    BOOL isLoadPageInProgress; //True if the system is currently trying to load the next page
    BOOL didSelectCorrectMenuOption; // True if user selected the correct menu option in IM mode

    CGPoint startLocation; //initial location of an object before it is moved
    CGPoint endLocation; // ending location of an object after it is moved
    CGPoint delta; //distance between the top-left corner of the image being moved and the point clicked.
    
    ContextualMenuDataSource *menuDataSource;
    PieContextualMenu *menu;
    UIView *IMViewMenu;
    BOOL menuExpanded;
    
    NSTimer *timer; //Controls the timing of the audio file that is playing
    BOOL isAudioLeft;
    
    
}

//@property (nonatomic, strong) IBOutlet UIWebView *bookView;
@property (strong) AVAudioPlayer *audioPlayer;
@property (strong) AVAudioPlayer *audioPlayerAfter; //Used to play sounds after the first audio player has finished playing
@property (nonatomic, assign)EMComplexity currentComplexityLevel;


@property (nonatomic, strong) IBOutlet PMView *pmView;

@end

@implementation PMViewController

@synthesize book;
@synthesize bookTitle;
@synthesize chapterTitle;
@synthesize bookImporter;

@synthesize libraryViewController;
@synthesize IntroductionClass;
@synthesize buildStringClass;
@synthesize playaudioClass;
@synthesize syn;

//Used to determine the required proximity of 2 hotspots to group two items together.
float const groupingProximity = 20.0;

BOOL wasPathFollowed = false;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.pmView.frame = self.view.bounds;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pmView = [[PMView alloc] initWithFrame:self.view.frame];
    
    [self.view addSubview:self.pmView];
    self.pmView.delegate = self;
    [self.view sendSubviewToBack:self.pmView];
    
//    NSLayoutConstraint *xCenterConstraint = [NSLayoutConstraint constraintWithItem:self.pmView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
//    [self.view addConstraint:xCenterConstraint];
//    
//    NSLayoutConstraint *yCenterConstraint = [NSLayoutConstraint constraintWithItem:self.pmView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
//    [self.view addConstraint:yCenterConstraint];
    
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.pmView
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.pmView
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeLeading
                                                             multiplier:1.0
                                                               constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.pmView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.pmView
                                                              attribute:NSLayoutAttributeTrailing
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeTrailing
                                                             multiplier:1.0
                                                               constant:0.0]];

    
    [self.pmView addGesture:tapRecognizer];
    [self.pmView addGesture:swipeRecognizer];
    [self.pmView addGesture:panRecognizer];
    
    //hides the default navigation bar to add custom back button
    self.navigationItem.hidesBackButton = YES;
    
    //custom back button to show confirmation alert
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle: @"Library" style: UIBarButtonItemStyleBordered target: self action: @selector(backButtonPressed:)];
    //Sets leftBarButtonItem to the custom back button in place of default back button
    self.navigationItem.leftBarButtonItem = backButton;
    
    conditionSetup = [ConditionSetup sharedInstance];
    manipulationContext = [[ManipulationContext alloc] init];
    
    buildStringClass = [[BuildHTMLString alloc] init];
    playaudioClass = [[PlayAudioFile alloc] init];
    IntroductionClass = [[IntroductionViewController alloc] initWithParams:playaudioClass :buildStringClass :conditionSetup];
    
    syn = [[AVSpeechSynthesizer alloc] init];
    
    menuDataSource = [[ContextualMenuDataSource alloc] init];
    
    //Added to deal with ios7 view changes. This makes it so the UIWebView and the navigation bar do not overlap.
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    currentPage = nil;
    
    pinching = FALSE;
    pinchToUngroup = FALSE;
    replenishSupply = FALSE;
    allowSnapback = TRUE;
    pressedNextLock = false;
    isLoadPageInProgress = false;
    didSelectCorrectMenuOption = false;
    
    movingObject = FALSE;
    movingObjectId = nil;
    collisionObjectId = nil;
    separatingObjectId = nil;
    lastRelationship = nil;
    allRelationships = [[NSMutableArray alloc] init];
    currentGroupings = [[NSMutableDictionary alloc] init];
    
    if (conditionSetup.condition  == CONTROL) {
        IntroductionClass.allowInteractions = FALSE;
        
        useSubject = NO_ENTITIES;
        useObject = NO_ENTITIES;
    }
    else if (conditionSetup.condition == EMBRACE) {
        IntroductionClass.allowInteractions = TRUE;
        maxAttempts = 5;
        numAttempts = 0;
        
        if (conditionSetup.currentMode == PM_MODE) {
            useSubject = ALL_ENTITIES;
            useObject = ONLY_CORRECT;
        }
        else if (conditionSetup.currentMode == IM_MODE) {
            useSubject = NO_ENTITIES;
            useObject = NO_ENTITIES;
        }
    }
    
    if (conditionSetup.appMode == ITS) {
        chooseComplexity = TRUE;
        pageStatistics = [[NSMutableDictionary alloc] init];
    }
    else {
        chooseComplexity = FALSE;
    }
    
    IntroductionClass.languageString = @"E";
    IntroductionClass.sameWordClicked = false;
    [[ITSController sharedInstance] setAnalyzerDelegate:self];
}

-(void)backButtonPressed:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Return to Library", @"") message:NSLocalizedString(@"Are you sure you want to return to the Library?", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
    [alertView show];
}

- (void)didReceiveMemoryWarning {
    NSLog(@"***************** Memory warning!! *****************");
}

- (void)pmViewDidLoad:(PMView *)view {
    isLoadPageInProgress = false;
   
    
    //Start off with no objects grouped together
    currentGroupings = [[NSMutableDictionary alloc] init];
    

    totalSentences = (int)[self.pmView totalSentences];

    //Dynamically reads the vocabulary words on the vocab page and creates and adds solutionsteps
    if ([currentPageId rangeOfString:@"-Intro"].location != NSNotFound) {
        [self createVocabSolutionsForPage];
    }
    else {
        if (conditionSetup.appMode == ITS) {
            self.currentComplexityLevel = [[ITSController sharedInstance] getCurrentComplexity];
            [self.pmView removeAllSentences];
            [self addSentencesWithComplexity:self.currentComplexityLevel];
        }
    }
       
        totalSentences = (int)[self.pmView totalSentences];
        

        //Get the id number of the first sentence on the page and set it equal to the current sentence number.
        //Because the PMActivity may have multiple pages, the first sentence on the page is not necessarily sentence 1.
        //   Ex. Page 1 may start at sentence 1, but page 2 may start at sentence 4.
        //   Thus, the first sentence on page 2 is sentence 4, not 1.
        //This is also to make sure we access the solution steps for the correct sentence.
        currentSentence = (int)[self.pmView getIdForSentence:0];
       
        currentSentenceText = [self.pmView getCurrentSentenceAt:currentSentence];
        //[[bookView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('s%d').innerHTML", currentSentence]] stringByConvertingHTMLToPlainText];
        
        manipulationContext.sentenceNumber = currentSentence;
        manipulationContext.sentenceText = currentSentenceText;
        manipulationContext.manipulationSentence = [self isManipulationSentence:currentSentence];
        [[ServerCommunicationController sharedInstance] logLoadSentence:currentSentence withText:currentSentenceText manipulationSentence:manipulationContext.manipulationSentence context:manipulationContext];
        
    
        
        //Remove any PM specific sentence instructions
        if(conditionSetup.currentMode == IM_MODE || conditionSetup.condition == CONTROL) {
            [self.pmView removePMInstructions:totalSentences];
        }
    

    
        //Set up current sentence appearance and solution steps
        [self setupCurrentSentence];
        [self setupCurrentSentenceColor];

    isAudioLeft = false;
    
    [self playCurrentSentenceAudio];
    
    //If there is at least one area/path to build
    if ([model getAreaWithPageId:currentPageId] || [model getAreaWithPageId:@"All_Chapters"]  ) {
        //Build area/path
        for (Area *area in [model areas]) {
            if ([area.pageId isEqualToString:currentPageId] || [area.pageId isEqualToString:@"All_Chapters"]) {
                [self buildPath:area.areaId];
            }
        }
    }
    
    [self drawAreasForPage];
    //Perform setup for activity
    [self performSetupForActivity];
}

- (void)drawAreasForPage {
    //TODO: remove hard coded draw areas and move to new setup draw area function
    //Draw area (hard-coded for now)
    //[self drawArea:@"outside":@"The Lopez Family"];
    //[self drawArea:@"aroundPaco":@"Is Paco a Thief?"];
    [self drawArea:@"aorta":@"The Amazing Heart":@"story2-PM-4"];
    [self drawArea:@"aortaPath":@"The Amazing Heart":@"story2-PM-4"];
    [self drawArea:@"aortaStart":@"The Amazing Heart":@"story2-PM-4"];
    //[self drawArea:@"arteries":@"Muscles Use Oxygen":@"story3-PM-1"];
    //[self drawArea:@"aortaPath2":@"Muscles Use Oxygen":@"story3-PM-1"];
    [self drawArea:@"veinPath":@"Getting More Oxygen for the Muscles":@"story4-PM-3"];
    [self drawArea:@"vein":@"Getting More Oxygen for the Muscles":@"story4-PM-3"];
    [self drawArea:@"veinPath":@"Muscles Use Oxygen":@"story3-PM-3"];
    
}

- (void)drawArea:(NSString *)areaName :(NSString *)chapter :(NSString *)pageId {
    if ([chapterTitle isEqualToString:chapter] && [currentPageId isEqualToString:pageId]) {
       
        [self.pmView drawArea:areaName
                      chapter:chapter
                       pageId:pageId
                    withModel:model];
    }
}

/*
 * Creates a solution step for each vocabulary word in the introduction and adds it to the page solutions
 */
- (void)createVocabSolutionsForPage {
    Chapter *chapter = [book getChapterWithTitle:chapterTitle];
    
    NSMutableSet *newVocab = [[NSMutableSet alloc] init];
    NSMutableArray *vocabSolutionSteps = [[NSMutableArray alloc] init];
    
    // Adds new vocabulary introduced in the chapter
    for (int i = 1; i < totalSentences + 1; i++) {
        NSString *vocabText = [[self.pmView getVocabAtId:i] lowercaseString];
        
        if (conditionSetup.language == BILINGUAL) {
            if (![[self getEnglishTranslation:vocabText] isEqualToString:@"Translation not found"]) {
                vocabText = [self getEnglishTranslation:vocabText];
            }
        }
        
        [newVocab addObject:vocabText];
        
        ActionStep *vocabSolutionStep = [[ActionStep alloc] initAsSolutionStep:i :nil :1 :@"tapWord" :vocabText :nil :nil :nil :nil :nil :nil];
        [vocabSolutionSteps addObject:vocabSolutionStep];
    }
    
    if (conditionSetup.appMode == ITS) {
        NSMutableSet *vocabToAdd = [[ITSController sharedInstance] getExtraIntroductionVocabularyForChapter:chapter inBook:book];
        
        for (NSString *vocab in vocabToAdd) {
            totalSentences++;
            
            NSString *englishText = vocab;
            NSString *spanishText = [NSString stringWithFormat:@""];
            
            if (conditionSetup.language == BILINGUAL) {
                if (![[self getEnglishTranslation:vocab] isEqualToString:@"Translation not found"]) {
                    englishText = [self getEnglishTranslation:vocab];
                    spanishText = vocab;
                }
            }
            
            [self.pmView addVocabularyWithID:totalSentences englishText:englishText spanishText:spanishText];
            
            ActionStep *vocabSolutionStep = [[ActionStep alloc] initAsSolutionStep:totalSentences :nil :1 :@"tapWord" :englishText :nil :nil :nil :nil :nil :nil];
            [vocabSolutionSteps addObject:vocabSolutionStep];
        }
    }
    
    if (conditionSetup.currentMode == PM_MODE || conditionSetup.condition == CONTROL) {
        PMSolution = [[PhysicalManipulationSolution alloc] init];
        PMSolution.solutionSteps = vocabSolutionSteps;
        
        PhysicalManipulationActivity *PMActivity = (PhysicalManipulationActivity *)[chapter getActivityOfType:PM_MODE];
        [PMActivity addPMSolution:PMSolution forActivityId:currentPageId];
    }
    else if (conditionSetup.currentMode == IM_MODE) {
        IMSolution = [[ImagineManipulationSolution alloc] init];
        IMSolution.solutionSteps = vocabSolutionSteps;
        
        ImagineManipulationActivity *IMActivity = (ImagineManipulationActivity *)[chapter getActivityOfType:IM_MODE];
        [IMActivity addIMSolution:IMSolution forActivityId:currentPageId];
    }
}

//Temporary menu to select complexity of sentences on page or to dismiss page statistics
//TODO: remove temporary menu or enable for debug/testing mode only
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView title] isEqualToString:@"Choose sentence complexity levels"]) {
//        Statistics *statistics = [[Statistics alloc] init];
//        [pageStatistics setObject:statistics forKey:currentPageId];
//        
//        pageSentences = [[pageStatistics objectForKey:currentPageId] pageSentences];
//        
//        if (buttonIndex == 0) {
//            //Swap sentences for specified complexity level
//            [self swapSentencesOnPage:60 :20 :20];
//        }
//        else if (buttonIndex == 1) {
//            //Swap sentences for specified complexity level
//            [self swapSentencesOnPage:20 :60 :20];
//        }
//        else if (buttonIndex == 2) {
//            //Swap sentences for specified complexity level
//            [self swapSentencesOnPage:20 :20 :60];
//        }
//        else if (buttonIndex == 3) {
//            //Keeps current sentences
//            [self swapSentencesOnPage:0 :100 :0];
//        }
//        
//        //Get the number of sentences on the page
//        NSString *requestSentenceCount = [NSString stringWithFormat:@"document.getElementsByClassName('sentence').length"];
//        int sentenceCount = [[bookView stringByEvaluatingJavaScriptFromString:requestSentenceCount] intValue];
//        
//        //Get the id number of the last sentence on the page and set it equal to the total number of sentences.
//        //Because the PMActivity may have multiple pages, this id number may not match the sentence count for the page.
//        //   Ex. Page 1 may have three sentences: 1, 2, and 3. Page 2 may also have three sentences: 4, 5, and 6.
//        //   The total number of sentences is like a running total, so by page 2, there are 6 sentences instead of 3.
//        //This is to make sure we access the solution steps for the correct sentence on this page, and not a sentence on
//        //a previous page.
//        //if (![vocabularies objectForKey:chapterTitle]) {
//        NSString *requestLastSentenceId = [NSString stringWithFormat:@"document.getElementsByClassName('sentence')[%d - 1].id", sentenceCount];
//        NSString *lastSentenceId = [bookView stringByEvaluatingJavaScriptFromString:requestLastSentenceId];
//        int lastSentenceIdNumber = [[lastSentenceId substringFromIndex:1] intValue];
//        totalSentences = lastSentenceIdNumber;
//        
//        //Get the id number of the first sentence on the page and set it equal to the current sentence number.
//        //Because the PMActivity may have multiple pages, the first sentence on the page is not necessarily sentence 1.
//        //   Ex. Page 1 may start at sentence 1, but page 2 may start at sentence 4.
//        //   Thus, the first sentence on page 2 is sentence 4, not 1.
//        //This is also to make sure we access the solution steps for the correct sentence.
//        NSString *requestFirstSentenceId = [NSString stringWithFormat:@"document.getElementsByClassName('sentence')[0].id"];
//        NSString *firstSentenceId = [bookView stringByEvaluatingJavaScriptFromString:requestFirstSentenceId];
//        int firstSentenceIdNumber = [[firstSentenceId substringFromIndex:1] intValue];
//        currentSentence = firstSentenceIdNumber;
//        
//        //Set up current sentence appearance and solution steps
//        [self setupCurrentSentence];
//        [self setupCurrentSentenceColor];
    }
    else if ([[alertView title] isEqualToString:@"Page Statistics"]) {
        if (buttonIndex == 0) {
            [self loadNextPage];
        }
    }
    else if([[alertView title] isEqualToString:@"Return to Library"])
    {
        //Get title of pressed alert button
        NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
        
        //If button pressed is Yes, return to libraryView
        if([title isEqualToString:@"Yes"])
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

//Temporary function to show page statistics
//TODO: remove or enable for debug/testing only
- (void)showPageStatistics {
    Statistics *statistics = [pageStatistics objectForKey:currentPageId];
    
    NSString *numStepsString = [NSString stringWithFormat:@"Number of steps:\nSimple: %d\nMedium: %d\nComplex: %d", [statistics getNumStepsForComplexity:0], [statistics getNumStepsForComplexity:1], [statistics getNumStepsForComplexity:2]];
    NSString *numErrorsString = [NSString stringWithFormat:@"Number of errors:\nSimple: %d\nMedium: %d\nComplex: %d", [statistics getNumErrorsForComplexity:0], [statistics getNumErrorsForComplexity:1], [statistics getNumErrorsForComplexity:2]];
    NSString *timeString = [NSString stringWithFormat:@"Average time per step:\nSimple: %f\nMedium: %f\nComplex: %f", [statistics calculateAverageTimePerStepForComplexity:0], [statistics calculateAverageTimePerStepForComplexity:1], [statistics calculateAverageTimePerStepForComplexity:2]];
    NSString *numNonActSentsString = [NSString stringWithFormat:@"Number of non-action sentences:\nSimple: %d\nMedium: %d\nComplex: %d", [statistics getNumNonActSentsForComplexity:0], [statistics getNumNonActSentsForComplexity:1], [statistics getNumNonActSentsForComplexity:2]];
    NSString *timeForNonActsSentsString = [NSString stringWithFormat:@"Average time per non-action sentence:\nSimple: %f\nMedium: %f\nComplex: %f", [statistics calculateAverageTimePerNonActSentForComplexity:0], [statistics calculateAverageTimePerNonActSentForComplexity:1], [statistics calculateAverageTimePerNonActSentForComplexity:2]];
    NSString *numVocabRequestsString = [NSString stringWithFormat:@"Number of vocabulary requests:\nSimple: %d\nMedium: %d\nComplex: %d", [statistics getNumVocabTapsForComplexity:0], [statistics getNumVocabTapsForComplexity:1], [statistics getNumVocabTapsForComplexity:2]];
    
    NSString *message = [NSString stringWithFormat:@"%@\n\n%@\n\n%@\n\n%@\n\n%@\n\n%@", numStepsString, numErrorsString, timeString, numNonActSentsString, timeForNonActsSentsString, numVocabRequestsString];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Page Statistics" message:message delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
}

/*
 * Gets the book reference for the book that's been opened.
 * Also sets the reference to the interaction model of the book.
 * Sets the page to the one for the current chapter activity.
 * Calls the function to load the html content for the activity.
 */
- (void)loadFirstPage {
    book = [bookImporter getBookWithTitle:bookTitle]; //Get the book reference.
    model = [book model];
  
    currentPage = [book getNextPageForChapterAndActivity:chapterTitle : conditionSetup.currentMode :nil];
    
    if (!conditionSetup.vocabPageEnabled && [currentPage containsString:@"-Intro"]) {
        currentSentence = 1;
        currentPage = [book getNextPageForChapterAndActivity:chapterTitle :PM_MODE :currentPage];
    }
    
    actualPage = currentPage;
    
    //Instantiates all introduction variables
    [IntroductionClass loadFirstPageIntroduction:model :chapterTitle];
    
    [self loadPage];
}

/*
 * Loads the next page for the current chapter based on the current activity.
 * If the activity has multiple pages, it would load the next page in the activity.
 * Otherwise, it will load the next chaper.
 */
- (void) loadNextPage {
    isLoadPageInProgress =true;
    [self.playaudioClass stopPlayAudioFile];

    currentPage = [book getNextPageForChapterAndActivity:chapterTitle :PM_MODE :currentPage];
    
    //No more pages in chapter
    if (currentPage == nil) {
        //TODO: remove hard coded strings
        if ([chapterTitle isEqualToString:@"Introduction to The Best Farm"] ||
            [chapterTitle isEqualToString:@"Introduction to The House"])
        {
            [[ServerCommunicationController sharedInstance] logCompleteManipulation:manipulationContext];
            
            //Set introduction as completed
            [[(LibraryViewController *)libraryViewController studentProgress] setStatusOfChapter:chapterTitle :COMPLETED fromBook:[bookTitle stringByReplacingOccurrencesOfString:@" - Unknown-1" withString:@""]];
            
            //Return to library view
            [self.view setUserInteractionEnabled:YES];
            [self.navigationController popViewControllerAnimated:YES];
        }
        else {
            [[ServerCommunicationController sharedInstance] logCompleteManipulation:manipulationContext];
            
            if(conditionSetup.assessmentPageEnabled)
            {
                [self.view setUserInteractionEnabled:YES];
                [self loadAssessmentActivity];
            }
            else
            {
                [[ServerCommunicationController sharedInstance] studyContext].condition = @"NULL";
               
                //TODO: remove hard coded strings
                if([bookTitle containsString:@"- Unknown-1"])
                {
                    [[(LibraryViewController *)libraryViewController studentProgress] setStatusOfChapter:chapterTitle :COMPLETED fromBook:[bookTitle stringByReplacingOccurrencesOfString:@" - Unknown-1" withString:@""]];
                }
                else if([bookTitle containsString:@"- Unknown"])
                {
                    [[(LibraryViewController *)libraryViewController studentProgress] setStatusOfChapter:chapterTitle :COMPLETED fromBook:[bookTitle stringByReplacingOccurrencesOfString:@" - Unknown" withString:@""]];
                }
                else
                {
                    //Set chapter as completed
                    [[(LibraryViewController *)libraryViewController studentProgress] setStatusOfChapter:chapterTitle :COMPLETED fromBook:bookTitle];
                }
                
                //Return to library view
                [self.view setUserInteractionEnabled:YES];
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    }
    else {
        [self loadPage];
    }
}

/*
 * Loads the html content and solution steps for the current page.
 */
- (void)loadPage {
   
    animatingObjects = [[NSMutableDictionary alloc] init];
    [self.pmView loadPageFor:book andCurrentPage:currentPage];
    self.title = chapterTitle;
    
    //Instantiates all vocab variables
    [IntroductionClass loadFirstPageVocabulary:model :chapterTitle];
    
    //Set the current page id
    currentPageId = [book getIdForPageInChapterAndActivity:currentPage :chapterTitle :conditionSetup.currentMode];
    
    [self setManipulationContext];
    
    NSString *pageLanguage = [currentPage containsString:@"S.xhtml"] ? @"Spanish" : @"English";
    manipulationContext.pageLanguage = pageLanguage;
    
    [[ServerCommunicationController sharedInstance] logLoadPage:[manipulationContext pageLanguage] mode:[manipulationContext pageMode] number:[manipulationContext pageNumber] context:manipulationContext];
    
    //TODO: Remove hard coded strings
    //Get the solutions for the appropriate manipulation activity
    if (conditionSetup.condition == EMBRACE || ([chapterTitle isEqualToString:@"The Naughty Monkey"])) {
        PhysicalManipulationActivity *PMActivity;
        ImagineManipulationActivity *IMActivity;
        
        if (([chapterTitle isEqualToString:@"The Naughty Monkey"] && ([currentPageId rangeOfString:@"PM-2"].location != NSNotFound) && conditionSetup.condition == CONTROL))
        {
            IntroductionClass.allowInteractions = false;
            //Get the PM solution steps for the current chapter
            Chapter *chapter = [book getChapterWithTitle:chapterTitle]; //get current chapter
            PMActivity = (PhysicalManipulationActivity *)[chapter getActivityOfType:PM_MODE]; //get PM Activity from chapter
            PMSolution = [[[PMActivity PMSolutions] objectForKey:currentPageId] objectAtIndex:0]; //get PM solution
            currentIdea = [[[PMSolution solutionSteps] objectAtIndex:0] sentenceNumber];
            manipulationContext.ideaNumber = currentIdea;
        }
        else if (([chapterTitle isEqualToString:@"The Naughty Monkey"] && (([currentPageId rangeOfString:@"PM-1"].location != NSNotFound)|| ([currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) && conditionSetup.condition == CONTROL))
        {
            IntroductionClass.allowInteractions = false;
        }
        else if (conditionSetup.currentMode == PM_MODE) {
            IntroductionClass.allowInteractions = TRUE;
            
            //Get the PM solution steps for the current chapter
            Chapter *chapter = [book getChapterWithTitle:chapterTitle]; //get current chapter
            PMActivity = (PhysicalManipulationActivity *)[chapter getActivityOfType:PM_MODE]; //get PM Activity from chapter
            PMSolution = [[[PMActivity PMSolutions] objectForKey:currentPageId] objectAtIndex:0]; //get PM solution
            currentIdea = [[[PMSolution solutionSteps] objectAtIndex:0] sentenceNumber];
            manipulationContext.ideaNumber = currentIdea;
        }
        else if (conditionSetup.currentMode == IM_MODE) {
            //Get the IM solution steps for the current chapter
            Chapter *chapter = [book getChapterWithTitle:chapterTitle]; //get current chapter
            IMActivity = (ImagineManipulationActivity *)[chapter getActivityOfType:IM_MODE]; //get IM Activity from chapter
            IMSolution = [[[IMActivity IMSolutions] objectForKey:currentPageId] objectAtIndex:0]; //get IM solution
        }
    }
}

/*
 * Gets the number of steps for the current sentence and sets the current step to 1.
 * Performs steps automatically if needed. Step is complete if it's a non-action sentence.
 */
- (void)setupCurrentSentence {
    currentStep = 1;
    manipulationContext.stepNumber = currentStep;
    stepsComplete = FALSE;
    
    //Get number of steps for current sentence
    if (conditionSetup.appMode == ITS && [pageSentences count] > 0) {
        if (currentSentence > 0) {
            numSteps = [[[pageSentences objectAtIndex:currentSentence - 1] solutionSteps] count];
            
            //Set current complexity based on senten ce
            currentComplexity = [[pageSentences objectAtIndex:currentSentence - 1] complexity];
        }
        else {
            numSteps = 0; //sentence 0 is the title, so it has no steps
        }
    }
    else {
        //TODO: create function to return correct number of steps returnNumSteps
        if (conditionSetup.condition == CONTROL) {
            numSteps = [PMSolution getNumStepsForSentence:currentSentence];
        }
        else if (conditionSetup.condition == EMBRACE) {
            if (conditionSetup.currentMode == PM_MODE) {
                //NOTE: Currently hardcoded because The Best Farm Solutions-MetaData.xml is different format from other stories
                if ([bookTitle rangeOfString:@"The Best Farm"].location != NSNotFound) {
                    numSteps = [PMSolution getNumStepsForSentence:currentIdea];
                }
                else {
                    numSteps = [PMSolution getNumStepsForSentence:currentSentence];
                }
            }
            else if (conditionSetup.currentMode == IM_MODE) {
                numSteps = [IMSolution getNumStepsForSentence:currentSentence];
            }
        }
    }
    
    //If it is an action sentence, perform its solution steps if necessary
    if ([self.pmView isActionSentence:currentSentence]) {
        [self performAutomaticSteps];
    }
    else {
        [[ServerCommunicationController sharedInstance] logLoadStep:currentStep ofType:@"NULL" context:manipulationContext];
        
        stepsComplete = TRUE; //no steps to complete for non-action sentence
    }
    
    startTime = [NSDate date]; //for page statistics
}

/* Sets up the appearance of the current sentence by highlighting it as blue (if it is an action sentence)
 * or as black (if it is a non-action sentence).
 */
- (void)setupCurrentSentenceColor {
    [self.pmView setupCurrentSentenceColor:currentSentence condition:conditionSetup.condition
                                   andMode:conditionSetup.currentMode];
}

/*
 * Moves to next step in a sentence if possible. The step is performed automatically 
 * if it is ungroup, move, or swap image.
 */
- (void)incrementCurrentStep {
    //TODO: change currSolSteps && currSolStep to private and accessible to all functions in this view controller
    
    //Get steps for current sentence
    NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
    
    //Get current step to be completed
    ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
    
    if (conditionSetup.appMode == ITS) {
        //Not automatic step
        if (!([[currSolStep stepType] isEqualToString:@"ungroup"] || [[currSolStep stepType] isEqualToString:@"move"] || [[currSolStep stepType] isEqualToString:@"swapImage"])) {
            endTime = [NSDate date];
            double elapsedTime = [endTime timeIntervalSinceDate:startTime];
            
            //Record time for complexity
            [[pageStatistics objectForKey:currentPageId] addTime:elapsedTime ForComplexity:(currentComplexity - 1)];
            
            startTime = [NSDate date];
        }
    }
    
    //Check if able to increment current step
    if (currentStep < numSteps) {
        
        //if the current solution step is a custom pm, then increment current step minMenuOption times
        if ([@"PM_CUSTOM" isEqualToString: [currSolStep menuType]]){
            for (int i=0; i<minMenuItems; i++) {
                currentStep++;
            }
        }
        //current solution step is normal and just increment once
        else{
            currentStep++;
        }
        
        manipulationContext.stepNumber = currentStep;
        [self performAutomaticSteps]; //automatically perform ungroup or move steps if necessary
    }
    else {
        stepsComplete = TRUE; //no more steps to complete
    }
}

/*
 * Displays the assessment activity view controller
 */
- (void)loadAssessmentActivity {
    UIImage *background = [self getBackgroundImage];
    
    //TODO: Remove hard coded workaround and find way to have same functionality
    //Hardcoding for second Introduction to EMBRACE
    if ([[(LibraryViewController *)libraryViewController studentProgress] getStatusOfBook:[book title]] == COMPLETED && ([[(LibraryViewController *)libraryViewController studentProgress] getStatusOfBook:@"Second Introduction to EMBRACE"] == IN_PROGRESS || [[(LibraryViewController *)libraryViewController studentProgress] getStatusOfBook:@"Second Introduction to EMBRACE"] == COMPLETED))
        {
            //Create an instance of the assessment activity view controller
            AssessmentActivityViewController *assessmentActivityViewController = [[AssessmentActivityViewController alloc]initWithModel:model : libraryViewController :background :@"Second Introduction to EMBRACE" :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
        
            //Push the assessment view controller as the top controller
            [self.navigationController pushViewController:assessmentActivityViewController animated:YES];
        }
    else
    {
        //Create an instance of the assessment activity view controller
        AssessmentActivityViewController *assessmentActivityViewController = [[AssessmentActivityViewController alloc]initWithModel:model : libraryViewController :background :[book title] :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
        
        //Push the assessment view controller as the top controller
        [self.navigationController pushViewController:assessmentActivityViewController animated:YES];
    }
}

/*
 * Converts an ActionStep object to a PossibleInteraction object
 */
- (PossibleInteraction *)convertActionStepToPossibleInteraction:(ActionStep *)step {
    PossibleInteraction *interaction;
    
    //Get step information
    NSString *obj1Id = [step object1Id];
    NSString *obj2Id = [step object2Id];
    NSString *action = [step action];
    
    //Objects involved in interaction
    NSArray *objects;
    
    //Get hotspots for both objects associated with action, first assuming that obj1 is the subject of the interaction
    Hotspot *hotspot1 = [model getHotspotforObjectWithActionAndRole:obj1Id :action :@"subject"];
    Hotspot *hotspot2 = [model getHotspotforObjectWithActionAndRole:obj2Id :action :@"object"];
    
    //If no hotspots were found with obj1 as the subject, then assume obj1 is the object of the interaction
    //Add the subject before the object to the interaction
    if (hotspot1 == nil && hotspot2 == nil) {
        objects = [[NSArray alloc] initWithObjects:obj2Id, obj1Id, nil];
        
        hotspot1 = [model getHotspotforObjectWithActionAndRole:obj2Id :action :@"subject"];
        hotspot2 = [model getHotspotforObjectWithActionAndRole:obj1Id :action :@"object"];
    }
    else {
        objects = [[NSArray alloc] initWithObjects:obj1Id, obj2Id, nil];
    }
    
    NSArray *hotspotsForInteraction = [[NSArray alloc]initWithObjects:hotspot1, hotspot2, nil];
    
    //swap order of isEqualToStrings to resolve nil crashing events
    //The move case only applies if an object is being moved to another object, not a waypoint
    if ([[step stepType] isEqualToString:@"group"] ||
        [[step stepType] isEqualToString:@"move"] ||
        [[step stepType] isEqualToString:@"groupAuto"]) {
        interaction = [[PossibleInteraction alloc]initWithInteractionType:GROUP];
        
        [interaction addConnection:GROUP :objects :hotspotsForInteraction];
    }
    else if ([[step stepType] isEqualToString:@"ungroup"] ||
             [[step stepType] isEqualToString:@"ungroupAndStay"]) {
        interaction = [[PossibleInteraction alloc]initWithInteractionType:UNGROUP];
        
        [interaction addConnection:UNGROUP :objects :hotspotsForInteraction];
    }
    else if ([[step stepType] isEqualToString:@"disappear"]) {
        interaction = [[PossibleInteraction alloc]initWithInteractionType:DISAPPEAR];
        
        [interaction addConnection:DISAPPEAR :objects :hotspotsForInteraction];
    }
    
    return interaction;
}

/*
 * Perform any necessary setup for this physical manipulation page.
 * For example, if the cart should be connected to the tractor at the beginning of the story,
 * then this function will connect the cart to the tractor.
 */
- (void)performSetupForActivity {
    Chapter *chapter = [book getChapterWithTitle:chapterTitle]; //get current chapter
    
    PhysicalManipulationActivity *PMActivity = (PhysicalManipulationActivity *)[chapter getActivityOfType:PM_MODE]; //get PM Activity from chapter
    NSMutableArray *setupSteps = [[PMActivity setupSteps] objectForKey:currentPageId]; //get setup steps for current page
    
    for (ActionStep *setupStep in setupSteps) {
        if ([[setupStep stepType] isEqualToString:@"group"]) {
            PossibleInteraction *interaction = [self convertActionStepToPossibleInteraction:setupStep];
            [self performInteraction:interaction]; //groups the objects
        }
        else if ([[setupStep stepType] isEqualToString:@"move"]) {
            //Get information for move step type
            NSString *object1Id = [setupStep object1Id];
            NSString *action = [setupStep action];
            NSString *object2Id = [setupStep object2Id];
            NSString *waypointId = [setupStep waypointId];
            
            //Move either requires object1 to move to object2 (which creates a group interaction) or it requires object1 to move to a waypoint
            if (object2Id != nil) {
                PossibleInteraction* correctInteraction = [self getCorrectInteraction];
                [self performInteraction:correctInteraction]; //performs solution step
            }
            else if (waypointId != nil) {
                //Get position of hotspot in pixels based on the object image size
                Hotspot *hotspot = [model getHotspotforObjectWithActionAndRole:object1Id :action :@"subject"];
                CGPoint hotspotLocation = [self getHotspotLocationOnImage:hotspot];
                
                //Get position of waypoint in pixels based on the background size
                Waypoint* waypoint = [model getWaypointWithId:waypointId];
                CGPoint waypointLocation = [self getWaypointLocation:waypoint];
                
                if ([self.pmView isObjectCenter:object1Id]) {
                    hotspotLocation.x = 0;
                    hotspotLocation.y = 0;
                }
                
                //Move the object
                [self moveObject:object1Id :waypointLocation :hotspotLocation :false];
                
                //Clear highlighting
                [self.pmView clearAllHighLighting];
            }
        }
    }
}

/*
 * Performs ungroup, move, and swap image steps automatically
 */
- (void)performAutomaticSteps {
    if ([IntroductionClass.introductions objectForKey:chapterTitle] && [[IntroductionClass.performedActions objectAtIndex:INPUT] isEqualToString:@"next"]) {
        IntroductionClass.allowInteractions = TRUE;
    }
    
    //Perform steps only if they exist for the sentence
    if (numSteps > 0 && IntroductionClass.allowInteractions) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        [[ServerCommunicationController sharedInstance] logLoadStep:currentStep ofType:[currSolStep stepType] context:manipulationContext];
        
        //Automatically perform interaction if step is ungroup, move, or swap image
        if (!pinchToUngroup && ([[currSolStep stepType] isEqualToString:@"ungroup"] ||
                                [[currSolStep stepType] isEqualToString:@"ungroupAndStay"])) {
            PossibleInteraction *correctUngrouping = [self getCorrectInteraction];
            
            [self performInteraction:correctUngrouping];
            [self incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:@"groupAuto"]) {
            PossibleInteraction *correctGrouping = [self getCorrectInteraction];
            
            [self performInteraction:correctGrouping];
            [self incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:@"move"]) {
            [self moveObjectForSolution];
            [self incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:@"swapImage"]) {
            [self swapObjectImage];
            [self incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:@"appear"]) {
            [self loadImage];
            [self incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:@"appearAutoWithDelay"]) {
            [self loadImage];
            [self incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:@"disappearAuto"]) {
            [self hideImage];
            [self incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:@"disappearAutoWithDelay"]) {
            [self hideImage];
            [self incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:@"changeZIndex"]) {
            [self changeZIndex];
            [self incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:@"animate"]) {
            [self animateObject];
            [self incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:@"playSound"]) {
            NSString *file = [currSolStep fileName];
            
            
            if ([file isEqualToString:@"NaughtyMonkey_Script4.mp3"]
                && conditionSetup.language == BILINGUAL) {
                    [self.playaudioClass playAudioFile:self :@"NaughtyMonkey_Script4_S.mp3"];
            } else {
                [self.playaudioClass playAudioFile:self :file];
            }
            
            [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:[[currSolStep fileName] stringByDeletingPathExtension] inLanguage:@"NULL" ofType:@"Play Sound" :manipulationContext];
            
            [self incrementCurrentStep];
        }
    }
    
    if ([IntroductionClass.introductions objectForKey:chapterTitle] && [[IntroductionClass.performedActions objectAtIndex:INPUT] isEqualToString:@"next"]) {
        IntroductionClass.allowInteractions = FALSE;
    }
}

/*
 * Returns a CGPoint containing the x and y coordinates of the position of an object
 */
- (CGPoint)getObjectPosition:(NSString *)object {
    return [self.pmView getObjectPosition:object];
}

//TODO: add description, move to new class
- (void)animateObject {
    //Check solution only if it exists for the sentence
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:@"animate"]) {
            //Get information for animation step type
            NSString *object1Id = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            NSString *waypointId = [currSolStep waypointId];
            NSString *areaId = [currSolStep areaId];
            
            if ([areaId isEqualToString:@""]) {
                areaId = @"area";
            }
            
            CGPoint imageLocation = [self getObjectPosition:object1Id];
            
            //Calculate offset between top-left corner of image and the point clicked.
            delta = [self calculateDeltaForMovingObjectAtPoint:imageLocation];
            
            //Change the location to accounting for the difference between the point clicked and the top-left corner which is used to set the position of the image.
            CGPoint adjLocation = CGPointMake(imageLocation.x - delta.x, imageLocation.y - delta.y);
            
            CGPoint waypointLocation;
            
            if ([waypointId isEqualToString:@""]) {
                waypointLocation.x = 0;
                waypointLocation.y = 0;
            }
            else {
                Waypoint *waypoint = [model getWaypointWithId:waypointId];
                waypointLocation = [self getWaypointLocation:waypoint];
            }
            
            //Call the animateObject function in the js file.
            [self.pmView animateObject:object1Id from:adjLocation to:waypointLocation action:action areaId:areaId];
            [animatingObjects setObject:[NSString stringWithFormat:@"%@,%@,%@", @"animate", action, areaId] forKey:object1Id];
            
            [[ServerCommunicationController sharedInstance] logAnimateObject:object1Id forAction:action context:manipulationContext];
        }
    }
}

/*
 * Calls the buildPath function on the JS file
 * Sends all the points in an area or path to the the JS to load them in memory
 */
- (void)buildPath:(NSString *)areaId {
    [self.pmView buildPath:areaId pageId:currentPageId withModel:model];
}

/*
 * User pressed Library button. Write log data to file.
 */
- (void)viewWillDisappear:(BOOL)animated {
    [self.playaudioClass stopPlayAudioFile];
    [super viewWillDisappear:animated];
    
    if (![[self.navigationController viewControllers] containsObject:self]) {
        [[ServerCommunicationController sharedInstance] logPressLibrary:manipulationContext];
        [[ServerCommunicationController sharedInstance] studyContext].condition = @"NULL";
    }
}

/*
 * Tap gesture handles taps on menus, words, images
 */
//TODO: break up logic in if else statements into new functions
- (IBAction)tapGesturePerformed:(UITapGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];
    
    if ((conditionSetup.condition == EMBRACE && conditionSetup.currentMode == IM_MODE) && (!IntroductionClass.allowInteractions)) {
        IntroductionClass.allowInteractions = true;
    }
    
    //Check to see if we have a menu open. If so, process menu click.
    if (menu != nil && IntroductionClass.allowInteractions) {
        allowSnapback = false;
        
        int menuItem = [menu pointInMenuItem:location];
        
        //If we've selected a menuItem.
        if (menuItem != -1) {
            //Get the information from the particular menu item that was pressed.
            MenuItemDataSource *dataForItem = [menuDataSource dataObjectAtIndex:menuItem];
            PossibleInteraction *interaction = [dataForItem interaction];
            
            //Used to store menu item data as strings for logging
            NSMutableArray *menuItemData = [[NSMutableArray alloc] init];
            
            //Go through each connection in the interaction and extract data for logging
            for (Connection *connection in [interaction connections]) {
                NSMutableDictionary *connectionData = [[NSMutableDictionary alloc] init];
                
                NSArray *objects = [connection objects];
                NSString *hotspot = [(Hotspot *)[[connection hotspots] objectAtIndex:0] action];
                NSString *interactionType = [connection returnInteractionTypeAsString];
                
                [connectionData setObject:objects forKey:@"objects"];
                [connectionData setObject:hotspot forKey:@"hotspot"];
                [connectionData setObject:interactionType forKey:@"interactionType"];
                
                [menuItemData addObject:connectionData];
            }
            
            [[ServerCommunicationController sharedInstance] logSelectMenuItem:menuItemData atIndex:menuItem context:manipulationContext];

            [self checkSolutionForInteraction:interaction]; //check if selected interaction is correct
            
            if ((conditionSetup.condition == EMBRACE && conditionSetup.currentMode == IM_MODE) && (IntroductionClass.allowInteractions)) {
                IntroductionClass.allowInteractions = FALSE;
            }
            
            //allowSnapback = true;
        }
        //No menuItem was selected
        else {
            [[ServerCommunicationController sharedInstance] logSelectMenuItem:nil atIndex:-1 context:manipulationContext];
        }
        
        //No longer moving object
        movingObject = FALSE;
        movingObjectId = nil;
        allowSnapback =true;
        
        /* TODO: See if this is removalable in refactor
        //Re-add the tap gesture recognizer before the menu is removed
        //[self.view addGestureRecognizer:tapRecognizer];
        
        if (conditionSetup.condition == EMBRACE && conditionSetup.currentMode == PM_MODE) {
            //Remove menu.
            [menu removeFromSuperview];
            menu = nil;
            menuExpanded = FALSE;
        }*/
    }
    else {
        if (numSteps > 0 && IntroductionClass.allowInteractions) {
            //Get steps for current sentence
            NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];

            if ([currSolSteps count] > 0) {
                //Get current step to be completed
                ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
                
                //Current step is checkAndSwap
                if ([[currSolStep stepType] isEqualToString:@"checkAndSwap"]) {
                    //Get the object at this point
                    NSString *imageAtPoint = [self getObjectAtPoint:location ofType:nil];
                    
                    [[ServerCommunicationController sharedInstance] logTapObject:imageAtPoint :manipulationContext];
                    
                    //If the correct object was tapped, swap its image and increment the step
                    if ([self checkSolutionForSubject:imageAtPoint]) {
                        [[ServerCommunicationController sharedInstance] logVerification:true forAction:@"Tap Object" context:manipulationContext];
                        
                        [self swapObjectImage];
                        [self incrementCurrentStep];
                    }
                }
                else if ([[currSolStep stepType] isEqualToString:@"tapToAnimate"] ||
                         [[currSolStep stepType] isEqualToString:@"shakeOrTap"]) {
                    //Get the object at this point
                    NSString *imageAtPoint = [self getObjectAtPoint:location ofType:nil];
                    
                    [[ServerCommunicationController sharedInstance] logTapObject:imageAtPoint :manipulationContext];
                    
                    //If the correct object was tapped, increment the step
                    if ([self checkSolutionForSubject:imageAtPoint]) {
                        [[ServerCommunicationController sharedInstance] logVerification:true forAction:@"Tap Object" context:manipulationContext];
                        
                        [self incrementCurrentStep];
                    }
                    
                }
            }
        }
        
        //Get the object at that point if it's a manipulation object.
        NSString *imageAtPoint = [self getObjectAtPoint:location ofType:@"manipulationObject"];
        
        //Retrieve the name of the object at this location
        
        imageAtPoint = [self.pmView getElementAtLocation:location];
        
        //Capture the clicked text id, if it exists
        NSString *sentenceID = [self.pmView getElementAtLocation:location];
        int sentenceIDNum = [[sentenceID stringByReplacingOccurrencesOfString:@"s" withString:@""] intValue];

        NSString *requestSentenceText;
        NSString *sentenceText;
        
        if([currentPageId rangeOfString:@"-Intro"].location != NSNotFound) {
            //Capture the clicked text, if it exists
            sentenceText = [self.pmView getCurrentSentenceAt:sentenceIDNum];
        }
        else {
            //Capture the clicked text, if it exists
            requestSentenceText = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).innerHTML", location.x, location.y];
            sentenceText = [self.pmView getTextAtLocation:location];
        }
        
        //Capture the spanish extension
        NSString *spanishExt = [self.pmView getSpanishExtention:location];

        if (conditionSetup.appMode == ITS) {
            //Record vocabulary request for complexity
            [[pageStatistics objectForKey:currentPageId] addVocabTapForComplexity:(currentComplexity - 1)];
        }
        
        //Convert to lowercase so the sentence text can be mapped to objects
        sentenceText = [sentenceText lowercaseString];
        NSString *englishSentenceText = sentenceText;
        
        if (conditionSetup.language == BILINGUAL) {
            if (![[self getEnglishTranslation:sentenceText] isEqualToString:@"Translation not found"]) {
                englishSentenceText = [self getEnglishTranslation:sentenceText];
            }
        }
        
        //Vocabulary introduction mode
        if ([currentPageId rangeOfString:@"-Intro"].location != NSNotFound) {
            //Get steps for current sentence
            NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
            
            if ([currSolSteps count] > 0) {
                //Get current step to be completed
                ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
            
                if([[currSolStep stepType] isEqualToString:@"tapWord"]) {
                    if([englishSentenceText containsString: [currSolStep object1Id]] && (currentSentence == sentenceIDNum) && !stepsComplete) {
                        [[ServerCommunicationController sharedInstance] logTapWord:sentenceText :manipulationContext];
                        
                        [self incrementCurrentStep];
                        [self playIntroVocabWord:englishSentenceText :currSolStep];
                    }
                }
            }
        }
        //Taps on vocab word in story
        else if ([currentPageId rangeOfString:@"-PM"].location != NSNotFound) {
            //Get steps for current sentence
            NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
            
            if (![self.playaudioClass isAudioLeftInSequence]) {
                if (currSolSteps != nil && [currSolSteps count] > 0) {
                    //Get current step to be completed
                    ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
                    
                    if ([[currSolStep stepType] isEqualToString:@"tapWord"]) {
                        if (([[currSolStep object1Id] containsString: englishSentenceText] && (currentSentence == sentenceIDNum)) ||
                            ([chapterTitle isEqualToString:@"The Naughty Monkey"] && conditionSetup.condition == CONTROL && [[currSolStep object1Id] containsString: englishSentenceText] && currentSentence == 2 && [currentPageId rangeOfString:@"-PM-2"].location != NSNotFound) ||
                            ([chapterTitle isEqualToString:@"The Naughty Monkey"] && conditionSetup.condition == EMBRACE && [[currSolStep object1Id] containsString: englishSentenceText] && (currentSentence == sentenceIDNum) && currentSentence !=2 && [currentPageId rangeOfString:@"-PM-2"].location != NSNotFound)) {
                            [[ServerCommunicationController sharedInstance] logTapWord:sentenceText :manipulationContext];
                            [self.playaudioClass stopPlayAudioFile];
                            [self playAudioForVocabWord: englishSentenceText : spanishExt];
                            [self incrementCurrentStep];
                        }
                        else if([[Translation translationWords] objectForKey:englishSentenceText]) {
                            [[ServerCommunicationController sharedInstance] logTapWord:englishSentenceText :manipulationContext];
                            [self.playaudioClass stopPlayAudioFile];
                            [self playAudioForVocabWord: englishSentenceText : spanishExt];
                        }
                    }
                    else if([[Translation translationWords] objectForKey:englishSentenceText]) {
                        [[ServerCommunicationController sharedInstance] logTapWord:englishSentenceText :manipulationContext];
                        [self.playaudioClass stopPlayAudioFile];
                        [self playAudioForVocabWord: englishSentenceText : spanishExt];
                    }
                }
                else if([[Translation translationWords] objectForKey:englishSentenceText]) {
                    [[ServerCommunicationController sharedInstance] logTapWord:englishSentenceText :manipulationContext];
                    [self.playaudioClass stopPlayAudioFile];
                    [self playAudioForVocabWord: englishSentenceText : spanishExt];
                }
            }
        }
    }
    
    if ((conditionSetup.condition == EMBRACE && conditionSetup.currentMode == IM_MODE) && (IntroductionClass.allowInteractions)) {
        IntroductionClass.allowInteractions = false;
    }
}

//TODO: add description, condense code
- (void)playAudioForVocabWord:(NSString *)englishSentenceText :(NSString *)spanishExt {
    
    //Since the name of the carbon dioxide file is carbonDioxide, its name is hard-coded
    if ([englishSentenceText isEqualToString:@"carbon dioxide"]) {
        englishSentenceText = @"carbonDioxide";
    }
    
    if (conditionSetup.language == BILINGUAL) {
        NSString *spanishAudio = [NSString stringWithFormat:@"%@%@.mp3", [englishSentenceText capitalizedString], @"S"];
        NSString *engAudio = [NSString stringWithFormat:@"%@%@.mp3", [englishSentenceText capitalizedString], @"E"];
        
        if ([spanishExt isEqualToString:@""] == NO) {
            spanishAudio = [NSString stringWithFormat:@"%@%@.mp3", [englishSentenceText capitalizedString], spanishExt];
        }
        
        //Play Sp audio then En auido
        bool success = [self.playaudioClass playAudioInSequence:self :spanishAudio : engAudio];
        
        if (!success) {
            NSString *spanishAudio = [NSString stringWithFormat:@"%@%@.m4a", englishSentenceText, @"S"];
            NSString *engAudio = [NSString stringWithFormat:@"%@%@.m4a", englishSentenceText, @"E"];
            
            if ([spanishExt isEqualToString:@""] == NO) {
                spanishAudio = [NSString stringWithFormat:@"%@%@.m4a", englishSentenceText, spanishExt];
            }
            
            [self.playaudioClass playAudioInSequence:self :spanishAudio :engAudio];
        }
        
        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:englishSentenceText inLanguage:@"Spanish" ofType:@"Play Word" :manipulationContext];
        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:englishSentenceText inLanguage:@"English" ofType:@"Play Word" :manipulationContext];
        
        [[ITSController sharedInstance] userDidPlayWord:englishSentenceText];
    }
    else {
        //Play En audio twice
        NSString *engAudio = [NSString stringWithFormat:@"%@%@.mp3", [englishSentenceText capitalizedString], @"E"];
        
        //Play Sp audio then En auido
        bool success = [self.playaudioClass playAudioInSequence:self :engAudio :engAudio];
        
        if (!success) {
            engAudio = [NSString stringWithFormat:@"%@%@.m4a", englishSentenceText, @"E"];
            [self.playaudioClass playAudioInSequence:self :engAudio :engAudio];
        }

        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:englishSentenceText inLanguage:@"English" ofType:@"Play Word" :manipulationContext];
        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:englishSentenceText inLanguage:@"English" ofType:@"Play Word" :manipulationContext];
        
        [[ITSController sharedInstance] userDidPlayWord:englishSentenceText];
        
    }
    
    //Revert the carbon dioxide name for highlighting
    if ([englishSentenceText isEqualToString:@"carbonDioxide"]) {
        englishSentenceText = @"carbon dioxide";
    }
    
    [self highlightImageForText:englishSentenceText];
}


//TODO: add description, condense code
- (void) playIntroVocabWord: (NSString *) englishSentenceText : (ActionStep *) currSolStep {
    if (conditionSetup.language == ENGLISH) {
        //Play En audio
        bool success = [self.playaudioClass playAudioFile:self:[NSString stringWithFormat:@"%@%@.mp3", [englishSentenceText capitalizedString], @"_def_E"]];
        
        if (!success) {
//            //if error try m4a format
//            [self.playaudioClass playAudioFile:self:[NSString stringWithFormat:@"%@%@.m4a", englishSentenceText, @"E"]];
            
            [self.playaudioClass playAudioFile:self :[NSString stringWithFormat:@"%@%@.mp3", [englishSentenceText capitalizedString], @"E"]];
        }
       
        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:englishSentenceText inLanguage:@"English" ofType:@"Play Word with Definition" :manipulationContext];
    }
    else {
        //Play Sp Audio
        bool success = [self.playaudioClass playAudioFile:self:[NSString stringWithFormat:@"%@%@.mp3",[englishSentenceText capitalizedString],@"_def_S"]];
    
        if (!success) {
//            //if error try m4a format
//            [self.playaudioClass playAudioFile:self:[NSString stringWithFormat:@"%@%@.m4a" ,englishSentenceText, @"S"]];
            
            [self.playaudioClass playAudioFile:self:[NSString stringWithFormat:@"%@%@.mp3" ,[englishSentenceText capitalizedString], @"S"]];
        }
        
        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:englishSentenceText inLanguage:@"Spanish" ofType:@"Play Word with Definition" :manipulationContext];
    }

    [self highlightImageForText:englishSentenceText];

    // This delay is needed in order to be able to play the last definition on a vocabulary page
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,[self.playaudioClass audioDuration]*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        //if audioPlayer is nil then we have returned to library view and should not play audio
        if ([self.playaudioClass audioPlayer] != nil) {
            //Play En audio
            bool success = [self.playaudioClass playAudioFile:self:[NSString stringWithFormat:@"%@%@.mp3",[englishSentenceText capitalizedString],@"_def_E"]];
        
            if (!success) {
                //if error try m4a format
                [self.playaudioClass playAudioFile:self:[NSString stringWithFormat:@"%@%@.m4a",englishSentenceText,@"E"]];
            }
        
            [self highlightImageForText:englishSentenceText];
        
            currentSentence++;
            currentSentenceText = [self.pmView getCurrentSentenceAt:currentSentence];
            stepsComplete = NO;
            
            manipulationContext.sentenceNumber = currentSentence;
            manipulationContext.sentenceText = currentSentenceText;
            manipulationContext.manipulationSentence = [self isManipulationSentence:currentSentence];
            [[ServerCommunicationController sharedInstance] logLoadSentence:currentSentence withText:currentSentenceText manipulationSentence:manipulationContext.manipulationSentence context:manipulationContext];
        
            [self performSelector:@selector(colorSentencesUponNext) withObject:nil afterDelay:([self.playaudioClass audioPlayer].duration)];
        }
    });
}

//TODO: add description, remove hard coded strings
- (NSMutableArray *)returnCurrentSolutionSteps {
    NSMutableArray *currSolSteps;
    
    if (conditionSetup.appMode == ITS && [currentPageId rangeOfString:@"-Intro"].location == NSNotFound) {
        if (currentSentence > 0) {
            currSolSteps = [[pageSentences objectAtIndex:currentSentence - 1] solutionSteps];
        }
    }
    else {
        if (conditionSetup.condition == CONTROL) {
            currSolSteps = [PMSolution getStepsForSentence:currentSentence];
        }
        else if (conditionSetup.condition == EMBRACE) {
            if (conditionSetup.currentMode == PM_MODE) {
                //NOTE: Currently hardcoded because The Best Farm Solutions-MetaData.xml is different format from other stories
                if ([bookTitle rangeOfString:@"The Best Farm"].location != NSNotFound
                    && [currentPageId rangeOfString:@"-Intro"].location == NSNotFound) {
                    currSolSteps = [PMSolution getStepsForSentence:currentIdea];
                }
                else {
                    currSolSteps = [PMSolution getStepsForSentence:currentSentence];
                }
            }
            else if (conditionSetup.currentMode == IM_MODE) {
                currSolSteps = [IMSolution getStepsForSentence:currentSentence];
            }
        }
    }
    
    return currSolSteps;
}

/*
 *  Highlights the image of the selected
 */
- (void)highlightImageForText:(NSString *)englishSentenceText {
    NSObject *valueImage = [[Translation translationImages]objectForKey:englishSentenceText];
    
    if (valueImage == nil) {
        valueImage = englishSentenceText;
    }
    
    NSString *imageHighlighted = @"";
    
    //If the key contains more than one value
    if ([valueImage isKindOfClass:[NSArray class]]) {
        NSArray *imageArray = ((NSArray *)valueImage);
        for (int i = 0; i < [imageArray count]; i++) {
            imageHighlighted = imageArray[i];
            [self highlightObject:imageHighlighted:1.5];
        }
    }
    else {
        imageHighlighted = (NSString *)valueImage;
        [self highlightObject:imageHighlighted:1.5];
    }
}

/*
 * Long press gesture. Either tap or long press can be used for definitions.
 */
//TODO: remove comments
- (IBAction)longPressGesturePerformed:(UILongPressGestureRecognizer *)recognizer {
    //This is the location of the point in the parent UIView, not in the UIWebView.
    //These two coordinate systems may be different.
    /*CGPoint location = [recognizer locationInView:self.view];
     
     NSString *requestImageAtPoint = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).id", location.x, location.y];
     
     NSString *imageAtPoint = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPoint];*/
    
    //NSLog(@"imageAtPoint: %@", imageAtPoint);
}

/*
 * Swipe gesture. Only recognizes a downwards two finger swipe. Used to skip the current step
 * by performing it automatically according to the solution.
 */
//TODO: confirm all gestures are included in emergency swipe
- (IBAction)swipeGesturePerformed:(UISwipeGestureRecognizer *)recognizer {
    //Emergency swipe to bypass the vocab intros
    if ([IntroductionClass.vocabularies objectForKey:chapterTitle] && [currentPageId rangeOfString:@"Intro"].location != NSNotFound) {
        [[ServerCommunicationController sharedInstance] logEmergencySwipe:manipulationContext];
        [self.playaudioClass stopPlayAudioFile];
        [self loadNextPage];
    }
    //Perform steps only if they exist for the sentence and have not been completed
    else if ((numSteps > 0 && !stepsComplete && conditionSetup.condition == EMBRACE && conditionSetup.currentMode == PM_MODE) || ([chapterTitle isEqualToString:@"The Naughty Monkey"] && numSteps > 0 && !stepsComplete)) {
        [[ServerCommunicationController sharedInstance] logEmergencySwipe:manipulationContext];
        
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        NSString *stepType = [currSolStep stepType];
        
        if ([stepType isEqualToString:@"check"] || [stepType isEqualToString:@"checkLeft"] || [stepType isEqualToString:@"checkRight"] || [stepType isEqualToString:@"checkUp"] || [stepType isEqualToString:@"checkDown"] || [stepType isEqualToString:@"checkAndSwap"] || [stepType isEqualToString:@"tapToAnimate"] || [stepType isEqualToString:@"checkPath"] || [stepType isEqualToString:@"shakeAndTap"] || [stepType isEqualToString:@"tapWord"] ) {
            if ([stepType isEqualToString:@"checkAndSwap"]) {
                [self swapObjectImage];
            }
            
            [self incrementCurrentStep];
        }
        //Current step is either group, ungroup, disappear, or transference
        else {
            //Get the interaction to be performed
            PossibleInteraction *interaction = [self getCorrectInteraction];
            
            //Perform the interaction and increment the step
            [self checkSolutionForInteraction:interaction];
        }
    }
}

/*
 * Pinch gesture. Used to ungroup two images from each other.
 */
- (IBAction)pinchGesturePerformed:(UIPinchGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan && IntroductionClass.allowInteractions && pinchToUngroup) {
        pinching = TRUE;
        
        NSString *imageAtPoint = [self getObjectAtPoint:location ofType:@"manipulationObject"];
        
        //if it's an image that can be moved, then start moving it.
        if (imageAtPoint != nil && !stepsComplete) {
            separatingObjectId = imageAtPoint;
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        //Get pairs of other objects grouped with this object.
        NSArray *itemPairArray = [self getObjectsGroupedWithObject:separatingObjectId];
        
        if (itemPairArray != nil) {
            NSMutableArray *possibleInteractions = [[NSMutableArray alloc] init];
        
            for (NSString *pairStr in itemPairArray) {
                //Create an array that will hold all the items in this group
                NSMutableArray *groupedItemsArray = [[NSMutableArray alloc] init];
                
                //Separate the objects in this pair and add them to our array of all items in this group.
                [groupedItemsArray addObjectsFromArray:[pairStr componentsSeparatedByString:@", "]];
                
                //Only allow the correct subject and object to ungroup if necessary
                BOOL allowSubjectToUngroup = false;
                BOOL allowObjectToUngroup = false;
                
                for (NSString *obj in groupedItemsArray) {
                    if (useSubject == ONLY_CORRECT) {
                        if ([self checkSolutionForSubject:obj]) {
                            allowSubjectToUngroup = true;
                        }
                    }
                    else if (useSubject == ALL_ENTITIES) {
                        allowSubjectToUngroup = true;
                    }
                    
                    if (useObject == ONLY_CORRECT) {
                        if ([self checkSolutionForObject:obj]) {
                            allowObjectToUngroup = true;
                        }
                    }
                    else if (useObject == ALL_ENTITIES) {
                        allowObjectToUngroup = true;
                    }
                }
                
                //Objects are allowed to ungroup
                if (allowSubjectToUngroup && allowObjectToUngroup) {
                    PossibleInteraction *interaction = [[PossibleInteraction alloc] initWithInteractionType:UNGROUP];
                    [interaction addConnection:UNGROUP :groupedItemsArray :nil];
                    
                    //Only one possible ungrouping found
                    if ([itemPairArray count] == 1) {
                        [self checkSolutionForInteraction:interaction]; //check if interaction is correct before ungrouping
                    }
                    //Multiple possible ungroupings found
                    else {
                        [possibleInteractions addObject:interaction];
                    }
                }
            }
            
            //Show the menu if multiple possible ungroupings are found
            if ([itemPairArray count] > 1) {
                //Populate the data source and expand the menu.
                [self populateMenuDataSource:possibleInteractions:allRelationships];
                
                if (!menuExpanded)
                    [self expandMenu];
            }
        }
        else
            NSLog(@"no items grouped");
        
        pinching = FALSE;
    }
}

/*
 * Pan gesture. Used to move objects from one location to another.
 */
//TODO: move logic in if else statements into new functions
- (IBAction)panGesturePerformed:(UIPanGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];

    //This should work with requireGestureRecognizerToFail:pinchRecognizer but it doesn't currently.
    if (!pinching && IntroductionClass.allowInteractions) {
        BOOL useProximity = NO;
        
        static UIBezierPath *path = nil;
        static CAShapeLayer *shapeLayer = nil;
        
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            //Starts true because the object starts within the area
            wasPathFollowed = true;
            
            panning = TRUE;
            
            //Get the object at that point if it's a manipulation object.
            NSString *imageAtPoint = [self getObjectAtPoint:location ofType:@"manipulationObject"];
            
            if ([IntroductionClass.introductions objectForKey:chapterTitle]) {
                stepsComplete = false;
            }
            
            //If it's an image that can be moved, then start moving it.
            if (imageAtPoint != nil && !stepsComplete) {
                movingObject = TRUE;
                movingObjectId = imageAtPoint;
            
                NSString *imageMarginLeft = [self.pmView imageMarginLeft:movingObjectId];
                NSString *imageMarginTop = [self.pmView imageMarginTop:movingObjectId];
                
                if (![imageMarginLeft isEqualToString:@""] && ![imageMarginTop isEqualToString:@""]) {
                    //Calulate offset between top-left corner of image and the point clicked for centered images
                    delta = [self calculateDeltaForMovingObjectAtPointWithCenter:movingObjectId :location];
                }
                else {
                    //Calculate offset between top-left corner of image and the point clicked.
                    delta = [self calculateDeltaForMovingObjectAtPoint:location];
                }
                
                //Record the starting location of the object when it is selected
                startLocation = CGPointMake(location.x - delta.x, location.y - delta.y);
                
                if ([animatingObjects objectForKey:imageAtPoint] && [[animatingObjects objectForKey:imageAtPoint] containsString: @"animate"]) {
                    
                    NSArray *animation = [[animatingObjects objectForKey:imageAtPoint] componentsSeparatedByString: @","];
                    NSString *animationType = animation[1];
                    NSString *animationAreaId = animation[2];
                
                    [self.pmView animateObject:imageAtPoint from:startLocation to:CGPointZero action:@"pauseAnimation" areaId:@""];
                    
                    [animatingObjects setObject:[NSString stringWithFormat:@"%@,%@,%@", @"pause", animationType, animationAreaId]  forKey:imageAtPoint];
                }
            }
        }
        else if (recognizer.state == UIGestureRecognizerStateEnded) {
            path = nil;
            panning = FALSE;
            
            //If moving object, move object to final position.
            if (movingObject) {
                [self moveObject:movingObjectId :location :delta :true];
                NSArray *overlappingWith = [self getObjectsOverlappingWithObject:movingObjectId];
                if (numSteps > 0) {
                    //Get steps for current sentence
                    NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
                    
                    //Get current step to be completed
                    ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
                    
                    if ([[currSolStep stepType] isEqualToString:@"check"] ||
                        [[currSolStep stepType] isEqualToString:@"checkLeft"] ||
                        [[currSolStep stepType] isEqualToString:@"checkRight"] ||
                        [[currSolStep stepType] isEqualToString:@"checkUp"] ||
                        [[currSolStep stepType] isEqualToString:@"checkDown"]) {
                        //Check if object is in the correct location or area
                        if ((([[currSolStep stepType] isEqualToString:@"checkLeft"] && startLocation.x > endLocation.x ) ||
                            ([[currSolStep stepType] isEqualToString:@"checkRight"] && startLocation.x < endLocation.x ) ||
                            ([[currSolStep stepType] isEqualToString:@"checkUp"] && startLocation.y > endLocation.y ) ||
                            ([[currSolStep stepType] isEqualToString:@"checkDown"] && startLocation.y < endLocation.y )) ||
                           ([self isHotspotInsideLocation] || [self isHotspotInsideArea])) {
//                            if ([IntroductionClass.introductions objectForKey:chapterTitle]) {
//                                /*Check to see if an object is at a certain location or is grouped with another object e.g. farmergetIncorralArea or farmerleadcow. These strings come from the solution steps */
//                                if ([[IntroductionClass.performedActions objectAtIndex:INPUT] isEqualToString:[NSString stringWithFormat:@"%@%@%@",[currSolStep object1Id], [currSolStep action], [currSolStep locationId]]]
//                                   || [[IntroductionClass.performedActions objectAtIndex:INPUT] isEqualToString:[NSString stringWithFormat:@"%@%@%@",[currSolStep object1Id], [currSolStep action], [currSolStep object2Id]]]) {
//                                        IntroductionClass.currentIntroStep++;
//                                    [IntroductionClass loadIntroStep:bookView:self: currentSentence];
//                                }
//                            }
                            
                            if ([self checkSolutionForSubject:movingObjectId]) {
                                NSString *destination;
                                
                                if ([currSolStep locationId] != nil) {
                                    destination = [currSolStep locationId];
                                }
                                else if ([currSolStep areaId] != nil) {
                                    destination = [currSolStep areaId];
                                }
                                else {
                                    destination = @"NULL";
                                }
                                
                                [[ServerCommunicationController sharedInstance] logMoveObject:movingObjectId toDestination:destination ofType:@"Location" startPos:startLocation endPos:endLocation performedBy:USER context:manipulationContext];

                                [[ServerCommunicationController sharedInstance] logVerification:true forAction:@"Move Object" context:manipulationContext];
                                [[ITSController sharedInstance] movedObject:movingObjectId
                                                          destinationObjects:@[destination]
                                                                 isVerified:true
                                                                 actionStep:currSolStep
                                                        manipulationContext:manipulationContext
                                                                forSentence:currentSentenceText
                                                            withWordMapping:model.wordMapping];
                                
                                [animatingObjects setObject:@"stop" forKey:movingObjectId];
                                [self incrementCurrentStep];
                            }
                            //Reset object location
                            else {
                                [[ServerCommunicationController sharedInstance] logMoveObject:movingObjectId toDestination:@"NULL" ofType:@"Location" startPos:startLocation endPos:endLocation performedBy:USER context:manipulationContext];

                                [self handleErrorForAction:@"Move Object"];
                                
                                [[ITSController sharedInstance] movedObject:movingObjectId
                                                         destinationObjects:overlappingWith
                                                                 isVerified:false
                                                                 actionStep:currSolStep
                                                        manipulationContext:manipulationContext
                                                                forSentence:currentSentenceText
                                 withWordMapping:model.wordMapping];
                            }
                        }
                        else {
                            [[ServerCommunicationController sharedInstance] logMoveObject:movingObjectId toDestination:@"NULL" ofType:@"Location" startPos:startLocation endPos:endLocation performedBy:USER context:manipulationContext];
                            
                            [self handleErrorForAction:@"Move Object"];
                            
                            // Find the location if overlapping is nil;
                            if (overlappingWith == nil) {
                                
                                NSString *areaId = [model getObjectIdAtLocation:endLocation];
                                if (areaId)
                                    overlappingWith = @[areaId];
                                
                            }
                            [[ITSController sharedInstance] movedObject:movingObjectId
                                                     destinationObjects:overlappingWith
                                                             isVerified:false
                                                             actionStep:currSolStep
                                                    manipulationContext:manipulationContext
                                                            forSentence:currentSentenceText
                                                        withWordMapping:model.wordMapping];
                        }
                    }
                    else if ([[currSolStep stepType] isEqualToString:@"shakeOrTap"]) {
                        [[ServerCommunicationController sharedInstance] logMoveObject:movingObjectId toDestination:@"NULL" ofType:@"Location" startPos:startLocation endPos:endLocation performedBy:USER context:manipulationContext];
                        
                        if ([self checkSolutionForSubject:movingObjectId] && ([self areHotspotsInsideArea] || [self isHotspotInsideLocation])) {
                            [[ServerCommunicationController sharedInstance] logVerification:true forAction:@"Move Object" context:manipulationContext];
                            
                            [animatingObjects setObject:@"stop" forKey:movingObjectId];
                            
                            [[ITSController sharedInstance] movedObject:movingObjectId
                                                     destinationObjects:@[currSolStep.locationId]
                                                             isVerified:true
                                                             actionStep:currSolStep
                                                    manipulationContext:manipulationContext
                                                            forSentence:currentSentenceText
                                                        withWordMapping:model.wordMapping];
                            
                            [self resetObjectLocation];
                            [self incrementCurrentStep];
                        }
                        else {
                            [self handleErrorForAction:@"Move Object"];
                            
                            [[ITSController sharedInstance] movedObject:movingObjectId
                                                     destinationObjects:@[currSolStep.locationId]
                                                             isVerified:false
                                                             actionStep:currSolStep
                                                    manipulationContext:manipulationContext
                                                            forSentence:currentSentenceText
                                                        withWordMapping:model.wordMapping];
                        }
                    }
                    else if ([[currSolStep stepType] isEqualToString:@"checkPath"]) {
                        [[ServerCommunicationController sharedInstance] logMoveObject:movingObjectId toDestination:@"NULL" ofType:@"Location" startPos:startLocation endPos:endLocation performedBy:USER context:manipulationContext];
                        
                        if (wasPathFollowed) {
                            [[ServerCommunicationController sharedInstance] logVerification:true forAction:@"Move Object" context:manipulationContext];
                            
                            [animatingObjects setObject:@"stop" forKey:movingObjectId];
                            [self incrementCurrentStep];
                        }
                        else {
                            [self handleErrorForAction:@"Move Object"];
                        }
                    }
                    else {
                        //Check if the object is overlapping anything
                        NSArray *overlappingWith = [self getObjectsOverlappingWithObject:movingObjectId];
                        
                        //Get possible interactions only if the object is overlapping something
                        if (overlappingWith != nil) {
                            [[ServerCommunicationController sharedInstance] logMoveObject:movingObjectId toDestination:[overlappingWith componentsJoinedByString:@", "] ofType:@"Object" startPos:startLocation endPos:endLocation performedBy:USER context:manipulationContext];
                            
                            //Resets allRelationship arrray
                            if ([allRelationships count]) {
                                [allRelationships removeAllObjects];
                            }
                            
                            //If the object was dropped, check if it's overlapping with any other objects that it could interact with.
                            NSMutableArray *possibleInteractions = [self getPossibleInteractions:useProximity];
                            
                            //No possible interactions were found
                            if ([possibleInteractions count] == 0) {
                                [self handleErrorForAction:@"Move Object"];
                                
                                [[ITSController sharedInstance] movedObject:movingObjectId
                                                         destinationObjects:overlappingWith
                                                                 isVerified:false
                                                                 actionStep:currSolStep
                                                        manipulationContext:manipulationContext
                                                                forSentence:currentSentenceText
                                                            withWordMapping:model.wordMapping];
                            }
                            //If only 1 possible interaction was found, go ahead and perform that interaction if it's correct.
                            if ([possibleInteractions count] == 1) {
                                PossibleInteraction *interaction = [possibleInteractions objectAtIndex:0];

                                //Checks solution and accomplishes action trace
                                [self checkSolutionForInteraction:interaction];
                            }
                            //If more than 1 was found, prompt the user to disambiguate.
                            else if ([possibleInteractions count] > 1) {
                                //The chapter title hard-coded for now
//                                if ([IntroductionClass.introductions objectForKey:chapterTitle] &&
//                                    [[IntroductionClass.performedActions objectAtIndex:INPUT] isEqualToString:
//                                     [NSString stringWithFormat:@"%@%@%@",[currSolStep object1Id], [currSolStep action], [currSolStep object2Id]]]) {
//
//                                    IntroductionClass.currentIntroStep++;
//                                    [IntroductionClass loadIntroStep:bookView :self :currentSentence];
//                                }
                                
                                PossibleInteraction* correctInteraction = [self getCorrectInteraction];
                                BOOL correctInteractionExists = false;
                                
                                //Look for the correct interaction
                                for (int i = 0; i < [possibleInteractions count]; i++) {
                                    if ([[possibleInteractions objectAtIndex:i] isEqual:correctInteraction]) {
                                        correctInteractionExists = true;
                                    }
                                }
                                
                                //Only populate Menu if user is moving the correct object to the correct objects
                                if (correctInteractionExists) {
                                    //TODO: add a parameter check
                                    if (!menuExpanded && [@"PM_CUSTOM" isEqualToString:[currSolStep menuType]]) {
                                        //Reset allRelationships arrray
                                        if ([allRelationships count]) {
                                            [allRelationships removeAllObjects];
                                        }
                                        
                                        PossibleInteraction *interaction;
                                        NSMutableArray *interactions = [[NSMutableArray alloc]init ];
                                        
                                        if (currSolSteps.count != 0 && (currSolSteps.count+1-currentStep) >= minMenuItems) {
                                            for (int i = currentStep-1; i < (currentStep-1+minMenuItems); i++) {
                                                ActionStep *currSolStep = currSolSteps[i];
                                                interaction = [self convertActionStepToPossibleInteraction:currSolStep];
                                                [interactions addObject:interaction];
                                                Relationship *relationshipBetweenObjects = [[Relationship alloc] initWithValues:[currSolStep object1Id] : [currSolStep action] : [currSolStep stepType] : [currSolStep object2Id]];
                                                [allRelationships addObject:relationshipBetweenObjects];
                                            }
                                            
                                            interactions = [self shuffleMenuOptions: interactions];
                                            
                                            //Populate the menu data source and expand the menu.
                                            [self populateMenuDataSource:interactions :allRelationships];
                                            [self expandMenu];
                                        }
                                        else {
                                            //TODO: log error
                                        }
                                        
                                    }
                                    else if (!menuExpanded) {
                                        //First rank the interactions based on location to story.
                                        [self rankPossibleInteractions:possibleInteractions];
                                        
                                        //Populate the menu data source and expand the menu.
                                        [self populateMenuDataSource:possibleInteractions :allRelationships];
                                        [self expandMenu];
                                    }
                                    else {
                                        //TODO: add log statement
                                    }
                                }
                                //Otherwise reset object location and play error noise
                                else {
                                    [self handleErrorForAction:@"Move Object"];
                                }
                            }
                        }
                        //Not overlapping any object
                        else {
                            [[ServerCommunicationController sharedInstance] logMoveObject:movingObjectId toDestination:@"NULL" ofType:@"Location" startPos:startLocation endPos:endLocation performedBy:USER context:manipulationContext];
                            
                            [self handleErrorForAction:@"Move Object"];
                            
                            // Find the location if overlapping is nil;
                            if (overlappingWith == nil) {
                                //TODO: Find the object precent in destination location.
                                NSString *areaId = [model getObjectIdAtLocation:endLocation];
                                NSLog(@"Area - %@",areaId);
                                if (areaId)
                                    overlappingWith = @[areaId];
                                
                            }
                            [[ITSController sharedInstance] movedObject:movingObjectId
                                                     destinationObjects:overlappingWith
                                                             isVerified:false
                                                             actionStep:currSolStep
                                                    manipulationContext:manipulationContext
                                                            forSentence:currentSentenceText
                                                        withWordMapping:model.wordMapping];
                        }
                    }
                }
                
                if (!menuExpanded) {
                    //No longer moving object
                    movingObject = FALSE;
                    movingObjectId = nil;
                }
                
                [self.pmView clearAllHighLighting];
            }
        }
        //If we're in the middle of moving the object, just call the JS to move it.
        else if (movingObject)  {
            //Set to true for debugging; set to false to disable
            if (false) {
                // Start drawing the path
                CGPoint pointLocation = [recognizer locationInView:recognizer.view];
                
                if (!path) {
                    path = [UIBezierPath bezierPath];
                    [path moveToPoint:pointLocation];
                    
                    shapeLayer = [[CAShapeLayer alloc] init];
                    shapeLayer.strokeColor = [self generateRandomColor].CGColor;
                    shapeLayer.fillColor = [UIColor clearColor].CGColor;
                    shapeLayer.lineWidth = 10.0;
                    [recognizer.view.layer addSublayer:shapeLayer];
                    
                }
                else {
                    [path addLineToPoint:pointLocation];
                    shapeLayer.path = path.CGPath;
                }
                
                if (![self isHotspotInsideArea]) {
                    wasPathFollowed = false;
                }
            }
            
            [self moveObject:movingObjectId :location :delta :true];
            
            //If we're overlapping with another object, then we need to figure out which hotspots are currently active and highlight those hotspots.
            //When moving the object, we may have the JS return a list of all the objects that are currently grouped together so that we can process all of them.
            NSArray *overlappingWith = [self getObjectsOverlappingWithObject:movingObjectId];
            
            if (overlappingWith != nil) {
                for (NSString *objId in overlappingWith) {
                    //We have the list of objects it's overlapping with, we now have to figure out which hotspots to draw.
                    NSMutableArray *hotspots = [model getHotspotsForObject:objId OverlappingWithObject:movingObjectId];
                    
                    //Since hotspots are filtered based on relevant relationships between objects, only highlight objects that have at least one hotspot returned by the model.
                    if ([hotspots count] > 0) {
                        [self.pmView highLightObject:objId];
                    }
                }
            }
        }
    }
}

//TODO: add description
- (void)resetObjectLocation {
    if (allowSnapback) {
        //Snap the object back to its original location
        [self moveObject:movingObjectId :startLocation :CGPointMake(0, 0) :false];
        
        //If it was an animation object, animate it again after snapping back
        if ([animatingObjects objectForKey:movingObjectId] && [[animatingObjects objectForKey:movingObjectId] containsString: @"pause"]) {
            NSArray *animation = [[animatingObjects objectForKey:movingObjectId] componentsSeparatedByString: @","];
            NSString *animationType = animation[1];
            NSString *animationAreaId = animation[2];
        
            [self.pmView animateObject:movingObjectId
                                  from:startLocation
                                    to:CGPointZero
                                action:animationType
                                areaId:animationAreaId];
           
            [animatingObjects setObject:[NSString stringWithFormat:@"%@,%@,%@", @"animate", animationType, animationAreaId] forKey:movingObjectId];
        }
        
        [[ServerCommunicationController sharedInstance] logResetObject:movingObjectId startPos:endLocation endPos:startLocation context:manipulationContext];
    }
}

//TODO: add description
- (UIColor *)generateRandomColor {
    NSInteger aRedValue = arc4random() % 255;
    NSInteger aGreenValue = arc4random() % 255;
    NSInteger aBlueValue = arc4random() % 255;
    
    UIColor *randColor = [UIColor colorWithRed:aRedValue/255.0f green:aGreenValue/255.0f blue:aBlueValue/255.0f alpha:1.0f];
    
    return randColor;
}

//TODO: add description
- (UIImage *)getBackgroundImage{
    return [self.pmView getBackgroundImage];
}

/*
 * Gets the necessary information from the JS for this particular image id and creates a
 * MenuItemImage out of that information. If FLIP is TRUE, the image will be horizontally 
 * flipped. If the image src isn't found, returns nil. Otherwise, returned the MenuItemImage 
 * that was created.
 */
- (MenuItemImage *)createMenuItemForImage:(NSString *)objId :(NSString *)FLIP {
    return [self.pmView createMenuItemForImage:objId flip:FLIP];
    
}

/*
 * This function takes in a possible interaction and calculates the layout of the images after the interaction occurs.
 * It then adds the result to the menuDataSource in order to display each menu item appropriately.
 * NOTE: For the moment this code could be used to create both the ungroup and all other interactions...lets see if this is the case after this code actually simulates the end result. If it is, the code should be simplified to use the same function.
 * NOTE: This should be pushed to the JS so that all actual positioning information is in one place and we're not duplicating code that's in the JS in the objC as well. For now...we'll just do it here.
 * Come back to this...
 */
- (void)simulatePossibleInteractionForMenuItem:(PossibleInteraction *)interaction :(Relationship *)relationship {
    NSMutableDictionary *images = [[NSMutableDictionary alloc] init];
    
    //Populate the mutable dictionary of menuItemImages.
    for (Connection* connection in [interaction connections]) {
        NSArray *objectIds = [connection objects];
        
        //Get all the necessary information of the UIImages.
        for (int i = 0; i < [objectIds count]; i++) {
            NSString *objId = objectIds[i];
            
            if ([images objectForKey:objId] == nil) {
                MenuItemImage *itemImage;
                
                //Horizontally flip the image of the subject performing a transfer and disappear interaction to make it look like it is giving an object to the receiver.
                if ([interaction interactionType] == TRANSFERANDDISAPPEAR
                    && [connection interactionType] == UNGROUP
                    && objId == [[connection objects] objectAtIndex:0]) {
                    itemImage = [self createMenuItemForImage:objId :@"rotate"];
                }
                else if ([[relationship action] isEqualToString:@"flip"])
                {
                    itemImage = [self createMenuItemForImage:objId : @"flipHorizontal"];
                }
                //Otherwise, leave the image unflipped
                else {
                    itemImage = [self createMenuItemForImage:objId : @"normal"];
                }
                
                if (itemImage != nil)
                    [images setObject:itemImage forKey:objId];
            }
        }
        
        //If the objects are already connected to other objects, create images for those as well, if they haven't already been created
        for (NSString *objectId in objectIds) {
            NSMutableArray *connectedObject = [currentGroupings objectForKey:objectId];
            
            for (int i = 0; connectedObject && [connection interactionType] != UNGROUP && i < [connectedObject count]; i++) {
                if ([images objectForKey:connectedObject[i]] == nil) {
                    MenuItemImage *itemImage = [self createMenuItemForImage:connectedObject[i] :@"normal"];
                    
                    if (itemImage != nil) {
                        [images setObject:itemImage forKey:connectedObject[i]];
                    }
                }
            }
        }
    }
    
    //Perform the changes to the connections.
    for (Connection* connection in [interaction connections]) {
        NSArray *objectIds = [connection objects];
        NSArray *hotspots = [connection hotspots];
        
        //Update the locations of the UIImages based on the type of interaction with the simulated location.
        //get the object Ids for this particular menuItem.
        NSString *obj1 = [objectIds objectAtIndex:0]; //get object 1
        NSString *obj2 = [objectIds objectAtIndex:1]; //get object 2
        NSString *connectedObject;
        Hotspot *connectedHotspot1;
        Hotspot *connectedHotspot2;
        
        if ([connection interactionType] == UNGROUP) {
            float GAP; //we want a pixel gap between objects to show that they're no longer grouped together.
            
            //The object performing a transfer and disappear interaction will be ungrouped from the object
            //it is transferring, but we use a negative GAP value because we still want it to appear close
            //enough to look as though it is giving the object to the receiver.
            if ([interaction interactionType] == TRANSFERANDDISAPPEAR)
                GAP = -15;
            //For other ungroup interactions, we want a 15 pixel gap between objects to show they are separated
            else
                GAP = 15;
            
            [self simulateUngrouping:obj1 :obj2 :images :GAP];
        }
        else if ([connection interactionType] == GROUP || [connection interactionType] == DISAPPEAR) {
            //Get hotspots.
            Hotspot *hotspot1 = [hotspots objectAtIndex:0];
            Hotspot *hotspot2 = [hotspots objectAtIndex:1];
            
            //Find all objects connected to the moving object
            for (int objectIndex = 2; objectIndex < [objectIds count]; objectIndex++) {
                //For each object, find the hotspots that serve as the connection points
                connectedObject = [objectIds objectAtIndex:objectIndex];
                
                NSMutableArray *movingObjectHotspots = [model getHotspotsForObject:obj1 OverlappingWithObject:connectedObject];
                NSMutableArray *containedHotspots = [model getHotspotsForObject:connectedObject OverlappingWithObject:obj1];
                
                connectedHotspot1 = [self findConnectedHotspot:movingObjectHotspots :connectedObject];
                connectedHotspot2 = [self findConnectedHotspot:containedHotspots :connectedObject];
                
                //This object is connected to the moving object at a particular hotspot
                if (![[connectedHotspot2 objectId] isEqualToString:@""]) {
                    for (Hotspot *ht in containedHotspots) {
                        CGPoint hotspotLoc = [self.pmView getHotspotLocation:ht];
                        NSString *isHotspotConnectedMovingObjectString = [self.pmView groupedObject:connectedObject atHotSpot:hotspotLoc];
                        if ([isHotspotConnectedMovingObjectString isEqualToString:obj1])
                            connectedHotspot2 = ht;
                    }
                }
            }
            
            NSMutableArray *groupObjects = [[NSMutableArray alloc] initWithObjects:obj1, obj2, connectedObject, nil];
            NSMutableArray *hotspotsForGrouping = [[NSMutableArray alloc] initWithObjects:hotspot1, hotspot2, connectedHotspot2, nil];
            
            [self simulateGroupingMultipleObjects:groupObjects :hotspotsForGrouping :images];
        }
    }
    
    NSMutableArray *imagesArray = [[images allValues] mutableCopy];
    
    //Calculate the bounding box for the group of objects being passed to the menu item.
    CGRect boundingBox = [self getBoundingBoxOfImages:imagesArray];
    
    [menuDataSource addMenuItem:interaction :relationship :imagesArray :boundingBox];
}

/*
 * This function gets passed in an array of MenuItemImages and calculates the bounding box for the entire array.
 */
- (CGRect)getBoundingBoxOfImages:(NSMutableArray *)images {
    CGRect boundingBox = CGRectMake(0, 0, 0, 0);
    
    if ([images count] > 0) {
        float leftMostPoint = ((MenuItemImage *)[images objectAtIndex:0]).boundingBoxImage.origin.x;
        float topMostPoint = ((MenuItemImage *)[images objectAtIndex:0]).boundingBoxImage.origin.y;
        float rightMostPoint = ((MenuItemImage *)[images objectAtIndex:0]).boundingBoxImage.origin.x + ((MenuItemImage *)[images objectAtIndex:0]).boundingBoxImage.size.width;
        float bottomMostPoint = ((MenuItemImage *)[images objectAtIndex:0]).boundingBoxImage.origin.y + ((MenuItemImage *)[images objectAtIndex:0]).boundingBoxImage.size.height;
        
        for (MenuItemImage *image in images) {
            if (image.boundingBoxImage.origin.x < leftMostPoint)
                leftMostPoint = image.boundingBoxImage.origin.x;
            if (image.boundingBoxImage.origin.y < topMostPoint)
                topMostPoint = image.boundingBoxImage.origin.y;
            if (image.boundingBoxImage.origin.x + image.boundingBoxImage.size.width > rightMostPoint)
                rightMostPoint = image.boundingBoxImage.origin.x + image.boundingBoxImage.size.width;
            if (image.boundingBoxImage.origin.y + image.boundingBoxImage.size.height > bottomMostPoint)
                bottomMostPoint = image.boundingBoxImage.origin.y + image.boundingBoxImage.size.height;
        }
        
        boundingBox = CGRectMake(leftMostPoint, topMostPoint, rightMostPoint - leftMostPoint,
                                 bottomMostPoint - topMostPoint);
    }
    
    return boundingBox;
}


//TODO: add description
- (void)simulateGrouping:(NSString *)obj1 :(Hotspot *)hotspot1 :(NSString *)obj2 :(Hotspot *)hotspot2 :(NSMutableDictionary *)images {
    CGPoint hotspot1Loc = [self calculateHotspotLocationBasedOnBoundingBox:hotspot1 :[[images objectForKey:obj1] boundingBoxImage]];
    CGPoint hotspot2Loc = [self calculateHotspotLocationBasedOnBoundingBox:hotspot2 :[[images objectForKey:obj2] boundingBoxImage]];
    
    //Figure out the distance necessary for obj1 to travel such that hotspot1 and hotspot2 are in the same location.
    float deltaX = hotspot2Loc.x - hotspot1Loc.x; //get the delta between the 2 hotspots.
    float deltaY = hotspot2Loc.y - hotspot1Loc.y;
    
    //Get the location of the top left corner of obj1.
    MenuItemImage* obj1Image = [images objectForKey:obj1];
    CGFloat positionX = [obj1Image boundingBoxImage].origin.x;
    CGFloat positionY = [obj1Image boundingBoxImage].origin.y;
    
    //set the location of the top left corner of the image being moved to its current top left corner + delta.
    CGFloat obj1FinalPosX = positionX + deltaX;
    CGFloat obj1FinalPosY = positionY + deltaY;
    
    [obj1Image setBoundingBoxImage:CGRectMake(obj1FinalPosX, obj1FinalPosY, [obj1Image boundingBoxImage].size.width, [obj1Image boundingBoxImage].size.height)];
}

//TODO: add description
- (void)simulateGroupingMultipleObjects:(NSMutableArray *)objs :(NSMutableArray *)hotspots :(NSMutableDictionary *)images {
    CGPoint hotspot1Loc = [self calculateHotspotLocationBasedOnBoundingBox:hotspots[0]
                                                                          :[[images objectForKey:objs[0]] boundingBoxImage]];
    CGPoint hotspot2Loc = [self calculateHotspotLocationBasedOnBoundingBox:hotspots[1]
                                                                          :[[images objectForKey:objs[1]] boundingBoxImage]];
    
    //Figure out the distance necessary for obj1 to travel such that hotspot1 and hotspot2 are in the same location.
    float deltaX = hotspot2Loc.x - hotspot1Loc.x; //get the delta between the 2 hotspots.
    float deltaY = hotspot2Loc.y - hotspot1Loc.y;
    
    //Get the location of the top left corner of obj1.
    MenuItemImage *obj1Image = [images objectForKey:objs[0]];
    CGFloat positionX = [obj1Image boundingBoxImage].origin.x;
    CGFloat positionY = [obj1Image boundingBoxImage].origin.y;
    
    //set the location of the top left corner of the image being moved to its current top left corner + delta.
    CGFloat obj1FinalPosX = positionX + deltaX;
    CGFloat obj1FinalPosY = positionY + deltaY;
    
    [obj1Image setBoundingBoxImage:CGRectMake(obj1FinalPosX, obj1FinalPosY, [obj1Image boundingBoxImage].size.width, [obj1Image boundingBoxImage].size.height)];
   
    NSMutableArray *connectedObjects = [currentGroupings valueForKey:objs[0]];
    
    if (connectedObjects && [connectedObjects count] > 0) {
        //Get locations of all objects connected to object1
        MenuItemImage *obj3Image = [images objectForKey:connectedObjects[0]];
        CGFloat connectedObjectPositionX = [obj3Image boundingBoxImage].origin.x;
        CGFloat connectedObjectPositionY = [obj3Image boundingBoxImage].origin.y;
    
        //find the final position of the connect objects
        CGFloat obj3FinalPosX = connectedObjectPositionX + deltaX;
        CGFloat obj3FinalPosY = connectedObjectPositionY + deltaY;
    
        [obj3Image setBoundingBoxImage:CGRectMake(obj3FinalPosX, obj3FinalPosY, [obj3Image boundingBoxImage].size.width, [obj3Image boundingBoxImage].size.height)];
    }
}

//TODO: add description
- (void)simulateUngrouping:(NSString *)obj1 :(NSString *)obj2 :(NSMutableDictionary *)images :(float)GAP {
    
    [self.pmView simulateUngrouping:obj1
                            object2:obj2
                             images:images
                                gap:GAP];
}

/*
 * This checks the PossibleInteractin passed in to figure out what type of interaction it is,
 * extracts the necessary information and calls the appropriate function to perform the interaction.
 */
- (void)performInteraction:(PossibleInteraction *)interaction {
    for (Connection *connection in [interaction connections]) {
        NSArray *objectIds = [connection objects]; //get the object Ids for this particular menuItem.
        NSArray *hotspots = [connection hotspots]; //Array of hotspot objects.
        
        //Get object 1 and object 2
        NSString *obj1 = [objectIds objectAtIndex:0];
        NSString *obj2 = [objectIds objectAtIndex:1];
        
        if ([connection interactionType] == UNGROUP && [[self getCurrentSolutionStep] isEqualToString:@"ungroupAndStay"]) {
            [self ungroupObjectsAndStay:obj1 :obj2];
            
            [[ServerCommunicationController sharedInstance] logGroupOrUngroupObjects:obj1 object2:obj2 ofType:@"Ungroup and Stay Objects" hotspot:@"NULL" :manipulationContext];
        }
        else if ([connection interactionType] == UNGROUP) {
            [self ungroupObjects:obj1 :obj2]; //ungroup objects
            
            [[ServerCommunicationController sharedInstance] logGroupOrUngroupObjects:obj1  object2:obj2 ofType:@"Ungroup Objects" hotspot:@"NULL" :manipulationContext];
        }
        else if ([connection interactionType] == GROUP) {
            //Get hotspots.
            Hotspot *hotspot1 = [hotspots objectAtIndex:0];
            Hotspot *hotspot2 = [hotspots objectAtIndex:1];
            
            CGPoint hotspot1Loc = [self.pmView getHotspotLocation:hotspot1];
            CGPoint hotspot2Loc = [self.pmView getHotspotLocation:hotspot2];
            
            [self groupObjects:obj1 :hotspot1Loc :obj2 :hotspot2Loc]; //group objects
            
            [[ServerCommunicationController sharedInstance] logGroupOrUngroupObjects:obj1  object2:obj2 ofType:@"Group Objects" hotspot:[hotspot1 action] :manipulationContext];
        }
        else if ([connection interactionType] == DISAPPEAR) {
            [self consumeAndReplenishSupply:obj2]; //make object disappear
            
            [[ServerCommunicationController sharedInstance] logAppearOrDisappearObject:obj2 ofType:@"Disappear Object" context:manipulationContext];
        }
    }
}

/*
 * Returns true if the specified subject from the solutions is part of a group with the
 * specified object. Otherwise, returns false.
 */
- (BOOL)isSubject:(NSString *)subject ContainedInGroupWithObject:(NSString *)object {
    //Get pairs of other objects grouped with this object
    NSArray *itemPairArray = [self getObjectsGroupedWithObject:object];
    
    if (itemPairArray != nil) {
        //Create an array that will hold all the items in this group
        NSMutableArray *groupedItemsArray = [[NSMutableArray alloc] init];
        
        for (NSString *pairStr in itemPairArray) {
            //Separate the objects in this pair and add them to our array of all items in this group.
            [groupedItemsArray addObjectsFromArray:[pairStr componentsSeparatedByString:@", "]];
        }
        
        //Checks if one of the grouped objects is the subject
        for (NSString *obj in groupedItemsArray) {
            if ([obj isEqualToString:subject])
                return true;
        }
    }
    
    return false;
}

/*
 * Returns true if the correct object is selected as the subject based on the solutions
 * for group step types. Otherwise, it returns false.
 */
- (BOOL)checkSolutionForSubject:(NSString *)subject {
    //Check solution only if it exists for the sentence
    if (numSteps > 0 && !stepsComplete) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:@"transferAndGroup"]) {
            //Get next sentence step
            ActionStep *nextSolStep = [currSolSteps objectAtIndex:currentStep];
            
            //Correct subject for a transfer and group step is the obj1 of the next transfer and group step
            NSString *correctSubject = [nextSolStep object1Id];
            
            //Selected object is the correct subject
            if ([correctSubject isEqualToString:subject]) {
                return true;
            }
            else {
                //Check if selected object is in a group with the correct subject
                BOOL isSubjectInGroup = [self isSubject:correctSubject ContainedInGroupWithObject:subject];
                return isSubjectInGroup;
            }
        }
        else {
            NSString *correctSubject = [currSolStep object1Id];
            
            //Selected object is the correct subject
            if ([correctSubject isEqualToString:subject]) {
                return true;
            }
            else {
                //Check if selected object is in a group with the correct subject
                BOOL isSubjectInGroup = [self isSubject:correctSubject ContainedInGroupWithObject:subject];
                return isSubjectInGroup;
            }
        }
    }
    else {
        stepsComplete = TRUE; //no steps to complete for current sentence
        
        //User cannot move anything if there are no steps to be performed
        return false;
    }
}

/*
 * Returns true if the active object is overlapping the correct object based on the solutions.
 * Otherwise, it returns false.
 */
- (BOOL)checkSolutionForObject:(NSString *)overlappingObject {
    //Check solution only if it exists for the sentence
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        //If current step requires transference and group, the correct object depends on the format used.
        //transferAndGroup steps may be written in two different ways:
        //   1. obj2Id is the same for both steps, so correct object is object1 of next step
        //      (ex. farmer give bucket; cat accept bucket)
        //   2. obj2Id of first step is obj1Id of second step, so correct object is object2 of next step
        //      (ex. farmer putDown hay; hay getIn cart)
        if ([[currSolStep stepType] isEqualToString:@"transferAndGroup"]) {
            //Get next step
            ActionStep *nextSolStep = [currSolSteps objectAtIndex:currentStep];

            if ([[currSolStep object2Id] isEqualToString:[nextSolStep object2Id]]) {
                if ([overlappingObject isEqualToString:[nextSolStep object1Id]]) {
                    return true;
                }
            }
            else {
                if ([overlappingObject isEqualToString:[nextSolStep object2Id]]) {
                    return true;
                }
            }
        }
        //If current step requires transference and disapppear, the correct object should be the object1 of the next step
        else if ([[currSolStep stepType] isEqualToString:@"transferAndDisappear"]) {
            //Get next step
            ActionStep *nextSolStep = [currSolSteps objectAtIndex:currentStep];
            
            if ([overlappingObject isEqualToString:[nextSolStep object1Id]]) {
                return true;
            }
        }
        else {
            if ([overlappingObject isEqualToString:[currSolStep object2Id]]) {
                return true;
            }
        }
    }
    
    return false;
}

/*
 * Moves an object to another object or waypoint for move step types
 */
- (void)moveObjectForSolution {
    //Check solution only if it exists for the sentence
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:@"move"]) {
            //Get information for move step type
            NSString *object1Id = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            NSString *object2Id = [currSolStep object2Id];
            NSString *waypointId = [currSolStep waypointId];
            
            //Move either requires object1 to move to object2 (which creates a group interaction) or it requires object1 to move to a waypoint
            if (object2Id != nil) {
                PossibleInteraction *correctInteraction = [self getCorrectInteraction];
                [self performInteraction:correctInteraction]; //performs solution step
            }
            else if (waypointId != nil) {
                //Get position of hotspot in pixels based on the object image size
                Hotspot *hotspot = [model getHotspotforObjectWithActionAndRole:object1Id :action :@"subject"];
                CGPoint hotspotLocation = [self getHotspotLocationOnImage:hotspot];
                
                //Get position of waypoint in pixels based on the background size
                Waypoint *waypoint = [model getWaypointWithId:waypointId];
                CGPoint waypointLocation = [self getWaypointLocation:waypoint];
                
                if ([self.pmView isObjectCenter:object1Id]) {
                    hotspotLocation.x = 0;
                    hotspotLocation.y = 0;
                }
                
                //Move the object
                [self moveObject:object1Id :waypointLocation :hotspotLocation :false];
                
                //Clear highlighting
                [self.pmView clearAllHighLighting];
                
                [[ServerCommunicationController sharedInstance] logMoveObject:object1Id toDestination:[waypoint waypointId] ofType:@"Waypoint" startPos:startLocation endPos:waypointLocation performedBy:SYSTEM context:manipulationContext];
            }
        }
    }
}

/*
 * Calls the JS function to swap an object's image with its alternate one
 */
- (void)swapObjectImage {
    //Check solution only if it exists for the sentence
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:@"swapImage"] || [[currSolStep stepType] isEqualToString:@"checkAndSwap"]) {
            //Get information for swapImage step type
            NSString *object1Id = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            
            //Get alternate image
            AlternateImage* altImage = [model getAlternateImageWithActionAndObjectID:action :object1Id];
            
            //Get alternate image information
            NSString *altSrc = [altImage alternateSrc];
            NSString *width = [altImage width];
            NSString *height = [altImage height];
            CGPoint location = [altImage location];
            NSString *zIndex = [altImage zPosition];
        
            [self.pmView swapImages:object1Id
                       alternateSrc:altSrc
                              width:width
                             height:height
                           location:location
                             zIndex:zIndex];
            
            [[ServerCommunicationController sharedInstance] logSwapImageForObject:object1Id altImage:[altSrc stringByDeletingPathExtension] context:manipulationContext];
        }
    }
}

/*
 * Loads an image calling the loadImage JS function and using the AlternateImage class
 */
- (void)loadImage {
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:@"appear"] ||
            [[currSolStep stepType] isEqualToString:@"appearAutoWithDelay"]) {
            //Get information for appear step type
            NSString *object1Id = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            
            //Get alternate image
            AlternateImage *altImage = [model getAlternateImageWithActionAndObjectID:action:object1Id];
            
            //Get alternate image information
            NSString *altSrc = [altImage alternateSrc];
            NSString *width = [altImage width];
            NSString *height = [altImage height];
            CGPoint location = [altImage location];
            NSString *className = [altImage className];
            NSString *zPosition = [altImage zPosition];
            
        
            if ([[currSolStep stepType] isEqualToString:@"appear"]) {
               [self.pmView loadImage:object1Id
                         alternateSrc:altSrc
                                width:width
                               height:height
                             location:location
                            className:className
                               zIndex:zPosition];
                
                [[ServerCommunicationController sharedInstance] logAppearOrDisappearObject:object1Id ofType:@"Appear Object" context:manipulationContext];
            }
            else if([[currSolStep stepType] isEqualToString:@"appearAutoWithDelay"]) {
                NSInteger delay = [[currSolStep object2Id] intValue];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    
                    [self.pmView loadImage:object1Id
                              alternateSrc:altSrc
                                     width:width
                                    height:height
                                  location:location
                                 className:className
                                    zIndex:zPosition];
                    
                    [[ServerCommunicationController sharedInstance] logAppearOrDisappearObject:object1Id ofType:@"Appear Object" context:manipulationContext];
                });
            }
        }
    }
}

/*
 * Calls the removeImage from the ImageManipulation.js file
 */
- (void)hideImage {
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:@"disappearAuto"]) {
            NSString *object2Id = [currSolStep object2Id];
            
            //Hide image
            [self.pmView removeObject:object2Id];
            [[ServerCommunicationController sharedInstance] logAppearOrDisappearObject:object2Id ofType:@"Disappear Object" context:manipulationContext];
        }
        else if ([[currSolStep stepType] isEqualToString:@"disappearAutoWithDelay"]) {
            NSString *object1Id = [currSolStep object1Id];
            NSInteger delay = [[currSolStep object2Id] intValue];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                //Hide image
                [self.pmView removeObject:object1Id];
                
                [[ServerCommunicationController sharedInstance] logAppearOrDisappearObject:object1Id ofType:@"Disappear Object" context:manipulationContext];
            });
        }
    }
}

/*
 * Calls the changeZIndex from ImageManipulation.js file
 */
- (void)changeZIndex {
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:@"changeZIndex"]) {
            //Get information for appear step type
            NSString *object1Id = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            
            //Get alternate image
            AlternateImage* altImage = [model getAlternateImageWithActionAndObjectID:action:object1Id];
            
            //Get alternate image information
            NSString *altSrc = [altImage alternateSrc];
            NSString *width = [altImage width];
            CGPoint location = [altImage location];
            NSString *className = [altImage className];
            NSString *zPosition = [altImage zPosition];
            
            //Swap images using alternative src
            [self.pmView loadImage:object1Id
                      alternateSrc:altSrc
                             width:width
                            height:@""
                          location:location
                         className:className
                            zIndex:zPosition];
            
            [[ServerCommunicationController sharedInstance] logSwapImageForObject:object1Id altImage:altSrc context:manipulationContext];
        }
    }
}

/*
 * Returns true if the hotspot of an object (for a check step type) is inside the correct location.
 * Otherwise, returns false.
 */
- (BOOL)isHotspotInsideLocation {
    //Check solution only if it exists for the sentence
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:@"check"] ||
            [[currSolStep stepType] isEqualToString:@"checkPath"] ||
            [[currSolStep stepType] isEqualToString:@"shakeOrTap"]) {
            //Get information for check step type
            NSString *objectId = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            NSString *locationId = [currSolStep locationId];
            
            //Get hotspot location of correct subject
            Hotspot *hotspot = [model getHotspotforObjectWithActionAndRole:objectId :action :@"subject"];
            CGPoint hotspotLocation = [self.pmView getHotspotLocation:hotspot];
            
            //Get location that hotspot should be inside
            Location *location = [model getLocationWithId:locationId];
            
            //Calculate the x,y coordinates and the width and height in pixels from %
            float locationX = [location.originX floatValue] / 100.0 * [self.pmView frame].size.width;
            float locationY = [location.originY floatValue] / 100.0 * [self.pmView frame].size.height;
            float locationWidth = [location.width floatValue] / 100.0 * [self.pmView frame].size.width;
            float locationHeight = [location.height floatValue] / 100.0 * [self.pmView frame].size.height;
            
            //Check if hotspot is inside location
            if (((hotspotLocation.x < locationX + locationWidth) && (hotspotLocation.x > locationX)
                && (hotspotLocation.y < locationY + locationHeight) && (hotspotLocation.y > locationY)) || [locationId isEqualToString:@"anywhere"]) {
                return true;
            }
        }
    }
    
    return false;
}

/*
 * Returns true if the hotspot of an object (for a check step type) is inside the correct area. Otherwise, returns false.
 */
- (BOOL)isHotspotInsideArea {
    //Check solution only if it exists for the sentence
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:@"check"] || [[currSolStep stepType] isEqualToString:@"checkPath"]) {
            //Get information for check step type
            NSString *objectId = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            
            NSString *areaId = [currSolStep areaId];
            
            //Get hotspot location of correct subject
            Hotspot *hotspot = [model getHotspotforObjectWithActionAndRole:objectId :action :@"subject"];
            CGPoint hotspotLocation = [self.pmView getHotspotLocation:hotspot];
            
            //Get area that hotspot should be inside
            Area* area = [model getArea:areaId:currentPageId];
            
            if ([area.aPath containsPoint:hotspotLocation]) {
                return true;
            }
        }
    }
    
    return false;
}

/*
 * Returns true if the start location and the end location of an object are within the same area. Otherwise, returns false.  
 */
- (BOOL)areHotspotsInsideArea {
    //Check solution only if it exists for the sentence
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:@"shakeOrTap"]) {
            //Get information for check step type
            NSString *objectId = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            NSString *areaId = [currSolStep areaId];
            
            //Get hotspot location of correct subject
            Hotspot *hotspot = [model getHotspotforObjectWithActionAndRole:objectId :action :@"subject"];
            CGPoint hotspotLocation = [self.pmView getHotspotLocation:hotspot];
            
            //Get area that hotspot should be inside
            Area *area = [model getArea:areaId : currentPageId];
            
            if (([area.aPath containsPoint:hotspotLocation] && [area.aPath containsPoint:startLocation]) || [areaId isEqualToString:@"anywhere"]) {
                return true;
            }
        }
    }
    
    return false;
}

/*
 * Returns true if a location belongs to an area path. Otherwise, returns false.
 */
- (BOOL)isHotspotOnPath {
    //Check solution only if it exists for the sentence
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:@"checkPath"]) {
            //Get information for check step type
            NSString *objectId = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            
            NSString *areaId = [currSolStep areaId];
            
            //Get hotspot location of correct subject
            Hotspot *hotspot = [model getHotspotforObjectWithActionAndRole:objectId :action :@"subject"];
            CGPoint hotspotLocation = [self.pmView getHotspotLocation:hotspot];
            
            //Get area that hotspot should be inside
            Area *area = [model getArea:areaId : currentPageId];
            
            if ([area.aPath containsPoint:hotspotLocation]){
                return true;
            }
        }
    }
    
    return false;
}

/*
 * Sends the JS request for the element at the location provided, and takes care of moving any
 * canvas objects out of the way to get accurate information.
 * It also checks to make sure the object that is at that point is of a certain class (manipulation or 
 * background) before returning it.
 */
- (NSString *)getObjectAtPoint:(CGPoint) location ofType:(NSString *)class {

    //Temporarily hide the overlay canvas to get the object we need
    [self.pmView hideCanvas];
    
    //Retrieve the elements at this location and see if it's an element that is moveable
    NSString *imageAtPoint = [self.pmView getElementAtLocation:location];
    NSString *imageAtPointClass = [self.pmView getClassForElemAtLocation:location];
    
    //Bring the canvas back to where it should be.
    [self.pmView showCanvas];
    
    //Check if the object has the correct class, or if no class was specified before returning
    if (( (class == nil) || (![imageAtPointClass isEqualToString:@""] && [imageAtPointClass rangeOfString:class].location != NSNotFound))) {
        //Any subject can be used, so just return the object id
        if (useSubject == ALL_ENTITIES)
            return imageAtPoint;
        //Check if the subject is correct before returning the object id
        else if (useSubject == ONLY_CORRECT) {
            if ([self checkSolutionForSubject:imageAtPoint])
                return imageAtPoint;
            else
                return nil;
        }
        else
            return nil;
    }
    else
        return nil;
}

/*
 * Gets the current solution step and returns it
 */
- (NSString *)getCurrentSolutionStep {
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        //If step type involves transference, we must manually create the PossibleInteraction object.
        //Otherwise, it can be directly converted.
        return [currSolStep stepType];
    }
    else {
        return nil;
    }
}

/*
 * Gets the current solution step of ActionStep type and converts it to a PossibleInteraction
 * object
 */
- (PossibleInteraction *)getCorrectInteraction {
    PossibleInteraction* correctInteraction;
    
    //Check solution only if it exists for the sentence
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        //If step type involves transference, we must manually create the PossibleInteraction object.
        //Otherwise, it can be directly converted.
        if ([[currSolStep stepType] isEqualToString:@"transferAndGroup"] ||
            [[currSolStep stepType] isEqualToString:@"transferAndDisappear"]) {
            correctInteraction = [[PossibleInteraction alloc] init];
            
            //Get step information for current step
            NSString *currObj1Id = [currSolStep object1Id];
            NSString *currObj2Id = [currSolStep object2Id];
            NSString *currAction = [currSolStep action];
            
            //Objects involved in group setup for current step
            NSArray *currObjects = [[NSArray alloc] initWithObjects:currObj1Id, currObj2Id, nil];
            
            //Get hotspots for both objects associated with action for current step
            Hotspot *currHotspot1 = [model getHotspotforObjectWithActionAndRole:currObj1Id :currAction :@"subject"];
            Hotspot *currHotspot2 = [model getHotspotforObjectWithActionAndRole:currObj2Id :currAction :@"object"];
            NSArray *currHotspotsForInteraction = [[NSArray alloc]initWithObjects:currHotspot1, currHotspot2, nil];
            
            [correctInteraction addConnection:UNGROUP :currObjects :currHotspotsForInteraction];
            
            //Get next step to be completed
            ActionStep *nextSolStep = [currSolSteps objectAtIndex:currentStep];
            
            //Get step information for next step
            NSString *nextObj1Id = [nextSolStep object1Id];
            NSString *nextObj2Id = [nextSolStep object2Id];
            NSString *nextAction = [nextSolStep action];
            
            //Objects involved in group setup for next step
            NSArray *nextObjects = [[NSArray alloc] initWithObjects:nextObj1Id, nextObj2Id, nil];
            
            //Get hotspots for both objects associated with action for next step
            Hotspot *nextHotspot1 = [model getHotspotforObjectWithActionAndRole:nextObj1Id :nextAction :@"subject"];
            Hotspot *nextHotspot2 = [model getHotspotforObjectWithActionAndRole:nextObj2Id :nextAction :@"object"];
            NSArray *nextHotspotsForInteraction = [[NSArray alloc]initWithObjects:nextHotspot1, nextHotspot2, nil];
            
            //Add the group or disappear connection and set the interaction to the appropriate type
            if ([[currSolStep stepType] isEqualToString:@"transferAndGroup"]) {
                [correctInteraction addConnection:GROUP :nextObjects :nextHotspotsForInteraction];
                [correctInteraction setInteractionType:TRANSFERANDGROUP];
            }
            else if ([[currSolStep stepType] isEqualToString:@"transferAndDisappear"]) {
                [correctInteraction addConnection:DISAPPEAR :nextObjects :nextHotspotsForInteraction];
                [correctInteraction setInteractionType:TRANSFERANDDISAPPEAR];
            }
        }
        else {
            correctInteraction = [self convertActionStepToPossibleInteraction:currSolStep];
        }
    }
    
    return correctInteraction;
}

/*
 * Checks if an interaction is correct by comparing it to the solution. If it is correct, the interaction is performed and 
 * the current step is incremented. If it is incorrect, an error noise is played, and the objects snap back to their 
 * original positions.
 */
//TODO: move logic in if else statements into new functions
- (void)checkSolutionForInteraction:(PossibleInteraction *)interaction {
    //Get correct interaction to compare
    PossibleInteraction *correctInteraction = [self getCorrectInteraction];
    
    //Check if selected interaction is correct
    if ([interaction isEqual:correctInteraction]) {
        if (conditionSetup.condition == EMBRACE && conditionSetup.currentMode == IM_MODE) {
            [[ServerCommunicationController sharedInstance] logVerification:true forAction:@"Select Menu Item" context:manipulationContext];
            
            //Re-add the tap gesture recognizer before the menu is removed
            [self.view addGestureRecognizer:tapRecognizer];
            
            //Remove menu
            [menu removeFromSuperview];
            menu = nil;
            menuExpanded = FALSE;
            
            if (IMViewMenu != nil) {
                [IMViewMenu removeFromSuperview];
            }
            
            didSelectCorrectMenuOption = true;
            /* TODO: See if this is removalable in refactor
            //For the moment just move through the sentences, until you get to the last one, then move to the next activity.
            if (currentSentence > 0) {
                currentIdea++;
                manipulationContext.ideaNumber = currentIdea;
            }
            
            currentSentence++;
            currentSentenceText = [[bookView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('s%d').innerHTML", currentSentence]] stringByConvertingHTMLToPlainText];
            
            manipulationContext.sentenceNumber = currentSentence;
            manipulationContext.sentenceText = currentSentenceText;
            manipulationContext.manipulationSentence = [self isManipulationSentence:currentSentence];
            [[ServerCommunicationController sharedInstance] logLoadSentence:currentSentence withText:currentSentenceText manipulationSentence:manipulationContext.manipulationSentence context:manipulationContext];
        
            //Set up current sentence appearance and solution steps
            [self setupCurrentSentence];
            [self colorSentencesUponNext];
        
            //currentSentence is 1 indexed.
            if (currentSentence > totalSentences) {
                [self loadNextPage];
            }
            else {
                [self playCurrentSentenceAudio];
            }*/
        }
        else if (conditionSetup.condition == EMBRACE && conditionSetup.currentMode == PM_MODE){
            if (menu != nil) {
                [[ServerCommunicationController sharedInstance] logVerification:true forAction:@"Select Menu Item" context:manipulationContext];
                
                //Re-add the tap gesture recognizer before the menu is removed
                [self.view addGestureRecognizer:tapRecognizer];
                
                //Remove menu
                [menu removeFromSuperview];
                menu = nil;
                menuExpanded = FALSE;
                allowSnapback = true;
            }
            else {
                [[ServerCommunicationController sharedInstance] logVerification:true forAction:@"Move Object" context:manipulationContext];
                Connection *con = [interaction.connections objectAtIndex:0];
                NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
                
                //Get current step to be completed
                ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
                [[ITSController sharedInstance] movedObject:[con.objects objectAtIndex:0]
                                         destinationObjects:@[[con.objects objectAtIndex:1]]
                                                 isVerified:true
                                                 actionStep:currSolStep
                                        manipulationContext:manipulationContext
                                                forSentence:currentSentenceText
                                            withWordMapping:model.wordMapping];
            }
            
            [self performInteraction:interaction];
        }
        
//        if ([IntroductionClass.introductions objectForKey:chapterTitle]) {
//            IntroductionClass.currentIntroStep++;
//            [IntroductionClass loadIntroStep:bookView:self :currentSentence];
//        }
        
        if (conditionSetup.condition == EMBRACE && conditionSetup.currentMode == PM_MODE) {
            [self incrementCurrentStep];
        }
        
        //Transference counts as two steps, so we must increment again
        if ([interaction interactionType] == TRANSFERANDGROUP ||
            [interaction interactionType] == TRANSFERANDDISAPPEAR) {
            if (conditionSetup.condition == EMBRACE && conditionSetup.currentMode == PM_MODE) {
                [self incrementCurrentStep];
            }
        }
    }
    else {
        NSString *action;
        
        if (menu != nil) {
            action = [NSString stringWithFormat:@"Select Menu Item"];
        }
        else {
            action = [NSString stringWithFormat:@"Move Object"];
        }
        
        Connection *con = [interaction.connections objectAtIndex:0];
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        [[ITSController sharedInstance] movedObject:[con.objects objectAtIndex:0]
                                 destinationObjects:@[[con.objects objectAtIndex:1]]
                                         isVerified:false
                                         actionStep:currSolStep
                                manipulationContext:manipulationContext
                                        forSentence:currentSentenceText
                                    withWordMapping:model.wordMapping];
    
        [self handleErrorForAction:action];
    }
    
    //Clear any remaining highlighting
    [self.pmView clearAllHighLighting];
}

/*
 * Handles errors by logging the action, playing a noise, and resetting the object location.
 * The ITS will check if the user's number of attempts has reached the maximum number of attempts; if so, it will
 * automatically perform the step.
 */
- (void)handleErrorForAction:(NSString *)action {
    [[ServerCommunicationController sharedInstance] logVerification:false forAction:action context:manipulationContext];
    
    [self playErrorNoise];
    [self resetObjectLocation];
    
    numAttempts++;
    
    if (numAttempts >= maxAttempts) {
        numAttempts = 0;
        
        [self animatePerformingStep];
        [playaudioClass playAutoCompleteStepNoise];
    }
    else {
        if (conditionSetup.appMode == ITS) {
            // TODO: Determine most probable error type
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Choose the most probable error type:" message:nil preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Vocabulary" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                              {
                                  [self provideFeedbackForErrorType:@"vocabulary"];
                              }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Syntax" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                              {
                                  [self provideFeedbackForErrorType:@"syntax"];
                              }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Usability" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                              {
                                  [self provideFeedbackForErrorType:@"usability"];
                              }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"None" style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    
    if (conditionSetup.appMode == ITS) {
        //Record error for complexity
        [[pageStatistics objectForKey:currentPageId] addErrorForComplexity:(currentComplexity - 1)];
    }
}

// TODO: Change error type NSString to enum
- (void)provideFeedbackForErrorType:(NSString *)errorType {
    if ([errorType isEqualToString:@"vocabulary"]) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        NSString *stepType = [currSolStep stepType];
        
        if ([stepType isEqualToString:@"check"] || [stepType isEqualToString:@"checkLeft"] || [stepType isEqualToString:@"checkRight"] || [stepType isEqualToString:@"checkUp"] || [stepType isEqualToString:@"checkDown"] || [stepType isEqualToString:@"checkAndSwap"] || [stepType isEqualToString:@"tapToAnimate"] || [stepType isEqualToString:@"checkPath"] || [stepType isEqualToString:@"shakeAndTap"] || [stepType isEqualToString:@"tapWord"] ) {
            // TODO: Highlight object and location
        }
        else {
            NSString *object1Id = [currSolStep object1Id];
            NSString *object2Id = [currSolStep object2Id];
            
            [self highlightImageForText:object1Id];
            [self highlightImageForText:object2Id];
        }
    }
    else if ([errorType isEqualToString:@"syntax"]) {
        NSMutableArray *simplerSentences = [[NSMutableArray alloc] init];
        
        if (currentComplexity > 1) {
            Chapter *chapter = [book getChapterWithTitle:chapterTitle]; //get current chapter
            PhysicalManipulationActivity *PMActivity = (PhysicalManipulationActivity *)[chapter getActivityOfType:PM_MODE]; //get PM Activity from chapter
            
            for (AlternateSentence *alternateSentence in [[PMActivity alternateSentences] objectForKey:currentPageId]) {
                if ([alternateSentence complexity] == currentComplexity - 1 && [[alternateSentence ideas] containsObject:@(currentIdea)]) {
                    [simplerSentences addObject:[alternateSentence text]];
                }
            }
        }
        
        if ([simplerSentences count] > 0) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hint" message:[simplerSentences componentsJoinedByString:@" "] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:action];
            [self presentViewController:alert animated:YES completion:nil];
        }
        // TODO: Temporary message for demo purposes only
        else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hint" message:@"There are no simpler sentences available." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:action];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    else if ([errorType isEqualToString:@"usability"]) {
        [self animatePerformingStep];
        [playaudioClass playAutoCompleteStepNoise];
    }
}

- (void)animatePerformingStep {
    //Get steps for current sentence
    NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
    
    //Get current step to be completed
    ActionStep *currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
    NSString *stepType = [currSolStep stepType];
    
    if ([stepType isEqualToString:@"check"] || [stepType isEqualToString:@"checkLeft"] || [stepType isEqualToString:@"checkRight"] || [stepType isEqualToString:@"checkUp"] || [stepType isEqualToString:@"checkDown"] || [stepType isEqualToString:@"checkAndSwap"] || [stepType isEqualToString:@"tapToAnimate"] || [stepType isEqualToString:@"checkPath"] || [stepType isEqualToString:@"shakeAndTap"] || [stepType isEqualToString:@"tapWord"] ) {
        if ([stepType isEqualToString:@"checkAndSwap"]) {
            [self swapObjectImage];
        }
        
        [self incrementCurrentStep];
    }
    else {
        NSString *object1Id = [currSolStep object1Id];
        NSString *object2Id = [currSolStep object2Id];
        
        CGPoint object1Location = [self getObjectPosition:object1Id];
        CGPoint object2Location = [self getObjectPosition:object2Id];
        
        CGSize object1Size = [self.pmView sizeOfObject:object1Id];
        CGSize object2Size = [self.pmView sizeOfObject:object2Id];
        
        CGPoint object1Center = CGPointMake(object1Location.x + object1Size.width / 2, object1Location.y + object1Size.height / 2);
        CGPoint object2Center = CGPointMake(object2Location.x + object2Size.width / 2, object2Location.y + object2Size.height / 2);
        
        [self.pmView animateObject:object1Id from:object1Center to:object2Center action:@"moveToLocation" areaId:@""];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            //Get the interaction to be performed
            PossibleInteraction *interaction = [self getCorrectInteraction];
            
            //Perform the interaction and increment the step
            [self checkSolutionForInteraction:interaction];
        });
    }
}

/*
 * Checks if one object is contained inside another object and returns the contained object
 */
- (NSString *)findContainedObject:(NSArray *)objects {
    return [self.pmView findContainedObject:objects];
}

//TODO: add description
- (NSMutableArray *)getPossibleInteractions:(BOOL)useProximity {
    //Get pairs of other objects grouped with this object
    NSArray *itemPairArray = [self getObjectsGroupedWithObject:movingObjectId];
    
    if (itemPairArray != nil) {
        NSMutableArray *groupings = [[NSMutableArray alloc] init];
        NSMutableSet *uniqueObjIds = [[NSMutableSet alloc] init];
        
        for (NSString *pairStr in itemPairArray) {
            //Separate the objects in this pair.
            NSArray *itemPair = [pairStr componentsSeparatedByString:@", "];
            
            for (NSString *item in itemPair) {
                [uniqueObjIds addObject:item];
            }
        }
        
        //Get the possible interactions for all objects in the group
        for (NSString *obj in uniqueObjIds) {
            [groupings addObjectsFromArray:[self getPossibleInteractions:useProximity forObject:obj]];
        }
        
        return groupings;
    }
    else {
        return [self getPossibleInteractions:useProximity forObject:movingObjectId];
    }
}

/*
 * Returns all possible interactions that can occur between the object being moved and any other objects it's overlapping with.
 * This function takes into account all hotspots, both available and unavailable. It checks cases in which all hotspots are
 * available, as well as instances in which one hotspots is already taken up by a grouping but the other is not. The func
 tion
 * checks both group and disappear interaction types.
 
 * TODO: Figure out how to return all possible interactions robustly. Currently if the student drags the hay and the farmer (when grouped) by the hay, then the interaction will not be identified.
 * TODO: Lots of duplication here. Need to fix the above and then pull out duplicate code.
 
 * We also want to double check and make sure that neither of the objects is already grouped with another object at the relevant hotspots. If it is, that means we may need to transfer the grouping, instead of creating a new grouping.
 * If it is, we have to make sure that the hotspots for the two objects are within a certain radius of each other for the grouping to occur.
 * If they are, we want to go ahead and group the objects.
 
 * TODO: Instead of just checking based on the object that's being moved, we should get all objects the movingObject is connected to. From there, we can either get all the possible interactions for each object, or we can figure out which one is the "subject" and use that one. For example, when the farmer is holding the hay, the farmer is the one doing the action, so the farmer would be the subject. Does this work in all instances? If so, we may also want to think about looking at the object's role when coming up with transfer interactions as well.
 */
//TODO: move logic in if else statements to new functions
- (NSMutableArray *)getPossibleInteractions:(BOOL)useProximity forObject:(NSString *)obj{
    NSMutableArray *groupings = [[NSMutableArray alloc] init];
    
    //Get the objects that this object is overlapping with
    NSArray *overlappingWith = [self getObjectsOverlappingWithObject:obj];
    BOOL ObjectIDUsed = false;
    NSString *tempCollisionObject = nil;
    
    if (overlappingWith != nil) {
        for (NSString *objId in overlappingWith) {
            //If only the correct object can be used, then check if the overlapping object is correct. If it is not, do not get any possible interactions for it.
            BOOL getInteractions = TRUE;

            if (useObject == ONLY_CORRECT) {
                if (![self checkSolutionForObject:objId]) {
                    getInteractions = FALSE;
                    
                    if (!ObjectIDUsed) {
                        ObjectIDUsed = true;
                        tempCollisionObject = objId;
                    }
                }
            }
            
            if (getInteractions) {
                ObjectIDUsed = true;
                tempCollisionObject = objId;
                
                NSMutableArray *hotspots = [model getHotspotsForObject:objId OverlappingWithObject:obj];
                NSMutableArray *movingObjectHotspots = [model getHotspotsForObject:obj OverlappingWithObject:objId];
                
                //Compare hotspots of the two objects. 
                for (Hotspot *hotspot in hotspots) {
                    for (Hotspot *movingObjectHotspot in movingObjectHotspots) {
                        //Need to calculate exact pixel locations of both hotspots and then make sure they're within a specific distance of each other.
                        CGPoint movingObjectHotspotLoc = [self.pmView getHotspotLocation:movingObjectHotspot];
                        CGPoint hotspotLoc = [self.pmView getHotspotLocation:hotspot];
                        
                        //Check to see if either of these hotspots are currently connected to another objects.
//                        NSString *isHotspotConnectedMovingObject = [NSString stringWithFormat:@"objectGroupedAtHotspot(%@, %f, %f)", obj, movingObjectHotspotLoc.x, movingObjectHotspotLoc.y];
//                        NSString *isHotspotConnectedMovingObjectString  = [bookView stringByEvaluatingJavaScriptFromString:isHotspotConnectedMovingObject];
//                        
//                        NSString *isHotspotConnectedObject = [NSString stringWithFormat:@"objectGroupedAtHotspot(%@, %f, %f)", objId, hotspotLoc.x, hotspotLoc.y];
//                        NSString *isHotspotConnectedObjectString  = [bookView stringByEvaluatingJavaScriptFromString:isHotspotConnectedObject];
//
                        NSString *isHotspotConnectedObjectString = [self.pmView groupedObject:objId atHotSpot:hotspotLoc];
                        NSString *isHotspotConnectedMovingObjectString  = [self.pmView groupedObject:obj atHotSpot:movingObjectHotspotLoc];
                        bool rolesMatch = [[hotspot role] isEqualToString:[movingObjectHotspot role]];
                        bool actionsMatch = [[hotspot action] isEqualToString:[movingObjectHotspot action]];
                        
                        //Make sure the two hotspots have the same action. It may also be necessary to ensure that the roles do not match. Also make sure neither of the hotspots are connected to another object.
                        if (actionsMatch
                               && ![self.pmView isObjectGrouped:obj atHotSpot:movingObjectHotspotLoc]
                               && ![self.pmView isObjectGrouped:objId atHotSpot:hotspotLoc]
                               && !rolesMatch) {
                            //Although the matching hotspots are free, transference may still be possible if one of the objects is connected at a different hotspot that must be ungrouped first.
                            NSString *objTransferringObj = [self getObjectPerformingTransference:obj :objId :@"object"];
                            NSString *objTransferringObjId = [self getObjectPerformingTransference:objId :obj :@"subject"];
                            
                            //Transference is possible
                            if (objTransferringObj != nil && objTransferringObjId == nil) {
                                [groupings addObjectsFromArray:[self getPossibleTransferInteractionsforObjects:obj :objTransferringObj :objId :movingObjectHotspot :hotspot]];
                            }
                            else if (objTransferringObjId != nil && objTransferringObj == nil) {
                                [groupings addObjectsFromArray:[self getPossibleTransferInteractionsforObjects:objId :objTransferringObjId :obj :hotspot :movingObjectHotspot]];
                            }
                            //Group or disappear normally
                            else {
                                //Get the relationship between these two objects so we can check to see what type of relationship it is.
                                Relationship *relationshipBetweenObjects = [model getRelationshipForObjectsForAction:obj :objId :[movingObjectHotspot action]];
                                lastRelationship = relationshipBetweenObjects;
                                [allRelationships addObject:lastRelationship];
                                
                                //Check to make sure that the two hotspots are in close proximity to each other.
                                if ((useProximity && [self hotspotsWithinGroupingProximity:movingObjectHotspot :hotspot])
                                   || !useProximity) {
                                    //Create necessary arrays for the interaction.
                                    NSArray *objects;
                                    NSArray *hotspotsForInteraction;
                                    
                                    if ([[relationshipBetweenObjects actionType] isEqualToString:@"group"]) {
                                        //Check if the moving object is already grouped with another
                                        //object
                                        NSArray *groupedObjects = [self getObjectsGroupedWithObject:movingObjectId];
                                        
                                        //Object is already grouped to another object
                                        if (groupedObjects != nil) {
                                            //Check if this new grouping meets constraints before
                                            //creating the PossibleInteraction object
                                            if ([self doesObjectMeetComboConstraints:movingObjectId :movingObjectHotspot]) {
                                                PossibleInteraction *interaction = [[PossibleInteraction alloc] initWithInteractionType:GROUP];
                                                
                                                objects = [[NSArray alloc] initWithObjects:obj, objId, nil];
                                                hotspotsForInteraction = [[NSArray alloc] initWithObjects:movingObjectHotspot, hotspot, nil];
                                                
                                                [interaction addConnection:GROUP :objects :hotspotsForInteraction];
                                                [groupings addObject:interaction];
                                            }
                                        }
                                        //Object is not grouped to another object
                                        else {
                                            PossibleInteraction *interaction = [[PossibleInteraction alloc] initWithInteractionType:GROUP];
                                            
                                            objects = [[NSArray alloc] initWithObjects:obj, objId, nil];
                                            hotspotsForInteraction = [[NSArray alloc] initWithObjects:movingObjectHotspot, hotspot, nil];
                                            
                                            [interaction addConnection:GROUP :objects :hotspotsForInteraction];
                                            [groupings addObject:interaction];
                                        }
                                    }
                                    else if ([[relationshipBetweenObjects actionType] isEqualToString:@"disappear"]) {
                                        PossibleInteraction *interaction = [[PossibleInteraction alloc] initWithInteractionType:DISAPPEAR];
                                        
                                        //Add the subject of the disappear interaction before the object
                                        if ([[movingObjectHotspot role] isEqualToString:@"subject"]) {
                                            objects = [[NSArray alloc] initWithObjects:obj, objId, nil];
                                            hotspotsForInteraction = [[NSArray alloc] initWithObjects:movingObjectHotspot, hotspot, nil];
                                        }
                                        else if ([[movingObjectHotspot role] isEqualToString:@"object"]) {
                                            objects = [[NSArray alloc] initWithObjects:objId, obj, nil];
                                            hotspotsForInteraction = [[NSArray alloc] initWithObjects:hotspot, movingObjectHotspot, nil];
                                        }
                                        
                                        [interaction addConnection:DISAPPEAR :objects :hotspotsForInteraction];
                                        [groupings addObject:interaction];
                                    }
                                }
                            }
                        }
                        //Otherwise, one of these is connected to another object...so we check to see if the other object can be connected with the unconnected one.
                        else if (actionsMatch
                                 && [self.pmView isObjectGrouped:obj atHotSpot:movingObjectHotspotLoc]
                                && [self.pmView isObjectGrouped:objId atHotSpot:hotspotLoc]
                                 && !rolesMatch) {
                            [groupings addObjectsFromArray:[self getPossibleTransferInteractionsforObjects:obj :[self.pmView groupedObject:obj atHotSpot:movingObjectHotspotLoc] :objId :movingObjectHotspot :hotspot]];
                        }
                        else if (actionsMatch && [isHotspotConnectedMovingObjectString isEqualToString:@""]
                                && ![isHotspotConnectedObjectString isEqualToString:@""] && !rolesMatch) {
                            [groupings addObjectsFromArray:[self getPossibleTransferInteractionsforObjects:objId :isHotspotConnectedObjectString :obj :hotspot :movingObjectHotspot]];
                        }
                    }
                }
            }
        }
    }
    
    collisionObjectId = tempCollisionObject;
    
    return groupings;
}

/*
 * Returns the ID of the object that is performing a possible transference. For this object to qualify, the transferred object must be
 * connected to it using the role specified. Additionally, it must have strictly greater than one possible hotspot that matches with the
 * receiver object (i.e. the object accepting the transferred object).
 */
- (NSString *)getObjectPerformingTransference:(NSString *)transferredObj :(NSString *)receiverObj :(NSString *)role {
    NSMutableArray *transferredObjHotspots = [model getHotspotsForObjectId:transferredObj];

    NSString *senderObj; //Object that is performing the transference
    
    //Check to see if the transferred object is already connected at a different hotspot that needs to be ungrouped for transference to occur
    for (Hotspot *transferredObjHotspot in transferredObjHotspots) {
        //Check if it is currently grouped with another object using the specified role
        if ([[transferredObjHotspot role] isEqualToString:role]) {
            CGPoint transferredObjHotspotLoc = [self.pmView getHotspotLocation:transferredObjHotspot];
            
            //Get the object that the transferred object is connected to at this hotspot
            NSString *isHotspotConnected = [NSString stringWithFormat:@"objectGroupedAtHotspot(%@, %f, %f)", transferredObj, transferredObjHotspotLoc.x, transferredObjHotspotLoc.y];
            NSString *isHotspotConnectedString = [self.pmView groupedObject:transferredObj atHotSpot:transferredObjHotspotLoc];
            
            if (![isHotspotConnectedString isEqualToString:@""]) {
                //If this object has multiple hotspots in common with the recipient object, then it must be capable of performing transference (i.e. an animate object)
                NSMutableArray *otherObjHotspots = [model getHotspotsForObject:isHotspotConnectedString OverlappingWithObject:receiverObj];
                
                if ([otherObjHotspots count] > 1) {
                    senderObj = isHotspotConnectedString;
                }
            }
        }
    }
    
    return senderObj;
}

//TODO: add descrption
- (NSMutableArray *)getPossibleTransferInteractionsforObjects:(NSString *)objConnected :(NSString *)objConnectedTo :(NSString *)currentUnconnectedObj :(Hotspot *)objConnectedHotspot :(Hotspot *)currentUnconnectedObjHotspot{
    NSMutableArray *groupings = [[NSMutableArray alloc] init];
    
    //Get the hotspots for the grouped objects
    NSMutableArray *hotspotsForObjConnected = [model getHotspotsForObject:objConnected OverlappingWithObject :objConnectedTo];
    NSMutableArray *hotspotsForObjConnectedTo = [model getHotspotsForObject:objConnectedTo OverlappingWithObject :objConnected];
    
    //Compare their hotspots to determine where the two objects are currently grouped
    for (Hotspot *hotspot1 in hotspotsForObjConnectedTo) {
        for (Hotspot *hotspot2 in hotspotsForObjConnected) {
            //Need to calculate exact pixel location of one of the hotspots and then make sure it is connected to the other object at that location
            CGPoint hotspot1Loc = [self.pmView getHotspotLocation:hotspot1];
            NSString *isConnectedObjHotspotConnectedString  = [self.pmView groupedObject:objConnectedTo atHotSpot:hotspot1Loc];
            
            //Make sure the two hotspots have the same action and make sure the roles do not match (there are only two possibilities right now: subject and object). Also make sure the hotspots are connected to each other. If all is well, these objects can be ungrouped.
            bool rolesMatch = [[hotspot1 role] isEqualToString:[hotspot2 role]];
            bool actionsMatch = [[hotspot1 action] isEqualToString:[hotspot2 action]];
            
            if (actionsMatch && ![isConnectedObjHotspotConnectedString isEqualToString:@""] && !rolesMatch) {
                PossibleInteraction *interaction = [[PossibleInteraction alloc] init];
                
                //Add the connection to ungroup first.
                NSArray *ungroupObjects;
                NSArray *hotspotsForUngrouping;
                
                //Add the subject to the ungroup connection before the object
                if ([[hotspot1 role] isEqualToString:@"subject"]) {
                    ungroupObjects = [[NSArray alloc] initWithObjects:objConnectedTo, objConnected, nil];
                    hotspotsForUngrouping = [[NSArray alloc] initWithObjects:hotspot1, hotspot2, nil];
                }
                else {
                    ungroupObjects = [[NSArray alloc] initWithObjects:objConnected, objConnectedTo, nil];
                    hotspotsForUngrouping = [[NSArray alloc] initWithObjects:hotspot2, hotspot1, nil];
                }
                
                [interaction addConnection:UNGROUP :ungroupObjects :hotspotsForUngrouping];
                
                //Then add the connection to group or disappear
                NSArray *transferObjects;
                NSArray *hotspotsForTransfer;
                
                //Add the subject to the group or disappear interaction before the object
                if ([[objConnectedHotspot role] isEqualToString:@"subject"]) {
                    transferObjects = [[NSArray alloc] initWithObjects:objConnected, currentUnconnectedObj, nil];
                    hotspotsForTransfer = [[NSArray alloc] initWithObjects:objConnectedHotspot, currentUnconnectedObjHotspot, nil];
                }
                else {
                    transferObjects = [[NSArray alloc] initWithObjects:currentUnconnectedObj, objConnected, nil];
                    hotspotsForTransfer = [[NSArray alloc] initWithObjects:currentUnconnectedObjHotspot, objConnectedHotspot, nil];
                }
                
                //Get the relationship between the connected and currently unconnected objects so we can check to see what type of relationship it is.
                Relationship *relationshipBetweenObjects = [model getRelationshipForObjectsForAction:objConnected :currentUnconnectedObj :[objConnectedHotspot action]];
                lastRelationship = relationshipBetweenObjects;
                [allRelationships addObject:lastRelationship];
                
                if ([[relationshipBetweenObjects  actionType] isEqualToString:@"group"]) {
                    [interaction addConnection:GROUP :transferObjects :hotspotsForTransfer];
                    [interaction setInteractionType:TRANSFERANDGROUP];
                    
                    [groupings addObject:interaction];
                }
                else if ([[relationshipBetweenObjects actionType] isEqualToString:@"disappear"]) {
                    [interaction addConnection:DISAPPEAR :transferObjects :hotspotsForTransfer];
                    [interaction setInteractionType:TRANSFERANDDISAPPEAR];
                    
                    [groupings addObject:interaction];
                }
            }
        }
    }
    
    return groupings;
}

/*
 * Returns an array containing pairs of grouped objects (with the format "hay, farmer") connected to the object specified
 */
- (NSArray *)getObjectsGroupedWithObject:(NSString *)object {

    return [self.pmView getObjectsGroupedWithObject:object];
}

/*
 * Returns an array containing objects that are overlapping with the object specified
 */
- (NSArray *)getObjectsOverlappingWithObject:(NSString *)object {
    
    return [self.pmView getObjectsOverlappingWithObject:object movingObject:movingObjectId];
}

/*
 * Checks an object's array of hotspots to determine if one is connected to a specific object and returns that hotspot
 */
- (Hotspot *)findConnectedHotspot:(NSMutableArray *)movingObjectHotspots :(NSString *)objConnectedTo {
    Hotspot *connectedHotspot = NULL;
    
    for (Hotspot *movingObjectHotspot in movingObjectHotspots) {
        //Get the hotspot location
        CGPoint movingObjectHotspotLoc = [self.pmView getHotspotLocation:movingObjectHotspot];
        
        //Check if this hotspot is currently in use
        NSString *isHotspotConnectedMovingObjectString  = [self.pmView groupedObject:movingObjectId atHotSpot:movingObjectHotspotLoc];
        
        //Check if this hotspot is being used by the objConnectedTo
        if ([isHotspotConnectedMovingObjectString isEqualToString:objConnectedTo]) {
            connectedHotspot = movingObjectHotspot;
        }
    }
    
    return connectedHotspot;
}

/*
 * Determines whether the potential connection is allowed to take place (i.e. whether the
 * hotspot can be used) based on the combo constraints.
 *
 * Ex. A combo constraint may specify that the farmer may not use the pickUp
 * and lead hotspots at the same time. This function will look up the farmer's combo
 * constraints, determine which hotspot is currently in use, and check whether the connected
 * (pickUp) and potential (lead) hotspots are both restricted by the constraint.
 *
 * TODO: Currently, this only checks if any 2 hotspots (one connected, one potential) can be
 * used at the same time. It should be able to check cases such as 3 hotspots exactly
 * (2 connected, 1 potential).
 */
- (BOOL)doesObjectMeetComboConstraints:(NSString *)connectedObject :(Hotspot *)potentialConnection {
    //Records whether the potential and connected hotspots are present in the list
    //of combo constraints for an object contained in a group with connectedObject.
    //If they both are, then this object does not meet the combo constraints.
    BOOL potentialConstraint = FALSE;
    BOOL connectedConstraint = FALSE;
    
    //Get pairs of other objects grouped with this object.
    NSArray *itemPairArray = [self getObjectsGroupedWithObject:connectedObject];
    
    if (itemPairArray != nil) {
        for (NSString *pairStr in itemPairArray) {
            //Create an array that will hold all the items in this group
            NSMutableArray *groupedItemsArray = [[NSMutableArray alloc] init];
            
            //Separate the objects in this pair and add them to our array of all items in this group.
            [groupedItemsArray addObjectsFromArray:[pairStr componentsSeparatedByString:@", "]];
            
            for (NSString *object in groupedItemsArray) {
                //Get the combo constraints for the object
                NSMutableArray *objectComboConstraints = [model getComboConstraintsForObjectId:object];
                
                //The object has combo constraints
                if ([objectComboConstraints count] > 0) {
                    //Get the hotspots for the object
                    NSMutableArray *objectHotspots = [model getHotspotsForObjectId:object];
                    
                    for (Hotspot *hotspot in objectHotspots) {
                        //Get the hotspot location
                        CGPoint hotspotLocation = [self.pmView getHotspotLocation:hotspot];
                        
                        //Check if this hotspot is currently connected to another object
                        NSString *isHotspotConnectedString = [self.pmView groupedObject:object atHotSpot:hotspotLocation];
                        //Hotspot is connected to another object
                        if (![isHotspotConnectedString isEqualToString:@""]) {
                            for (ComboConstraint *comboConstraint in objectComboConstraints) {
                                //Get the list of actions for the combo constraint
                                NSMutableArray *comboActions = [comboConstraint comboActions];
                                
                                for (NSString *comboAction in comboActions) {
                                    //Get the hotspot associated with the action, assuming the
                                    //role as subject. Also get the hotspot location.
                                    Hotspot *comboHotspot = [model getHotspotforObjectWithActionAndRole:[comboConstraint objId] :comboAction :@"subject"];
                                    CGPoint comboHotspotLocation;
                                    
                                    if (comboHotspot != nil) {
                                        comboHotspotLocation = [self.pmView getHotspotLocation:comboHotspot];
                                    }
                                    else {
                                        //If no hotspot was found assuming the role as subject,
                                        //then the role must be object.
                                        comboHotspot = [model getHotspotforObjectWithActionAndRole:[comboConstraint objId] :comboAction :@"object"];
                                        comboHotspotLocation = [self.pmView getHotspotLocation:comboHotspot];
                                    }
                                    
                                    //Check if the potential hotspot matches an action on the list
                                    if ([[potentialConnection action] isEqualToString:comboAction]) {
                                        potentialConstraint = TRUE;
                                    }
                                    
                                    //Check if the connected hotspot matches an action on the list
                                    //based on its name or location
                                    if ([[hotspot action] isEqualToString:comboAction] || CGPointEqualToPoint(hotspotLocation, comboHotspotLocation)) {
                                        connectedConstraint = TRUE;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    //Both potential and connected hotspots were present in the list
    if (potentialConstraint && connectedConstraint) {
        return FALSE; //fails to meet combo constraint
    }
    else {
        return TRUE; //meets combo constraint
    }
}

/*
 * Re-orders the possible interactions in place based on the location in the story at which the user is currently.
 * TODO: Pull up information from solution step and rank based on the location in the story and the current step
 * For now, the function makes sure the interaction which ensures going to the next step in the story is present
 * somewhere in the first three (maximum menu items) indexes of the possibleInteractions array.
 */
- (void)rankPossibleInteractions:(NSMutableArray *)possibleInteractions {
    PossibleInteraction* correctInteraction = [self getCorrectInteraction];
    
    int correctIndex; //index to insert correct menu item
    
    //Generate a random index number up to the number of PossibleInteraction objects (if less than the maximum number of menu items) or up to the maximum number of menu items otherwise. The index is random to ensure that the correct interaction won't always be at the same location on the menu.
    if ([possibleInteractions count] < maxMenuItems) {
        correctIndex = arc4random_uniform([possibleInteractions count]);
    }
    else {
        correctIndex = arc4random_uniform(maxMenuItems);
    }
    
    //Look for the correct interaction and swap it with the element at the correct index
    for (int i = 0; i < [possibleInteractions count]; i++) {
        if ([[possibleInteractions objectAtIndex:i] isEqual:correctInteraction]) {
            [possibleInteractions exchangeObjectAtIndex:i withObjectAtIndex:correctIndex];
        }
    }
}

/*
 * Checks to see whether two hotspots are within grouping proximity.
 * Returns true if they are, false otherwise.
 */
- (BOOL)hotspotsWithinGroupingProximity:(Hotspot *)hotspot1 :(Hotspot *)hotspot2 {
    CGPoint hotspot1Loc = [self.pmView getHotspotLocation:hotspot1];
    CGPoint hotspot2Loc = [self.pmView getHotspotLocation:hotspot2];
    
    float deltaX = fabsf(hotspot1Loc.x - hotspot2Loc.x);
    float deltaY = fabsf(hotspot1Loc.y - hotspot2Loc.y);
    
    if (deltaX <= groupingProximity && deltaY <= groupingProximity)
        return true;
    
    return false;
}

/*
 * Calculates the delta pixel change for the object that is being moved
 * and changes the lcoation from relative % to pixels if necessary.
 */
- (CGPoint)calculateDeltaForMovingObjectAtPoint:(CGPoint)location {
    return [self.pmView deltaForMovingObjectAtPoint:location];
}

/*
 * Calculates the delta pixel change for the object that is being moved
 * and changes the lcoation from relative % to pixels if necessary.
 */
- (CGPoint)calculateDeltaForMovingObjectAtPointWithCenter:(NSString *)object :(CGPoint)location {
    return [self.pmView deltaForMovingObjectAtPointWithCenter:object :location];
}

/*
 * Moves the object passed in to the location given. Calculates the difference between the point touched and the
 * top-left corner of the image, which is the x,y coordate that's actually used when moving the object.
 * Also ensures that the image is not moved off screen or outside of any specified bounding boxes for the image.
 * Updates the JS Connection hotspot locations if necessary.
 */
//TODO: condense logic
- (void)moveObject:(NSString *)object :(CGPoint)location :(CGPoint)offset :(BOOL)updateCon {
    
    endLocation = [self.pmView moveObject:object
                   location:location
                     offset:offset
     shouldUpdateConnection:updateCon
                  withModel:model
               movingObject:movingObjectId
              startLocation:startLocation
                  shouldPan:panning];
}

/*
 * Calls the JS function to group two objects at the specified hotspots.
 */
- (void)groupObjects:(NSString *)object1 :(CGPoint)object1Hotspot :(NSString *)object2 :(CGPoint)object2Hotspot {

    //Maintain a list of current groupings, with the subject as a key. Currently only supports two objects
    
    //Get the current groupings of the objects
    NSMutableArray *object1Groups = [currentGroupings objectForKey:object1];
    NSMutableArray *object2Groups = [currentGroupings objectForKey:object2];
    
    if (!object1Groups) //if there already exists some groupings add the new grouping
        object1Groups = [[NSMutableArray alloc] init];
    
    [object1Groups addObject:object2];

    if (!object2Groups) //if there already exists some groupings add the new grouping
    object2Groups = [[NSMutableArray alloc] init];
    [object2Groups addObject:object1];
    
    [currentGroupings setValue:object1Groups forKey:object1];
    [currentGroupings setValue:object2Groups forKey:object2];
    [self.pmView groupObjects:object1
               object1HotSpot:object1Hotspot
                      object2:object2
               object2Hotspot:object2Hotspot];

}

/*
 * Calls the JS function to ungroup two objects.
 */
- (void)ungroupObjects:(NSString *)object1 :(NSString *)object2 {
    
    //Get the current groupings of the objects
    NSMutableArray *object1Groups = [currentGroupings objectForKey:object1];
    NSMutableArray *object2Groups = [currentGroupings objectForKey:object2];
    
    if ([object1Groups containsObject:object2]) {
        [object1Groups removeObject:object2];
        [currentGroupings setValue:object1Groups forKey:object1];
    }
    if ([object2Groups containsObject:object1]) {
        [object2Groups removeObject:object1];
        [currentGroupings setValue:object2Groups forKey:object2];
    }
    [self.pmView ungroupObjects:object1 object2:object2];
}

/*
 * Calls the JS function to ungroup two objects.
 */
- (void)ungroupObjectsAndStay:(NSString *)object1 :(NSString *)object2 {
    
    //Get the current groupings of the objects
    NSMutableArray *object1Groups = [currentGroupings objectForKey:object1];
    NSMutableArray *object2Groups = [currentGroupings objectForKey:object2];
    
    if ([object1Groups containsObject:object2]) {
        [object1Groups removeObject:object2];
        [currentGroupings setValue:object1Groups forKey:object1];
    }
    if ([object2Groups containsObject:object1]) {
        [object2Groups removeObject:object1];
        [currentGroupings setValue:object2Groups forKey:object2];
    }

    [self.pmView ungroupObjectsAndStay:object1 object2:object2];
}

/*
 * Call JS code to cause the object to disappear, then calculate where it needs to re-appear and call the JS code to make
 * it re-appear at the new location.
 */
- (void)consumeAndReplenishSupply:(NSString *)disappearingObject {
    CGPoint point = [self.pmView consumeAndReplenishSupply:disappearingObject
                                           shouldReplenish:replenishSupply
                                                     model:model
                                              movingObject:movingObjectId
                                             startLocation:startLocation
                                                 shouldPan:NO];
    if(point.x != -99) {
        endLocation = point;
    }
}

/*
 * Calls the JS function to draw each individual hotspot in the array provided
 * with the color specified.
 */
- (void)drawHotspots:(NSMutableArray *)hotspots :(NSString *)color{
    [self.pmView drawHotspots:hotspots color:color];
}


/*
 * Returns the hotspot location in pixels based on the object image size
 */
- (CGPoint)getHotspotLocationOnImage:(Hotspot *)hotspot {
    
    return [self.pmView getHotspotLocationOnImage:hotspot];
}

/*
 * Returns the waypoint location in pixels based on the background size
 */
- (CGPoint)getWaypointLocation:(Waypoint *)waypoint {
    return [self.pmView getWaypointLocation:waypoint];
}

/*
 * Calculates the location of the hotspot based on the bounding box provided.
 * This function is used when simulating the locations of objects, since we can't pull the
 * current location and size of the image for this.
 */
- (CGPoint)calculateHotspotLocationBasedOnBoundingBox:(Hotspot *)hotspot :(CGRect)boundingBox {
    float imageWidth = boundingBox.size.width;
    float imageHeight = boundingBox.size.height;
    
    //if image height and width are 0 then the image doesn't exist on this page.
    if (imageWidth > 0 && imageHeight > 0) {
        float locX = boundingBox.origin.x;
        float locY = boundingBox.origin.y;
        
        //Now we've got the location of the top left corner of the image, the size of the image and the relative position of the hotspot. Need to calculate the pixel location of the hotspot and call the js to draw the hotspot.
        float hotspotX = locX + (imageWidth * [hotspot location].x / 100.0);
        float hotspotY = locY + (imageHeight * [hotspot location].y / 100.0);
        
        return CGPointMake(hotspotX, hotspotY);
    }
    
    return CGPointMake(-1, -1);
}

//Needed so the Controller gets the touch events.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

/*
 * Button listener for the "Next" button. This function moves to the next active sentence in the story, or to the
 * next story if at the end of the current story. Eventually, this function will also ensure that the correctness
 * of the interaction is checked against the current sentence before moving on to the next sentence. If the manipulation
 * is correct, then it will move on to the next sentence. If the manipulation is not current, then feedback will be provided.
 */
//TODO: move logic in if else statements into new functions heavy refactoring needed
- (IBAction)pressedNext:(id)sender {
    @synchronized(self) {
        
    
    if (!pressedNextLock && !isLoadPageInProgress) {
    
        pressedNextLock = true;
        [self.view setUserInteractionEnabled:NO];
    
    [[ServerCommunicationController sharedInstance] logPressNextInManipulationActivity:manipulationContext];
    
    //NSString *preAudio = [bookView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById(preaudio)"]];
    
    if ([currentPageId rangeOfString:@"-Intro"].location != NSNotFound) {
            if(currentSentence > totalSentences) {
                [self.playaudioClass stopPlayAudioFile];
                currentSentence = 1;
                
                manipulationContext.sentenceNumber = currentSentence;
                manipulationContext.sentenceText = currentSentenceText;
                manipulationContext.manipulationSentence = [self isManipulationSentence:currentSentence];
                
                [self loadNextPage];
            }
            else if (currentSentence == totalSentences &&
                 [bookTitle rangeOfString:@"Introduction to EMBRACE - Unknown"].location != NSNotFound)
            {
                [self.playaudioClass stopPlayAudioFile];
                currentSentence = 1;
            
                manipulationContext.sentenceNumber = currentSentence;
                manipulationContext.sentenceText = currentSentenceText;
                manipulationContext.manipulationSentence = [self isManipulationSentence:currentSentence];
            
                [self loadNextPage];
            }
            else
            {
                [self.view setUserInteractionEnabled:YES];
            }
    }
    else {
        NSString *sentenceClass = [self.pmView getSentenceClass:currentSentence];

        if ((conditionSetup.condition == EMBRACE && conditionSetup.currentMode == IM_MODE) && ([sentenceClass containsString: @"sentence actionSentence"] || [sentenceClass containsString: @"sentence IMactionSentence"])) {
            
            //Reset allRelationships arrray
            if ([allRelationships count]) {
                [allRelationships removeAllObjects];
            }
            
            //Get steps for current sentence
            NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
            
            PossibleInteraction *interaction;
            NSMutableArray *interactions = [[NSMutableArray alloc]init ];
            
            if (currSolSteps.count != 0 && !didSelectCorrectMenuOption) {
                for (ActionStep *currSolStep in currSolSteps) {
                    interaction = [self convertActionStepToPossibleInteraction:currSolStep];
                    [interactions addObject:interaction];
                    Relationship *relationshipBetweenObjects = [[Relationship alloc] initWithValues:[currSolStep object1Id] :[currSolStep action] :[currSolStep stepType] :[currSolStep object2Id]];
                    [allRelationships addObject:relationshipBetweenObjects];
                }
                
                interactions = [self shuffleMenuOptions: interactions];
                
                //Populate the menu data source and expand the menu.
                [self populateMenuDataSource:interactions :allRelationships];
                
                //Add subview to hide story
                IMViewMenu = [[UIView alloc] initWithFrame:[self.pmView frame]];
                IMViewMenu.backgroundColor = [UIColor whiteColor];
                UILabel *IMinstructions = [[UILabel alloc] initWithFrame:CGRectMake(200, 10, IMViewMenu.frame.size.width, 40)];
                
                IMinstructions.center = CGPointMake(IMViewMenu.frame.size.width  / 2, 40);
                IMinstructions.text = @"Which did you imagine?";
                IMinstructions.textAlignment = NSTextAlignmentCenter;
                IMinstructions.textColor = [UIColor blackColor];
                IMinstructions.font = [UIFont fontWithName:@"GillSans" size:28];
                
                [IMViewMenu addSubview:IMinstructions];
                IMViewMenu.backgroundColor = [UIColor colorWithRed:165.0/255.0 green:203.0/255.0 blue:231.0/255.0 alpha:1.0];
                
                //Add sentence instructions
                [[self view] addSubview:IMViewMenu];
                
                //Expand menu
                [self expandMenu];
                [IMViewMenu bringSubviewToFront:IMinstructions];
                [self.view setUserInteractionEnabled:YES];
            }
            else {
                //For the moment just move through the sentences, until you get to the last one, then move to the next activity.
                if (currentSentence > 0) {
                    currentIdea++;
                    manipulationContext.ideaNumber = currentIdea;
                }
                
                didSelectCorrectMenuOption = false;
                currentSentence++;
                currentSentenceText = [self.pmView getCurrentSentenceAt:currentSentence];
                manipulationContext.sentenceNumber = currentSentence;
                manipulationContext.sentenceText = currentSentenceText;
                manipulationContext.manipulationSentence = [self isManipulationSentence:currentSentence];
                [[ServerCommunicationController sharedInstance] logLoadSentence:currentSentence withText:currentSentenceText manipulationSentence:manipulationContext.manipulationSentence context:manipulationContext];
                
                //currentSentence is 1 indexed.
                if (currentSentence > totalSentences) {
                    [self loadNextPage];
                }
                else {
                    //Set up current sentence appearance and solution steps
                    [self setupCurrentSentence];
                    [self colorSentencesUponNext];
                    [self playCurrentSentenceAudio];
                }
            }
        }
        else if (stepsComplete || numSteps == 0 || (IntroductionClass.allowInteractions && ([chapterTitle isEqualToString:@"The Naughty Monkey"] && [currentPageId rangeOfString:@"PM-2"].location != NSNotFound && conditionSetup.condition == EMBRACE && !stepsComplete && currentSentence == 2))
                 
                 || (!IntroductionClass.allowInteractions && ![chapterTitle isEqualToString:@"The Naughty Monkey"])
                 
                 || (!IntroductionClass.allowInteractions && ([chapterTitle isEqualToString:@"The Naughty Monkey"] && [currentPageId rangeOfString:@"PM-2"].location != NSNotFound && conditionSetup.condition == CONTROL && stepsComplete && currentSentence == 2))
                 
                 || (!IntroductionClass.allowInteractions && ([chapterTitle isEqualToString:@"The Naughty Monkey"] && conditionSetup.condition == CONTROL && !stepsComplete && currentSentence != 2)))
        {
            if (currentSentence > 0) {
                currentIdea++;
                manipulationContext.ideaNumber = currentIdea;
            }
            
            currentSentence++;
            currentSentenceText = [self.pmView getCurrentSentenceAt:currentSentence];
            manipulationContext.sentenceNumber = currentSentence;
            manipulationContext.sentenceText = currentSentenceText;
            manipulationContext.manipulationSentence = [self isManipulationSentence:currentSentence];
            [[ServerCommunicationController sharedInstance] logLoadSentence:currentSentence withText:currentSentenceText manipulationSentence:manipulationContext.manipulationSentence context:manipulationContext];

            //currentSentence is 1 indexed
            if (currentSentence > totalSentences) {
                [self loadNextPage];
            }
            else {
                //For page statistics
                if (conditionSetup.appMode == ITS && numSteps == 0 && currentComplexity > 0) {
                    endTime = [NSDate date];
                    
                    //Record time for non-action sentence for complexity
                    [[pageStatistics objectForKey:currentPageId] addTimeForNonActSents:[endTime timeIntervalSinceDate:startTime] ForComplexity:(currentComplexity - 1)];
                }
                
                //Set up current sentence appearance and solution steps
                [self setupCurrentSentence];
                [self colorSentencesUponNext];
                [self playCurrentSentenceAudio];
            }
        }
        else {
            [[ServerCommunicationController sharedInstance] logVerification:false forAction:@"Press Next" context:manipulationContext];
            
            //Play noise if not all steps have been completed
            [self playErrorNoise];
            [self.view setUserInteractionEnabled:YES];
        }
    }
        
        pressedNextLock = false;
    }
    }
    NSLog(@"manipulationContext.sentenceNumber = %d",manipulationContext.sentenceNumber);
    
}

/*
 * Randomizer function that randomizes the menu options
 */
- (NSMutableArray *)shuffleMenuOptions: (NSMutableArray *) interactions {
    NSUInteger count = [allRelationships count];
    
    for (NSUInteger i = 0; i < count; ++i) {
        //NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = (arc4random() % (count - i)) + i;
        [allRelationships exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
        [interactions exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
    
    return interactions;
}

//TODO: add description
- (void)playErrorNoise {
    [self.playaudioClass playErrorNoise];
    
    [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:@"Error Noise" inLanguage:@"NULL" ofType:@"Play Error Noise" :manipulationContext];
}

//todo: add description
- (void)playCurrentSentenceAudio {
    
    //disable user interactions when preparing to play audio to prevent users from skipping audio
    [self.view setUserInteractionEnabled:NO];
    
    NSString *sentenceAudioFile = nil;
    
    //TODO: move chapter checks to new class or function
    //Only play sentence audio if system is reading
    if (conditionSetup.reader == SYSTEM) {
        //If we are on the first or second manipulation page of The Contest, play the audio of the current sentence
        if ([chapterTitle isEqualToString:@"The Contest"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound)) {
            if ((conditionSetup.language == BILINGUAL)) {
                sentenceAudioFile = [NSString stringWithFormat:@"BFEC%d.m4a", currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"BFTC%d.m4a", currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of Cleaning Up, play the audio of the current sentence
        if ([chapterTitle isEqualToString:@"Cleaning Up"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound)) {
            
                sentenceAudioFile = [NSString stringWithFormat:@"CleaningUpS%dE.mp3", currentSentence];
        }
        
        //If we are on the first or second manipulation page of Getting Ready, play the audio of the current sentence
        if ([chapterTitle isEqualToString:@"Getting Ready"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"GettingReadyS%dE.mp3", currentSentence];
        }
        
        //If we are on the first or second manipulation page of Who is the Best Animal?, play the audio of the current sentence
        if ([chapterTitle isEqualToString:@"Who is the Best Animal?"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"WhoIsTheBestAnimalS%dE.mp3", currentSentence];
        }
        
        //If we are on the first or second manipulation page of The Wise Owl, play the audio of the current sentence
        if ([chapterTitle isEqualToString:@"The Wise Owl"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"TheWiseOwlS%dE.mp3", currentSentence];
        }
        
        //If we are on the first or second manipulation page of Everyone Helps, play the audio of the current sentence
        if ([chapterTitle isEqualToString:@"Everyone Helps"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"EveryoneHelpsS%dE.mp3", currentSentence];
        }
        
        //If we are on the first or second manipulation page of The Best Farm Award, play the audio of the current sentence
        if ([chapterTitle isEqualToString:@"The Best Farm Award"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"TheBestFarmAwardS%dE.mp3", currentSentence];
        }
        
        //If we are on the first or second manipulation page of Why We Breathe, play the audio of the current sentence
        if ([chapterTitle isEqualToString:@"Why We Breathe"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
            if ((conditionSetup.language == BILINGUAL)) {
                sentenceAudioFile = [NSString stringWithFormat:@"CPQR%d.m4a", currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"CWWB%d.m4a", currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of The Lopez Family, play the current sentence
        if ([chapterTitle isEqualToString:@"The Lopez Family"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
            if (conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"TheLopezFamilyS%dS.mp3", currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"TheLopezFamilyS%dE.mp3", currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of Is Paco a Thief?, play the current sentence
        if ([chapterTitle isEqualToString:@"Is Paco a Thief?"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"IsPacoAThiefS%dE.mp3", currentSentence];
        }
        
        //If we are on the first or second manipulation page of Missing Keys, play the current sentence
        if ([chapterTitle isEqualToString:@"Missing Keys"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"MissingKeysS%dE.mp3", currentSentence];
        }
        
        //If we are on the first or second manipulation page of More is Missing!, play the current sentence
        if ([chapterTitle isEqualToString:@"More is Missing!"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"MoreIsMissingS%dE.mp3", currentSentence];
        }
        
        //If we are on the first or second manipulation page of The Baby's Rattle is Gone, Too!, play the current sentence
        if ([chapterTitle isEqualToString:@"The Baby's Rattle is Gone, Too!"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"TheBaby'sRattleIsGoneTooS%dE.mp3", currentSentence];
        }
        
        //If we are on the first or second manipulation page of The Mystery is Solved, play the current sentence
        if ([chapterTitle isEqualToString:@"The Mystery is Solved"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"TheMysteryIsSolvedS%dE.mp3", currentSentence];
        }
        
        //If we are on the first or second manipulation page of The Lucky Stone, play the current sentence
        if ([chapterTitle isEqualToString:@"The Lucky Stone"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound)) {
            if (conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"TheLuckyStoneS%dS.mp3", currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"TheLuckyStoneS%dE.mp3", currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of Baby Brother, play the current sentence
        if ([chapterTitle isEqualToString:@"Baby Brother"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
           
            sentenceAudioFile = [NSString stringWithFormat:@"BabyBrotherS%dE.mp3", currentSentence];
            
        }
        
        //If we are on the first or second manipulation page of Catch!, play the current sentence
        if ([chapterTitle isEqualToString:@"Catch!"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"CatchS%dE.mp3", currentSentence];
            
        }
        
        //If we are on the first or second manipulation page of Magic Toys, play the current sentence
        if ([chapterTitle isEqualToString:@"Magic Toys"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"MagicToysS%dE.mp3", currentSentence];
            
        }
        
        //If we are on the first or second manipulation page of Words of Wisdom, play the current sentence
        if ([chapterTitle isEqualToString:@"Words of Wisdom"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"WordsOfWisdomS%dE.mp3", currentSentence];
            
        }
        
        //If we are on the first or second manipulation page of The Naughty Monkey, play the current sentence
        if ([chapterTitle isEqualToString:@"The Naughty Monkey"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound ||
            [currentPageId rangeOfString:@"PM-3"].location != NSNotFound) &&
            currentSentence != 1) {
            if (conditionSetup.language == BILINGUAL && currentSentence < 8) {
                sentenceAudioFile = [NSString stringWithFormat:@"TheNaughtyMonkeyS%dS.mp3", currentSentence - 2];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"TheNaughtyMonkeyS%dE.mp3", currentSentence - 2 ];
            }
        }
        
        //If we are on the first or second manipulation page of How Do Objects Move, play the current sentence
        if ([chapterTitle isEqualToString:@"How do Objects Move?"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound)) {
            if (conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"HowDoObjectsMoveS%dS.mp3", currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"HowDoObjectsMoveS%dE.mp3", currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of The Navajo Hogan, play the current sentence
        if ([chapterTitle isEqualToString:@"The Navajo Hogan"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
            if (conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"TheNavajoHoganS%dS.mp3", currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"TheNavajoHoganS%dE.mp3", currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of Native Intro, play the current sentence
        if ([chapterTitle isEqualToString:@"Introduction to Native American Homes"] && ([currentPageId rangeOfString:@"PM"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound)) {
            if (conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"NativeIntroS%dS.mp3", currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"NativeIntroS%dE.mp3", currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of Key Ingredients, play the current sentence
        if ([chapterTitle isEqualToString:@"Key Ingredients"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
            if (conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"KeyIngredientsS%dS.mp3", currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"KeyIngredientsS%dE.mp3", currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of Mancha the Horse, play the current sentence
        if ([chapterTitle isEqualToString:@"Mancha the Horse"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"ManchaTheHorseS%dE.mp3", currentSentence];
           
        }
        
        //If we are on the first or second manipulation page of A Friend in Need, play the current sentence
        if ([chapterTitle isEqualToString:@"A Friend in Need"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"AFriendInNeedS%dE.mp3", currentSentence];
            
        }
        
        //If we are on the first or second manipulation page of Shopping at the Market, play the current sentence
        if ([chapterTitle isEqualToString:@"Shopping at the Market"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound || [currentPageId rangeOfString:@"PM-4"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"ShoppingAtTheMarketS%dE.mp3", currentSentence];
            
        }
        
        //If we are on the first or second manipulation page of A Gift for the Bride, play the current sentence
        if ([chapterTitle isEqualToString:@"A Gift for the Bride"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound || [currentPageId rangeOfString:@"PM-4"].location != NSNotFound || [currentPageId rangeOfString:@"PM-5"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"AGiftForTheBrideS%dE.mp3", currentSentence];
            
        }
        
        //If we are on the first or second manipulation page of Homecoming, play the current sentence
        if ([chapterTitle isEqualToString:@"Homecoming"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound || [currentPageId rangeOfString:@"PM-4"].location != NSNotFound)) {
            
            sentenceAudioFile = [NSString stringWithFormat:@"HomecomingS%dE.mp3", currentSentence];
            
        }
        
        //If we are on the first or second manipulation page of Disasters Intro, play the current sentence
        if ([chapterTitle isEqualToString:@"Introduction to Natural Disasters"] && ([currentPageId rangeOfString:@"PM"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound)) {
            if (conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"DisastersIntroS%dS.mp3", currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"DisastersIntroS%dE.mp3", currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of The Moving Earth, play the current sentence
        if ([chapterTitle isEqualToString:@"The Moving Earth"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
            if (conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"TheMovingEarthS%dS.mp3", currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"TheMovingEarthS%dE.mp3", currentSentence];
            }
        }
    }
    
    NSMutableArray *array = [NSMutableArray array];
    Chapter *chapter = [book getChapterWithTitle:chapterTitle];
    ScriptAudio *script = nil;
    NSString *introAudio = nil;
    LibraryViewController *vc = (LibraryViewController *)libraryViewController;
    ActivitySequenceController * seqController = vc.sequenceController;
    
    if (seqController && [seqController.sequences count] > 1) {
        
        ActivitySequence *seq = [seqController.sequences objectAtIndex:1];
        ActivityMode *mode = [seq getModeForChapter:chapterTitle];
        
        if([currentPageId rangeOfString:@"-Intro"].location != NSNotFound &&
           [currentPageId rangeOfString:@"story1"].location != NSNotFound &&
           ([chapterTitle isEqualToString:@"The Lucky Stone"] || [chapterTitle isEqualToString:@"The Lopez Family"])
           && [bookTitle rangeOfString:seq.bookTitle].location != NSNotFound) {
            
            introAudio = @"splWordsIntro";
            
            [array addObject:[NSString stringWithFormat:@"%@.mp3",introAudio]];
            if (mode.language == BILINGUAL && mode.newInstructions) {
                
                introAudio = [NSString stringWithFormat:@"%@_S",introAudio];
                [array addObject:[NSString stringWithFormat:@"%@.mp3",introAudio]];
                
            }
        }
    }
    
    
    if ([ConditionSetup sharedInstance].condition == EMBRACE) {
        script = [chapter embraceScriptFor:[NSString stringWithFormat:@"%lu", (unsigned long)currentSentence]];
    }
    else {
        script = [chapter controlScriptFor:[NSString stringWithFormat:@"%lu", (unsigned long)currentSentence]];
    }
    
    if (conditionSetup.newInstructions) {
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
            if ([audio containsString:@"Intro"]) {
                
                if ([ConditionSetup sharedInstance].condition == EMBRACE) {
                    if ([ConditionSetup sharedInstance].currentMode == PM_MODE) {
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
                        conditionSetup.newInstructions) {
                        spanishAudio = [NSString stringWithFormat:@"%@_S.mp3",audio];
                        
                    }

                    audio = [NSString stringWithFormat:@"%@.mp3",audio];
                    preAudio = [NSArray arrayWithObjects:audio, spanishAudio, nil];
                    
                }
            }
        }
        
        
        [array addObjectsFromArray:preAudio];
        
        for (NSString *preAudioFile in preAudio) {
            [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:[preAudioFile stringByDeletingPathExtension] inLanguage:[conditionSetup returnLanguageEnumtoString:[conditionSetup language]] ofType:@"Pre-Sentence Script Audio" :manipulationContext];
        }
    }
    
    if (sentenceAudioFile != nil) {
        [array addObject:sentenceAudioFile];
        
        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:[sentenceAudioFile stringByDeletingPathExtension] inLanguage:[conditionSetup returnLanguageEnumtoString:[conditionSetup language]] ofType:@"Sentence Audio" :manipulationContext];
    }
    
    if (postAudio != nil) {
        [array addObjectsFromArray:postAudio];
        
        for (NSString *postAudioFile in postAudio) {
            [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:[postAudioFile stringByDeletingPathExtension] inLanguage:[conditionSetup returnLanguageEnumtoString:[conditionSetup language]] ofType:@"Post-Sentence Script Audio" :manipulationContext];
        }
    }
    
    if ([array count] > 0) {
        [self.playaudioClass playAudioInSequence:array :self];
    }
    else
    {
        //there are no audio files to play so allow interactions
        [self.view setUserInteractionEnabled:YES];
    }
}


- (void)addSentencesWithComplexity:(EMComplexity)complexity {
    
    Chapter *chapter = [book getChapterWithTitle:chapterTitle]; //get current chapter
    PhysicalManipulationActivity *PMActivity = (PhysicalManipulationActivity *)[chapter getActivityOfType:PM_MODE]; //get PM Activity from chapter
    NSMutableArray *alternateSentences = [[PMActivity alternateSentences] objectForKey:currentPageId]; //get alternate sentences for current page
    
    NSString *addSentenceString;
    int sentenceNumber = 1; //used for assigning sentence ids
    int previousIdeaNum = 0; //used for making sure same idea does not get repeated
    
    NSMutableArray *ideaNums = [PMSolution getIdeaNumbers]; //get list of idea numbers on the page
    pageSentences = [NSMutableArray array];
    //Add alternate sentences associated with each idea
    for (NSNumber *ideaNum in ideaNums) {
        if ([ideaNum intValue] > previousIdeaNum) {
            
            
            BOOL foundIdea = false; //flag to check if there is a sentence with the specified complexity for the idea number
            
            //Create an array to hold sentences that will be added to the page
            NSMutableArray *sentencesToAdd = [[NSMutableArray alloc] init];
            
            //Look for alternate sentences that match the idea number and complexity
            for (AlternateSentence *altSent in alternateSentences) {
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
                    if ([[[altSent ideas] objectAtIndex:0] isEqualToNumber:ideaNum] && [altSent complexity] == 2) {
                        foundIdea = true;
                        [sentencesToAdd addObject:altSent];
                        previousIdeaNum = [[[altSent ideas] lastObject] intValue];
                    }
                }
            }
            
            for (AlternateSentence *sentenceToAdd in sentencesToAdd) {
//                //Get alternate sentence information
//                BOOL action = [sentenceToAdd actionSentence];
//                NSString *text = [sentenceToAdd text];
//                
//                //Split sentence text into individual tokens (words)
//                NSArray *textTokens = [text componentsSeparatedByString:@" "];
//                
//                //Contains the vocabulary words that appear in the sentence
//                NSMutableArray *words = [[NSMutableArray alloc] init];
//                
//                //Contains the sentence text split around vocabulary words
//                NSMutableArray *splitText = [[NSMutableArray alloc] init];
//                
//                //Combines tokens into the split sentence text
//                NSString *currentSplit = @"";
//                
//                for (NSString *textToken in textTokens) {
//                    NSString *modifiedTextToken = textToken;
//                    
//                    //Replaces the ' character if it exists in the token
//                    if ([modifiedTextToken rangeOfString:@"'"].location != NSNotFound) {
//                        modifiedTextToken = [modifiedTextToken stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
//                    }
//                    
//                    BOOL addedWord = false; //whether token contains vocabulary word
//                    
//                    for (NSString *vocab in [[Translation translationWords] allKeys]) {
//                        //Match the whole vocabulary word only
//                        NSString *regex = [NSString stringWithFormat:@"\\b%@\\b", vocab];
//                        
//                        //Token contains vocabulary word
//                        if ([modifiedTextToken rangeOfString:regex options:NSRegularExpressionSearch].location != NSNotFound) {
//                            [words addObject:vocab]; //add word to list
//                            addedWord = true;
//                            
//                            [splitText addObject:currentSplit];
//                            
//                            //Reset current split to be anything that appears after the vocabulary word and add a space in the beginning
//                            currentSplit = [[modifiedTextToken stringByReplacingOccurrencesOfString:vocab withString:@""] stringByAppendingString:@" "];
//                            
//                            break;
//                        }
//                    }
//                    
//                    //Token does not contain vocabulary word
//                    if (!addedWord) {
//                        //Add token to current split with a space after it
//                        NSString *textTokenSpace = [NSString stringWithFormat:@"%@ ", modifiedTextToken];
//                        currentSplit = [currentSplit stringByAppendingString:textTokenSpace];
//                    }
//                }
//                
//                [splitText addObject:currentSplit]; //make sure to add the last split
//                
//                //Create array strings for vocabulary and split text to send to JS function
//                NSString *wordsArrayString = [words componentsJoinedByString:@"','"];
//                NSString *splitTextArrayString = [splitText componentsJoinedByString:@"','"];
//                
//                //Add alternate sentence to page
//                addSentenceString = [NSString stringWithFormat:@"addSentence('s%d', %@, ['%@'], ['%@'])", sentenceNumber++, action ? @"true" : @"false", splitTextArrayString, wordsArrayString];
//                [self.bookView stringByEvaluatingJavaScriptFromString:addSentenceString];
//
                [self.pmView addSentence:sentenceToAdd withSentenceNumber:sentenceNumber];
                sentenceNumber++;
                //Add alternate sentence to array
                [pageSentences addObject:sentenceToAdd];
                
                BOOL transference = FALSE;
                
                //Count number of user steps for page statistics
                for (ActionStep *as in [sentenceToAdd solutionSteps]) {
                    if (!([[as stepType] isEqualToString:@"ungroup"] ||
                          [[as stepType] isEqualToString:@"move"] ||
                          [[as stepType] isEqualToString:@"swapImage"])) {
                        //Make sure transference steps don't get counted twice
                        if ([[as stepType] isEqualToString:@"transferAndGroup"] ||
                            [[as stepType] isEqualToString:@"transferAndDisappear"]) {
                            if (!transference) {
                                [[pageStatistics objectForKey:currentPageId] addStepForComplexity:([sentenceToAdd complexity] - 1)];
                                
                                transference = TRUE;
                            }
                            else {
                                transference = FALSE;
                            }
                        }
                        else {
                            [[pageStatistics objectForKey:currentPageId] addStepForComplexity:([sentenceToAdd complexity] - 1)];
                        }
                    }
                }
                
                //Count number of non-action sentences for each complexity
                if ([sentenceToAdd actionSentence] == FALSE) {
                    [[pageStatistics objectForKey:currentPageId] addNonActSentForComplexity:([sentenceToAdd complexity] - 1)];
                }
            }
        }
    }
}

/*
 * Swaps all sentences on the current page for the versions with the specified level of complexity
 */
//TODO: move logic in if else statements into new functions and move into new class
- (void)swapSentencesOnPage:(double)simple :(double)medium :(double)complex {
//    Chapter *chapter = [book getChapterWithTitle:chapterTitle]; //get current chapter
//    PhysicalManipulationActivity *PMActivity = (PhysicalManipulationActivity *)[chapter getActivityOfType:PM_MODE]; //get PM Activity from chapter
//    NSMutableArray *alternateSentences = [[PMActivity alternateSentences] objectForKey:currentPageId]; //get alternate sentences for current page
//    
//    if ([alternateSentences count] > 0) {
//        //Get the number of sentences on the page
//        NSString *requestSentenceCount = [NSString stringWithFormat:@"document.getElementsByClassName('sentence').length"];
//        int sentenceCount = [[bookView stringByEvaluatingJavaScriptFromString:requestSentenceCount] intValue];
//        
//        //Get the id number of the last sentence on the page
//        NSString *requestLastSentenceId = [NSString stringWithFormat:@"document.getElementsByClassName('sentence')[%d - 1].id", sentenceCount];
//        NSString *lastSentenceId = [bookView stringByEvaluatingJavaScriptFromString:requestLastSentenceId];
//        int lastSentenceIdNumber = [[lastSentenceId substringFromIndex:1] intValue];
//        
//        //Get the id number of the first sentence on the page
//        NSString *requestFirstSentenceId = [NSString stringWithFormat:@"document.getElementsByClassName('sentence')[0].id"];
//        NSString *firstSentenceId = [bookView stringByEvaluatingJavaScriptFromString:requestFirstSentenceId];
//        int firstSentenceIdNumber = [[firstSentenceId substringFromIndex:1] intValue];
//        
//        NSString *removeSentenceString;
//        
//        //Remove all sentences on page
//        for (int i = firstSentenceIdNumber; i <= lastSentenceIdNumber; i++) {
//            //Skip the title (sentence 0) if it's the first on the page
//            if (i > 0) {
//                removeSentenceString = [NSString stringWithFormat:@"removeSentence('s%d')", i];
//                [bookView stringByEvaluatingJavaScriptFromString:removeSentenceString];
//            }
//        }
//        
//        NSString *addSentenceString;
//        int sentenceNumber = 1; //used for assigning sentence ids
//        int previousIdeaNum = 0; //used for making sure same idea does not get repeated
//        
//        NSMutableArray *ideaNums = [PMSolution getIdeaNumbers]; //get list of idea numbers on the page
//        
//        double sumOfComplexities[3]; //running sum of complexity parameters used to randomly choose complexity
//        sumOfComplexities[0] = simple;
//        sumOfComplexities[1] = sumOfComplexities[0] + medium;
//        sumOfComplexities[2] = sumOfComplexities[1] + complex;
//        
//        //Add alternate sentences associated with each idea
//        for (NSNumber *ideaNum in ideaNums) {
//            if ([ideaNum intValue] > previousIdeaNum) {
//                NSUInteger complexity = 0;
//                double generateComplexity = ((double) arc4random() / 0x100000000) * 100; //randomly choose complexity
//                
//                for (int i = 0; i < 3; i++) {
//                    if (generateComplexity <= sumOfComplexities[i]) {
//                        complexity = i + 1;
//                        break;
//                    }
//                }
//                
//                BOOL foundIdea = false; //flag to check if there is a sentence with the specified complexity for the idea number
//                
//                //Create an array to hold sentences that will be added to the page
//                NSMutableArray *sentencesToAdd = [[NSMutableArray alloc] init];
//                
//                //Look for alternate sentences that match the idea number and complexity
//                for (AlternateSentence *altSent in alternateSentences) {
//                    if ([[[altSent ideas] objectAtIndex:0] isEqualToNumber:ideaNum] && [altSent complexity] == complexity) {
//                        foundIdea = true;
//                        [sentencesToAdd addObject:altSent];
//                        previousIdeaNum = [[[altSent ideas] lastObject] intValue];
//                    }
//                }
//                
//                //If a sentence with the specified complexity was not found for the idea number, look for a
//                //sentence with complexity level 2
//                if (!foundIdea) {
//                    for (AlternateSentence *altSent in alternateSentences) {
//                        if ([[[altSent ideas] objectAtIndex:0] isEqualToNumber:ideaNum] && [altSent complexity] == 2) {
//                            foundIdea = true;
//                            [sentencesToAdd addObject:altSent];
//                            previousIdeaNum = [[[altSent ideas] lastObject] intValue];
//                        }
//                    }
//                }
//                
//                for (AlternateSentence *sentenceToAdd in sentencesToAdd) {
//                    //Get alternate sentence information
//                    BOOL action = [sentenceToAdd actionSentence];
//                    NSString *text = [sentenceToAdd text];
//                    
//                    //Split sentence text into individual tokens (words)
//                    NSArray *textTokens = [text componentsSeparatedByString:@" "];
//                    
//                    //Contains the vocabulary words that appear in the sentence
//                    NSMutableArray *words = [[NSMutableArray alloc] init];
//                    
//                    //Contains the sentence text split around vocabulary words
//                    NSMutableArray *splitText = [[NSMutableArray alloc] init];
//                    
//                    //Combines tokens into the split sentence text
//                    NSString *currentSplit = @"";
//                    
//                    for (NSString *textToken in textTokens) {
//                        NSString *modifiedTextToken = textToken;
//                        
//                        //Replaces the ' character if it exists in the token
//                        if ([modifiedTextToken rangeOfString:@"'"].location != NSNotFound) {
//                            modifiedTextToken = [modifiedTextToken stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
//                        }
//                        
//                        BOOL addedWord = false; //whether token contains vocabulary word
//                        
//                        for (NSString *vocab in [[Translation translationWords] allKeys]) {
//                            //Match the whole vocabulary word only
//                            NSString *regex = [NSString stringWithFormat:@"\\b%@\\b", vocab];
//                            
//                            //Token contains vocabulary word
//                            if ([modifiedTextToken rangeOfString:regex options:NSRegularExpressionSearch].location != NSNotFound) {
//                                [words addObject:vocab]; //add word to list
//                                addedWord = true;
//                                
//                                [splitText addObject:currentSplit];
//                                
//                                //Reset current split to be anything that appears after the vocabulary word and add a space in the beginning
//                                currentSplit = [[modifiedTextToken stringByReplacingOccurrencesOfString:vocab withString:@""] stringByAppendingString:@" "];
//                                
//                                break;
//                            }
//                        }
//                        
//                        //Token does not contain vocabulary word
//                        if (!addedWord) {
//                            //Add token to current split with a space after it
//                            NSString *textTokenSpace = [NSString stringWithFormat:@"%@ ", modifiedTextToken];
//                            currentSplit = [currentSplit stringByAppendingString:textTokenSpace];
//                        }
//                    }
//                    
//                    [splitText addObject:currentSplit]; //make sure to add the last split
//                    
//                    //Create array strings for vocabulary and split text to send to JS function
//                    NSString *wordsArrayString = [words componentsJoinedByString:@"','"];
//                    NSString *splitTextArrayString = [splitText componentsJoinedByString:@"','"];
//                    
//                    //Add alternate sentence to page
//                    addSentenceString = [NSString stringWithFormat:@"addSentence('s%d', %@, ['%@'], ['%@'])", sentenceNumber++, action ? @"true" : @"false", splitTextArrayString, wordsArrayString];
//                    [bookView stringByEvaluatingJavaScriptFromString:addSentenceString];
//                    
//                    //Add alternate sentence to array
//                    [pageSentences addObject:sentenceToAdd];
//                    
//                    BOOL transference = FALSE;
//                    
//                    //Count number of user steps for page statistics
//                    for (ActionStep *as in [sentenceToAdd solutionSteps]) {
//                        if (!([[as stepType] isEqualToString:@"ungroup"] ||
//                              [[as stepType] isEqualToString:@"move"] ||
//                              [[as stepType] isEqualToString:@"swapImage"])) {
//                            //Make sure transference steps don't get counted twice
//                            if ([[as stepType] isEqualToString:@"transferAndGroup"] ||
//                                [[as stepType] isEqualToString:@"transferAndDisappear"]) {
//                                if (!transference) {
//                                    [[pageStatistics objectForKey:currentPageId] addStepForComplexity:([sentenceToAdd complexity] - 1)];
//                                    
//                                    transference = TRUE;
//                                }
//                                else {
//                                    transference = FALSE;
//                                }
//                            }
//                            else {
//                                [[pageStatistics objectForKey:currentPageId] addStepForComplexity:([sentenceToAdd complexity] - 1)];
//                            }
//                        }
//                    }
//                    
//                    //Count number of non-action sentences for each complexity
//                    if ([sentenceToAdd actionSentence] == FALSE) {
//                        [[pageStatistics objectForKey:currentPageId] addNonActSentForComplexity:([sentenceToAdd complexity] - 1)];
//                    }
//                }
//            }
//        }
//    }
}




/*
 * Creates the menuDataSource from the list of possible interactions.
 * This function assumes that the possible interactions are already rank ordered
 * in cases where that's necessary.
 * If more possible interactions than the alloted number max menu items exists
 * the function will stop after the max number of menu items possible.
 */
- (void)populateMenuDataSource:(NSMutableArray *)possibleInteractions :(NSMutableArray *)relationships {
    //Clear the old data source.
    [menuDataSource clearMenuitems];
    
    //Create new data source for menu.
    //Go through and create a menuItem for every possible interaction
    int interactionNum = 1;
    
    for (PossibleInteraction* interaction in possibleInteractions) {
        //Dig into simulatePossibleInteractionForMenu to log populated menu
        [self simulatePossibleInteractionForMenuItem:interaction :[relationships objectAtIndex:interactionNum - 1]];
        interactionNum++;
        
        //If the number of interactions is greater than the max number of menu items allowed, then stop.
        if (interactionNum > maxMenuItems)
            break;
    }
}

/*
 * Clears the highlighting on the scene
 */
- (void)clearHighlightedObject {
    [self.pmView clearAllHighLighting];
}

- (void)colorSentencesUponNext {
   
    [self.pmView colorSentencesUponNext:currentSentence
                              condition:conditionSetup.condition
                                andMode:conditionSetup.currentMode];
}

/*
 * Checks whether the specified sentence number requires physical or imagine manipulation
 */
- (BOOL)isManipulationSentence:(NSInteger)sentenceNumber {
    BOOL isManipulationSentence = false;
    
    //Get the sentence class
    NSString *sentenceClass = [self.pmView getSentenceClass:sentenceNumber];
    if ([sentenceClass containsString: @"sentence actionSentence"] || ([sentenceClass containsString: @"sentence IMactionSentence"] && conditionSetup.condition == EMBRACE && conditionSetup.currentMode == IM_MODE)) {
        isManipulationSentence = true;
    }
    
    return isManipulationSentence;
}

//TODO: add description
- (void)highlightObject:(NSString *)object :(double)delay {
    if ([model getArea:object:currentPageId]) {
        //Highlight the tapped object
        [self.pmView highLightArea:object];
    }
    else {
        //Highlight the tapped object
        [self.pmView highlightObjectOnWordTap:object];
    }

    //Clear highlighted object
    [self performSelector:@selector(clearHighlightedObject) withObject:nil afterDelay:delay];
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
        return @"Translation not found";
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
        return @"Translation not found";
}


/*
 * Expands the contextual menu, allowing the user to select a possible grouping/ungrouping.
 * This function is called after the data source is created.
 */
//TODO: simplify im and pm menu logic
- (void)expandMenu {
    menu = [[PieContextualMenu alloc] initWithFrame:[self.pmView frame]];
    [menu addGestureRecognizer:tapRecognizer];
    
    if (conditionSetup.condition == EMBRACE && conditionSetup.currentMode == IM_MODE) {
        [IMViewMenu addSubview:menu];
    }
    else {
        [[self view] addSubview:menu];
    }
    
    menu.delegate = self;
    menu.dataSource = menuDataSource;
    
    CGFloat radius;
    
    if (conditionSetup.condition == EMBRACE && conditionSetup.currentMode == IM_MODE) {
        //Calculate the radius of the circle
         radius = (menuBoundingBoxIM -  (itemRadiusIM * 2)) / 2;
    }
    else {
        //Calculate the radius of the circle
        radius = (menuBoundingBoxPM -  (itemRadiusPM * 2)) / 2;
    }
    
    [menu expandMenu:radius];
    menuExpanded = TRUE;
    
    //Used to store menu items data as strings for logging
    NSMutableArray *menuItemsData = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [menuDataSource numberOfMenuItems]; i++) {
        MenuItemDataSource *dataForItem = [menuDataSource dataObjectAtIndex:i];
        PossibleInteraction *interaction = [dataForItem interaction];
        
        //Used to store menu item data as strings for logging
        NSMutableArray *menuItemData = [[NSMutableArray alloc] init];
        
        //Go through each connection in the interaction and extract data for logging
        for (Connection *connection in [interaction connections]) {
            NSMutableDictionary *connectionData = [[NSMutableDictionary alloc] init];
            
            NSArray *objects = [connection objects];
            NSString *hotspot = [(Hotspot *)[[connection hotspots] objectAtIndex:0] action];
            NSString *interactionType = [connection returnInteractionTypeAsString];
            
            [connectionData setObject:objects forKey:@"objects"];
            [connectionData setObject:hotspot forKey:@"hotspot"];
            [connectionData setObject:interactionType forKey:@"interactionType"];
            
            [menuItemData addObject:connectionData];
        }
        
        [menuItemsData addObject:menuItemData];
    }
    
    if (([chapterTitle isEqualToString:@"The Naughty Monkey"]) && currentSentence == 6 && currentStep == 2) {
        if (conditionSetup.language == ENGLISH) {
            [self.playaudioClass playAudioFile:self :@"NaughtyMonkey_Script5.mp3"];
        } else {
            [self.playaudioClass playAudioFile:self :@"NaughtyMonkey_Script5_S.mp3"];
        }
        
        
    } else if (([chapterTitle isEqualToString:@"The Naughty Monkey"]) && currentSentence == 7 && currentStep == 3 ) {
        if (conditionSetup.language == ENGLISH) {
            [self.playaudioClass playAudioFile:self :@"NaughtyMonkey_Script7.mp3"];
        } else {
            [self.playaudioClass playAudioFile:self :@"NaughtyMonkey_Script7_S.mp3"];
        }
        
    }
    
   [[ServerCommunicationController sharedInstance] logDisplayMenuItems:menuItemsData context:manipulationContext];
}

//TODO: add description
- (void)setManipulationContext {
    //Hardcoding for second Introduction to EMBRACE
    if ([[(LibraryViewController *)libraryViewController studentProgress] getStatusOfBook:[book title]] == COMPLETED && ([[(LibraryViewController *)libraryViewController studentProgress] getStatusOfBook:@"Second Introduction to EMBRACE"] == IN_PROGRESS || [[(LibraryViewController *)libraryViewController studentProgress] getStatusOfBook:@"Second Introduction to EMBRACE"] == COMPLETED)) {
        manipulationContext.bookTitle = @"Second Introduction to EMBRACE";
    }
    else {
        manipulationContext.bookTitle = [book title];
    }
    
    manipulationContext.chapterTitle = chapterTitle;
    
    //currentPageId has format "story<chapter number>-<mode>-<page number>" (e.g., "story1-PM-1")
    NSArray *currentPageIdComponents = [currentPageId componentsSeparatedByString:@"-"];
    
    manipulationContext.chapterNumber = [[[currentPageIdComponents objectAtIndex:0] stringByReplacingOccurrencesOfString:@"story" withString:@""] intValue];
    manipulationContext.pageNumber = [currentPageIdComponents count] == 3 ? [[currentPageIdComponents objectAtIndex:2] intValue] : 0;
    
    if ([[currentPageIdComponents objectAtIndex:1] isEqualToString:@"Intro"]) {
        manipulationContext.pageMode = @"Intro";
    }
    else {
        manipulationContext.pageMode = @"Intervention";
    }
}

#pragma mark - ManipulationAnalyserProtocol

- (CGPoint)locationOfObject:(NSString *)object
                   analyzer:(ManipulationAnalyser *)analyzer {
    
    return [self getObjectPosition:object];
}

- (CGSize)sizeOfObject:(NSString *)object analyzer:(ManipulationAnalyser *)analyzer {
    return [self.pmView sizeOfObject:object];
}

- (void)analyzer:(ManipulationAnalyser *)analyzer showMessage:(NSString *)message {
   
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Dismiss"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [alert addAction:action];
//    [self presentViewController:alert animated:YES completion:nil];
    
//    int duration = 5; // duration in seconds
//    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        [alert dismissViewControllerAnimated:YES completion:nil];
//    });
}

- (NSArray *)getNextStepsForCurrentSentence:(ManipulationAnalyser *)analyzer {
    NSMutableArray *currSolSteps = [self returnCurrentSolutionSteps];
    NSArray *nextSteps = nil;
    
    if ([currSolSteps count] > currentStep) {
        NSRange range = NSMakeRange(currentStep, [currSolSteps count] - currentStep);
        nextSteps = [currSolSteps subarrayWithRange:range];
    }
    
    return nextSteps;
}

- (EMComplexity)analyzer:(ManipulationAnalyser *)analyzer getComplexityForSentence:(int)sentenceNumber {
    return self.currentComplexityLevel;
}

@end
