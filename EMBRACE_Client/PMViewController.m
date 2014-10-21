//
//  BookViewController.m
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

@interface PMViewController () {
    NSString* currentPage; //The current page being shown, so that the next page can be requested.
    NSString* currentPageId; //The id of the current page being shown
    
    NSUInteger currentSentence; //Active sentence to be completed.
    NSUInteger totalSentences; //Total number of sentences on this page.
    NSUInteger currentIntroStep; //Current step in the introduction
    
    PhysicalManipulationSolution* PMSolution; //Solution steps for current chapter
    NSUInteger numSteps; //Number of steps for current sentence
    NSUInteger currentStep; //Active step to be completed.
    BOOL stepsComplete; //True if all steps have been completed for a sentence
    
    NSString *movingObjectId; //Object currently being moved.
    NSString *collisionObjectId; //Object the moving object was moved to.
    NSString *separatingObjectId; //Object identified when pinch gesture performed.
    Relationship *lastRelationship;//stores the most recent relationship between objects used
    NSMutableArray *allRelationships;// stores an array of all relationships which is populated in getPossibleInteractions
    BOOL movingObject; //True if an object is currently being moved, false otherwise.
    BOOL separatingObject; //True if two objects are currently being ungrouped, false otherwise.
    
    BOOL panning;
    BOOL pinching;
    BOOL pinchToUngroup; //TRUE if pinch gesture is used to ungroup; FALSE otherwise
    BOOL allowInteractions; //TRUE if objects can be manipulated; FALSE otherwise
    
    NSMutableDictionary *currentGroupings;
    
    BOOL replenishSupply; //TRUE if object should reappear after disappearing
    BOOL allowSnapback; //TRUE if objects should snap back to original location upon error

    CGPoint startLocation; //initial location of an object before it is moved
    CGPoint delta; //distance between the top-left corner of the image being moved and the point clicked.
    
    ContextualMenuDataSource *menuDataSource;
    PieContextualMenu *menu;
    BOOL menuExpanded;
    
    InteractionModel *model;
    
    Condition condition; //Study condition to run the app (e.g. MENU, HOTSPOT, etc.)
    InteractionRestriction useSubject; //Determines which objects the user can manipulate as the subject
    InteractionRestriction useObject; //Determines which objects the user can interact with as the object
    
    NSMutableDictionary* introductions; //Stores the instances of the introductions from metadata.xml
    NSUInteger totalIntroSteps; //Stores the total number of introduction steps for the current chapter
    NSMutableArray* currentIntroSteps; //Stores the introduction steps for the current chapter
    NSArray *performedActions; //Store the information of the current step
    
    NSMutableDictionary* vocabularies; //Stores the instances of the vocabs from metadata.xml
    NSUInteger currentVocabStep; //Stores the index of the current vocab step
    NSMutableArray* currentVocabSteps; //Stores the vocab steps for the current chapter
    NSUInteger totalVocabSteps; //Stores the total number of vocab steps for the current chapter
    
    NSString* actualPage; //Stores the address of the current page we are at
    NSString* actualWord; //Stores the current word that was clicked
    NSTimer* timer; //Controls the timing of the audio file that is playing
    NSString* languageString; //Defines the languange to be used 'E' for English 'S' for Spanish
    BOOL sameWordClicked; //Defines if a word has been clicked or not
    NSString* vocabAudio; //Used to store the next vocab audio file to be played
    NSInteger lastStep; //Used to store the most recent intro step
    NSString* nextIntro; //Used to store the most recent intro step
    NSString* currentAudio; //Used to store the current vocab audio file to be played
}

@property (nonatomic, strong) IBOutlet UIWebView *bookView;
@property (strong) AVAudioPlayer *audioPlayer;
@property (strong) AVAudioPlayer *audioPlayerAfter; // Used to play sounds after the first audio player has finished playing

@end

@implementation PMViewController

@synthesize book;

@synthesize bookTitle;
@synthesize chapterTitle;

@synthesize bookImporter;
@synthesize bookView;

@synthesize syn;

//Used to determine the required proximity of 2 hotspots to group two items together.
float const groupingProximity = 20.0;

//In the bilingual introduction there are 13 steps in Spanish before switching to English only
int const STEPS_TO_SWITCH_LANGUAGES_EMBRACE = 12;
int const STEPS_TO_SWITCH_LANGUAGES_CONTROL = 11;
int language_condition = ENGLISH;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    bookView.frame = self.view.bounds;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    syn = [[AVSpeechSynthesizer alloc] init];
    
    //Added to deal with ios7 view changes. This makes it so the UIWebView and the navigation bar do not overlap.
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    bookView.scalesPageToFit = YES;
    bookView.scrollView.delegate = self;
    
    [[bookView scrollView] setBounces: NO];
    [[bookView scrollView] setScrollEnabled:NO];
    
    movingObject = FALSE;
    pinching = FALSE;
    menuExpanded = FALSE;
    
    movingObjectId = nil;
    collisionObjectId = nil;
    lastRelationship = nil;
    allRelationships = [[NSMutableArray alloc] init];
    separatingObjectId = nil;
    
    currentPage = nil;
    
    condition = CONTROL;
    languageString = @"E";
    
    if (condition == CONTROL) {
        allowInteractions = FALSE; //control condition allows user to read only; no manipulations
    }
    else {
        allowInteractions = TRUE;
    }
    
    useSubject = ALL_ENTITIES;
    useObject = ONLY_CORRECT;
    pinchToUngroup = FALSE;
    replenishSupply = FALSE;
    allowSnapback = TRUE;
    
    sameWordClicked = false;
    
    currentGroupings = [[NSMutableDictionary alloc] init];
    
    //Create contextualMenuController
    menuDataSource = [[ContextualMenuDataSource alloc] init];
    
    //Ensure that the pinch recognizer gets called before the pan gesture recognizer.
    //That way, if a user is trying to ungroup objects, they can do so without the objects moving as well.
    //TODO: Figure out how to get the pan gesture to still properly recognize the begin and continue actions.
    //[panRecognizer requireGestureRecognizerToFail:pinchRecognizer];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // Disable user selection
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
    // Disable callout
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
    
    // Load the js files.
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"ImageManipulation" ofType:@"js"];
    
    if(filePath == nil) {
        NSLog(@"Cannot find js file: ImageManipulation");
    }
    else {
        NSData *fileData = [NSData dataWithContentsOfFile:filePath];
        NSString *jsString = [[NSMutableString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
        [bookView stringByEvaluatingJavaScriptFromString:jsString];
    }
    
    //Start off with no objects grouped together
    currentGroupings = [[NSMutableDictionary alloc] init];

    //Get the number of sentences on the page
    NSString* requestSentenceCount = [NSString stringWithFormat:@"document.getElementsByClassName('sentence').length"];
    int sentenceCount = [[bookView stringByEvaluatingJavaScriptFromString:requestSentenceCount] intValue];
    
    //Get the id number of the last sentence on the page and set it equal to the total number of sentences.
    //Because the PMActivity may have multiple pages, this id number may not match the sentence count for the page.
    //   Ex. Page 1 may have three sentences: 1, 2, and 3. Page 2 may also have three sentences: 4, 5, and 6.
    //   The total number of sentences is like a running total, so by page 2, there are 6 sentences instead of 3.
    //This is to make sure we access the solution steps for the correct sentence on this page, and not a sentence on
    //a previous page.
    //if (![vocabularies objectForKey:chapterTitle]) {
        NSString* requestLastSentenceId = [NSString stringWithFormat:@"document.getElementsByClassName('sentence')[%d - 1].id", sentenceCount];
        NSString* lastSentenceId = [bookView stringByEvaluatingJavaScriptFromString:requestLastSentenceId];
        int lastSentenceIdNumber = [[lastSentenceId substringFromIndex:1] intValue];
        totalSentences = lastSentenceIdNumber;
    //}
    //else {
        //totalSentences = sentenceCount;
    //}
    
    //Get the id number of the first sentence on the page and set it equal to the current sentence number.
    //Because the PMActivity may have multiple pages, the first sentence on the page is not necessarily sentence 1.
    //   Ex. Page 1 may start at sentence 1, but page 2 may start at sentence 4.
    //   Thus, the first sentence on page 2 is sentence 4, not 1.
    //This is also to make sure we access the solution steps for the correct sentence.
    NSString* requestFirstSentenceId = [NSString stringWithFormat:@"document.getElementsByClassName('sentence')[0].id"];
    NSString* firstSentenceId = [bookView stringByEvaluatingJavaScriptFromString:requestFirstSentenceId];
    int firstSentenceIdNumber = [[firstSentenceId substringFromIndex:1] intValue];
    currentSentence = firstSentenceIdNumber;
    
    //Set up current sentence appearance and solution steps
    [self setupCurrentSentence];
    [self setupCurrentSentenceColor];
    
    if ([introductions objectForKey:chapterTitle] || ([vocabularies objectForKey:chapterTitle] && [currentPageId rangeOfString:@"Intro"].location != NSNotFound)) {
        allowInteractions = FALSE;
    }
    
    //Load the first step for the current chapter
    if ([introductions objectForKey:chapterTitle]) {
        [self loadIntroStep];
    }
    
    //Create UIView for textbox area to recognize swipe gesture
    //NOTE: Currently not in use because it disables tap gesture recognition over the textbox area and we haven't
    //found a way to fix this yet.
    //[self createTextboxView];
    
    //Load the first vocabulary step for the current chapter (hard-coded for now)
    if ([vocabularies objectForKey:chapterTitle] && [currentPageId rangeOfString:@"Intro"].location != NSNotFound) {
        //The first word is in Spanish
        [self loadVocabStep];
    }
    
    //If we are on the first or second manipulation page of The Contest, play the audio of the first sentence
    if(language_condition == BILINGUAL) {
    
    }
    if ([chapterTitle isEqualToString:@"The Contest"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound)) {
        if(language_condition == BILINGUAL) {
                [self playAudioFile:[NSString stringWithFormat:@"BFEC%d.m4a",currentSentence]];
        }
        else {
            [self playAudioFile:[NSString stringWithFormat:@"BFTC%d.m4a",currentSentence]];
        }
    }
    
    //If we are on the first or second manipulation page of Why We Breathe, play the audio of the first sentence
    if ([chapterTitle isEqualToString:@"Why We Breathe"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
        if(language_condition == BILINGUAL) {
            [self playAudioFile:[NSString stringWithFormat:@"CPQR%d.m4a",currentSentence]];
        }
        else {
            [self playAudioFile:[NSString stringWithFormat:@"CWWB%d.m4a",currentSentence]];
        }
    }
    
    //Perform setup for activity
    [self performSetupForActivity];
}

/*
 * Gets the book reference for the book that's been opened.
 * Also sets the reference to the interaction model of the book.
 * Sets the page to the one for th current chapter activity.
 * Calls the function to load the html content for the activity.
 */
- (void) loadFirstPage {
    book = [bookImporter getBookWithTitle:bookTitle]; //Get the book reference.
    model = [book model];
  
    currentPage = [book getNextPageForChapterAndActivity:chapterTitle :PM_MODE :nil];
    
    actualPage = currentPage;
    
    //Introduction setup
    currentIntroStep = 1;
    
    //Load the introduction data
    introductions = [model getIntroductions];
    
    //Get the steps for the introduction of the current chapter
    currentIntroSteps = [introductions objectForKey:chapterTitle];
    totalIntroSteps = [currentIntroSteps count];
    
    [self loadPage];
    
    //change logging to introduction??
    //Logging added by James for Loading First Page of selected Chapter form Library View
    [[ServerCommunicationController sharedManager] logNextChapterNavigation:bookTitle :@"Title Page" :currentPage :@"Load First Page" :bookTitle :chapterTitle : currentPage : [NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] : [NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
    //Logging Completes Here.
}

/*
 * Loads the next page for the current chapter based on the current activity.
 * If the activity has multiple pages, it would load the next page in the activity.
 * Otherwise, it will load the next chaper.
 */
-(void) loadNextPage {
    //stores last page
    NSString *tempLastPage = currentPage;
    currentPage = [book getNextPageForChapterAndActivity:chapterTitle :PM_MODE :currentPage];
    
    //Logging added by James for Computer Navigation to next Page
    [[ServerCommunicationController sharedManager] logNextPageNavigation:@"Next Button" :tempLastPage :currentPage :@"Next Page" :bookTitle :chapterTitle : currentPage : [NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] : [NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
    //Logging Completes Here.
    
    //No more pages in chapter
    if (currentPage == nil) {
        chapterTitle = [book getChapterAfterChapter:chapterTitle];
        
        if(chapterTitle == nil) { //no more chapters.
            //Logging added by James for Computer Navigation when end of chapter is reached
            [[ServerCommunicationController sharedManager] logNextChapterNavigation:@"Next Button" :tempLastPage :currentPage :@"Next Page | No more Chapters" :bookTitle :chapterTitle : currentPage : [NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] : [NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
            //Logging Completes Here.
        }
        
        [self.navigationController popViewControllerAnimated:YES]; //return to library view
        return;
    }
    
    [self loadPage];
}

/*
 * Loads the html content for the current page.
 */
-(void) loadPage {
    NSURL* baseURL = [NSURL fileURLWithPath:[book getHTMLURL]];
    
    if(baseURL == nil)
        NSLog(@"did not load baseURL");
    
    NSError *error;
    NSString* pageContents = [[NSString alloc] initWithContentsOfFile:currentPage encoding:NSASCIIStringEncoding error:&error];
    if(error != nil)
        NSLog(@"problem loading page contents");
    
    [bookView loadHTMLString:pageContents baseURL:baseURL];
    [bookView stringByEvaluatingJavaScriptFromString:@"document.body.style.webkitTouchCallout='none';"];
    //[bookView becomeFirstResponder];
    
    self.title = chapterTitle;
    
    //Set the current page id
    currentPageId = [book getIdForPageInChapterAndActivity:currentPage :chapterTitle :PM_MODE];
    
    //Get the solution steps for the current chapter
    Chapter* chapter = [book getChapterWithTitle:chapterTitle]; //get current chapter
    PhysicalManipulationActivity* PMActivity = (PhysicalManipulationActivity*)[chapter getActivityOfType:PM_MODE]; //get PM Activity from chapter
    PMSolution = [PMActivity PMSolution]; //get PM solution
    
    //Vocabulary setup
    currentVocabStep = 1;
    lastStep = 1;
    
    //Load the vocabulary data
    vocabularies = [model getVocabularies];
    
    //Get the vocabulary steps (words) for the current story
    currentVocabSteps = [vocabularies objectForKey:chapterTitle];
    totalVocabSteps = [currentVocabSteps count];
    
    if (condition != CONTROL) {
        allowInteractions = TRUE;
    }
}

/*
 * Gets the number of steps for the current
 * sentence and sets the current step to 1. Steps are complete if it's a non-action sentence.
 */
-(void) setupCurrentSentence {
    currentStep = 1;
    stepsComplete = FALSE;
    
    //Get number of steps for current sentence
    numSteps = [PMSolution getNumStepsForSentence:currentSentence];
    
    //Check to see if it is an action sentence
    NSString* actionSentence = [NSString stringWithFormat:@"getSentenceClass(s%d)", currentSentence];
    NSString* sentenceClass = [bookView stringByEvaluatingJavaScriptFromString:actionSentence];
    
    //If it is an action sentence, perform its solution steps if necessary
    if ([sentenceClass  isEqualToString: @"sentence actionSentence"]) {
        [self performAutomaticSteps];
    }
    else {
        stepsComplete = TRUE; //no steps to complete for non-action sentence
    }
}

/* Sets up the appearance of the current sentence by highlighting it as blue (if it is an action sentence)
 * or as black (if it is a non-action sentence).
 */
-(void) setupCurrentSentenceColor {
    //Highlight the sentence and set its color to black.
    NSString* setSentenceOpacity = [NSString stringWithFormat:@"setSentenceOpacity(s%d, 1.0)", currentSentence];
    [bookView stringByEvaluatingJavaScriptFromString:setSentenceOpacity];
    
    NSString* setSentenceColor = [NSString stringWithFormat:@"setSentenceColor(s%d, 'black')", currentSentence];
    [bookView stringByEvaluatingJavaScriptFromString:setSentenceColor];
    
    //Check to see if it is an action sentence
    NSString* actionSentence = [NSString stringWithFormat:@"getSentenceClass(s%d)", currentSentence];
    NSString* sentenceClass = [bookView stringByEvaluatingJavaScriptFromString:actionSentence];
    
    //If it is an action sentence, set its color to blue and automatically perform solution steps if necessary
    if ([sentenceClass  isEqualToString: @"sentence actionSentence"]) {
        setSentenceColor = [NSString stringWithFormat:@"setSentenceColor(s%d, 'blue')", currentSentence];
        [bookView stringByEvaluatingJavaScriptFromString:setSentenceColor];
    }
    
    //Set the opacity of all but the current sentence to .2
    for(int i = currentSentence; i < totalSentences; i++) {
        NSString* setSentenceOpacity = [NSString stringWithFormat:@"setSentenceOpacity(s%d, .2)", i + 1];
        [bookView stringByEvaluatingJavaScriptFromString:setSentenceOpacity];
    }
}

/*
 * Moves to next step in a sentence if possible. The step is performed automatically 
 * if it is ungroup, move, or swap image.
 */
-(void) incrementCurrentStep {
    //Check if able to increment current step
    if (currentStep < numSteps) {
        NSString *tempsteps = [NSString stringWithFormat:@"%lu", (unsigned long)currentStep];
        currentStep++;
    
        //Logging added by James for Computer Navigation to next Step
        [[ServerCommunicationController sharedManager] logNextStepNavigation:@"Automatic Computer Action" :tempsteps :[NSString stringWithFormat:@"%lu", (unsigned long)currentStep] :@"Next Step" :bookTitle :chapterTitle : currentPage : [NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] :tempsteps];
        //Logging Completes Here.
        
        [self performAutomaticSteps]; //automatically perform ungroup or move steps if necessary
    }
    else {
        stepsComplete = TRUE; //no more steps to complete
    }
}

/*
 * Converts an ActionStep object to a PossibleInteraction object
 */
-(PossibleInteraction*) convertActionStepToPossibleInteraction:(ActionStep*)step {
    PossibleInteraction* interaction;
    
    //Get step information
    NSString* obj1Id = [step object1Id];
    NSString* obj2Id = [step object2Id];
    NSString* action = [step action];
    
    //Objects involved in interaction
    NSArray* objects;
    
    //Get hotspots for both objects associated with action, first assuming that obj1 is the subject of the interaction
    Hotspot* hotspot1 = [model getHotspotforObjectWithActionAndRole:obj1Id :action :@"subject"];
    Hotspot* hotspot2 = [model getHotspotforObjectWithActionAndRole:obj2Id :action :@"object"];
    
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
    
    NSArray* hotspotsForInteraction = [[NSArray alloc]initWithObjects:hotspot1, hotspot2, nil];
    
    //The move case only applies if an object is being moved to another object, not a waypoint
    if ([[step stepType] isEqualToString:@"group"] || [[step stepType] isEqualToString:@"move"]) {
        interaction = [[PossibleInteraction alloc]initWithInteractionType:GROUP];
        
        [interaction addConnection:GROUP :objects :hotspotsForInteraction];
    }
    else if ([[step stepType] isEqualToString:@"ungroup"]) {
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
-(void) performSetupForActivity {
    Chapter* chapter = [book getChapterWithTitle:chapterTitle]; //get current chapter
    PhysicalManipulationActivity* PMActivity = (PhysicalManipulationActivity*)[chapter getActivityOfType:PM_MODE]; //get PM Activity from chapter
    NSMutableArray* setupSteps = [[PMActivity setupSteps] objectForKey:currentPageId]; //get setup steps for current page
    
    for (ActionStep* setupStep in setupSteps) {
        if ([[setupStep stepType] isEqualToString:@"group"]) {
            PossibleInteraction* interaction = [self convertActionStepToPossibleInteraction:setupStep];
            [self performInteraction:interaction]; //groups the objects
        }
        else if ([[setupStep stepType] isEqualToString:@"move"]) {
            //Get information for move step type
            NSString* object1Id = [setupStep object1Id];
            NSString* action = [setupStep action];
            NSString* object2Id = [setupStep object2Id];
            NSString* waypointId = [setupStep waypointId];
            
            //Move either requires object1 to move to object2 (which creates a group interaction) or it requires object1 to move to a waypoint
            if (object2Id != nil) {
                PossibleInteraction* correctInteraction = [self getCorrectInteraction];
                [self performInteraction:correctInteraction]; //performs solution step
            }
            else if (waypointId != nil) {
                //Get position of hotspot in pixels based on the object image size
                Hotspot* hotspot = [model getHotspotforObjectWithActionAndRole:object1Id :action :@"subject"];
                CGPoint hotspotLocation = [self getHotspotLocationOnImage:hotspot];
                
                //Get position of waypoint in pixels based on the background size
                Waypoint* waypoint = [model getWaypointWithId:waypointId];
                CGPoint waypointLocation = [self getWaypointLocation:waypoint];
                
                //Move the object
                [self moveObject:object1Id :waypointLocation :hotspotLocation :false:waypointId];
                
                //Clear highlighting
                NSString *clearHighlighting = [NSString stringWithFormat:@"clearAllHighlighted()"];
                [bookView stringByEvaluatingJavaScriptFromString:clearHighlighting];
            }
        }
    }
}

/*
 * Performs ungroup, move, and swap image steps automatically
 */
-(void) performAutomaticSteps {
    
    if([introductions objectForKey:chapterTitle] && [[performedActions objectAtIndex:INPUT] isEqualToString:@"next"]) {
        allowInteractions = TRUE;
    }
    
    //Perform steps only if they exist for the sentence
    if (numSteps > 0 && allowInteractions) {
        //Get steps for current sentence
        NSMutableArray* currSolSteps = [PMSolution getStepsForSentence:currentSentence];
        
        //Get current step to be completed
        ActionStep* currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        //Automatically perform interaction if step is ungroup, move, or swap image
        if (!pinchToUngroup && [[currSolStep stepType] isEqualToString:@"ungroup"]) {
            PossibleInteraction* correctUngrouping = [self getCorrectInteraction];
            
            [self performInteraction:correctUngrouping];
            
            //add logging to performInteraction maybe add a log here for perform atomic steps to distinguish automatic steps are being done and then just use performinterction to show the interaction
            //[[ServerCommunicationController sharedManager] logComputerGroupingObjects:<#(NSString *)#>]
            
            [self incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:@"move"]) {
            [self moveObjectForSolution];
            
            //add logging
            //[[ServerCommunicationController sharedManager] logComputerGroupingObjects:<#(NSString *)#>]
            
            [self incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:@"swapImage"]) {
            [self swapObjectImage];
            
            //add logging
            //[[ServerCommunicationController sharedManager] logComputerGroupingObjects:<#(NSString *)#>]
            
            [self incrementCurrentStep];
        }
    }
    
    if([introductions objectForKey:chapterTitle] && [[performedActions objectAtIndex:INPUT] isEqualToString:@"next"]) {
        allowInteractions = FALSE;
    }
}

#pragma mark - Responding to gestures
/*
 * Plays a noise for error feedback if the user performs a manipulation incorrectly
 */
- (IBAction) playErrorNoise {
    AudioServicesPlaySystemSound(1053);
    
    //Logging added by James for Error Noise
    [[ServerCommunicationController sharedManager] logComputerPlayAudio: @"Play Error Audio" : @"NULL" :@"Error Noise"  :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu",(unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
}


/*
 * Tap gesture. Currently only used for menu selection.
 */
- (IBAction)tapGesturePerformed:(UITapGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];
    
    if([introductions objectForKey:chapterTitle] && [[performedActions objectAtIndex:INPUT] isEqualToString:@"menu"]) {
        allowInteractions = TRUE;
    }
    
    //check to see if we have a menu open. If so, process menu click.
    if(menu != nil && allowInteractions) {
        int menuItem = [menu pointInMenuItem:location];
        
        //If we've selected a menuItem.
        if(menuItem != -1) {
            //Get the information from the particular menu item that was pressed.
            MenuItemDataSource *dataForItem = [menuDataSource dataObjectAtIndex:menuItem];
            PossibleInteraction *interaction = [dataForItem interaction];
            
            NSInteger numMenuItems = [menuDataSource numberOfMenuItems];
            NSMutableArray *menuItemInteractions = [[NSMutableArray alloc] init];
            NSMutableArray *menuItemImages =[[NSMutableArray alloc] init];
            NSMutableArray *menuItemRelationships = [[NSMutableArray alloc] init];
            
            for (int x=0; x<numMenuItems; x++) {
                MenuItemDataSource *tempMenuItem = [menuDataSource dataObjectAtIndex:x];
                PossibleInteraction *tempMenuInteraction =[tempMenuItem interaction];
                Relationship *tempMenuRelationship = [tempMenuItem menuRelationship];
                
                //[menuItemInteractions addObject:[tempMenuRelationship actionType]];
                
                if(tempMenuInteraction.interactionType == DISAPPEAR)
                {
                    [menuItemInteractions addObject:@"Disappear"];
                }
                if (tempMenuInteraction.interactionType == UNGROUP)
                {
                    [menuItemInteractions addObject:@"Ungroup"];
                }
                if (tempMenuInteraction.interactionType == GROUP)
                {
                    [menuItemInteractions addObject:@"Group"];
                }
                if (tempMenuInteraction.interactionType == TRANSFERANDDISAPPEAR)
                {
                    [menuItemInteractions addObject:@"Transfer And Disappear"];
                }
                if (tempMenuInteraction.interactionType == TRANSFERANDGROUP)
                {
                    [menuItemInteractions addObject:@"Transfer And Group"];
                }
                if(tempMenuInteraction.interactionType ==NONE)
                {
                    [menuItemInteractions addObject:@"none"];
                }
                
                [menuItemImages addObject:[NSString stringWithFormat:@"%d", x]];
                
                for(int i=0; i< [tempMenuItem.images count]; i++)
                {
                    MenuItemImage *tempimage =  [tempMenuItem.images objectAtIndex:i];
                    [menuItemImages addObject:[tempimage.image accessibilityIdentifier]];
                }
                
                [menuItemRelationships addObject:tempMenuRelationship.action];
            }
            
            //Logging Add by James for Menu Selection
            [[ServerCommunicationController sharedManager] logMenuSelection: menuItem: menuItemInteractions : menuItemImages : menuItemRelationships :@"Menu Item Selected" :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
            
            [self checkSolutionForInteraction:interaction]; //check if selected interaction is correct
        }
        //No menuItem was selected
        else {
            if (allowSnapback) {
                //Snap the object back to its original location
                [self moveObject:movingObjectId :startLocation :CGPointMake(0, 0) :false : @"None"];
                
                //Clear any remaining highlighting.
                NSString *clearHighlighting = [NSString stringWithFormat:@"clearAllHighlighted()"];
                [bookView stringByEvaluatingJavaScriptFromString:clearHighlighting];
            }
        }
        
        //No longer moving object
        movingObject = FALSE;
        movingObjectId = nil;
        
        //Re-add the tap gesture recognizer before the menu is removed
        [self.view addGestureRecognizer:tapRecognizer];
        
        //Remove menu.
        [menu removeFromSuperview];
        menu = nil;
        menuExpanded = FALSE;
    }
    else {
        if (numSteps > 0 && allowInteractions) {
            //Get steps for current sentence
            NSMutableArray* currSolSteps = [PMSolution getStepsForSentence:currentSentence];
            
            if ([currSolSteps count] > 0) {
                //Get current step to be completed
                ActionStep* currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
                
                //Current step is checkAndSwap
                if ([[currSolStep stepType] isEqualToString:@"checkAndSwap"]) {
                    //Get the object at this point
                    NSString* imageAtPoint = [self getObjectAtPoint:location ofType:nil];
                    
                    //If the correct object was tapped, swap its image and increment the step
                    if ([self checkSolutionForSubject:imageAtPoint]) {
                        [self swapObjectImage];
                        [self incrementCurrentStep];
                    }
                }
            }
        }
        
        //Get the object at that point if it's a manipulation object.
        NSString* imageAtPoint = [self getObjectAtPoint:location ofType:@"manipulationObject"];
        
        //NSLog(@"location pressed: (%f, %f)", location.x, location.y);
        
        //Retrieve the name of the object at this location
        NSString* requestImageAtPoint = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).id", location.x, location.y];
        
        imageAtPoint = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPoint];
            
        //Capture the clicked text, if it exists
        NSString* requestSentenceText = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).innerHTML", location.x, location.y];
        NSString* sentenceText = [bookView stringByEvaluatingJavaScriptFromString:requestSentenceText];
        
        //Capture the clicked text id, if it exists
        NSString* requestSentenceID = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).id", location.x, location.y];
        NSString* sentenceID = [bookView stringByEvaluatingJavaScriptFromString:requestSentenceID];
        int sentenceIDNum = [[sentenceID substringFromIndex:0] intValue];

        //Logs user Word Press
        [[ServerCommunicationController sharedManager] logUserPressWord:sentenceText :@"Tap" :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu",(unsigned long)currentSentence] :[NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
        
        NSLog(@"%@",sentenceText);
        
        //Convert to lowercase so the sentence text can be mapped to objects
        sentenceText = [sentenceText lowercaseString];
        NSString* englishSentenceText = sentenceText;
        
        if (language_condition == BILINGUAL) {
            if(![[self getEnglishTranslation:sentenceText] isEqualToString:@"Translation not found"]) {
                englishSentenceText = [self getEnglishTranslation:sentenceText];
            }
        }
        
        //Enable the introduction clicks on words and images, if it is intro mode
        if ([introductions objectForKey:chapterTitle]) {
            if (([[performedActions objectAtIndex:SELECTION] isEqualToString:@"word"] &&
                [englishSentenceText isEqualToString:[performedActions objectAtIndex:INPUT]])) {
                //Destroy the timer to avoid playing the previous sound
                //[timer invalidate];
                //timer = nil;
                
                [self playAudioFile:[NSString stringWithFormat:@"%@%@.m4a",englishSentenceText,languageString]];
                
                //Logging added by James for Word Audio
                [[ServerCommunicationController sharedManager] logComputerPlayAudio: @"Play Word" : languageString :[NSString stringWithFormat:@"%@%@.m4a",englishSentenceText,languageString]  :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu",(unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
                
                [self highlightObject:englishSentenceText:1.5];
                //Bypass the image-tap steps which are found after each word-tap step on the metadata
                // since they are not needed anymore
                currentIntroStep+=1;
                [self performSelector:@selector(loadIntroStep) withObject:nil afterDelay:2];
            }
        }
        //Vocabulary introduction mode
        else if ([vocabularies objectForKey:chapterTitle] && [currentPageId rangeOfString:@"Intro"].location != NSNotFound) {
            //If the user clicked on the correct word or image
            if (([[performedActions objectAtIndex:SELECTION] isEqualToString:@"word"] &&
                 [englishSentenceText isEqualToString:[performedActions objectAtIndex:INPUT]]) ||
                ([[performedActions objectAtIndex:SELECTION] isEqualToString:@"image"] &&
                 [imageAtPoint isEqualToString:[performedActions objectAtIndex:INPUT]])) {
                    //[timer invalidate];
                    //timer = nil;
                    
                    //If the user clicked on a word
                    if ([[performedActions objectAtIndex:SELECTION] isEqualToString:@"word"] && [[performedActions objectAtIndex:INPUT] isEqualToString:englishSentenceText] && !sameWordClicked && (currentSentence == sentenceIDNum)) {
                        
                        sameWordClicked = true;
                        if ([chapterTitle isEqualToString:@"The Contest"] || [chapterTitle isEqualToString:@"Why We Breathe"]) {
                            [self playAudioFile:vocabAudio];
                        }
                        else {
                            [self playAudioFile:currentAudio];
                        }
                        
                        //Logging added by James for Word Audio
                        [[ServerCommunicationController sharedManager] logComputerPlayAudio: @"Play Word" : languageString :[NSString stringWithFormat:@"%@%@.m4a",sentenceText,languageString]  :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu",(unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
                        
                        [self highlightObject:[[Translation translationImages] objectForKey:englishSentenceText]:1.5];
                        
                        currentSentence++;
                        [self performSelector:@selector(colorSentencesUponNext) withObject:nil afterDelay:4];
                        
                        currentVocabStep++;
                        [self performSelector:@selector(loadVocabStep) withObject:nil afterDelay:4];
                }
            }
        }
        else if([[Translation translationWords] objectForKey:englishSentenceText]) {
            // Since the name of the carbon dioxide file is carbonDioxide, its name is hard-coded
            if([englishSentenceText isEqualToString:@"carbon dioxide"]) {
                englishSentenceText = @"carbonDioxide";
            }
            
            if (language_condition == BILINGUAL && ([chapterTitle isEqualToString:@"The Contest"] || [chapterTitle isEqualToString:@"Why We Breathe"])) {
                //Play word audio Sp
                [self playAudioInSequence:[NSString stringWithFormat:@"%@%@.m4a",englishSentenceText,@"S"]:[NSString stringWithFormat:@"%@%@.m4a",englishSentenceText,@"E"]];
                
                //Logging added by James for Word Audio
                [[ServerCommunicationController sharedManager] logComputerPlayAudio: @"Play Word" : @"S" :[NSString stringWithFormat:@"%@%@.m4a",englishSentenceText,languageString]  :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu",(unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
            }
            else if (language_condition == BILINGUAL) {
                //Play word audio Sp
                [self playAudioInSequence:[NSString stringWithFormat:@"%@%@.m4a",englishSentenceText,@"E"]:[NSString stringWithFormat:@"%@%@.m4a",englishSentenceText,@"S"]];
                
                //Logging added by James for Word Audio
                [[ServerCommunicationController sharedManager] logComputerPlayAudio: @"Play Word" : @"S" :[NSString stringWithFormat:@"%@%@.m4a",englishSentenceText,languageString]  :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu",(unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
            }
            else {
                //Play En audio twice
                [self playAudioInSequence:[NSString stringWithFormat:@"%@%@.m4a",englishSentenceText,@"E"]:[NSString stringWithFormat:@"%@%@.m4a",englishSentenceText,@"E"]];
                
                //Logging added by James for Word Audio
                [[ServerCommunicationController sharedManager] logComputerPlayAudio: @"Play Word" : @"E" :[NSString stringWithFormat:@"%@%@.m4a",englishSentenceText,languageString]  :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu",(unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
            }
            
            // Revert the carbon dioxide name for highlighting
            if([englishSentenceText isEqualToString:@"carbonDioxide"]) {
                englishSentenceText = @"carbon dioxide";
            }
            
            [self highlightObject:[[Translation translationImages] objectForKey:englishSentenceText]:1.5];
        }
    }
}

/*
 * Long press gesture. Either tap or long press can be used for definitions.
 */
-(IBAction)longPressGesturePerformed:(UILongPressGestureRecognizer *)recognizer {
    //This is the location of the point in the parent UIView, not in the UIWebView.
    //These two coordinate systems may be different.
    /*CGPoint location = [recognizer locationInView:self.view];
     
     NSString* requestImageAtPoint = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).id", location.x, location.y];
     
     NSString* imageAtPoint = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPoint];*/
    
    //NSLog(@"imageAtPoint: %@", imageAtPoint);
}


/*
 * Swipe gesture. Only recognizes a downwards two finger swipe. Used to skip the current step
 * by performing it automatically according to the solution.
 */
-(IBAction)swipeGesturePerformed:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"Swiper no swiping!");
    
    // Emergency swipe to bypass the vocab intros
    if ([vocabularies objectForKey:chapterTitle] && [currentPageId rangeOfString:@"Intro"].location != NSNotFound) {
        [_audioPlayer stop];
        [self loadNextPage];
    }
    
    //Perform steps only if they exist for the sentence and have not been completed
    else if (numSteps > 0 && !stepsComplete && allowInteractions) {
        
        //Logging Added by James for Emergency Swipe
        [[ServerCommunicationController sharedManager] logUserEmergencyNext:@"Emergency Swipe" :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu",(unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
        
        //Get steps for current sentence
        NSMutableArray* currSolSteps = [PMSolution getStepsForSentence:currentSentence];
        
        //Get current step to be completed
        ActionStep* currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        //Current step is check and involves moving an object to a location
        if ([[currSolStep stepType] isEqualToString:@"check"]) {
            //Get information for check step type
            NSString* objectId = [currSolStep object1Id];
            NSString* action = [currSolStep action];
            NSString* locationId = [currSolStep locationId];
            
            //Get hotspot location of object
            Hotspot* hotspot = [model getHotspotforObjectWithActionAndRole:objectId :action :@"subject"];
            CGPoint hotspotLocation = [self getHotspotLocationOnImage:hotspot];
            
            //Get location that hotspot should be inside
            Location* location = [model getLocationWithId:locationId];
            
            //Calculate the x,y coordinates and the width and height in pixels from %
            float locationX = [location.originX floatValue] / 100.0 * [bookView frame].size.width;
            float locationY = [location.originY floatValue] / 100.0 * [bookView frame].size.height;
            float locationWidth = [location.width floatValue] / 100.0 * [bookView frame].size.width;
            float locationHeight = [location.height floatValue] / 100.0 * [bookView frame].size.height;
            
            //Calculate the center point of the location
            float midX = locationX + (locationWidth / 2);
            float midY = locationY + (locationHeight / 2);
            CGPoint midpoint = CGPointMake(midX, midY);
            
            //Move the object to the center of the location
            [self moveObject:objectId :midpoint :hotspotLocation :false : @"None"];
            
            //Clear highlighting
            NSString *clearHighlighting = [NSString stringWithFormat:@"clearAllHighlighted()"];
            [bookView stringByEvaluatingJavaScriptFromString:clearHighlighting];
            
            //Object should now be in the correct location, so the step can be incremented
            if([self isHotspotInsideLocation]) {
                [self incrementCurrentStep];
            }
        }
        //Current step is checkAndSwap and involves swapping an image
        else if ([[currSolStep stepType] isEqualToString:@"checkAndSwap"]) {
            [self swapObjectImage];
            [self incrementCurrentStep];
        }
        //Current step is either group, ungroup, disappear, or transference
        else {
            //Get the interaction to be performed
            PossibleInteraction* interaction = [self getCorrectInteraction];
            
            //Perform the interaction and increment the step
            [self checkSolutionForInteraction:interaction];
        }
    }
}

/*
 * Pinch gesture. Used to ungroup two images from each other.
 */
-(IBAction)pinchGesturePerformed:(UIPinchGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];
    
    if(recognizer.state == UIGestureRecognizerStateBegan && allowInteractions && pinchToUngroup) {
        pinching = TRUE;
        
        NSString* imageAtPoint = [self getObjectAtPoint:location ofType:@"manipulationObject"];
        
        //if it's an image that can be moved, then start moving it.
        if(imageAtPoint != nil && !stepsComplete) {
            separatingObjectId = imageAtPoint;
        }
    }
    else if(recognizer.state == UIGestureRecognizerStateEnded) {
        //Get pairs of other objects grouped with this object.
        NSArray* itemPairArray = [self getObjectsGroupedWithObject:separatingObjectId];
        
        if (itemPairArray != nil) {
            NSMutableArray* possibleInteractions = [[NSMutableArray alloc] init];
        
            for(NSString* pairStr in itemPairArray) {
                //Create an array that will hold all the items in this group
                NSMutableArray* groupedItemsArray = [[NSMutableArray alloc] init];
                
                //Separate the objects in this pair and add them to our array of all items in this group.
                [groupedItemsArray addObjectsFromArray:[pairStr componentsSeparatedByString:@", "]];
                
                //Only allow the correct subject and object to ungroup if necessary
                BOOL allowSubjectToUngroup = false;
                BOOL allowObjectToUngroup = false;
                
                for(NSString* obj in groupedItemsArray) {
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
                    PossibleInteraction* interaction = [[PossibleInteraction alloc] initWithInteractionType:UNGROUP];
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
                
                if(!menuExpanded)
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
-(IBAction)panGesturePerformed:(UIPanGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];

    //This should work with requireGestureRecognizerToFail:pinchRecognizer but it doesn't currently.
    if(!pinching && allowInteractions) {
        BOOL useProximity = NO;
        
        if(recognizer.state == UIGestureRecognizerStateBegan) {
            //NSLog(@"pan gesture began at location: (%f, %f)", location.x, location.y);
            panning = TRUE;
            
            //Get the object at that point if it's a manipulation object.
            NSString* imageAtPoint = [self getObjectAtPoint:location ofType:@"manipulationObject"];
            //NSLog(@"location pressed: (%f, %f)", location.x, location.y);
            
            if ([introductions objectForKey:chapterTitle]) {
                stepsComplete = false;
            }
            
            //if it's an image that can be moved, then start moving it.
            if(imageAtPoint != nil && !stepsComplete) {
                
                //add logging: began object move ?
                
                movingObject = TRUE;
                movingObjectId = imageAtPoint;
                
                //Calculate offset between top-left corner of image and the point clicked.
                delta = [self calculateDeltaForMovingObjectAtPoint:location];
                
                //Record the starting location of the object when it is selected
                startLocation = CGPointMake(location.x - delta.x, location.y - delta.y);
            }
        }
        else if(recognizer.state == UIGestureRecognizerStateEnded) {
            //NSLog(@"pan gesture ended at location (%f, %f)", location.x, location.y);
            panning = FALSE;
            
            //if moving object, move object to final position.
            if(movingObject) {
                
                [self moveObject:movingObjectId :location :delta :true: @"Ended"];
                
                if (numSteps > 0) {
                    //Get steps for current sentence
                    NSMutableArray* currSolSteps = [PMSolution getStepsForSentence:currentSentence];
                    
                    //Get current step to be completed
                    ActionStep* currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
                    
                    if ([[currSolStep stepType] isEqualToString:@"check"]) {
                        //Check if object is in the correct location
                        if([self isHotspotInsideLocation]) {
                            if ([introductions objectForKey:chapterTitle]) {
                                /*Check to see if an object is at a certain location or is grouped with another object e.g. farmergetIncorralArea or farmerleadcow. These strings come from the solution steps */
                                if([[performedActions objectAtIndex:INPUT] isEqualToString:[NSString stringWithFormat:@"%@%@%@",[currSolStep object1Id], [currSolStep action], [currSolStep locationId]]]
                                   || [[performedActions objectAtIndex:INPUT] isEqualToString:[NSString stringWithFormat:@"%@%@%@",[currSolStep object1Id], [currSolStep action], [currSolStep object2Id]]]) {
                                        // Destroy the timer to avoid playing the previous sound
                                        //[timer invalidate];
                                        //timer = nil;
                                        currentIntroStep++;
                                        [self loadIntroStep];
                                }
                            }
                            
                            [self incrementCurrentStep];
                            //moving an object to a location (barn, hay loft etc)
                            
                            //gets hotspot id for logging
                            NSString* locationId = [currSolStep locationId];
                            //Logging added by James for User Move Object to object
                            [[ServerCommunicationController sharedManager] logUserMoveObject:movingObjectId  : locationId :startLocation.x :startLocation.y :location.x :location.y :@"Move to Hotspot" :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat: @"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
                            
                            //Logging added by James for user Move Object to Hotspot Correct
                            [[ServerCommunicationController sharedManager] logComputerVerification: @"Move to Hotspot":true : movingObjectId:bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
                        }
                        else {
                            //gets hotspot id for logging
                            NSString* locationId = [currSolStep locationId];
                            //Logging added by James for User Move Object to object
                            [[ServerCommunicationController sharedManager] logUserMoveObject:movingObjectId  : locationId:startLocation.x :startLocation.y :location.x :location.y :@"Move to Hotspot" :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat: @"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
                            
                            //Logging added by James for user Move Object to Hotspot Incorrect
                            [[ServerCommunicationController sharedManager] logComputerVerification:@"Move to Hotspot" :false : movingObjectId:bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
                            
                            [self playErrorNoise];
                            
                            if (allowSnapback) {
                                //Snap the object back to its original location
                                [self moveObject:movingObjectId :startLocation :CGPointMake(0, 0) :false : @"None"];
                                //if incorrect location reset object to beginning of gesture
                                
                            }
                        }
                    }
                    else {
                        //Check if the object is overlapping anything
                        NSArray* overlappingWith = [self getObjectsOverlappingWithObject:movingObjectId];
                        
                        //Get possible interactions only if the object is overlapping something
                        if (overlappingWith != nil) {
                            if (condition == HOTSPOT) {
                                useProximity = YES;
                            }
                            
                            //resets allRelationship arrray
                            if([allRelationships count]) {
                                [allRelationships removeAllObjects];
                            }
                            
                            //If the object was dropped, check if it's overlapping with any other objects that it could interact with.
                            NSMutableArray* possibleInteractions = [self getPossibleInteractions:useProximity];
                            
                            //No possible interactions were found
                            if ([possibleInteractions count] == 0) {
                                //Logging added by James for User Move Object to object
                                [[ServerCommunicationController sharedManager] logUserMoveObject:movingObjectId  : collisionObjectId:startLocation.x :startLocation.y :location.x :location.y :@"Move to Object" :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat: @"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
                                
                                //Logging added by James for Verifying Move Object to object
                                [[ServerCommunicationController sharedManager] logComputerVerification: @"Move to Object":false : movingObjectId:bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
                                
                                [self playErrorNoise];
                                
                                if (allowSnapback) {
                                    //Snap the object back to its original location
                                    [self moveObject:movingObjectId :startLocation :CGPointMake(0, 0) :false : @"None"];
                                    //wrong because two objects cant interact with each other reset object
                                }
                            }
                            //If only 1 possible interaction was found, go ahead and perform that interaction if it's correct.
                            if ([possibleInteractions count] == 1) {
                                PossibleInteraction* interaction = [possibleInteractions objectAtIndex:0];
                                
                                //Logging added by James for User Move Object to object
                                [[ServerCommunicationController sharedManager] logUserMoveObject:movingObjectId  : collisionObjectId:startLocation.x :startLocation.y :location.x :location.y :@"Move to Object" :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat: @"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
                                
                                //checks solution and accomplishes action trace
                                [self checkSolutionForInteraction:interaction];
                            }
                            //If more than 1 was found, prompt the user to disambiguate.
                            else if ([possibleInteractions count] > 1) {
                                //The chapter title hard-coded for now
                                if ([introductions objectForKey:chapterTitle] &&
                                    [[performedActions objectAtIndex:INPUT] isEqualToString:
                                     [NSString stringWithFormat:@"%@%@%@",[currSolStep object1Id], [currSolStep action], [currSolStep object2Id]]]) {
                                    // Destroy the timer to avoid playing the previous sound
                                    //[timer invalidate];
                                    //timer = nil;
                                    currentIntroStep++;
                                    [self loadIntroStep];
                                }
                                
                                //First rank the interactions based on location to story.
                                [self rankPossibleInteractions:possibleInteractions];
                                
                                //Logging added by James for User Move Object to object
                                [[ServerCommunicationController sharedManager] logUserMoveObject:movingObjectId  : collisionObjectId:startLocation.x :startLocation.y :location.x :location.y :@"Move to Object" :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat: @"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
                                
                                //Logging added by James for Move Object to object Verification
                                [[ServerCommunicationController sharedManager] logComputerVerification: @"Move to Object":true : movingObjectId:bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
                                
                                //Populate the menu data source and expand the menu.
                                [self populateMenuDataSource:possibleInteractions:allRelationships];
                                
                                if(!menuExpanded)
                                {
                                    //Logging added by James for Move Object to object Verification
                                        [[ServerCommunicationController sharedManager] logComputerVerification: @"Display Menu":true : movingObjectId:bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
                                    
                                    [self expandMenu];
                                
                                }
                                
                                
                            }
                        }
                        //Not overlapping any object
                        else {
                            [self playErrorNoise];
                            
                            if (allowSnapback) {
                                //Snap the object back to its original location
                                [self moveObject:movingObjectId :startLocation :CGPointMake(0, 0) :false : @"None"];
                            }
                        }
                    }
                }
                
                if (!menuExpanded) {
                    //No longer moving object
                    movingObject = FALSE;
                    movingObjectId = nil;
                }
                
                //Clear any remaining highlighting.
                //TODO: it's probably better to move the highlighting outside of the move function, that way we don't have to clear the highlighting at a point when highlighting shouldn't happen anyway.
                //TODO: Double check to see whether we've already done this or not.
                NSString *clearHighlighting = [NSString stringWithFormat:@"clearAllHighlighted()"];
                [bookView stringByEvaluatingJavaScriptFromString:clearHighlighting];
            }
        }
        //If we're in the middle of moving the object, just call the JS to move it.
        else if(movingObject)  {
            [self moveObject:movingObjectId :location :delta :true : @"isMoving"];
            
            //If we're overlapping with another object, then we need to figure out which hotspots are currently active and highlight those hotspots.
            //When moving the object, we may have the JS return a list of all the objects that are currently grouped together so that we can process all of them.
            NSArray* overlappingWith = [self getObjectsOverlappingWithObject:movingObjectId];
            
            if (overlappingWith != nil) {
                for(NSString* objId in overlappingWith) {
                    //we have the list of objects it's overlapping with, we now have to figure out which hotspots to draw.
                    NSMutableArray* hotspots = [model getHotspotsForObject:objId OverlappingWithObject:movingObjectId];
                    
                    //Since hotspots are filtered based on relevant relationships between objects, only highlight objects that have at least one hotspot returned by the model.
                    if([hotspots count] > 0) {
                        NSString* highlight = [NSString stringWithFormat:@"highlightObject(%@)", objId];
                        [bookView stringByEvaluatingJavaScriptFromString:highlight];
                    }
                }
                
                if (condition == HOTSPOT) {
                    //resets allRelationship arrray
                    if([allRelationships count])
                    {
                        [allRelationships removeAllObjects];
                    }
                    NSMutableArray* possibleInteractions = [self getPossibleInteractions:useProximity];
                    
                    //Keep a list of all hotspots so that we know which ones should be drawn as green and which should be drawn as red. At the end, draw all hotspots together.
                    NSMutableArray* redHotspots = [[NSMutableArray alloc] init];
                    NSMutableArray* greenHotspots = [[NSMutableArray alloc] init];
                    
                    for(PossibleInteraction* interaction in possibleInteractions) {
                        for(Connection* connection in [interaction connections]) {
                            if([connection interactionType] != NONE) {
                                NSMutableArray* hotspots  = [[connection hotspots] mutableCopy];
                                //NSLog(@"Hotspot Obj1: %@ Hotspot Obj2: %@", [connection objects][0], [connection objects][1]);
                                
                                //Figure out whether two hotspots are close enough together to currently be grouped. If so, draw the hotspots with green. Otherwise, draw them with red.
                                BOOL areWithinProximity = [self hotspotsWithinGroupingProximity:[hotspots objectAtIndex:0] :[hotspots objectAtIndex:1]];
                                
                                //NSLog(@"are within proximity:%u:", areWithinProximity);
                                //NSLog(@"within proximity %hhd %u", areWithinProximity, [interaction interactionType]);
                                
                                //TODO: Make sure this is correct.
                                if(areWithinProximity || ([interaction interactionType] == TRANSFERANDGROUP) || ([interaction interactionType] == TRANSFERANDDISAPPEAR)) {
                                    [greenHotspots addObjectsFromArray:hotspots];
                                }
                                else {
                                    [redHotspots addObjectsFromArray:hotspots];
                                }
                            }
                        }
                    }
                    
                    //NSLog(@"number of hotspots:%d %d", [redHotspots count], [greenHotspots count]);
                    //Draw red hotspots first, then green ones.
                    [self drawHotspots:redHotspots :@"red"];
                    [self drawHotspots:greenHotspots :@"green"];
                }
            }
        }
    }
}

/*
 * Gets the necessary information from the JS for this particular image id and creates a
 * MenuItemImage out of that information. If FLIP is TRUE, the image will be horizontally 
 * flipped. If the image src isn't found, returns nil. Otherwise, returned the MenuItemImage 
 * that was created.
 */
-(MenuItemImage*) createMenuItemForImage:(NSString*) objId :(BOOL)FLIP {
    //NSLog(@"creating menu item for image with object id: %@", objId);
    
    NSString* requestImageSrc = [NSString stringWithFormat:@"%@.src", objId];
    NSString* imageSrc = [bookView stringByEvaluatingJavaScriptFromString:requestImageSrc];
    
    //NSLog(@"createMenuItemForImage imagesrc %@", imageSrc);

    NSRange range = [imageSrc rangeOfString:@"file:"];
    NSString* imagePath = [imageSrc substringFromIndex:range.location + range.length + 1];
    
    imagePath = [imagePath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    //NSLog(@"createMenuItemForImage imagesrc %@", imagePath);

    UIImage* rawImage = [[UIImage alloc] initWithContentsOfFile:imagePath];
    UIImage* image = [UIImage alloc];
    
    //Horizontally flip the image
    if (FLIP) {
        image = [UIImage imageWithCGImage:rawImage.CGImage scale:rawImage.scale orientation:UIImageOrientationUpMirrored];
    }
    //Use the unflipped image
    else {
        image = rawImage;
    }
    
    //added by James to extract image name
    [image setAccessibilityIdentifier:objId];
    
    if(image == nil)
        NSLog(@"image is nil");
    else {
        MenuItemImage *itemImage = [[MenuItemImage alloc] initWithImage:image];
        
        //Get the z-index of the image.
        NSString* requestZIndex = [NSString stringWithFormat:@"%@.style.zIndex", objId];
        NSString* zIndex = [bookView stringByEvaluatingJavaScriptFromString:requestZIndex];
        
        //NSLog(@"z-index of %@: %@", objId, zIndex);
        
        [itemImage setZPosition:[zIndex floatValue]];
        
        //Get the location of the image, so we can position it appropriately.
        NSString* requestPositionX = [NSString stringWithFormat:@"%@.offsetLeft", objId];
        NSString* requestPositionY = [NSString stringWithFormat:@"%@.offsetTop", objId];
        
        NSString* positionX = [bookView stringByEvaluatingJavaScriptFromString:requestPositionX];
        NSString* positionY = [bookView stringByEvaluatingJavaScriptFromString:requestPositionY];
        
        //Get the size of the image, so that it can be scaled appropriately.
        NSString* requestWidth = [NSString stringWithFormat:@"%@.offsetWidth", objId];
        NSString* requestHeight = [NSString stringWithFormat:@"%@.offsetHeight", objId];
        
        NSString* width = [bookView stringByEvaluatingJavaScriptFromString:requestWidth];
        NSString* height = [bookView stringByEvaluatingJavaScriptFromString:requestHeight];
        
        //NSLog(@"location of %@: (%@, %@) with size: %@ x %@, zindex:%@", objId, positionX, positionY, width, height, zIndex);
        
        [itemImage setBoundingBoxImage:CGRectMake([positionX floatValue], [positionY floatValue],
                                                  [width floatValue], [height floatValue])];
        
        return itemImage;
    }
    
    return nil;
}

/*
 * This function takes in a possible interaction and calculates the layout of the images after the interaction occurs.
 * It then adds the result to the menuDataSource in order to display each menu item appropriately.
 * NOTE: For the moment this code could be used to create both the ungroup and all other interactions...lets see if this is the case after this code actually simulates the end result. If it is, the code should be simplified to use the same function.
 * NOTE: This should be pushed to the JS so that all actual positioning information is in one place and we're not duplicating code that's in the JS in the objC as well. For now...we'll just do it here.
 * Come back to this...
 */
-(void) simulatePossibleInteractionForMenuItem:(PossibleInteraction*)interaction : (Relationship*) relationship{
    NSMutableDictionary* images = [[NSMutableDictionary alloc] init];
    
    //Populate the mutable dictionary of menuItemImages.
    for(Connection* connection in [interaction connections]) {
        NSArray* objectIds = [connection objects];
        
        //Get all the necessary information of the UIImages.
        for (int i = 0; i < [objectIds count]; i++) {
            NSString* objId = objectIds[i];
            
            if ([images objectForKey:objId] == nil) {
                MenuItemImage *itemImage;
                
                //Horizontally flip the image of the subject performing a transfer and disappear interaction to make it look like it is giving an object to the receiver.
                if ([interaction interactionType] == TRANSFERANDDISAPPEAR
                    && [connection interactionType] == UNGROUP
                    && objId == [[connection objects] objectAtIndex:0]) {
                    itemImage = [self createMenuItemForImage:objId :TRUE];
                }
                //Otherwise, leave the image unflipped
                else {
                    itemImage = [self createMenuItemForImage:objId :FALSE];
                }
                
                //NSLog(@"obj id:%@", objId);
                
                if(itemImage != nil)
                    [images setObject:itemImage forKey:objId];
            }
        }
        
        //If the objects are already connected to other objects, create images for those as well, if they haven't already been created
        for (NSString* objectId in objectIds) {
            NSMutableArray *connectedObject = [currentGroupings objectForKey:objectId];
            
            for (int i = 0; connectedObject && [connection interactionType] != UNGROUP && i < [connectedObject count]; i++) {
                if ([images objectForKey:connectedObject[i]] == nil) {
                    MenuItemImage *itemImage = [self createMenuItemForImage:connectedObject[i] :FALSE];
                    
                    if(itemImage != nil) {
                        [images setObject:itemImage forKey:connectedObject[i]];
                    }
                }
            }
        }
    }
    
    //NSLog(@"images count:%d", [images count]);
    
    //Perform the changes to the connections.
    for(Connection* connection in [interaction connections]) {
        NSArray* objectIds = [connection objects];
        NSArray* hotspots = [connection hotspots];
        
        //Update the locations of the UIImages based on the type of interaction with the simulated location.
        //get the object Ids for this particular menuItem.
        NSString* obj1 = [objectIds objectAtIndex:0]; //get object 1
        NSString* obj2 = [objectIds objectAtIndex:1]; //get object 2
        NSString* connectedObject;
        Hotspot* connectedHotspot1;
        Hotspot* connectedHotspot2;
        
        if([connection interactionType] == UNGROUP) {
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
        else if([connection interactionType] == GROUP || [connection interactionType] == DISAPPEAR) {
            //NSLog(@"simulating grouping between %@ and %@", obj1, obj2);
            
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
                        CGPoint hotspotLoc = [self getHotspotLocation:ht];
                        
                        NSString *isHotspotConnectedMovingObject = [NSString stringWithFormat:@"objectGroupedAtHotspot(%@, %f, %f)", connectedObject, hotspotLoc.x, hotspotLoc.y];
                        NSString* isHotspotConnectedMovingObjectString = [bookView stringByEvaluatingJavaScriptFromString:isHotspotConnectedMovingObject];
                        
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
    
    NSMutableArray* imagesArray = [[images allValues] mutableCopy];
    
    //Calculate the bounding box for the group of objects being passed to the menu item.
    CGRect boundingBox = [self getBoundingBoxOfImages:imagesArray];
    
    [menuDataSource addMenuItem:interaction : relationship:imagesArray :boundingBox];
}

/*
 * This function gets passed in an array of MenuItemImages and calculates the bounding box for the entire array.
 */
-(CGRect) getBoundingBoxOfImages:(NSMutableArray*)images {
    CGRect boundingBox = CGRectMake(0, 0, 0, 0);
    
    if([images count] > 0) {
        float leftMostPoint = ((MenuItemImage*)[images objectAtIndex:0]).boundingBoxImage.origin.x;
        float topMostPoint = ((MenuItemImage*)[images objectAtIndex:0]).boundingBoxImage.origin.y;
        float rightMostPoint = ((MenuItemImage*)[images objectAtIndex:0]).boundingBoxImage.origin.x + ((MenuItemImage*)[images objectAtIndex:0]).boundingBoxImage.size.width;
        float bottomMostPoint = ((MenuItemImage*)[images objectAtIndex:0]).boundingBoxImage.origin.y + ((MenuItemImage*)[images objectAtIndex:0]).boundingBoxImage.size.height;
        
        for(MenuItemImage* image in images) {
            if(image.boundingBoxImage.origin.x < leftMostPoint)
                leftMostPoint = image.boundingBoxImage.origin.x;
            if(image.boundingBoxImage.origin.y < topMostPoint)
                topMostPoint = image.boundingBoxImage.origin.y;
            if(image.boundingBoxImage.origin.x + image.boundingBoxImage.size.width > rightMostPoint)
                rightMostPoint = image.boundingBoxImage.origin.x + image.boundingBoxImage.size.width;
            if(image.boundingBoxImage.origin.y + image.boundingBoxImage.size.height > bottomMostPoint)
                bottomMostPoint = image.boundingBoxImage.origin.y + image.boundingBoxImage.size.height;
        }
        
        boundingBox = CGRectMake(leftMostPoint, topMostPoint, rightMostPoint - leftMostPoint,
                                 bottomMostPoint - topMostPoint);
    }
    
    return boundingBox;
}

-(void)simulateGrouping:(NSString*)obj1 :(Hotspot*)hotspot1 :(NSString*)obj2 :(Hotspot*)hotspot2 :(NSMutableDictionary*)images {
    CGPoint hotspot1Loc = [self calculateHotspotLocationBasedOnBoundingBox:hotspot1
                                                                          :[[images objectForKey:obj1] boundingBoxImage]];
    CGPoint hotspot2Loc = [self calculateHotspotLocationBasedOnBoundingBox:hotspot2
                                                                          :[[images objectForKey:obj2] boundingBoxImage]];
    
    //Figure out the distance necessary for obj1 to travel such that hotspot1 and hotspot2 are in the same location.
    float deltaX = hotspot2Loc.x - hotspot1Loc.x; //get the delta between the 2 hotspots.
    float deltaY = hotspot2Loc.y - hotspot1Loc.y;
    
    //Get the location of the top left corner of obj1.
    //MenuItemImage* obj1Image = [images objectAtIndex:0];
    MenuItemImage* obj1Image = [images objectForKey:obj1];
    CGFloat positionX = [obj1Image boundingBoxImage].origin.x;
    CGFloat positionY = [obj1Image boundingBoxImage].origin.y;
    
    //set the location of the top left corner of the image being moved to its current top left corner + delta.
    CGFloat obj1FinalPosX = positionX + deltaX;
    CGFloat obj1FinalPosY = positionY + deltaY;
    
    //NSLog(@"Object1: %@ Object2: %@ X: %f Y: %f %f %f", obj1, obj2, obj1FinalPosX, obj1FinalPosY, [obj1Image boundingBoxImage].size.width, [obj1Image boundingBoxImage].size.height);
    
    [obj1Image setBoundingBoxImage:CGRectMake(obj1FinalPosX, obj1FinalPosY, [obj1Image boundingBoxImage].size.width,
                                              [obj1Image boundingBoxImage].size.height)];
}

-(void)simulateGroupingMultipleObjects:(NSMutableArray*)objs :(NSMutableArray*)hotspots :(NSMutableDictionary*)images {
    CGPoint hotspot1Loc = [self calculateHotspotLocationBasedOnBoundingBox:hotspots[0]
                                                                          :[[images objectForKey:objs[0]] boundingBoxImage]];
    CGPoint hotspot2Loc = [self calculateHotspotLocationBasedOnBoundingBox:hotspots[1]
                                                                          :[[images objectForKey:objs[1]] boundingBoxImage]];
    
    //NSLog(@"simulateGroupingMultipleObjects %@", objs);
    
    //Figure out the distance necessary for obj1 to travel such that hotspot1 and hotspot2 are in the same location.
    float deltaX = hotspot2Loc.x - hotspot1Loc.x; //get the delta between the 2 hotspots.
    float deltaY = hotspot2Loc.y - hotspot1Loc.y;
    
    //Get the location of the top left corner of obj1.
    MenuItemImage* obj1Image = [images objectForKey:objs[0]];
    CGFloat positionX = [obj1Image boundingBoxImage].origin.x;
    CGFloat positionY = [obj1Image boundingBoxImage].origin.y;
    
    //set the location of the top left corner of the image being moved to its current top left corner + delta.
    CGFloat obj1FinalPosX = positionX + deltaX;
    CGFloat obj1FinalPosY = positionY + deltaY;
    
    //NSLog(@"Object1: %@ Object2: %@ X: %f Y: %f %f %f", obj1, obj2, obj1FinalPosX, obj1FinalPosY, [obj1Image boundingBoxImage].size.width, [obj1Image boundingBoxImage].size.height);
    
    [obj1Image setBoundingBoxImage:CGRectMake(obj1FinalPosX, obj1FinalPosY, [obj1Image boundingBoxImage].size.width,
                                              [obj1Image boundingBoxImage].size.height)];
   
    NSMutableArray* connectedObjects = [currentGroupings valueForKey:objs[0]];
    
    if (connectedObjects && [connectedObjects count] > 0) {
        //Get locations of all objects connected to object1
        MenuItemImage* obj3Image = [images objectForKey:connectedObjects[0]];
        CGFloat connectedObjectPositionX = [obj3Image boundingBoxImage].origin.x;
        CGFloat connectedObjectPositionY = [obj3Image boundingBoxImage].origin.y;
    
        //find the final position of the connect objects
        CGFloat obj3FinalPosX = connectedObjectPositionX + deltaX;
        CGFloat obj3FinalPosY = connectedObjectPositionY + deltaY;
    
        [obj3Image setBoundingBoxImage:CGRectMake(obj3FinalPosX, obj3FinalPosY, [obj3Image boundingBoxImage].size.width,
                                                [obj3Image boundingBoxImage].size.height)];
    }
}

-(void)simulateUngrouping:(NSString*)obj1 :(NSString*)obj2 :(NSMutableDictionary*)images :(float)GAP {
    //See if one object is contained in the other.
    NSString* requestObj1ContainedInObj2 = [NSString stringWithFormat:@"objectContainedInObject(%@, %@)", obj1, obj2];
    NSString* obj1ContainedInObj2 = [bookView stringByEvaluatingJavaScriptFromString:requestObj1ContainedInObj2];
    
    NSString* requestObj2ContainedInObj1 = [NSString stringWithFormat:@"objectContainedInObject(%@, %@)", obj2, obj1];
    NSString* obj2ContainedInObj1 = [bookView stringByEvaluatingJavaScriptFromString:requestObj2ContainedInObj1];
    
    CGFloat obj1FinalPosX, obj2FinalPosX; //For ungrouping we only ever change X.
    
    //Get the locations and widths of objects 1 and 2.
    MenuItemImage* obj1Image = [images objectForKey:obj1];
    MenuItemImage* obj2Image = [images objectForKey:obj2];
    
    CGFloat obj1PositionX = [obj1Image boundingBoxImage].origin.x;
    CGFloat obj2PositionX = [obj2Image boundingBoxImage].origin.x;
    
    CGFloat obj1Width = [obj1Image boundingBoxImage].size.width;
    CGFloat obj2Width = [obj2Image boundingBoxImage].size.width;
    
    if([obj1ContainedInObj2 isEqualToString:@"true"]) {
        obj1FinalPosX = obj2PositionX - obj2Width - GAP;
        obj2FinalPosX = obj2PositionX;
        //NSLog(@"if %@ is contained in %@", obj1, obj2);
    }
    else if([obj2ContainedInObj1 isEqualToString:@"true"]) {
        obj1FinalPosX = obj1PositionX;
        obj2FinalPosX = obj1PositionX + obj1Width + GAP;
        //NSLog(@"else %@ is contained in %@", obj2, obj1);
    }
    
    //Otherwise, partially overlapping or connected on the edges.
    else {
        //Figure out which is the leftmost object. Unlike the animate ungrouping function, we're just going to move the leftmost object to the left so that it's not overlapping with the other one unless it's a TRANSFERANDDISAPPEAR interaction
        if(obj1PositionX < obj2PositionX) {
            obj1FinalPosX = obj2PositionX - obj2Width - GAP;
            
            //A negative GAP indicates a TRANSFERANDDISAPPEAR interaction, so we want to adjust the rightmost object so that it is slightly overlapping the right side of the leftmost object
            if (GAP < 0) {
                obj2FinalPosX = obj1FinalPosX + obj1Width + GAP;
            }
            //A positive GAP indicates a normal ungrouping interaction, so the leftmost object was moved to the left. If it's still overlapping, we move the rightmost object to the left of the leftmost object. Otherwise, we leave it alone.
            else {
                //Objects are overlapping
                if (obj2PositionX < obj1FinalPosX + obj1Width) {
                    obj2FinalPosX = obj1PositionX - obj1Width - GAP;
                }
                //Objects are not overlapping
                else {
                    obj2FinalPosX = obj2PositionX;
                }
            }
            
            //NSLog(@"%@ is the leftmost object", obj1);
            //NSLog(@"%@ width: %f", obj1, obj1Width);
        }
        else {
            obj1FinalPosX = obj1PositionX;
            obj2FinalPosX = obj1PositionX + obj1Width + GAP;
            //NSLog(@"%@ is the leftmost object", obj2);
        }
    }
    
    [obj1Image setBoundingBoxImage:CGRectMake(obj1FinalPosX, [obj1Image boundingBoxImage].origin.y,
                                              [obj1Image boundingBoxImage].size.width,
                                              [obj1Image boundingBoxImage].size.height)];
    [obj2Image setBoundingBoxImage:CGRectMake(obj2FinalPosX, [obj2Image boundingBoxImage].origin.y,
                                              [obj2Image boundingBoxImage].size.width,
                                              [obj2Image boundingBoxImage].size.height)];
}

/*
 * This checks the PossibleInteractin passed in to figure out what type of interaction it is,
 * extracts the necessary information and calls the appropriate function to perform the interaction.
 * TODO: Come back to this.
 */
-(void) performInteraction:(PossibleInteraction*)interaction {
    for(Connection* connection in [interaction connections]) {
        NSArray* objectIds = [connection objects]; //get the object Ids for this particular menuItem.
        NSArray* hotspots = [connection hotspots]; //Array of hotspot objects.
        
        //Get object 1 and object 2
        NSString* obj1 = [objectIds objectAtIndex:0];
        NSString* obj2 = [objectIds objectAtIndex:1];
        
        if([connection interactionType] == UNGROUP) {
            //NSLog(@"ungrouping items");

            [self ungroupObjects:obj1 :obj2]; //ungroup objects
            //logging done in ungroupObjects
           
        }
        else if([connection interactionType] == GROUP) {
            //NSLog(@"grouping items");
            
            //Get hotspots.
            Hotspot* hotspot1 = [hotspots objectAtIndex:0];
            Hotspot* hotspot2 = [hotspots objectAtIndex:1];
            
            CGPoint hotspot1Loc = [self getHotspotLocation:hotspot1];
            CGPoint hotspot2Loc = [self getHotspotLocation:hotspot2];
            
            [self groupObjects:obj1 :hotspot1Loc :obj2 :hotspot2Loc]; //group objects
            //logging done in groupObjects
            
        }
        else if([connection interactionType] == DISAPPEAR) {
            //NSLog(@"causing object to disappear");
            
            [self consumeAndReplenishSupply:obj2]; //make object disappear
            //logging done in consumeAndReplenishSupply
        }
    }
}

/*
 * Returns true if the specified subject from the solutions is part of a group with the
 * specified object. Otherwise, returns false.
 */
-(BOOL)isSubject:(NSString*)subject ContainedInGroupWithObject:(NSString*)object {
    //Get pairs of other objects grouped with this object
    NSArray* itemPairArray = [self getObjectsGroupedWithObject:object];
    
    if (itemPairArray != nil) {
        //Create an array that will hold all the items in this group
        NSMutableArray* groupedItemsArray = [[NSMutableArray alloc] init];
        
        for(NSString* pairStr in itemPairArray) {
            //Separate the objects in this pair and add them to our array of all items in this group.
            [groupedItemsArray addObjectsFromArray:[pairStr componentsSeparatedByString:@", "]];
        }
        
        //Checks if one of the grouped objects is the subject
        for(NSString* obj in groupedItemsArray) {
            if([obj isEqualToString:subject])
                return true;
        }
    }
    
    return false;
}

/*
 * Returns true if the correct object is selected as the subject based on the solutions
 * for group step types. Otherwise, it returns false.
 */
-(BOOL) checkSolutionForSubject:(NSString*)subject {
    //Check solution only if it exists for the sentence
    if (numSteps > 0 && !stepsComplete) {
        //Get steps for current sentence
        NSMutableArray* currSolSteps = [PMSolution getStepsForSentence:currentSentence];
        
        //Get current step to be completed
        ActionStep* currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:@"transferAndGroup"]) {
            //Get next sentence step
            ActionStep* nextSolStep = [currSolSteps objectAtIndex:currentStep];
            
            //Correct subject for a transfer and group step is the obj1 of the next transfer and group step
            NSString* correctSubject = [nextSolStep object1Id];
            
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
            NSString* correctSubject = [currSolStep object1Id];
            
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
-(BOOL) checkSolutionForObject:(NSString*)overlappingObject {
    //Check solution only if it exists for the sentence
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray* currSolSteps = [PMSolution getStepsForSentence:currentSentence];
        
        //Get current step to be completed
        ActionStep* currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        //If current step requires transference and group, the correct object depends on the format used.
        //transferAndGroup steps may be written in two different ways:
        //   1. obj2Id is the same for both steps, so correct object is object1 of next step
        //      (ex. farmer give bucket; cat accept bucket)
        //   2. obj2Id of first step is obj1Id of second step, so correct object is object2 of next step
        //      (ex. farmer putDown hay; hay getIn cart)
        if ([[currSolStep stepType] isEqualToString:@"transferAndGroup"]) {
            //Get next step
            ActionStep* nextSolStep = [currSolSteps objectAtIndex:currentStep];

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
            ActionStep* nextSolStep = [currSolSteps objectAtIndex:currentStep];
            
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
-(void) moveObjectForSolution {
    //Check solution only if it exists for the sentence
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray* currSolSteps = [PMSolution getStepsForSentence:currentSentence];
        
        //Get current step to be completed
        ActionStep* currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:@"move"]) {
            //Get information for move step type
            NSString* object1Id = [currSolStep object1Id];
            NSString* action = [currSolStep action];
            NSString* object2Id = [currSolStep object2Id];
            NSString* waypointId = [currSolStep waypointId];
            
            //Move either requires object1 to move to object2 (which creates a group interaction) or it requires object1 to move to a waypoint
            if (object2Id != nil) {
                PossibleInteraction* correctInteraction = [self getCorrectInteraction];
                [self performInteraction:correctInteraction]; //performs solution step
                
                //gets location of second object and passes into xml
               /* NSArray* hotspots = [connection hotspots]; //Array of hotspot objects.
                Hotspot* hotspot2 = [hotspots objectAtIndex:1];
                CGPoint hotspot2Loc = [self getHotspotLocation:hotspot2];*/
                
            }
            else if (waypointId != nil) {
                //Get position of hotspot in pixels based on the object image size
                Hotspot* hotspot = [model getHotspotforObjectWithActionAndRole:object1Id :action :@"subject"];
                CGPoint hotspotLocation = [self getHotspotLocationOnImage:hotspot];
                
                //Get position of waypoint in pixels based on the background size
                Waypoint* waypoint = [model getWaypointWithId:waypointId];
                CGPoint waypointLocation = [self getWaypointLocation:waypoint];
                
                //Move the object
                [self moveObject:object1Id :waypointLocation :hotspotLocation :false: waypointId];
                
                //Clear highlighting
                NSString *clearHighlighting = [NSString stringWithFormat:@"clearAllHighlighted()"];
                [bookView stringByEvaluatingJavaScriptFromString:clearHighlighting];
            }
        }
    }
}

/*
 * Calls the JS function to swap an object's image with its alternate one
 */
//for logging record alternate source image
-(void) swapObjectImage {
    //Check solution only if it exists for the sentence
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray* currSolSteps = [PMSolution getStepsForSentence:currentSentence];
        
        //Get current step to be completed
        ActionStep* currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:@"swapImage"] || [[currSolStep stepType] isEqualToString:@"checkAndSwap"]) {
            //Get information for swapImage step type
            NSString* object1Id = [currSolStep object1Id];
            NSString* action = [currSolStep action];
            
            //Get alternate image
            AlternateImage* altImage = [model getAlternateImageWithAction:action];
            
            //Get alternate image information
            NSString* altSrc = [altImage alternateSrc];
            NSString* width = [altImage width];
            CGPoint location = [altImage location];
            
            //Swap images using alternative src
            NSString* swapImages = [NSString stringWithFormat:@"swapImageSrc('%@', '%@', '%@', %f, %f)", object1Id, altSrc, width, location.x, location.y];
            [bookView stringByEvaluatingJavaScriptFromString:swapImages];
            
            //Logging added by James for Swap Images
            [[ServerCommunicationController sharedManager] logComputerSwapImages : object1Id : altSrc: @"Swap Image" : bookTitle : chapterTitle : currentPage : [NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] : [NSString stringWithFormat:@"%lu" , (unsigned long)currentStep]];
        }
    }
}

/*
 * Returns true if the hotspot of an object (for a check step type) is inside the correct location.
 * Otherwise, returns false.
 */
-(BOOL) isHotspotInsideLocation {
    //Check solution only if it exists for the sentence
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray* currSolSteps = [PMSolution getStepsForSentence:currentSentence];
        
        //Get current step to be completed
        ActionStep* currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:@"check"]) {
            //Get information for check step type
            NSString* objectId = [currSolStep object1Id];
            NSString* action = [currSolStep action];
            NSString* locationId = [currSolStep locationId];
            
            //Get hotspot location of correct subject
            Hotspot* hotspot = [model getHotspotforObjectWithActionAndRole:objectId :action :@"subject"];
            CGPoint hotspotLocation = [self getHotspotLocation:hotspot];
            
            //Get location that hotspot should be inside
            Location* location = [model getLocationWithId:locationId];
            
            //Calculate the x,y coordinates and the width and height in pixels from %
            float locationX = [location.originX floatValue] / 100.0 * [bookView frame].size.width;
            float locationY = [location.originY floatValue] / 100.0 * [bookView frame].size.height;
            float locationWidth = [location.width floatValue] / 100.0 * [bookView frame].size.width;
            float locationHeight = [location.height floatValue] / 100.0 * [bookView frame].size.height;
            
            //Check if hotspot is inside location
            if ((hotspotLocation.x < locationX + locationWidth) && (hotspotLocation.x > locationX)
                && (hotspotLocation.y < locationY + locationHeight) && (hotspotLocation.y > locationY)) {
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
-(NSString*) getObjectAtPoint:(CGPoint) location ofType:(NSString*)class {
    //Temporarily hide the overlay canvas to get the object we need
    NSString* hideCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.display = 'none';", @"'overlay'"];
    [bookView stringByEvaluatingJavaScriptFromString:hideCanvas];
    
    //Retrieve the elements at this location and see if it's an element that is moveable.
    NSString* requestImageAtPoint = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).id", location.x, location.y];
    
    NSString* requestImageAtPointClass = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).className", location.x, location.y];
    
    NSString* imageAtPoint = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPoint];
    NSString* imageAtPointClass = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointClass];
    
    //Bring the canvas back to where it should be.
    //NSString* showCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.zIndex = 100;", @"'overlay'"];
    NSString* showCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.display = 'block';", @"'overlay'"];
    [bookView stringByEvaluatingJavaScriptFromString:showCanvas];
    
    //Check if the object has the correct class, or if no class was specified before returning
    if([imageAtPointClass isEqualToString:class] || class == nil) {
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
 * Gets the current solution step of ActionStep type and converts it to a PossibleInteraction
 * object
 */
-(PossibleInteraction*) getCorrectInteraction {
    PossibleInteraction* correctInteraction;
    
    //Check solution only if it exists for the sentence
    if (numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray* currSolSteps = [PMSolution getStepsForSentence:currentSentence];
        
        //Get current step to be completed
        ActionStep* currSolStep = [currSolSteps objectAtIndex:currentStep - 1];
        
        //If step type involves transference, we must manually create the PossibleInteraction object.
        //Otherwise, it can be directly converted.
        if ([[currSolStep stepType] isEqualToString:@"transferAndGroup"] || [[currSolStep stepType] isEqualToString:@"transferAndDisappear"]) {
            correctInteraction = [[PossibleInteraction alloc] init];
            
            //Get step information for current step
            NSString* currObj1Id = [currSolStep object1Id];
            NSString* currObj2Id = [currSolStep object2Id];
            NSString* currAction = [currSolStep action];
            
            //Objects involved in group setup for current step
            NSArray* currObjects = [[NSArray alloc] initWithObjects:currObj1Id, currObj2Id, nil];
            
            //Get hotspots for both objects associated with action for current step
            Hotspot* currHotspot1 = [model getHotspotforObjectWithActionAndRole:currObj1Id :currAction :@"subject"];
            Hotspot* currHotspot2 = [model getHotspotforObjectWithActionAndRole:currObj2Id :currAction :@"object"];
            NSArray* currHotspotsForInteraction = [[NSArray alloc]initWithObjects:currHotspot1, currHotspot2, nil];
            
            [correctInteraction addConnection:UNGROUP :currObjects :currHotspotsForInteraction];
            
            //Get next step to be completed
            ActionStep* nextSolStep = [currSolSteps objectAtIndex:currentStep];
            
            //Get step information for next step
            NSString* nextObj1Id = [nextSolStep object1Id];
            NSString* nextObj2Id = [nextSolStep object2Id];
            NSString* nextAction = [nextSolStep action];
            
            //Objects involved in group setup for next step
            NSArray* nextObjects = [[NSArray alloc] initWithObjects:nextObj1Id, nextObj2Id, nil];
            
            //Get hotspots for both objects associated with action for next step
            Hotspot* nextHotspot1 = [model getHotspotforObjectWithActionAndRole:nextObj1Id :nextAction :@"subject"];
            Hotspot* nextHotspot2 = [model getHotspotforObjectWithActionAndRole:nextObj2Id :nextAction :@"object"];
            NSArray* nextHotspotsForInteraction = [[NSArray alloc]initWithObjects:nextHotspot1, nextHotspot2, nil];
            
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
-(void) checkSolutionForInteraction:(PossibleInteraction*)interaction {
    //Get correct interaction to compare
    PossibleInteraction* correctInteraction = [self getCorrectInteraction];
    
    //Check if selected interaction is correct
    if ([interaction isEqual:correctInteraction]) {
        //Logging added by James for Correct Interaction
        [[ServerCommunicationController sharedManager] logComputerVerification:@"Perform Interaction":true : movingObjectId:bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
        
        [self performInteraction:interaction];
        
        if ([introductions objectForKey:chapterTitle]) {
            currentIntroStep++;
            [self loadIntroStep];
        }
        
        [self incrementCurrentStep];
        
        //Transference counts as two steps, so we must increment again
        if ([interaction interactionType] == TRANSFERANDGROUP || [interaction interactionType] == TRANSFERANDDISAPPEAR) {
            [self incrementCurrentStep];
        }
    }
    else {
        if ([introductions objectForKey:chapterTitle]) {
            if (language_condition == ENGLISH || currentIntroStep > STEPS_TO_SWITCH_LANGUAGES_EMBRACE)
            {
                [self playAudioFile:@"tryAgainE.m4a"];
                
                //Logging added by James for Try Again
                [[ServerCommunicationController sharedManager] logComputerPlayAudio: @"Try Again" : @"E" : @"tryAgainE.m4a" :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu",(unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
            }
            else
            {
                [self playAudioFile:@"tryAgainS.m4a"];
                
                //Logging added by James for Try Again
                [[ServerCommunicationController sharedManager] logComputerPlayAudio: @"Try Again" : @"S" : @"tryAgainS.m4a" :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu",(unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
            }
        }
        else {
            //Logging added by James for Incorrect Interaction
            [[ServerCommunicationController sharedManager] logComputerVerification:@"Perform Interaction":false : movingObjectId:bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
            
            [self playErrorNoise]; //play noise if interaction is incorrect
        }
        
        if ([interaction interactionType] != UNGROUP && allowSnapback) {
            //Snap the object back to its original location
            [self moveObject:movingObjectId :startLocation :CGPointMake(0, 0) :false:@"None"];
            
            //move logging to moveObject
            //Logging added by James for Object Reset Location
            [[ServerCommunicationController sharedManager] logComputerResetObject : movingObjectId  :startLocation.x :startLocation.y : startLocation.x : startLocation.y : @"Reset" : bookTitle : chapterTitle : currentPage :[NSString stringWithFormat: @"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
        }
    }
    
    //Clear any remaining highlighting.
    NSString *clearHighlighting = [NSString stringWithFormat:@"clearAllHighlighted()"];
    [bookView stringByEvaluatingJavaScriptFromString:clearHighlighting];
}

/*
 * Checks if one object is contained inside another object and returns the contained object
 */
-(NSString*) findContainedObject:(NSArray*)objects {
    NSString *containedObject = @"";
    
    //Check the first object
    NSString *isContained = [NSString stringWithFormat:@"objectContainedInObject(%@,%@)", objects[0], objects[1]];
    NSString *isContainedString = [bookView stringByEvaluatingJavaScriptFromString:isContained];
    
    //First object in array is contained in second object in array
    if([isContainedString isEqualToString:@"true"]) {
        containedObject = objects[0];
    }
    //Check the second object
    else if([isContainedString isEqualToString:@"false"]) {
        isContained = [NSString stringWithFormat:@"objectContainedInObject(%@,%@)", objects[1], objects[0]];
        isContainedString = [bookView stringByEvaluatingJavaScriptFromString:isContained];
    }
    
    //Second object in array is contained in first object in array
    if([containedObject isEqualToString:@""] && [isContainedString isEqualToString:@"true"]) {
        containedObject = objects[1];
    }
    
    //NSLog(@"first obj:%@, second obj:%@, containedObject:%@", array[0], array[1], containedObject);
    
    return containedObject;
}

-(NSMutableArray*) getPossibleInteractions:(BOOL)useProximity {
    //Get pairs of other objects grouped with this object
    NSArray* itemPairArray = [self getObjectsGroupedWithObject:movingObjectId];
    
    if (itemPairArray != nil) {
        NSMutableArray* groupings = [[NSMutableArray alloc] init];
        NSMutableSet* uniqueObjIds = [[NSMutableSet alloc] init];
        
        for(NSString* pairStr in itemPairArray) {
            //Separate the objects in this pair.
            NSArray *itemPair = [pairStr componentsSeparatedByString:@", "];
            
            for(NSString* item in itemPair) {
                [uniqueObjIds addObject:item];
            }
        }
        
        //Get the possible interactions for all objects in the group
        for(NSString* obj in uniqueObjIds) {
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
 * available, as well as instances in which one hotspots is already taken up by a grouping but the other is not. The function
 * checks both group and disappear interaction types.
 
 * TODO: Figure out how to return all possible interactions robustly. Currently if the student drags the hay and the farmer (when grouped) by the hay, then the interaction will not be identified.
 * TODO: Lots of duplication here. Need to fix the above and then pull out duplicate code.
 
 * We also want to double check and make sure that neither of the objects is already grouped with another object at the relevant hotspots. If it is, that means we may need to transfer the grouping, instead of creating a new grouping.
 * If it is, we have to make sure that the hotspots for the two objects are within a certain radius of each other for the grouping to occur.
 * If they are, we want to go ahead and group the objects.
 
 * TODO: Instead of just checking based on the object that's being moved, we should get all objects the movingObject is connected to. From there, we can either get all the possible interactions for each object, or we can figure out which one is the "subject" and use that one. For example, when the farmer is holding the hay, the farmer is the one doing the action, so the farmer would be the subject. Does this work in all instances? If so, we may also want to think about looking at the object's role when coming up with transfer interactions as well.
 */
-(NSMutableArray*) getPossibleInteractions:(BOOL)useProximity forObject:(NSString*)obj{
    NSMutableArray* groupings = [[NSMutableArray alloc] init];
    
    //Get the objects that this object is overlapping with
    NSArray* overlappingWith = [self getObjectsOverlappingWithObject:obj];
    BOOL ObjectIDUsed = false;
    NSString *tempCollisionObject = nil;
    
    if (overlappingWith != nil) {
        for(NSString* objId in overlappingWith) {
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
                
                NSMutableArray* hotspots = [model getHotspotsForObject:objId OverlappingWithObject:obj];
                NSMutableArray* movingObjectHotspots = [model getHotspotsForObject:obj OverlappingWithObject:objId];
                
                //Compare hotspots of the two objects. 
                for(Hotspot* hotspot in hotspots) {
                    for(Hotspot* movingObjectHotspot in movingObjectHotspots) {
                        //Need to calculate exact pixel locations of both hotspots and then make sure they're within a specific distance of each other.
                        CGPoint movingObjectHotspotLoc = [self getHotspotLocation:movingObjectHotspot];
                        CGPoint hotspotLoc = [self getHotspotLocation:hotspot];
                        
                        //Check to see if either of these hotspots are currently connected to another objects.
                        NSString *isHotspotConnectedMovingObject = [NSString stringWithFormat:@"objectGroupedAtHotspot(%@, %f, %f)", obj, movingObjectHotspotLoc.x, movingObjectHotspotLoc.y];
                        NSString* isHotspotConnectedMovingObjectString  = [bookView stringByEvaluatingJavaScriptFromString:isHotspotConnectedMovingObject];
                        
                        NSString *isHotspotConnectedObject = [NSString stringWithFormat:@"objectGroupedAtHotspot(%@, %f, %f)", objId, hotspotLoc.x, hotspotLoc.y];
                        NSString* isHotspotConnectedObjectString  = [bookView stringByEvaluatingJavaScriptFromString:isHotspotConnectedObject];
                        
                        bool rolesMatch = [[hotspot role] isEqualToString:[movingObjectHotspot role]];
                        bool actionsMatch = [[hotspot action] isEqualToString:[movingObjectHotspot action]];
                        
                        //Make sure the two hotspots have the same action. It may also be necessary to ensure that the roles do not match. Also make sure neither of the hotspots are connected to another object.
                        if(actionsMatch && [isHotspotConnectedMovingObjectString isEqualToString:@""]
                           && [isHotspotConnectedObjectString isEqualToString:@""] && !rolesMatch) {
                            //Although the matching hotspots are free, transference may still be possible if one of the objects is connected at a different hotspot that must be ungrouped first.
                            NSString* objTransferringObj = [self getObjectPerformingTransference:obj :objId :@"object"];
                            NSString* objTransferringObjId = [self getObjectPerformingTransference:objId :obj :@"subject"];
                            
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
                                Relationship* relationshipBetweenObjects = [model getRelationshipForObjectsForAction:obj :objId :[movingObjectHotspot action]];
                                lastRelationship = relationshipBetweenObjects;
                                [allRelationships addObject:lastRelationship];
                                
                                //Check to make sure that the two hotspots are in close proximity to each other.
                                if((useProximity && [self hotspotsWithinGroupingProximity:movingObjectHotspot :hotspot])
                                   || !useProximity) {
                                    //Create necessary arrays for the interaction.
                                    NSArray* objects;
                                    NSArray* hotspotsForInteraction;
                                    
                                    if([[relationshipBetweenObjects actionType] isEqualToString:@"group"]) {
                                        //Check if the moving object is already grouped with another
                                        //object
                                        NSArray* groupedObjects = [self getObjectsGroupedWithObject:movingObjectId];
                                        
                                        //Object is already grouped to another object
                                        if (groupedObjects != nil) {
                                            //Check if this new grouping meets constraints before
                                            //creating the PossibleInteraction object
                                            if ([self doesObjectMeetComboConstraints:movingObjectId :movingObjectHotspot]) {
                                                PossibleInteraction* interaction = [[PossibleInteraction alloc] initWithInteractionType:GROUP];
                                                
                                                objects = [[NSArray alloc] initWithObjects:obj, objId, nil];
                                                hotspotsForInteraction = [[NSArray alloc] initWithObjects:movingObjectHotspot, hotspot, nil];
                                                
                                                [interaction addConnection:GROUP :objects :hotspotsForInteraction];
                                                [groupings addObject:interaction];
                                            }
                                        }
                                        //Object is not grouped to another object
                                        else {
                                            PossibleInteraction* interaction = [[PossibleInteraction alloc] initWithInteractionType:GROUP];
                                            
                                            objects = [[NSArray alloc] initWithObjects:obj, objId, nil];
                                            hotspotsForInteraction = [[NSArray alloc] initWithObjects:movingObjectHotspot, hotspot, nil];
                                            
                                            [interaction addConnection:GROUP :objects :hotspotsForInteraction];
                                            [groupings addObject:interaction];
                                        }
                                    }
                                    else if([[relationshipBetweenObjects actionType] isEqualToString:@"disappear"]) {
                                        PossibleInteraction* interaction = [[PossibleInteraction alloc] initWithInteractionType:DISAPPEAR];
                                        
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
                        else if(actionsMatch && ![isHotspotConnectedMovingObjectString isEqualToString:@""]
                                && [isHotspotConnectedObjectString isEqualToString:@""] && !rolesMatch) {
                            [groupings addObjectsFromArray:[self getPossibleTransferInteractionsforObjects:obj :isHotspotConnectedMovingObjectString :objId :movingObjectHotspot :hotspot]];
                        }
                        else if(actionsMatch && [isHotspotConnectedMovingObjectString isEqualToString:@""]
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
-(NSString*) getObjectPerformingTransference:(NSString*)transferredObj :(NSString*)receiverObj :(NSString*)role {
    NSMutableArray* transferredObjHotspots = [model getHotspotsForObjectId:transferredObj];

    NSString* senderObj; //Object that is performing the transference
    
    //Check to see if the transferred object is already connected at a different hotspot that needs to be ungrouped for transference to occur
    for(Hotspot* transferredObjHotspot in transferredObjHotspots) {
        //Check if it is currently grouped with another object using the specified role
        if ([[transferredObjHotspot role] isEqualToString:role]) {
            CGPoint transferredObjHotspotLoc = [self getHotspotLocation:transferredObjHotspot];
            
            //Get the object that the transferred object is connected to at this hotspot
            NSString* isHotspotConnected = [NSString stringWithFormat:@"objectGroupedAtHotspot(%@, %f, %f)", transferredObj, transferredObjHotspotLoc.x, transferredObjHotspotLoc.y];
            NSString* isHotspotConnectedString = [bookView stringByEvaluatingJavaScriptFromString:isHotspotConnected];
            
            if (![isHotspotConnectedString isEqualToString:@""]) {
                //If this object has multiple hotspots in common with the recipient object, then it must be capable of performing transference (i.e. an animate object)
                NSMutableArray* otherObjHotspots = [model getHotspotsForObject:isHotspotConnectedString OverlappingWithObject:receiverObj];
                
                if ([otherObjHotspots count] > 1) {
                    senderObj = isHotspotConnectedString;
                }
            }
        }
    }
    
    return senderObj;
}

-(NSMutableArray*) getPossibleTransferInteractionsforObjects:(NSString*)objConnected :(NSString*)objConnectedTo :(NSString*)currentUnconnectedObj :(Hotspot*)objConnectedHotspot :(Hotspot*)currentUnconnectedObjHotspot{
    NSMutableArray* groupings = [[NSMutableArray alloc] init];
    
    //Get the hotspots for the grouped objects
    NSMutableArray* hotspotsForObjConnected = [model getHotspotsForObject:objConnected OverlappingWithObject :objConnectedTo];
    NSMutableArray* hotspotsForObjConnectedTo = [model getHotspotsForObject:objConnectedTo OverlappingWithObject :objConnected];
    
    //Compare their hotspots to determine where the two objects are currently grouped
    for(Hotspot* hotspot1 in hotspotsForObjConnectedTo) {
        for(Hotspot* hotspot2 in hotspotsForObjConnected) {
            //Need to calculate exact pixel location of one of the hotspots and then make sure it is connected to the other object at that location
            CGPoint hotspot1Loc = [self getHotspotLocation:hotspot1];
            
            NSString *isObjConnectedToHotspotConnected = [NSString stringWithFormat:@"objectGroupedAtHotspot(%@, %f, %f)", objConnectedTo, hotspot1Loc.x, hotspot1Loc.y];
            NSString* isConnectedObjHotspotConnectedString  = [bookView stringByEvaluatingJavaScriptFromString:isObjConnectedToHotspotConnected];
            
            //Make sure the two hotspots have the same action and make sure the roles do not match (there are only two possibilities right now: subject and object). Also make sure the hotspots are connected to each other. If all is well, these objects can be ungrouped.
            bool rolesMatch = [[hotspot1 role] isEqualToString:[hotspot2 role]];
            bool actionsMatch = [[hotspot1 action] isEqualToString:[hotspot2 action]];
            
            if(actionsMatch && ![isConnectedObjHotspotConnectedString isEqualToString:@""] && !rolesMatch) {
                PossibleInteraction* interaction = [[PossibleInteraction alloc] init];
                
                //Add the connection to ungroup first.
                NSArray* ungroupObjects;
                NSArray* hotspotsForUngrouping;
                
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
                NSArray* transferObjects;
                NSArray* hotspotsForTransfer;
                
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
                Relationship* relationshipBetweenObjects = [model getRelationshipForObjectsForAction:objConnected :currentUnconnectedObj :[objConnectedHotspot action]];
                lastRelationship = relationshipBetweenObjects;
                [allRelationships addObject:lastRelationship];
                
                if([[relationshipBetweenObjects  actionType] isEqualToString:@"group"]) {
                    [interaction addConnection:GROUP :transferObjects :hotspotsForTransfer];
                    [interaction setInteractionType:TRANSFERANDGROUP];
                    
                    [groupings addObject:interaction];
                }
                else if([[relationshipBetweenObjects actionType] isEqualToString:@"disappear"]) {
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
-(NSArray*) getObjectsGroupedWithObject:(NSString*)object {
    NSArray* itemPairArray; //contains grouped objects split by pairs
    
    //Get other objects grouped with this object.
    NSString* requestGroupedImages = [NSString stringWithFormat:@"getGroupedObjectsString(%@)", object];
    
    /*
     * Say the cart is connected to the tractor and the tractor is "connected" to the farmer,
     * then groupedImages will be a string in the following format: "cart, tractor; tractor, farmer"
     * if the only thing you currently have connected to the hay is the farmer, then you'll get
     * a string back that is: "hay, farmer" or "farmer, hay"
     */
    NSString* groupedImages = [bookView stringByEvaluatingJavaScriptFromString:requestGroupedImages];
    
    //If there is an array, split the array based on pairs.
    if(![groupedImages isEqualToString:@""]) {
        itemPairArray = [groupedImages componentsSeparatedByString:@"; "];
    }
    
    return itemPairArray;
}

/*
 * Returns an array containing objects that are overlapping with the object specified
 */
-(NSArray*) getObjectsOverlappingWithObject:(NSString*)object {
    NSArray* overlappingWith; //contains overlapping objects
    
    //Check if object is overlapping anything
    NSString* overlappingObjects = [NSString stringWithFormat:@"checkObjectOverlapString(%@)", movingObjectId];
    NSString* overlapArrayString = [bookView stringByEvaluatingJavaScriptFromString:overlappingObjects];
    
    if(![overlapArrayString isEqualToString:@""]) {
        overlappingWith = [overlapArrayString componentsSeparatedByString:@", "];
    }
    
    return overlappingWith;
}

/*
 * Checks an object's array of hotspots to determine if one is connected to a specific object and returns that hotspot
 */
-(Hotspot*) findConnectedHotspot:(NSMutableArray*)movingObjectHotspots : (NSString*)objConnectedTo {
    Hotspot* connectedHotspot = NULL;
    
    for(Hotspot* movingObjectHotspot in movingObjectHotspots) {
        //Get the hotspot location
        CGPoint movingObjectHotspotLoc = [self getHotspotLocation:movingObjectHotspot];
        
        //Check if this hotspot is currently in use
        NSString* isHotspotConnectedMovingObject = [NSString stringWithFormat:@"objectGroupedAtHotspot(%@, %f, %f)", movingObjectId, movingObjectHotspotLoc.x, movingObjectHotspotLoc.y];
        NSString* isHotspotConnectedMovingObjectString  = [bookView stringByEvaluatingJavaScriptFromString:isHotspotConnectedMovingObject];
        
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
-(BOOL) doesObjectMeetComboConstraints:(NSString*)connectedObject :(Hotspot*)potentialConnection {
    //Records whether the potential and connected hotspots are present in the list
    //of combo constraints for an object contained in a group with connectedObject.
    //If they both are, then this object does not meet the combo constraints.
    BOOL potentialConstraint = FALSE;
    BOOL connectedConstraint = FALSE;
    
    //Get pairs of other objects grouped with this object.
    NSArray* itemPairArray = [self getObjectsGroupedWithObject:connectedObject];
    
    if (itemPairArray != nil) {
        for(NSString* pairStr in itemPairArray) {
            //Create an array that will hold all the items in this group
            NSMutableArray* groupedItemsArray = [[NSMutableArray alloc] init];
            
            //Separate the objects in this pair and add them to our array of all items in this group.
            [groupedItemsArray addObjectsFromArray:[pairStr componentsSeparatedByString:@", "]];
            
            for (NSString* object in groupedItemsArray) {
                //Get the combo constraints for the object
                NSMutableArray* objectComboConstraints = [model getComboConstraintsForObjectId:object];
                
                //The object has combo constraints
                if ([objectComboConstraints count] > 0) {
                    //Get the hotspots for the object
                    NSMutableArray* objectHotspots = [model getHotspotsForObjectId:object];
                    
                    for (Hotspot* hotspot in objectHotspots) {
                        //Get the hotspot location
                        CGPoint hotspotLocation = [self getHotspotLocation:hotspot];
                        
                        //Check if this hotspot is currently connected to another object
                        NSString *isHotspotConnected = [NSString stringWithFormat:@"objectGroupedAtHotspot(%@, %f, %f)", object, hotspotLocation.x, hotspotLocation.y];
                        NSString* isHotspotConnectedString = [bookView stringByEvaluatingJavaScriptFromString:isHotspotConnected];
                        
                        //Hotspot is connected to another object
                        if (![isHotspotConnectedString isEqualToString:@""]) {
                            for (ComboConstraint* comboConstraint in objectComboConstraints) {
                                //Get the list of actions for the combo constraint
                                NSMutableArray* comboActions = [comboConstraint comboActions];
                                
                                for (NSString* comboAction in comboActions) {
                                    //Get the hotspot associated with the action, assuming the
                                    //role as subject. Also get the hotspot location.
                                    Hotspot* comboHotspot = [model getHotspotforObjectWithActionAndRole:[comboConstraint objId] :comboAction :@"subject"];
                                    CGPoint comboHotspotLocation;
                                    
                                    if (comboHotspot != nil) {
                                        comboHotspotLocation = [self getHotspotLocation:comboHotspot];
                                    }
                                    else {
                                        //If no hotspot was found assuming the role as subject,
                                        //then the role must be object.
                                        comboHotspot = [model getHotspotforObjectWithActionAndRole:[comboConstraint objId] :comboAction :@"object"];
                                        comboHotspotLocation = [self getHotspotLocation:comboHotspot];
                                    }
                                    
                                    //Check if the potential hotspot matches an action on the list
                                    if ([[potentialConnection action] isEqualToString:comboAction]) {
                                        potentialConstraint = TRUE;
                                    }
                                    
                                    //Check if the connected hotspot matches an action on the list
                                    //based on its name or location
                                    if ([[hotspot action] isEqualToString:comboAction]
                                        || CGPointEqualToPoint(hotspotLocation, comboHotspotLocation)) {
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
-(void) rankPossibleInteractions:(NSMutableArray*)possibleInteractions {
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
-(BOOL) hotspotsWithinGroupingProximity:(Hotspot *)hotspot1 :(Hotspot *)hotspot2 {
    CGPoint hotspot1Loc = [self getHotspotLocation:hotspot1];
    CGPoint hotspot2Loc = [self getHotspotLocation:hotspot2];
    
    float deltaX = fabsf(hotspot1Loc.x - hotspot2Loc.x);
    float deltaY = fabsf(hotspot1Loc.y - hotspot2Loc.y);
    
    if(deltaX <= groupingProximity && deltaY <= groupingProximity)
        return true;
    
    return false;
}

/*
 * Calculates the delta pixel change for the object that is being moved
 * and changes the lcoation from relative % to pixels if necessary.
 */
-(CGPoint) calculateDeltaForMovingObjectAtPoint:(CGPoint) location {
    CGPoint change;
    
    //Calculate offset between top-left corner of image and the point clicked.
    NSString* requestImageAtPointTop = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).offsetTop", location.x, location.y];
    NSString* requestImageAtPointLeft = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).offsetLeft", location.x, location.y];
    
    NSString* imageAtPointTop = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointTop];
    NSString* imageAtPointLeft = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointLeft];
    
    //Check to see if the locations returned are in percentages. If they are, change them to pixel values based on the size of the screen.
    NSRange rangePercentTop = [imageAtPointTop rangeOfString:@"%"];
    NSRange rangePercentLeft = [imageAtPointLeft rangeOfString:@"%"];
    
    if(rangePercentTop.location != NSNotFound)
        change.y = location.y - ([imageAtPointTop floatValue] / 100.0 * [bookView frame].size.height);
    else
        change.y = location.y - [imageAtPointTop floatValue];
    
    if(rangePercentLeft.location != NSNotFound)
        change.x = location.x - ([imageAtPointLeft floatValue] / 100.0 * [bookView frame].size.width);
    else
        change.x = location.x - [imageAtPointLeft floatValue];
    
    return change;
}

/*
 * Moves the object passeed in to the location given. Calculates the difference between the point touched and the
 * top-left corner of the image, which is the x,y coordate that's actually used when moving the object.
 * Also ensures that the image is not moved off screen or outside of any specified bounding boxes for the image.
 * Updates the JS Connection hotspot locations if necessary.
 */
-(void) moveObject:(NSString*) object :(CGPoint) location :(CGPoint)offset :(BOOL)updateCon : (NSString*) waypointID{
    //Change the location to accounting for the different between the point clicked and the top-left corner which is used to set the position of the image.
    CGPoint adjLocation = CGPointMake(location.x - offset.x, location.y - offset.y);
    
    //Get the width and height of the image to ensure that the image is not being moved off screen and that the image is being moved in accordance with all movement constraints.
    NSString* requestImageHeight = [NSString stringWithFormat:@"%@.height", object];
    NSString* requestImageWidth = [NSString stringWithFormat:@"%@.width", object];
    
    float imageHeight = [[bookView stringByEvaluatingJavaScriptFromString:requestImageHeight] floatValue];
    float imageWidth = [[bookView stringByEvaluatingJavaScriptFromString:requestImageWidth] floatValue];
    
    //Check to see if the image is being moved outside of any bounding boxes. At this point in time, each object only has 1 movemet constraint associated with it and the movement constraint is a bounding box. The bounding box is in relative (percentage) values to the background object.
    NSArray* constraints = [model getMovementConstraintsForObjectId:object];
    
    //NSLog(@"location of image being moved adjusted for point clicked: (%f, %f) size of image: %f x %f", adjLocation.x, adjLocation.y, imageWidth, imageHeight);
    
    //If there are movement constraints for this object.
    if([constraints count] > 0) {
        MovementConstraint* constraint = (MovementConstraint*)[constraints objectAtIndex:0];
        
        //Calculate the x,y coordinates and the width and height in pixels from %
        float boxX = [constraint.originX floatValue] / 100.0 * [bookView frame].size.width;
        float boxY = [constraint.originY floatValue] / 100.0 * [bookView frame].size.height;
        float boxWidth = [constraint.width floatValue] / 100.0 * [bookView frame].size.width;
        float boxHeight = [constraint.height floatValue] / 100.0 * [bookView frame].size.height;
        
        //NSLog(@"location of bounding box: (%f, %f) and size of bounding box: %f x %f", boxX, boxY, boxWidth, boxHeight);
        
        //Ensure that the image is not being moved outside of its bounding box.
        if(adjLocation.x + imageWidth > boxX + boxWidth)
            adjLocation.x = boxX + boxWidth - imageWidth;
        else if(adjLocation.x < boxX)
            adjLocation.x = boxX;
        if(adjLocation.y + imageHeight > boxY + boxHeight)
            adjLocation.y = boxY + boxHeight - imageHeight;
        else if(adjLocation.y < boxY)
            adjLocation.y = boxY;
    }
    
    //Check to see if the image is being moved off screen. If it is, change it so that the image cannot be moved off screen.
    if(adjLocation.x + imageWidth > [bookView frame].size.width)
        adjLocation.x = [bookView frame].size.width - imageWidth;
    else if(adjLocation.x < 0)
        adjLocation.x = 0;
    if(adjLocation.y + imageHeight > [bookView frame].size.height)
        adjLocation.y = [bookView frame].size.height - imageHeight;
    else if(adjLocation.y < 0)
        adjLocation.y = 0;
    
    //May want to add code to keep objects from moving to the location that the text is taking up on screen.
    
    //logs only if object is moved by computer action, user pan done outside of this function
    if (![waypointID isEqualToString:@"isMoving"]) {
        //Logging added by James for Automatic Computer Move Object
        [[ServerCommunicationController sharedManager] logComputerMoveObject: object : waypointID: startLocation.x : startLocation.y : adjLocation.x : adjLocation.y : @"Snap to Hotspot" : bookTitle : chapterTitle : currentPage : [NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] : [NSString stringWithFormat:@"%lu" , (unsigned long)currentStep]];
    }
    
    
    //NSLog(@"new location of %@: (%f, %f)", object, adjLocation.x, adjLocation.y);
    //Call the moveObject function in the js file.
    NSString *move = [NSString stringWithFormat:@"moveObject(%@, %f, %f, %@)", object, adjLocation.x, adjLocation.y, updateCon ? @"true" : @"false"];
    [bookView stringByEvaluatingJavaScriptFromString:move];
    
    //Update the JS Connection manually only if we have stopped moving the object
    if (updateCon && !panning) {
        //Calculate difference between start and end positions of the object
        float deltaX = adjLocation.x - startLocation.x;
        float deltaY = adjLocation.y - startLocation.y;
        
        NSString* updateConnection = [NSString stringWithFormat:@"updateConnection(%@, %f, %f)", object, deltaX, deltaY];
        [bookView stringByEvaluatingJavaScriptFromString:updateConnection];
    }
}

/*
 * Calls the JS function to group two objects at the specified hotspots.
 */
-(void) groupObjects:(NSString*)object1 :(CGPoint)object1Hotspot :(NSString*)object2 :(CGPoint)object2Hotspot {
    NSString *groupObjects = [NSString stringWithFormat:@"groupObjectsAtLoc(%@, %f, %f, %@, %f, %f)", object1, object1Hotspot.x, object1Hotspot.y, object2, object2Hotspot.x, object2Hotspot.y];
    
    //Logging added by James for Grouping Objects
    [[ServerCommunicationController sharedManager] logComputerGroupingObjects: @"Group" :object1 :object2 : groupObjects:bookTitle :chapterTitle :currentPage :[NSString stringWithFormat: @"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
    
    //maintain a list of current groupings, with the subject as a key. currently only supports two objects
    
    //get the current groupings of the objects
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
    
    [bookView stringByEvaluatingJavaScriptFromString:groupObjects];
}


/*
 * Calls the JS function to ungroup two objects.
 */
-(void) ungroupObjects:(NSString* )object1 :(NSString*) object2 {
    NSString* ungroup = [NSString stringWithFormat:@"ungroupObjects(%@, %@)", object1, object2];

    //Logging added by James for Grouping Objects
    [[ServerCommunicationController sharedManager] logComputerGroupingObjects: @"Ungroup" :object1 :object2 : ungroup:bookTitle :chapterTitle :currentPage :[NSString stringWithFormat: @"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];

    
    //get the current groupings of the objects
    NSMutableArray *object1Groups = [currentGroupings objectForKey:object1];
    NSMutableArray *object2Groups = [currentGroupings objectForKey:object2];
    
    if ([object1Groups containsObject:object2]) {
        [object1Groups removeObject:object2];
        [currentGroupings setValue:object1Groups forKey:object1];
        //add the array back
    }
    if ([object2Groups containsObject:object1]) {
        [object2Groups removeObject:object1];
        [currentGroupings setValue:object2Groups forKey:object2];
        //add the array back
    }
    
    [bookView stringByEvaluatingJavaScriptFromString:ungroup];
}

/*
 * Call JS code to cause the object to disappear, then calculate where it needs to re-appear and call the JS code to make
 * it re-appear at the new location.
 * TODO: Figure out how to deal with instances of transferGrouping + consumeAndReplenishSupply
 */
- (void) consumeAndReplenishSupply:(NSString*)disappearingObject {
    //Replenish supply of disappearing object only if allowed
    if (replenishSupply) {
        //Move the object to the "appear" hotspot location. This means finding the hotspot that specifies this information for the object, and also finding the relationship that links this object to the other object it's supposed to appear at/in.
        Hotspot* hiddenObjectHotspot = [model getHotspotforObjectWithActionAndRole:disappearingObject :@"appear" :@"subject"];
        
        //Get the relationship between this object and the other object specifying where the object should appear. Even though the call is to a general function, there should only be 1 valid relationship returned.
        NSMutableArray* relationshipsForHiddenObject = [model getRelationshipForObjectForAction:disappearingObject :@"appear"];
        
        //There should be one and only one valid relationship returned, but we'll double check anyway.
        if([relationshipsForHiddenObject count] > 0) {
            Relationship *appearRelation = [relationshipsForHiddenObject objectAtIndex:0];
            
            //Now we have to pull the hotspot at which this relationship occurs.
            //Note: We may at one point want to programmatically determine the role, but for now, we'll hard code it in.
            Hotspot* appearHotspot = [model getHotspotforObjectWithActionAndRole:[appearRelation object2Id] :@"appear" :@"object"];
            
            //Make sure that the hotspot was found and returned.
            if(appearHotspot != nil) {
                //Use the hotspot returned to calculate the location at which the disappearing object should appear.
                //The two hotspots need to match up, so we need to figure out how far away the top-left corner of the disappearing object needs to be from the location it needs to appear at.
                CGPoint appearLocation = [self getHotspotLocation:appearHotspot];
                
                //Next we have to move the apple to that location. Need the pixel location of the hotspot of the disappearing object.
                //Again, double check to make sure this isn't nil.
                if(hiddenObjectHotspot != nil) {
                    CGPoint hiddenObjectHotspotLocation = [self getHotspotLocation:hiddenObjectHotspot];
                    
                    //With both hotspot pixel values we can calcuate the distance between the top-left corner of the hidden object and it's hotspot.
                    CGPoint change = [self calculateDeltaForMovingObjectAtPoint:hiddenObjectHotspotLocation];
                    
                    //Logging added by James for Object Disappear
                    [[ServerCommunicationController sharedManager] logComputerDisappearObject: @"Appear Object":disappearingObject :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
                    
                    //Now move the object taking into account the difference in change.
                    [self moveObject:disappearingObject :appearLocation :change :false:@"None"];
                }
            }
            else {
                NSLog(@"Uhoh, couldn't find relevant hotspot location to replenish the supply of: %@", disappearingObject);
            }
        }
        //Should've been at least 1 relationship returned
        else {
            NSLog(@"Oh, noes! We didn't find a relationship for the hidden object: %@", disappearingObject);
        }
    }
    //Otherwise, just make the object disappear
    else {
        
        NSString* hideObj = [NSString stringWithFormat:@"document.getElementById('%@').style.display = 'none';", disappearingObject];
        
        //Logging added by James for Object Disappear
        [[ServerCommunicationController sharedManager] logComputerDisappearObject: @"Disappear Object":disappearingObject :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
        
        [bookView stringByEvaluatingJavaScriptFromString:hideObj];
    }
}

/*
 * Calls the JS function to draw each individual hotspot in the array provided
 * with the color specified.
 */
-(void) drawHotspots:(NSMutableArray *)hotspots :(NSString *)color{
    for(Hotspot* hotspot in hotspots) {
        CGPoint hotspotLoc = [self getHotspotLocation:hotspot];
        
        if(hotspotLoc.x != -1) {
            NSString* drawHotspot = [NSString stringWithFormat:@"drawHotspot(%f, %f, \"%@\")",
                                     hotspotLoc.x, hotspotLoc.y, color];
            [bookView stringByEvaluatingJavaScriptFromString:drawHotspot];
        }
    }
}

/*
 * Returns the pixel location of the hotspot based on the location of the image and the relative location of the
 * hotspot to that image.
 */
- (CGPoint) getHotspotLocation:(Hotspot*) hotspot {
    //Get the height and width of the image.
    NSString* requestImageHeight = [NSString stringWithFormat:@"%@.height", [hotspot objectId]];
    NSString* requestImageWidth = [NSString stringWithFormat:@"%@.width", [hotspot objectId]];
    
    float imageWidth = [[bookView stringByEvaluatingJavaScriptFromString:requestImageWidth] floatValue];
    float imageHeight = [[bookView stringByEvaluatingJavaScriptFromString:requestImageHeight] floatValue];
    
    //if image height and width are 0 then the image doesn't exist on this page.
    if(imageWidth > 0 && imageHeight > 0) {
        //Get the location of the top left corner of the image.
        NSString* requestImageTop = [NSString stringWithFormat:@"%@.offsetTop", [hotspot objectId]];
        NSString* requestImageLeft = [NSString stringWithFormat:@"%@.offsetLeft", [hotspot objectId]];
        
        NSString* imageTop = [bookView stringByEvaluatingJavaScriptFromString:requestImageTop];
        NSString* imageLeft = [bookView stringByEvaluatingJavaScriptFromString:requestImageLeft];
        
        //Check to see if the locations returned are in percentages. If they are, change them to pixel values based on the size of the screen.
        NSRange rangePercentTop = [imageTop rangeOfString:@"%"];
        NSRange rangePercentLeft = [imageLeft rangeOfString:@"%"];
        float locY, locX;
        
        if(rangePercentLeft.location != NSNotFound) {
            locX = ([imageLeft floatValue] / 100.0 * [bookView frame].size.width);
        }
        else
            locX = [imageLeft floatValue];
        
        if(rangePercentTop.location != NSNotFound) {
            locY = ([imageTop floatValue] / 100.0 * [bookView frame].size.height);
        }
        else
            locY = [imageTop floatValue];
        
        //Now we've got the location of the top left corner of the image, the size of the image and the relative position of the hotspot. Need to calculate the pixel location of the hotspot and call the js to draw the hotspot.
        float hotspotX = locX + (imageWidth * [hotspot location].x / 100.0);
        float hotspotY = locY + (imageHeight * [hotspot location].y / 100.0);
        
        return CGPointMake(hotspotX, hotspotY);
    }
    
    return CGPointMake(-1, -1);
}

/*
 * Returns the hotspot location in pixels based on the object image size
 */
-(CGPoint) getHotspotLocationOnImage:(Hotspot*) hotspot {
    //Get the width and height of the object image
    NSString* requestImageHeight = [NSString stringWithFormat:@"%@.height", [hotspot objectId]];
    NSString* requestImageWidth = [NSString stringWithFormat:@"%@.width", [hotspot objectId]];
    
    float imageHeight = [[bookView stringByEvaluatingJavaScriptFromString:requestImageHeight] floatValue];
    float imageWidth = [[bookView stringByEvaluatingJavaScriptFromString:requestImageWidth] floatValue];
    
    //Get position of hotspot in pixels based on the object image size
    CGPoint hotspotLoc = [hotspot location];
    CGFloat hotspotX = hotspotLoc.x / 100.0 * imageWidth;
    CGFloat hotspotY = hotspotLoc.y / 100.0 * imageHeight;
    CGPoint hotspotLocation = CGPointMake(hotspotX, hotspotY);
    
    return hotspotLocation;
}

/*
 * Returns the waypoint location in pixels based on the background size
 */
-(CGPoint) getWaypointLocation:(Waypoint*) waypoint {
    //Get position of waypoint in pixels based on the background size
    CGPoint waypointLoc = [waypoint location];
    CGFloat waypointX = waypointLoc.x / 100.0 * [bookView frame].size.width;
    CGFloat waypointY = waypointLoc.y / 100.0 * [bookView frame].size.height;
    CGPoint waypointLocation = CGPointMake(waypointX, waypointY);
    
    return waypointLocation;
}

/*
 * Calculates the location of the hotspot based on the bounding box provided.
 * This function is used when simulating the locations of objects, since we can't pull the
 * current location and size of the image for this.
 */
-(CGPoint) calculateHotspotLocationBasedOnBoundingBox:(Hotspot*)hotspot :(CGRect) boundingBox {
    float imageWidth = boundingBox.size.width;
    float imageHeight = boundingBox.size.height;
    
    //if image height and width are 0 then the image doesn't exist on this page.
    if(imageWidth > 0 && imageHeight > 0) {
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

//Remove zoom in scroll view for UIWebView
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return nil;
}

/*
 * Button listener for the "Next" button. This function moves to the next active sentence in the story, or to the
 * next story if at the end of the current story. Eventually, this function will also ensure that the correctness
 * of the interaction is checked against the current sentence before moving on to the next sentence. If the manipulation
 * is correct, then it will move on to the next sentence. If the manipulation is not current, then feedback will be provided.
 */
-(IBAction)pressedNext:(id)sender {
    UIButton *buttonNext = (UIButton *) sender;
    buttonNext.enabled = false;
    
    if ([introductions objectForKey:chapterTitle]) {
        // If the user pressed next
        if ([[performedActions objectAtIndex:INPUT] isEqualToString:@"next"]) {
            // Destroy the timer to avoid playing the previous sound
            //[timer invalidate];
            //timer = nil;
            currentIntroStep++;
            
            if (currentIntroStep > totalIntroSteps) {
                [self loadNextPage]; //logging done in loadNextPage
            }
            else {
                // Load the next step
                [self loadIntroStep];
                [self setupCurrentSentenceColor];
                
                //add logging: next intro step
            }
        }
    }
    else if ([vocabularies objectForKey:chapterTitle] && [currentPageId rangeOfString:@"Intro"].location != NSNotFound) {
        NSString* input;
        
        if([chapterTitle isEqualToString:@"The Contest"] || [chapterTitle isEqualToString:@"Why We Breathe"]) {
            input = nextIntro;
        }
        else {
            input = [performedActions objectAtIndex:INPUT];
        }
        // If the user pressed next
        if ([input isEqualToString:@"next"]) {
            // Destroy the timer to avoid playing the previous sound
            //[timer invalidate];
            //timer = nil;
            currentVocabStep++;
            
            if(currentVocabStep > totalVocabSteps-1) {
                [_audioPlayer stop];
                currentSentence = 1;
                [self loadNextPage]; //logging done in loadNextPage
            
            }
            else {
                // Load the next step and update the performed actions
                [self loadVocabStep];
                
                //add logging: next vocab step
            }
        }
    }
    else {
        if (stepsComplete || numSteps == 0 || !allowInteractions) {
            //Logging added by James for User pressing the Next button
            [[ServerCommunicationController sharedManager] logUserNextButtonPressed:@"Next" :@"Tap" :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu",(unsigned long)currentSentence] :[NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
            
            //added for logging
            NSString *tempLastSentence = [NSString stringWithFormat:@"%lu", (unsigned long)currentSentence];
            
            //For the moment just move through the sentences, until you get to the last one, then move to the next activity.
            currentSentence ++;
            
            //Set up current sentence appearance and solution steps
            [self setupCurrentSentence];
            [self colorSentencesUponNext];
            
            //currentSentence is 1 indexed.
            if(currentSentence > totalSentences) {
                [self loadNextPage];
                //logging done in loadNextPage
            }
            else {
                //Logging added by James for Computer moving to next sentence
                [[ServerCommunicationController sharedManager] logNextSentenceNavigation:@"Next Button" :tempLastSentence : [NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] :@"Next Sentence" :bookTitle :chapterTitle : currentPage : tempLastSentence : [NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
                
                //If we are on the first or second manipulation page of The Contest, play the audio of the current sentence
                if ([chapterTitle isEqualToString:@"The Contest"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound)) {
                    if(language_condition == BILINGUAL) {
                        [self playAudioFile:[NSString stringWithFormat:@"BFEC%d.m4a",currentSentence]];
                    }
                    else {
                        [self playAudioFile:[NSString stringWithFormat:@"BFTC%d.m4a",currentSentence]];
                    }
                }
                
                //If we are on the first or second manipulation page of Why We Breathe, play the audio of the current sentence
                if ([chapterTitle isEqualToString:@"Why We Breathe"] && ([currentPageId rangeOfString:@"PM-1"].location != NSNotFound || [currentPageId rangeOfString:@"PM-2"].location != NSNotFound || [currentPageId rangeOfString:@"PM-3"].location != NSNotFound)) {
                    if(language_condition == BILINGUAL) {
                        [self playAudioFile:[NSString stringWithFormat:@"CPQR%d.m4a",currentSentence]];
                    }
                    else {
                        [self playAudioFile:[NSString stringWithFormat:@"CWWB%d.m4a",currentSentence]];
                    }
                }
            }
        }
        else {
            //Play noise if not all steps have been completed
            [self playErrorNoise];
        }
    }
}

/*
 * Creates a UIView for the textbox area so that the swipe gesture can only be recognized when performed
 * in this location. This would make it so that we can only skip forward in the story if
 * we swipe the textbox and not anywhere else on the screen.
 * NOTE: Currently not in use because it disables tap gesture recognition over the textbox area and we haven't
 * found a way to fix this yet.
 */
-(void) createTextboxView {
    //Get the textbox element
    NSString* textbox = [NSString stringWithFormat:@"document.getElementsByClassName('textbox')[0]"];
    
    //Get the textbox x, y, width, and height
    NSString* textboxXString = [NSString stringWithFormat:@"%@.offsetLeft", textbox];
    NSString* textboxYString = [NSString stringWithFormat:@"%@.offsetTop", textbox];
    NSString* textboxWidthString = [NSString stringWithFormat:@"%@.offsetWidth", textbox];
    NSString* textboxHeightString = [NSString stringWithFormat:@"%@.offsetHeight", textbox];
    
    float textboxX = [[bookView stringByEvaluatingJavaScriptFromString:textboxXString] floatValue];
    float textboxY = [[bookView stringByEvaluatingJavaScriptFromString:textboxYString] floatValue];
    float textboxWidth = [[bookView stringByEvaluatingJavaScriptFromString:textboxWidthString] floatValue];
    float textboxHeight = [[bookView stringByEvaluatingJavaScriptFromString:textboxHeightString] floatValue];
    
    //Create UIView over the textbox area
    CGRect textboxRect = CGRectMake(textboxX, textboxY, textboxWidth, textboxHeight);
    UIView* textboxView = [[UIView alloc] initWithFrame:textboxRect];
    
    //Add swipe gesture recognizer and add to the view
    [textboxView addGestureRecognizer:swipeRecognizer];
    [[self view] addSubview:textboxView];
}

/*
 * Creates the menuDataSource from the list of possible interactions.
 * This function assumes that the possible interactions are already rank ordered
 * in cases where that's necessary.
 * If more possible interactions than the alloted number max menu items exists
 * the function will stop after the max number of menu items possible.
 */
-(void)populateMenuDataSource:(NSMutableArray*)possibleInteractions : (NSMutableArray*)relationships {
    //Clear the old data source.
    [menuDataSource clearMenuitems];
    
    //Create new data source for menu.
    //Go through and great a menuItem for every possible interaction
    int interactionNum = 1;
    
    for(PossibleInteraction* interaction in possibleInteractions) {
        //dig into simulatepossibleinteractionformenu to log populated menu
        [self simulatePossibleInteractionForMenuItem: interaction : [relationships objectAtIndex:interactionNum-1]];
        interactionNum ++;
        
        //If the number of interactions is greater than the max number of menu Items allowed, then stop.
        if(interactionNum > maxMenuItems)
            break;
    }
}

/* Clears the highlighting on the scene */
-(void)clearHighlightedObject {
    NSString *clearHighlighting = [NSString stringWithFormat:@"clearAllHighlighted()"];
    [bookView stringByEvaluatingJavaScriptFromString:clearHighlighting];
    
    //log clear
}

/* Plays a text-to-speech audio in a given language */
-(void)playWordAudio:(NSString*) word :(NSString*) lang {
    AVSpeechUtterance *utteranceEn = [[AVSpeechUtterance alloc]initWithString:word];
    utteranceEn.rate = AVSpeechUtteranceMaximumSpeechRate/7;
    utteranceEn.voice = [AVSpeechSynthesisVoice voiceWithLanguage:lang];
    NSLog(@"Sentence: %@", word);
    NSLog(@"Volume: %f", utteranceEn.volume);
    [syn speakUtterance:utteranceEn];
    
    //log play audio
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
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&audioError];
    
    if (_audioPlayer == nil)
        NSLog(@"%@",[audioError description]);
    else
        [_audioPlayer play];
}

/* Plays an audio file at a given path */
-(void) playAudioFile:(NSString*) path {
    NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], path];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    NSError *audioError;
    
    allowInteractions = false;
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&audioError];
    _audioPlayer.delegate = self;
    
    if (_audioPlayer == nil)
        NSLog(@"%@",[audioError description]);
    else
        [_audioPlayer play];
}

/* Plays one audio file after the other */
-(void) playAudioInSequence:(NSString*) path :(NSString*) path2 {
    NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], path];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    NSError *audioError;
    
    NSString *soundFilePath2 = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], path2];
    NSURL *soundFileURL2 = [NSURL fileURLWithPath:soundFilePath2];
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&audioError];
    _audioPlayerAfter = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL2 error:&audioError];
    _audioPlayer.delegate = self;
    
    if (_audioPlayer == nil)
        NSLog(@"%@",[audioError description]);
    else
        [_audioPlayer play];
}

/* Delegate for the AVAudioPlayer */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag  {
    allowInteractions = true;
    [_audioPlayerAfter play];
}
    
// Loads the information of the currentIntroStep for the introduction
-(NSArray*) loadIntroStep {
    NSString* textEnglish;
    NSString* audioEnglish;
    NSString* textSpanish;
    NSString* audioSpanish;
    NSString* expectedSelection;
    NSString* expectedIntroAction;
    NSString* expectedIntroInput;
    NSString* underlinedVocabWord;
    NSString* wrapperObj1;
    
    //allowInteractions = FALSE;
    
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
    if (language_condition == BILINGUAL && currentIntroStep < STEPS_TO_SWITCH_LANGUAGES_EMBRACE && condition == MENU) {
        text = textSpanish;
        audio = audioSpanish;
        languageString = @"S";
        underlinedVocabWord = [[Translation translationWords] objectForKey:expectedIntroInput];
        if (!underlinedVocabWord) {
            underlinedVocabWord = expectedIntroInput;
        }
    }
    else if (language_condition == BILINGUAL && currentIntroStep < STEPS_TO_SWITCH_LANGUAGES_CONTROL && condition == CONTROL) {
        text = textSpanish;
        audio = audioSpanish;
        languageString = @"S";
        underlinedVocabWord = [[Translation translationWords] objectForKey:expectedIntroInput];
        if (!underlinedVocabWord) {
            underlinedVocabWord = expectedIntroInput;
        }
    }
    
    //Format text to load on the textbox
    NSString* formattedHTML = [self buildHTMLString:text:expectedSelection:underlinedVocabWord:expectedIntroAction];
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
    [self playAudioFile:audio];
    
    //Logging added by James for Introduction Audio
    [[ServerCommunicationController sharedManager] logComputerPlayAudio: @"Play Introduction Audio" : languageString :audio :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu",(unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
    
    
    //DEBUG code to play expected action
    //NSString* actions = [NSString stringWithFormat:@"%@ %@ %@",expectedIntroAction,expectedIntroInput,expectedSelection];
    //[self playWordAudio:actions:@"en-us"];
    
    //The response audio file names are hard-coded for now
    if ([expectedIntroInput isEqualToString:@"next"]) {
        wrapperObj1 = @"TTNBTC.m4a";
    }
    else if ([expectedIntroInput isEqualToString:@"next"] && language_condition == BILINGUAL) {
        wrapperObj1 = @"TEBNPC.m4a";
    }
    else if ([expectedSelection isEqualToString:@"word"]) {
        wrapperObj1 = @"BFCE_2B.m4a";
    }
    else if ([expectedSelection isEqualToString:@"word"] && language_condition == BILINGUAL) {
        wrapperObj1 = @"BFCS_2B.m4a";
    }
    else if ([expectedIntroAction isEqualToString:@"move"]) {
        wrapperObj1 = @"BFEE_8.m4a";
    }
    else if ([expectedIntroAction isEqualToString:@"move"] && language_condition == BILINGUAL) {
        wrapperObj1 = @"BFES_8.m4a";
    }
    
    //NSDictionary *wrapper = [NSDictionary dictionaryWithObjectsAndKeys:wrapperObj1, @"Key1", nil];
    //timer = [NSTimer scheduledTimerWithTimeInterval:17.5 target:self selector:@selector(playAudioFileTimed:) userInfo:wrapper repeats:YES];
    
    performedActions = [NSArray arrayWithObjects: expectedSelection, expectedIntroAction, expectedIntroInput, nil];
    
    return performedActions;
}

/*
 * Builds the format of the action sentence that allows words to be clickable
 */
-(NSString*) buildHTMLString:(NSString*)htmlText :(NSString*)selectionType :(NSString*)clickableWord :(NSString*) sentenceType {
    //String to build
    NSString* stringToBuild;
    
    //If string contains the special character "'"
    if ([htmlText rangeOfString:@"'"].location != NSNotFound) {
        htmlText = [htmlText stringByReplacingCharactersInRange:NSMakeRange([htmlText rangeOfString:@"'"].location,1) withString:@"&#39;"];
    }
    
    NSArray* splits = [htmlText componentsSeparatedByString:clickableWord];
    
    if ([sentenceType isEqualToString:@"move"] || [sentenceType isEqualToString:@"group"]) {
        stringToBuild = [NSString stringWithFormat:@"<span class=\"sentence actionSentence\" id=\"s1\">%@</span>",htmlText];
    }
    else if ([selectionType isEqualToString:@"word"]){
        stringToBuild = [NSString stringWithFormat:@"<span class=\"sentence\" id=\"s1\">%@<span class=\"audible\">%@</span>%@</span>",splits[0],clickableWord,splits[1]];
    }
    else {
        stringToBuild = [NSString stringWithFormat:@"<span class=\"sentence\" id=\"s1\">%@</span>",htmlText];
    }
    
    return stringToBuild;
}

-(NSArray*) loadVocabStep {
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
    
    if((language_condition == BILINGUAL) && (stepNumber & 1)) {
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
        if(language_condition == BILINGUAL && (stepNumber & 1)) {
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
        if(language_condition == BILINGUAL) {
            [self playAudioFile:audioSpanish];
        } else {
            //Play introduction audio
            [self playAudioFile:audio];
        }
        
        //Logging added by James for Word Audio
//        [[ServerCommunicationController sharedManager] logComputerPlayAudio: @"Play Step Audio" : @"E" :audio  :bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu",(unsigned long)currentSentence] :[NSString stringWithFormat: @"%lu", (unsigned long)currentStep]];
    }
    
    if (currentVocabStep == totalVocabSteps-1 && ([chapterTitle isEqualToString:@"The Contest"] || [chapterTitle isEqualToString:@"Why We Breathe"])) {
        if(language_condition == BILINGUAL) {
            [self playAudioFile:nextAudioSpanish];
        } else {
            //Play introduction audio
            [self playAudioFile:nextAudio];
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
    else if ([expectedIntroInput isEqualToString:@"next"] && language_condition == BILINGUAL) {
        wrapperObj1 = @"TEBNPC.m4a";
    }
    
    //The wrapper is a dictionary that stores the name of the file and a key.
    //It is used to pass this information to the timer as one of its parameters.
    //NSDictionary *wrapper = [NSDictionary dictionaryWithObjectsAndKeys:wrapperObj1, @"Key1", nil];
    //timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(playAudioFileTimed:) userInfo:wrapper repeats:YES];
    
    performedActions = [NSArray arrayWithObjects: expectedSelection, expectedIntroAction, expectedIntroInput, nil];
    
    return performedActions;
}

-(void) colorSentencesUponNext {
    //Color the current sentence black by default
    NSString* setSentenceColor = [NSString stringWithFormat:@"setSentenceColor(s%d, 'black')", currentSentence];
    [bookView stringByEvaluatingJavaScriptFromString:setSentenceColor];
    
    //Change the opacity to 1
    NSString* setSentenceOpacity = [NSString stringWithFormat:@"setSentenceOpacity(s%d, 1)", currentSentence];
    [bookView stringByEvaluatingJavaScriptFromString:setSentenceOpacity];
    
    //Set the color to black for the previous sentence also
    setSentenceColor = [NSString stringWithFormat:@"setSentenceColor(s%d, 'black')", currentSentence-1];
    [bookView stringByEvaluatingJavaScriptFromString:setSentenceColor];
    
    //Decrease the opacity of the previous sentence
    setSentenceOpacity = [NSString stringWithFormat:@"setSentenceOpacity(s%d, .2)", currentSentence-1];
    [bookView stringByEvaluatingJavaScriptFromString:setSentenceOpacity];
    
    //Get the sentence class
    NSString* actionSentence = [NSString stringWithFormat:@"getSentenceClass(s%d)", currentSentence];
    NSString* sentenceClass = [bookView stringByEvaluatingJavaScriptFromString:actionSentence];
    
    //If it is an action sentence color it blue
    if ([sentenceClass  isEqualToString: @"sentence actionSentence"]) {
        NSString* colorSentence = [NSString stringWithFormat:@"setSentenceColor(s%d, 'blue')", currentSentence];
        [bookView stringByEvaluatingJavaScriptFromString:colorSentence];
    }
}

-(void) highlightObject:(NSString*)object :(double)delay {
    //Highlight the tapped object
    NSString* highlight = [NSString stringWithFormat:@"highlightObjectOnWordTap(%@)", object];
    [bookView stringByEvaluatingJavaScriptFromString:highlight];

    //Clear highlighted object
    [self performSelector:@selector(clearHighlightedObject) withObject:nil afterDelay:delay];
}

- (void) viewDidDisappear:(BOOL)animated {
    //[timer invalidate];
    //timer = nil;
}

- (NSString*) getEnglishTranslation: (NSString*)sentence {
    NSArray* keys = [[Translation translationWords] allKeysForObject:sentence];
    if (keys != nil && [keys count] > 0)
        return [keys objectAtIndex:0];
    else
        return @"Translation not found";
}

#pragma mark - PieContextualMenuDelegate
/*
 * Expands the contextual menu, allowing the user to select a possible grouping/ungrouping.
 * This function is called after the data source is created.
 */
-(void) expandMenu {
    menu = [[PieContextualMenu alloc] initWithFrame:[bookView frame]];
    [menu addGestureRecognizer:tapRecognizer];
    [[self view] addSubview:menu];
    
    menu.delegate = self;
    menu.dataSource = menuDataSource;
    
    //Calculate the radius of the circle
    CGFloat radius = (menuBoundingBox -  (itemRadius * 2)) / 2;
    [menu expandMenu:radius];
    menuExpanded = TRUE;
    
    NSInteger numMenuItems = [menuDataSource numberOfMenuItems];
    NSMutableArray *menuItemInteractions = [[NSMutableArray alloc] init];
    NSMutableArray *menuItemImages =[[NSMutableArray alloc] init];
    NSMutableArray *menuItemRelationships = [[NSMutableArray alloc] init];
    
    for (int x=0; x<numMenuItems; x++) {
        MenuItemDataSource *tempMenuItem = [menuDataSource dataObjectAtIndex:x];
        PossibleInteraction *tempMenuInteraction =[tempMenuItem interaction];
        Relationship *tempMenuRelationship = [tempMenuItem menuRelationship];
        
        //[menuItemInteractions addObject:[tempMenuRelationship actionType]];
        
        if(tempMenuInteraction.interactionType == DISAPPEAR)
        {
            [menuItemInteractions addObject:@"Disappear"];
        }
        if (tempMenuInteraction.interactionType == UNGROUP)
        {
            [menuItemInteractions addObject:@"Ungroup"];
        }
        if (tempMenuInteraction.interactionType == GROUP)
        {
            [menuItemInteractions addObject:@"Group"];
        }
        if (tempMenuInteraction.interactionType == TRANSFERANDDISAPPEAR)
        {
            [menuItemInteractions addObject:@"Transfer And Disappear"];
        }
        if (tempMenuInteraction.interactionType == TRANSFERANDGROUP)
        {
            [menuItemInteractions addObject:@"Transfer And Group"];
        }
        if(tempMenuInteraction.interactionType ==NONE)
        {
            [menuItemInteractions addObject:@"none"];
        }
        
        [menuItemImages addObject:[NSString stringWithFormat:@"%d", x]];
        
        for(int i=0; i< [tempMenuItem.images count]; i++)
        {
            MenuItemImage *tempimage =  [tempMenuItem.images objectAtIndex:i];
            [menuItemImages addObject:[tempimage.image accessibilityIdentifier]];
        }
        
        [menuItemRelationships addObject:tempMenuRelationship.action];
    }
    
    //Logging Added by James for Menu Display
    [[ServerCommunicationController sharedManager] logComputerDisplayMenuItems : menuItemInteractions : menuItemImages : menuItemRelationships : bookTitle :chapterTitle :currentPage :[NSString stringWithFormat:@"%lu", (unsigned long)currentSentence] :[NSString stringWithFormat:@"%lu", (unsigned long)currentStep]];
}

@end
