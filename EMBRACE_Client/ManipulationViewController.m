//
//  PMViewController.m
//  eBookReader
//
//  Created by Andreea Danielescu on 2/12/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "ManipulationViewController.h"
#import "ContextualMenuDataSource.h"
#import "PieContextualMenu.h"
#import "Translation.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "IntroductionViewController.h"
#import "Statistics.h"
#import "LibraryViewController.h"
#import "NSString+HTML.h"
#import "PageController.h"
#import "SentenceController.h"
#import "SolutionStepController.h"
#import "PossibleInteractionController.h"
#import "ManipulationAnalyser.h"

@interface ManipulationViewController ()<ManipulationViewDelegate> {
    NSString *chapterTitle;
    NSString *bookTitle;

    //TODO: Determine what I can delete from here to next comment
    //NSString *currentPage; //Current page being shown, so that the next page can be requested
    //NSString *currentPageId; //Id of the current page being shown
    //NSString *actualPage; //Stores the address of the current page we are at
    //NSUInteger currentSentence; //Active sentence to be completed
    //NSString *currentSentenceText; //Text of current sentence
    //NSUInteger currentIdea; //Current idea number to be completed
    //NSUInteger totalSentences; //Total number of sentences on this page
    //NSString *actualWord; //Stores the current word that was clicked
    //NSString *previousStep;
    
    //NSUInteger currentComplexity; //Complexity level of current sentence
    NSDate *startTime;
    NSDate *endTime;
    
    //PhysicalManipulationSolution *PMSolution; //PM solution steps for current chapter
    //ImagineManipulationSolution *IMSolution; //IM solution steps for current chapter
    //NSUInteger numSteps; //Number of steps for current sentence
    //NSUInteger currentStep; //Active step to be completed
    //BOOL stepsComplete; //True if all steps have been completed for a sentence
    //TODO: Determine what I can delete from previous todo to here
    
    InteractionRestriction useSubject; //Determines which objects the user can manipulate as the subject
    InteractionRestriction useObject; //Determines which objects the user can interact with as the object
    
    NSString *movingObjectId; //Object currently being moved
    NSString *collisionObjectId; //Object the moving object was moved to
    NSString *separatingObjectId; //Object identified when pinch gesture performed
    BOOL containsAnimatingObject;
    BOOL movingObject; //True if an object is currently being moved
    BOOL separatingObject; //True if two objects are currently being ungrouped
    
    BOOL panning;
    BOOL pinching;
    BOOL pinchToUngroup; //True if pinch gesture is used to ungroup
    
    BOOL replenishSupply; //True if object should reappear after disappearing
    BOOL allowSnapback; //True if objects should snap back to original location upon error
    BOOL pressedNextLock; // True if user pressed next, and false after next function finishes execution
    BOOL didSelectCorrectMenuOption; // True if user selected the correct menu option in IM mode
    
    CGPoint endLocation; // ending location of an object after it is moved
    CGPoint delta; //distance between the top-left corner of the image being moved and the point clicked.
    
    PieContextualMenu *menu;
    UIView *IMViewMenu;
    BOOL menuExpanded;
    
    NSTimer *timer; //Controls the timing of the audio file that is playing
    BOOL isAudioLeft;
}

@property (nonatomic, strong) IBOutlet UIWebView *bookView;
//@property (nonatomic, strong) IBOutlet ManipulationView *manipulationView;

@end

@implementation ManipulationViewController

@synthesize pageContext;
@synthesize stepContext;
@synthesize sentenceContext;
@synthesize manipulationContext;
@synthesize conditionSetup;
@synthesize model;

@synthesize manipulationView;
@synthesize book;
@synthesize bookTitle;
@synthesize chapterTitle;
@synthesize bookImporter;

@synthesize libraryViewController;
@synthesize buildStringClass;
@synthesize playaudioClass;
@synthesize syn;
@synthesize allowInteractions;
@synthesize animatingObjects;
@synthesize isLoadPageInProgress;
@synthesize pc;
@synthesize sc;
@synthesize ssc;
@synthesize pic;
@synthesize currentComplexity;
@synthesize currentComplexityLevel;
@synthesize startTime;
@synthesize endTime;
@synthesize startLocation;
@synthesize pageStatistics;
@synthesize currentGroupings;
@synthesize lastRelationship;
@synthesize allRelationships;
@synthesize menuDataSource;
@synthesize bookView;

//Used to determine the required proximity of 2 hotspots to group two items together.
float const groupingProximity = 20.0;

BOOL wasPathFollowed = false;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    bookView.frame = self.view.bounds;
}

/*  Initial view setup after webview loads. Adds manipulationView as a subview and adds view constraints
*   Initilizes class variables
*/
- (void)viewDidLoad {
    [super viewDidLoad];
    self.manipulationView = [[ManipulationView alloc] initWithFrameAndView:self.view.frame:bookView];
    
    //[self.view addSubview:self.manipulationView];
    self.manipulationView.delegate = self;
    //[self.view sendSubviewToBack:self.manipulationView];
    
//    NSLayoutConstraint *xCenterConstraint = [NSLayoutConstraint constraintWithItem:self.manipulationView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
//    [self.view addConstraint:xCenterConstraint];
//    
//    NSLayoutConstraint *yCenterConstraint = [NSLayoutConstraint constraintWithItem:self.manipulationView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
//    [self.view addConstraint:yCenterConstraint];
    
    
    /*[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.manipulationView
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.manipulationView
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeLeading
                                                             multiplier:1.0
                                                               constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.manipulationView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.manipulationView
                                                              attribute:NSLayoutAttributeTrailing
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeTrailing
                                                             multiplier:1.0
                                                               constant:0.0]];
     */

    
    //[self.manipulationView addGesture:tapRecognizer];
    //[self.manipulationView addGesture:swipeRecognizer];
    //[self.manipulationView addGesture:panRecognizer];
    
    //hides the default navigation bar to add custom back button
    self.navigationItem.hidesBackButton = YES;
    
    //custom back button to show confirmation alert
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle: LIBRARY style: UIBarButtonItemStyleBordered target: self action: @selector(backButtonPressed:)];
    //Sets leftBarButtonItem to the custom back button in place of default back button
    self.navigationItem.leftBarButtonItem = backButton;
    
    conditionSetup = [ConditionSetup sharedInstance];
    manipulationContext = [[ManipulationContext alloc] init];
    pageContext = [[PageContext alloc] init];
    sentenceContext = [[SentenceContext alloc] init];
    stepContext = [[StepContext alloc] init];
    book = [[Book alloc]init];
    model = [[InteractionModel alloc]init];
    buildStringClass = [[BuildHTMLString alloc] init];
    playaudioClass = [[PlayAudioFile alloc] init];
    
    syn = [[AVSpeechSynthesizer alloc] init];
    
    menuDataSource = [[ContextualMenuDataSource alloc] init];
    
    //Added to deal with ios7 view changes. This makes it so the UIWebView and the navigation bar do not overlap.
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    manipulationView.bookView.scalesPageToFit = YES;
    manipulationView.bookView.scrollView.delegate = self;
    
    [[manipulationView.bookView scrollView] setBounces: NO];
    [[manipulationView.bookView scrollView] setScrollEnabled:NO];
    
    pageContext.currentPage = nil;
    
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
    
    if (conditionSetup.condition == CONTROL) {
        allowInteractions = FALSE;
        
        useSubject = NO_ENTITIES;
        useObject = NO_ENTITIES;
    }
    else if (conditionSetup.condition == EMBRACE) {
        allowInteractions = TRUE;
        
        stepContext.maxAttempts = 5;
        stepContext.numAttempts = 0;
        
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
        [[ITSController sharedInstance] setAnalyzerDelegate:self];
    }
}

//Custom back button to confirm navigation to library page
- (void)backButtonPressed:(id)sender {
    //Custom Back Button to confirm navigation
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(RETURN_TO_LIBRARY, EMPTYSTRING) message:NSLocalizedString(@"Are you sure you want to return to the Library?", EMPTYSTRING) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", EMPTYSTRING) otherButtonTitles:NSLocalizedString(@"Yes", EMPTYSTRING), nil];
    [alertView show];
}

//Memory warning; potentially expand functionality if there is a memory leak
- (void)didReceiveMemoryWarning {
    NSLog(@"***************** Memory warning!! *****************");
}

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *requestString = [[[request URL] absoluteString] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    
    if ([requestString hasPrefix:@"ios-log:"]) {
        NSString *logString = [[requestString componentsSeparatedByString:@":#iOS#"] objectAtIndex:1];
        NSLog(@"UIWebView console: %@", logString);
        return NO;
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    //Disable user selection
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
    
    //Disable callout
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
    self.manipulationView.bookView = self.bookView;
    [self.manipulationView loadJsFiles];
    [self manipulationViewDidLoad:manipulationView];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
}

#pragma mark - UIScrollView delegates

//Remove zoom in scroll view for UIWebView
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return nil;
}

//Function is called back from the ManipulationView after loading to setup sentences and areas
- (void)manipulationViewDidLoad:(ManipulationView *)view {
    isLoadPageInProgress = false; //page has finished loading
    
    //Start off with no objects grouped together
    currentGroupings = [[NSMutableDictionary alloc] init];
    
    //Perform setup of setentences for page
    [sc setupSentencesForPage];
    
    isAudioLeft = false;
    
    [self playCurrentSentenceAudio];
    
    //Perform setup of areas and paths for page
    [self drawAreasForPage];
    
    //Perform setup for activity
    [self performSetupForActivity];
}


/*
 *  Draws areas and paths for page
 */
- (void)drawAreasForPage {
    //If there is at least one area/path to build
    if ([model getAreaWithPageId:pageContext.currentPageId] || [model getAreaWithPageId:ALL_CHAPTERS]) {
        //Build area/path
        for (Area *area in [model areas]) {
            if ([area.pageId isEqualToString:pageContext.currentPageId] || [area.pageId isEqualToString:ALL_CHAPTERS]) {
                [self buildPath:area.areaId];
            }
        }
    }
    
    //TODO: remove hard coded draw areas and move to new setup draw area function
    //Draw area (hard-coded for now)
    //[self drawArea:@"outside":@"The Lopez Family"];
    //[self drawArea:@"aroundPaco":@"Is Paco a Thief?"];
    //[self drawArea:@"aorta":@"The Amazing Heart":@"story2-PM-4"];
    //[self drawArea:@"aortaPath":@"The Amazing Heart":@"story2-PM-4"];
    //[self drawArea:@"aortaStart":@"The Amazing Heart":@"story2-PM-4"];
    //[self drawArea:@"arteries":@"Muscles Use Oxygen":@"story3-PM-1"];
    //[self drawArea:@"aortaPath2":@"Muscles Use Oxygen":@"story3-PM-1"];
    //[self drawArea:@"veinPath":@"Getting More Oxygen for the Muscles":@"story4-PM-3"];
    //[self drawArea:@"vein":@"Getting More Oxygen for the Muscles":@"story4-PM-3"];
    //[self drawArea:@"veinPath":@"Muscles Use Oxygen":@"story3-PM-3"];
    //[self drawArea:@"aortaPath":@"Muscles Use Oxygen":@"story3-PM-1"];
}

/*
 * Draws a given area for the given chapter and page
 */
- (void)drawArea:(NSString *)areaName :(NSString *)chapter :(NSString *)pageId {
    if ([chapterTitle isEqualToString:chapter] && [pageContext.currentPageId isEqualToString:pageId]) {
        [self.manipulationView drawArea:areaName
                      chapter:chapter
                       pageId:pageId
                    withModel:model];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView title] isEqualToString:RETURN_TO_LIBRARY]) {
        //Get title of pressed alert button
        NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
        
        //If button pressed is Yes, return to libraryView
        if ([title isEqualToString:@"Yes"]) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

/*
 * Gets the book reference for the book that's been opened.
 * Also sets the reference to the interaction model of the book.
 * Sets the page to the one for the current chapter activity.
 * Calls the function to load the html content for the activity.
 */
- (void)loadFirstPage {
    pc = [[PageController alloc] initWithController:self];
    [pc loadFirstPage];
    
    sc = [[SentenceController alloc] initWithController:self];
    
    ssc = [[SolutionStepController alloc] initWithController:self];
    
    pic = [[PossibleInteractionController alloc] initWithController:self];
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
    Hotspot *hotspot1 = [model getHotspotforObjectWithActionAndRole:obj1Id :action :SUBJECT];
    Hotspot *hotspot2 = [model getHotspotforObjectWithActionAndRole:obj2Id :action :OBJECT];
    
    //If no hotspots were found with obj1 as the subject, then assume obj1 is the object of the interaction
    //Add the subject before the object to the interaction
    if (hotspot1 == nil && hotspot2 == nil) {
        objects = [[NSArray alloc] initWithObjects:obj2Id, obj1Id, nil];
        
        hotspot1 = [model getHotspotforObjectWithActionAndRole:obj2Id :action :SUBJECT];
        hotspot2 = [model getHotspotforObjectWithActionAndRole:obj1Id :action :OBJECT];
    }
    else {
        objects = [[NSArray alloc] initWithObjects:obj1Id, obj2Id, nil];
    }
    
    NSArray *hotspotsForInteraction = [[NSArray alloc]initWithObjects:hotspot1, hotspot2, nil];
    
    //swap order of isEqualToStrings to resolve nil crashing events
    //The move case only applies if an object is being moved to another object, not a waypoint
    if ([[step stepType] isEqualToString:GROUP_TXT] ||
        [[step stepType] isEqualToString:MOVE] ||
        [[step stepType] isEqualToString:GROUPAUTO]) {
        interaction = [[PossibleInteraction alloc]initWithInteractionType:GROUP];
        
        [interaction addConnection:GROUP :objects :hotspotsForInteraction];
    }
    else if ([[step stepType] isEqualToString:UNGROUP_TXT] ||
             [[step stepType] isEqualToString:UNGROUPANDSTAY]) {
        interaction = [[PossibleInteraction alloc]initWithInteractionType:UNGROUP];
        
        [interaction addConnection:UNGROUP :objects :hotspotsForInteraction];
    }
    else if ([[step stepType] isEqualToString:DISAPPEAR_TXT]) {
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
    NSMutableArray *setupSteps = [[PMActivity setupSteps] objectForKey:pageContext.currentPageId]; //get setup steps for current page
    
    //For each setupStep, perform action
    for (ActionStep *setupStep in setupSteps) {
        if ([[setupStep stepType] isEqualToString:GROUP_TXT]) {
            PossibleInteraction *interaction = [self convertActionStepToPossibleInteraction:setupStep];
            [pic performInteraction:interaction]; //groups the objects
        }
        else if ([[setupStep stepType] isEqualToString:MOVE]) {
            //Get information for move step type
            NSString *object1Id = [setupStep object1Id];
            NSString *action = [setupStep action];
            NSString *object2Id = [setupStep object2Id];
            NSString *waypointId = [setupStep waypointId];
            
            //Move either requires object1 to move to object2 (which creates a group interaction) or it requires object1 to move to a waypoint
            if (object2Id != nil) {
                PossibleInteraction* correctInteraction = [pic getCorrectInteraction];
                [pic performInteraction:correctInteraction]; //performs solution step
            }
            else if (waypointId != nil) {
                //Get position of hotspot in pixels based on the object image size
                Hotspot *hotspot = [model getHotspotforObjectWithActionAndRole:object1Id :action :SUBJECT];
                CGPoint hotspotLocation = [self getHotspotLocationOnImage:hotspot];
                
                //Get position of waypoint in pixels based on the background size
                Waypoint* waypoint = [model getWaypointWithId:waypointId];
                CGPoint waypointLocation = [self getWaypointLocation:waypoint];
                
                if ([self.manipulationView isObjectCenter:object1Id]) {
                    hotspotLocation.x = 0;
                    hotspotLocation.y = 0;
                }
                
                //Move the object
                [self moveObject:object1Id :waypointLocation :hotspotLocation :false];
                
                //Clear highlighting
                [self.manipulationView clearAllHighLighting];
            }
        }
    }
}

/*
 * Performs ungroup, move, appear, disappear, changezindex, annimate, and swap image steps automatically
 */
- (void)performAutomaticSteps {
    //Perform steps only if they exist for the sentence
    if (stepContext.numSteps > 0 && allowInteractions) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        
        [[ServerCommunicationController sharedInstance] logLoadStep:stepContext.currentStep ofType:[currSolStep stepType] context:manipulationContext];
        
        //Automatically perform interaction if step is ungroup, move, or swap image
        if (!pinchToUngroup && ([[currSolStep stepType] isEqualToString:UNGROUP_TXT] ||
                                [[currSolStep stepType] isEqualToString:UNGROUPANDSTAY])) {
            PossibleInteraction *correctUngrouping = [pic getCorrectInteraction];
            
            [pic performInteraction:correctUngrouping];
            [ssc incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:GROUPAUTO]) {
            PossibleInteraction *correctGrouping = [pic getCorrectInteraction];
            
            [pic performInteraction:correctGrouping];
            [ssc incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:MOVE]) {
            [ssc moveObjectForSolution];
            [ssc incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:SWAPIMAGE]) {
            [self swapObjectImage];
            [ssc incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:APPEAR] ||
                 [[currSolStep stepType] isEqualToString:APPEARAUTOWITHDELAY]) {
            [self loadImage];
            [ssc incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:DISAPPEARAUTO] ||
                 [[currSolStep stepType] isEqualToString:DISAPPEARAUTOWITHDELAY]) {
            [self hideImage];
            [ssc incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:CHANGEZINDEX]) {
            [self changeZIndex];
            [ssc incrementCurrentStep];
        }
        else if ([[currSolStep stepType] isEqualToString:ANIMATE]) {
            //If last step was a check step and user moved the object to the correct end location, then just move object to correct
            //last coordinate point for the path
            if ([currSolSteps count] >= 2 && stepContext.currentStep >= 2 && [[[currSolSteps objectAtIndex:stepContext.currentStep - 2] stepType] isEqualToString:CHECK]
               && [self isHotspotInsideLocation:true]) {
                NSString *areaId = [currSolStep areaId];
                
                //Get area that hotspot should be inside
                Area *area = [model getArea:areaId:pageContext.currentPageId];
                
                NSArray *areaKeys = [area.points allKeys];
                NSString *maxKey;
                
                //Get the max coordinate point
                for (NSString *key in areaKeys) {
                    NSString *curKey = key;
                    curKey = [key stringByReplacingOccurrencesOfString:@"x" withString:@""];
                    curKey = [curKey stringByReplacingOccurrencesOfString:@"y" withString:@""];
                    if (!maxKey) {
                        maxKey = curKey;
                    }
                    
                    if ([maxKey intValue] < [curKey intValue]) {
                        maxKey = curKey;
                    }
                }
                
                //Create the cgpoint for the end of path
                CGPoint endOfPath;
                NSString *xPoint = [area.points valueForKey:[NSString stringWithFormat:@"x%@", maxKey]];
                NSString *yPoint = [area.points valueForKey:[NSString stringWithFormat:@"y%@", maxKey]];
                endOfPath.x = [xPoint floatValue];
                endOfPath.y = [yPoint floatValue];
                
                [self moveObject:movingObjectId :endOfPath:CGPointMake(0, 0) :false];
                [ssc incrementCurrentStep];
            }
            else {
                [self animateObject];
                [ssc incrementCurrentStep];
            }
        }
        else if ([[currSolStep stepType] isEqualToString:PLAYSOUND]) {
            NSString *file = [currSolStep fileName];
            
            if ([file isEqualToString:@"NaughtyMonkey_Script4.mp3"]
                && conditionSetup.language == BILINGUAL) {
                [self.playaudioClass playAudioFile:self :@"NaughtyMonkey_Script4_S.mp3"];
            }
            else {
                [self.playaudioClass playAudioFile:self :file];
            }
            
            [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:[[currSolStep fileName] stringByDeletingPathExtension] inLanguage:NULL_TXT ofType:PLAY_SOUND :manipulationContext];
            
            [ssc incrementCurrentStep];
        }
    }
}

/*
 * animateObject based on current animation step
 */
- (void)animateObject {
    //Check solution only if it exists for the sentence
    if (stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:ANIMATE]) {
            //Get information for animation step type
            NSString *object1Id = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            NSString *waypointId = [currSolStep waypointId];
            NSString *areaId = [currSolStep areaId];
            
            if ([areaId isEqualToString:EMPTYSTRING]) {
                areaId = AREA;
            }
            
            CGPoint imageLocation = [self.manipulationView getObjectPosition:object1Id];
            
            //Calculate offset between top-left corner of image and the point clicked.
            delta = [self calculateDeltaForMovingObjectAtPoint:imageLocation];
            
            //Change the location to accounting for the difference between the point clicked and the top-left corner which is used to set the position of the image.
            CGPoint adjLocation = CGPointMake(imageLocation.x - delta.x, imageLocation.y - delta.y);
            
            CGPoint waypointLocation;
            
            if ([waypointId isEqualToString:EMPTYSTRING]) {
                waypointLocation.x = 0;
                waypointLocation.y = 0;
            }
            else {
                Waypoint *waypoint = [model getWaypointWithId:waypointId];
                waypointLocation = [self getWaypointLocation:waypoint];
            }
            
            //Call the animateObject function in the js file.
            [self.manipulationView animateObject:object1Id from:adjLocation to:waypointLocation action:action areaId:areaId];
            [animatingObjects setObject:[NSString stringWithFormat:@"%@,%@,%@", ANIMATE, action, areaId] forKey:object1Id];
            
            [[ServerCommunicationController sharedInstance] logAnimateObject:object1Id forAction:action context:manipulationContext];
        }
    }
}

/*
 * Calls the buildPath function on the JS file
 * Sends all the points in an area or path to the the JS to load them in memory
 */
- (void)buildPath:(NSString *)areaId {
    [self.manipulationView buildPath:areaId pageId:pageContext.currentPageId withModel:model];
}

/*
 * User pressed Library button. Write log data to file.
 */
- (void)viewWillDisappear:(BOOL)animated {
    [self.playaudioClass stopPlayAudioFile];
    [super viewWillDisappear:animated];
    
    if (![[self.navigationController viewControllers] containsObject:self]) {
        [[ServerCommunicationController sharedInstance] logPressLibrary:manipulationContext];
        [[ServerCommunicationController sharedInstance] studyContext].condition = NULL_TXT;
    }
}

/*
* Tap gesture handles taps on menus, words, images
*/
- (IBAction)tapGesturePerformed:(UITapGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];
    
    if ((conditionSetup.condition == EMBRACE && conditionSetup.currentMode == IM_MODE) && !allowInteractions) {
        allowInteractions = true;
    }
    
    //Check to see if we have a menu open. If so, process menu click.
    if (menu && allowInteractions) {
        [self tapGestureOnMenu:location];
    }
    //TODO: Figure out how to switch on object vs word type
    else {
        if (stepContext.numSteps > 0 && allowInteractions) {
            [self tapGestureOnObject:location];
        }
        
        //Get the object at that point if it's a manipulation object.
        NSString *imageAtPoint = [self getObjectAtPoint:location ofType:MANIPULATIONOBJECT];
        
        //Retrieve the name of the object at this location
        
        imageAtPoint = [self.manipulationView getElementAtLocation:location];
        
        //Capture the clicked text id, if it exists
        NSString *sentenceID = [self.manipulationView getElementAtLocation:location];
        int sentenceIDNum = [[sentenceID substringFromIndex:0] intValue];
        
        NSString *sentenceText;
        
        //Capture the clicked text, if it exists
        if ([pageContext.currentPageId containsString:DASH_INTRO]) {
            //Capture the clicked text, if it exists
            sentenceText = [self.manipulationView getVocabAtId:sentenceIDNum];
        }
        else if ([pageContext.currentPageId containsString:@"-PM"]) {
            sentenceText = [self.manipulationView getTextAtLocation:location];
        }
        
        //Convert to lowercase so the sentence text can be mapped to objects
        sentenceText = [sentenceText lowercaseString];
        NSString *englishSentenceText = sentenceText;
        
        //Capture the spanish extension
        NSString *spanishExt = [self.manipulationView getSpanishExtention:location];
        
        if (conditionSetup.language == BILINGUAL) {
            if (![[sc getEnglishTranslation:sentenceText] isEqualToString:NULL_TXT]) {
                englishSentenceText = [sc getEnglishTranslation:sentenceText];
            }
        }
        
        //Vocabulary introduction mode
        if ([pageContext.currentPageId containsString:DASH_INTRO]) {
            [self tapGestureOnVocabWord: englishSentenceText:sentenceText:sentenceIDNum];
        }
        //Taps on vocab word in story
        else if ([pageContext.currentPageId containsString:@"-PM"]) {
            [self tapGestureOnStoryWord:englishSentenceText:sentenceIDNum:spanishExt:sentenceText];
        }
    }
    
    //Disable user interactions in IM mode
    if ((conditionSetup.condition == EMBRACE && conditionSetup.currentMode == IM_MODE) && allowInteractions) {
        allowInteractions = false;
    }
}

/*
 *  Handles tap gesture on menu items for PM and IM menus
 */
- (void)tapGestureOnMenu:(CGPoint)location {
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
            
            [connectionData setObject:objects forKey:OBJECTS];
            [connectionData setObject:hotspot forKey:HOTSPOT];
            [connectionData setObject:interactionType forKey:INTERACTIONTYPE];
            
            [menuItemData addObject:connectionData];
        }
        
        [[ServerCommunicationController sharedInstance] logSelectMenuItem:menuItemData atIndex:menuItem context:manipulationContext];
        
        [self checkSolutionForInteraction:interaction]; //check if selected interaction is correct
        
        if ((conditionSetup.condition == EMBRACE && conditionSetup.currentMode == IM_MODE) && (allowInteractions)) {
            allowInteractions = FALSE;
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
    allowSnapback = TRUE;
}

/*
 *  Handles tap gesture on vocab words on intro page to play vocab audio and increment step
 */
- (void)tapGestureOnVocabWord:(NSString *)englishSentenceText :(NSString *)sentenceText :(NSInteger)sentenceIDNum {
    //Get steps for current sentence
    NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
    
    if ([currSolSteps count] > 0) {
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:TAPWORD]) {
            if ([englishSentenceText containsString: [currSolStep object1Id]] &&
               (sentenceContext.currentSentence == sentenceIDNum) && !stepContext.stepsComplete) {
                [[ServerCommunicationController sharedInstance] logTapWord:sentenceText :manipulationContext];
                
                if (conditionSetup.appMode == ITS) {
                    [[ITSController sharedInstance] userDidVocabPreviewWord:sentenceText context:manipulationContext];
                }
                
                [ssc incrementCurrentStep];
                [self playIntroVocabWord:englishSentenceText :currSolStep];
            }
            else {
                //pressed wrong word
            }
        }
        else {
            //incorrect solution step created for vocabulary page
        }
    }
    else {
        //no vocab steps
    }
}

/*
 *  Handles tap gesture on vocab words in story to play audio
 */
- (void)tapGestureOnStoryWord:(NSString *)englishSentenceText :(NSInteger)sentenceIDNum :(NSString *)spanishExt :(NSString *)sentenceText {
    //Get steps for current sentence
    NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
    
    if (![self.playaudioClass isAudioLeftInSequence]) {
        BOOL playedAudio = false;
        
        if (currSolSteps != nil && [currSolSteps count] > 0) {
            //Get current step to be completed
            ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
            
            if ([[currSolStep stepType] isEqualToString:TAPWORD]) {
                if (([[currSolStep object1Id] containsString: englishSentenceText] && (sentenceContext.currentSentence == sentenceIDNum)) ||
                    ([chapterTitle isEqualToString:@"The Naughty Monkey"] && conditionSetup.condition == CONTROL && [[currSolStep object1Id] containsString: englishSentenceText] && sentenceContext.currentSentence == 2 && [pageContext.currentPageId containsString:@"-PM-2"]) ||
                    ([chapterTitle isEqualToString:@"The Naughty Monkey"] && conditionSetup.condition == EMBRACE && [[currSolStep object1Id] containsString: englishSentenceText] && (sentenceContext.currentSentence == sentenceIDNum) && sentenceContext.currentSentence != 2 && [pageContext.currentPageId containsString:@"-PM-2"])) {
                    playedAudio = true;
                    [[ServerCommunicationController sharedInstance] logTapWord:sentenceText :manipulationContext];
                    
                    if (conditionSetup.appMode == ITS) {
                        [[ITSController sharedInstance] userDidPlayWord:sentenceText context:manipulationContext];
                    }
                    
                    [self.playaudioClass stopPlayAudioFile];
                    [self playAudioForVocabWord:englishSentenceText :spanishExt];
                    
                    [ssc incrementCurrentStep];
                }
            }
        }
        
        if (!playedAudio && [englishSentenceText length] > 0)// && [[Translation translationWords] objectForKey:englishSentenceText])
        {
            [[ServerCommunicationController sharedInstance] logTapWord:englishSentenceText :manipulationContext];
            
            if (conditionSetup.appMode == ITS) {
                [[ITSController sharedInstance] userDidPlayWord:englishSentenceText context:manipulationContext];
            }
            
            [self.playaudioClass stopPlayAudioFile];
            [self playAudioForVocabWord:englishSentenceText :spanishExt];
        }
    }
}

/*
 *  Handles tap gesture on object
 */
- (void)tapGestureOnObject:(CGPoint)location {
    //Get steps for current sentence
    NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
    
    if ([currSolSteps count] > 0) {
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:TAPTOANIMATE] ||
                 [[currSolStep stepType] isEqualToString:SHAKEORTAP] ||
                 [[currSolStep stepType] isEqualToString:CHECKANDSWAP]) {
            //Get the object at this point
            NSString *imageAtPoint = [self getObjectAtPoint:location ofType:nil];
            
            [[ServerCommunicationController sharedInstance] logTapObject:imageAtPoint :manipulationContext];
            
            //If the correct object was tapped, increment the step
            if ([ssc checkSolutionForSubject:imageAtPoint]) {
                [[ServerCommunicationController sharedInstance] logVerification:true forAction:TAP_OBJECT context:manipulationContext];
                
                if ([[currSolStep stepType] isEqualToString:CHECKANDSWAP]) {
                    [self swapObjectImage];
                }
                
                [ssc incrementCurrentStep];
            }
        }
    }
}

/*
 *  Plays audio for vocab word on story page
 */
- (void)playAudioForVocabWord:(NSString *)englishSentenceText :(NSString *)spanishExt {
    [self highlightImageForText:englishSentenceText];
    
    //Remove any whitespaces since this would cause the a failure for reading the file name
    englishSentenceText = [englishSentenceText stringByReplacingOccurrencesOfString:@" " withString:EMPTYSTRING];
    
    if (conditionSetup.language == BILINGUAL) {
        NSString *spanishAudio = [NSString stringWithFormat:@"%@%@.mp3", [englishSentenceText capitalizedString], S];
        NSString *engAudio = [NSString stringWithFormat:@"%@%@.mp3", [englishSentenceText capitalizedString], E];
        
        if ([spanishExt isEqualToString:EMPTYSTRING] == NO) {
            spanishAudio = [NSString stringWithFormat:@"%@%@.mp3", [englishSentenceText capitalizedString], spanishExt];
        }
        
        //Play Sp audio then En auido
        bool success = [self.playaudioClass playAudioInSequence:self :spanishAudio : engAudio];
        
        if (!success) {
            NSString *spanishAudio = [NSString stringWithFormat:@"%@%@.m4a", englishSentenceText, S];
            NSString *engAudio = [NSString stringWithFormat:@"%@%@.m4a", englishSentenceText, E];
            
            if ([spanishExt isEqualToString:EMPTYSTRING] == NO) {
                spanishAudio = [NSString stringWithFormat:@"%@%@.m4a", englishSentenceText, spanishExt];
            }
            
            [self.playaudioClass playAudioInSequence:self :spanishAudio :engAudio];
        }
        
        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:englishSentenceText inLanguage:SPANISH_TXT ofType:PLAY_WORD :manipulationContext];
        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:englishSentenceText inLanguage:ENGLISH_TXT ofType:PLAY_WORD :manipulationContext];
    }
    else {
        //Play En audio twice
        NSString *engAudio = [NSString stringWithFormat:@"%@%@.mp3", [englishSentenceText capitalizedString], E];
        
        //Play Sp audio then En auido
        bool success = [self.playaudioClass playAudioInSequence:self :engAudio :engAudio];
        
        if (!success) {
            engAudio = [NSString stringWithFormat:@"%@%@.m4a", englishSentenceText, E];
            [self.playaudioClass playAudioInSequence:self :engAudio :engAudio];
        }
        
        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:englishSentenceText inLanguage:ENGLISH_TXT ofType:PLAY_WORD :manipulationContext];
        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:englishSentenceText inLanguage:ENGLISH_TXT ofType:PLAY_WORD :manipulationContext];
    }
}

/*
 *  Plays vocab word audio for intro page
 */
- (void)playIntroVocabWord:(NSString *)englishSentenceText :(ActionStep *)currSolStep {
    if (conditionSetup.language == ENGLISH) {
        //Play En audio
        bool success = [self.playaudioClass playAudioFile:self:[NSString stringWithFormat:@"%@%@.mp3", [englishSentenceText capitalizedString], DEF_E]];
        
        if (!success) {
            //if error try m4a format
            [self.playaudioClass playAudioFile:self:[NSString stringWithFormat:@"%@%@.m4a", englishSentenceText, E]];
        }
        
        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:englishSentenceText inLanguage:ENGLISH_TXT ofType:PLAY_WORD_WITH_DEF :manipulationContext];
    }
    else {
        //Play Sp Audio
        bool success = [self.playaudioClass playAudioFile:self:[NSString stringWithFormat:@"%@%@.mp3",[englishSentenceText capitalizedString],DEF_S]];
        
        if (!success) {
            //if error try m4a format
            [self.playaudioClass playAudioFile:self:[NSString stringWithFormat:@"%@%@.m4a" ,englishSentenceText, S]];
        }
        
        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:englishSentenceText inLanguage:SPANISH_TXT ofType:PLAY_WORD_WITH_DEF :manipulationContext];
    }
    
    [self highlightImageForText:englishSentenceText];
    
    // This delay is needed in order to be able to play the last definition on a vocabulary page
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,[self.playaudioClass audioDuration]*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        //if audioPlayer is nil then we have returned to library view and should not play audio
        if ([self.playaudioClass audioPlayer] != nil) {
            //Play En audio
            bool success = [self.playaudioClass playAudioFile:self:[NSString stringWithFormat:@"%@%@.mp3",[englishSentenceText capitalizedString],DEF_E]];
            
            //Failed to load file with mp3 type, try m4a
            if (!success) {
                //if error try m4a format
                [self.playaudioClass playAudioFile:self:[NSString stringWithFormat:@"%@%@.m4a",englishSentenceText,E]];
            }
            
            [self highlightImageForText:englishSentenceText];
            
            sentenceContext.currentSentence++;
            sentenceContext.currentSentenceText = [self.manipulationView getCurrentSentenceAt:sentenceContext.currentSentence];
            stepContext.stepsComplete = NO;
            
            manipulationContext.sentenceNumber = sentenceContext.currentSentence;
            manipulationContext.sentenceComplexity = [sc getComplexityOfCurrentSentence];
            manipulationContext.sentenceText = sentenceContext.currentSentenceText;
            manipulationContext.manipulationSentence = [sc isManipulationSentence:sentenceContext.currentSentence];
            [[ServerCommunicationController sharedInstance] logLoadSentence:sentenceContext.currentSentence withComplexity:manipulationContext.sentenceComplexity withText:sentenceContext.currentSentenceText manipulationSentence:manipulationContext.manipulationSentence context:manipulationContext];
            
            [sc performSelector:@selector(colorSentencesUponNext) withObject:nil afterDelay:([self.playaudioClass audioPlayer].duration)];
        }
    });
}

/*
 *  Highlights the image of the selected text
 */
- (void)highlightImageForText:(NSString *)englishSentenceText {
    NSObject *valueImage = [[Translation translationImages]objectForKey:englishSentenceText];

    NSString *imageHighlighted = EMPTYSTRING;
    
    if (valueImage == nil) {
        valueImage = englishSentenceText;
    }
    
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
- (IBAction)swipeGesturePerformed:(UISwipeGestureRecognizer *)recognizer {
    //Emergency swipe to bypass the vocab intros
    if ([pageContext.currentPageId containsString:INTRO]) {
        [[ServerCommunicationController sharedInstance] logEmergencySwipe:manipulationContext];
        [self.playaudioClass stopPlayAudioFile];
        [pc loadNextPage];
    }
    //Perform steps only if they exist for the sentence and have not been completed
    else if ((stepContext.numSteps > 0 && !stepContext.stepsComplete && conditionSetup.condition == EMBRACE && conditionSetup.currentMode == PM_MODE) || ([chapterTitle isEqualToString:@"The Naughty Monkey"] && stepContext.numSteps > 0 && !stepContext.stepsComplete)) {
        [[ServerCommunicationController sharedInstance] logEmergencySwipe:manipulationContext];
        
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        NSString *stepType = [currSolStep stepType];
        
        //Check and tap steps will trigger automatic steps, just increment steps
        if ([stepType isEqualToString:CHECK] ||
            [stepType isEqualToString:CHECKLEFT] ||
            [stepType isEqualToString:CHECKRIGHT] ||
            [stepType isEqualToString:CHECKUP] ||
            [stepType isEqualToString:CHECKDOWN] ||
            [stepType isEqualToString:CHECKANDSWAP] ||
            [stepType isEqualToString:TAPTOANIMATE] ||
            [stepType isEqualToString:CHECKPATH] ||
            [stepType isEqualToString:SHAKEORTAP] ||
            [stepType isEqualToString:TAPWORD] ) {
            
            if ([stepType isEqualToString:CHECKANDSWAP]) {
                [self swapObjectImage];
            }
            
            [ssc incrementCurrentStep];
        }
        //Current step is either group, ungroup, disappear, or transference
        else {
            //Get the interaction to be performed
            PossibleInteraction *interaction = [pic getCorrectInteraction];
            
            //Perform the interaction and increment the step
            [pic performInteraction:interaction];
            [ssc incrementCurrentStep];
            
            if ([interaction interactionType] == TRANSFERANDGROUP || [interaction interactionType] == TRANSFERANDDISAPPEAR) {
                [ssc incrementCurrentStep];
            }
        }
        
        if (stepContext.stepsComplete) {
            [self pressedNext:self];
        }
    }
}

/*
 * Pinch gesture. Used to ungroup two images from each other.
 */
- (IBAction)pinchGesturePerformed:(UIPinchGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan && allowInteractions && pinchToUngroup) {
        pinching = TRUE;
        
        NSString *imageAtPoint = [self getObjectAtPoint:location ofType:MANIPULATIONOBJECT];
        
        //if it's an image that can be moved, then start moving it.
        if (imageAtPoint != nil && !stepContext.stepsComplete) {
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
                        if ([ssc checkSolutionForSubject:obj]) {
                            allowSubjectToUngroup = true;
                        }
                    }
                    else if (useSubject == ALL_ENTITIES) {
                        allowSubjectToUngroup = true;
                    }
                    
                    if (useObject == ONLY_CORRECT) {
                        if ([ssc checkSolutionForObject:obj]) {
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
 * Handles beginning of a pan gesture
 */
- (void)panGestureBegan:(CGPoint)location {
    //Starts true because the object starts within the area
    wasPathFollowed = true;
    panning = TRUE;
    
    //Get the object at that point if it's a manipulation object.
    NSString *imageAtPoint = [self getObjectAtPoint:location ofType:MANIPULATIONOBJECT];
    
    //If it's an image that can be moved, then start moving it.
    if (imageAtPoint != nil && !stepContext.stepsComplete) {
        movingObject = TRUE;
        movingObjectId = imageAtPoint;
        
        NSString *imageMarginLeft = [self.manipulationView imageMarginLeft:movingObjectId];
        NSString *imageMarginTop = [self.manipulationView imageMarginTop:movingObjectId];
        
        if (![imageMarginLeft isEqualToString:EMPTYSTRING] && ![imageMarginTop isEqualToString:EMPTYSTRING]) {
            //Calulate offset between top-left corner of image and the point clicked for centered images
            delta = [self calculateDeltaForMovingObjectAtPointWithCenter:movingObjectId :location];
        }
        else {
            //Calculate offset between top-left corner of image and the point clicked.
            delta = [self calculateDeltaForMovingObjectAtPoint:location];
        }
        
        //Record the starting location of the object when it is selected
        startLocation = CGPointMake(location.x - delta.x, location.y - delta.y);
        
        if ([animatingObjects objectForKey:imageAtPoint] && [[animatingObjects objectForKey:imageAtPoint] containsString: ANIMATE]) {
            
            NSArray *animation = [[animatingObjects objectForKey:imageAtPoint] componentsSeparatedByString: @","];
            NSString *animationType = animation[1];
            NSString *animationAreaId = animation[2];
            
            [self.manipulationView animateObject:imageAtPoint from:startLocation to:CGPointZero action:@"pauseAnimation" areaId:EMPTYSTRING];
            
            [animatingObjects setObject:[NSString stringWithFormat:@"%@,%@,%@", PAUSE, animationType, animationAreaId]  forKey:imageAtPoint];
        }
    }
}

/*
 * Handles the end of a pan gesture
 */
- (void)panGestureEnded:(CGPoint)location {
    panning = FALSE;
    BOOL useProximity = NO;
    
    //If moving object, move object to final position.
    if (movingObject) {
        [self moveObject:movingObjectId :location :delta :true];
        NSArray *overlappingWith = [self getObjectsOverlappingWithObject:movingObjectId];
        
        if (stepContext.numSteps > 0) {
            //Get steps for current sentence
            NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
            
            //Get current step to be completed
            ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
            
            //If correct step is of type check
            if ([[currSolStep stepType] isEqualToString:CHECK] ||
                [[currSolStep stepType] isEqualToString:CHECKLEFT] ||
                [[currSolStep stepType] isEqualToString:CHECKRIGHT] ||
                [[currSolStep stepType] isEqualToString:CHECKUP] ||
                [[currSolStep stepType] isEqualToString:CHECKDOWN]) {
                //Check if object is in the correct location or area
                if ((([[currSolStep stepType] isEqualToString:CHECKLEFT] && startLocation.x > endLocation.x ) ||
                     ([[currSolStep stepType] isEqualToString:CHECKRIGHT] && startLocation.x < endLocation.x ) ||
                     ([[currSolStep stepType] isEqualToString:CHECKUP] && startLocation.y > endLocation.y ) ||
                     ([[currSolStep stepType] isEqualToString:CHECKDOWN] && startLocation.y < endLocation.y )) ||
                    ([self isHotspotInsideLocation:false] || [self isHotspotInsideArea])) {
                    
                    if ([ssc checkSolutionForSubject:movingObjectId]) {
                        NSString *destination;
                        
                        if ([currSolStep locationId] != nil) {
                            destination = [currSolStep locationId];
                        }
                        else if ([currSolStep areaId] != nil) {
                            destination = [currSolStep areaId];
                        }
                        else {
                            destination = NULL_TXT;
                        }
                        
                        [[ServerCommunicationController sharedInstance] logMoveObject:movingObjectId toDestination:destination ofType:LOCATION startPos:startLocation endPos:endLocation performedBy:USER context:manipulationContext];
                        
                        [[ServerCommunicationController sharedInstance] logVerification:true forAction:MOVE_OBJECT context:manipulationContext];
                        
                        if (conditionSetup.appMode == ITS) {
                            [[ITSController sharedInstance] movedObjectIDs:[self.manipulationView getSetOfObjectsGroupedWithObject:movingObjectId] destinationIDs:@[destination] isVerified:true actionStep:currSolStep manipulationContext:manipulationContext forSentence:sentenceContext.currentSentenceText withWordMapping:model.wordMapping];
                        }
                        
                        [animatingObjects setObject:STOP forKey:movingObjectId];
                        [ssc incrementCurrentStep];
                    }
                    //Reset object location
                    else {
                        [[ServerCommunicationController sharedInstance] logMoveObject:movingObjectId toDestination:NULL_TXT ofType:LOCATION startPos:startLocation endPos:endLocation performedBy:USER context:manipulationContext];
                        
                        if (conditionSetup.appMode == ITS) {
                            [[ITSController sharedInstance] movedObjectIDs:[self.manipulationView getSetOfObjectsGroupedWithObject:movingObjectId] destinationIDs:overlappingWith isVerified:false actionStep:currSolStep manipulationContext:manipulationContext forSentence:sentenceContext.currentSentenceText withWordMapping:model.wordMapping];
                        }

                        [self handleErrorForAction:MOVE_OBJECT];
                    }
                }
                else {
                    [[ServerCommunicationController sharedInstance] logMoveObject:movingObjectId toDestination:NULL_TXT ofType:LOCATION startPos:startLocation endPos:endLocation performedBy:USER context:manipulationContext];
                    
                    // Find the location if overlapping is nil;
                    if (overlappingWith == nil) {
                        NSString *areaId = [model getObjectIdAtLocation:endLocation];
                        
                        if (areaId)
                            overlappingWith = @[areaId];
                        
                    }
                    
                    if (conditionSetup.appMode == ITS) {
                        [[ITSController sharedInstance] movedObjectIDs:[self.manipulationView getSetOfObjectsGroupedWithObject:movingObjectId] destinationIDs:overlappingWith isVerified:false actionStep:currSolStep manipulationContext:manipulationContext forSentence:sentenceContext.currentSentenceText withWordMapping:model.wordMapping];
                    }

                    [self handleErrorForAction:MOVE_OBJECT];
                }
            }
            else if ([[currSolStep stepType] isEqualToString:SHAKEORTAP]) {
                [[ServerCommunicationController sharedInstance] logMoveObject:movingObjectId toDestination:NULL_TXT ofType:LOCATION startPos:startLocation endPos:endLocation performedBy:USER context:manipulationContext];
                
                if ([ssc checkSolutionForSubject:movingObjectId] && ([self areHotspotsInsideArea] || [self isHotspotInsideLocation:false])) {
                    [[ServerCommunicationController sharedInstance] logVerification:true forAction:MOVE_OBJECT context:manipulationContext];
                    
                    [animatingObjects setObject:STOP forKey:movingObjectId];
                    
                    if (conditionSetup.appMode == ITS) {
                        [[ITSController sharedInstance] movedObjectIDs:[self.manipulationView getSetOfObjectsGroupedWithObject:movingObjectId] destinationIDs:@[currSolStep.locationId] isVerified:true actionStep:currSolStep manipulationContext:manipulationContext forSentence:sentenceContext.currentSentenceText withWordMapping:model.wordMapping];
                    }
                    
                    [self resetObjectLocation];
                    [ssc incrementCurrentStep];
                }
                else {
                    if (conditionSetup.appMode == ITS) {
                        [[ITSController sharedInstance] movedObjectIDs:[self.manipulationView getSetOfObjectsGroupedWithObject:movingObjectId] destinationIDs:@[currSolStep.locationId] isVerified:false actionStep:currSolStep manipulationContext:manipulationContext forSentence:sentenceContext.currentSentenceText withWordMapping:model.wordMapping];
                    }
                
                    [self handleErrorForAction:MOVE_OBJECT];
                }
            }
            else if ([[currSolStep stepType] isEqualToString:CHECKPATH]) {
                [[ServerCommunicationController sharedInstance] logMoveObject:movingObjectId toDestination:NULL_TXT ofType:LOCATION startPos:startLocation endPos:endLocation performedBy:USER context:manipulationContext];
                
                if (wasPathFollowed) {
                    [[ServerCommunicationController sharedInstance] logVerification:true forAction:MOVE_OBJECT context:manipulationContext];
                    
                    [animatingObjects setObject:STOP forKey:movingObjectId];
                    [ssc incrementCurrentStep];
                }
                else {
                    [self handleErrorForAction:MOVE_OBJECT];
                }
            }
            else {
                //Check if the object is overlapping anything
                NSArray *overlappingWith = [self getObjectsOverlappingWithObject:movingObjectId];
                
                //Get possible interactions only if the object is overlapping something
                if (overlappingWith != nil) {
                    [[ServerCommunicationController sharedInstance] logMoveObject:movingObjectId toDestination:[overlappingWith componentsJoinedByString:@", "] ofType:OBJECT startPos:startLocation endPos:endLocation performedBy:USER context:manipulationContext];
                    
                    //Resets allRelationship arrray
                    if ([allRelationships count]) {
                        [allRelationships removeAllObjects];
                    }
                    
                    //If the object was dropped, check if it's overlapping with any other objects that it could interact with.
                    NSMutableArray *possibleInteractions = [self getPossibleInteractions:useProximity];
                    
                    //No possible interactions were found
                    if ([possibleInteractions count] == 0) {
                        if (conditionSetup.appMode == ITS) {
                            [[ITSController sharedInstance] movedObjectIDs:[self.manipulationView getSetOfObjectsGroupedWithObject:movingObjectId] destinationIDs:overlappingWith isVerified:false actionStep:currSolStep manipulationContext:manipulationContext forSentence:sentenceContext.currentSentenceText withWordMapping:model.wordMapping];
                        }
                        
                        [self handleErrorForAction:MOVE_OBJECT];
                    }
                    //If only 1 possible interaction was found, go ahead and perform that interaction if it's correct.
                    else if ([possibleInteractions count] == 1) {
                        PossibleInteraction *interaction = [possibleInteractions objectAtIndex:0];
                        
                        //Checks solution and accomplishes action trace
                        [self checkSolutionForInteraction:interaction];
                    }
                    //If more than 1 was found, prompt the user to disambiguate.
                    else if ([possibleInteractions count] > 1) {
                        PossibleInteraction* correctInteraction = [pic getCorrectInteraction];
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
                            if (!menuExpanded && [PM_CUSTOM isEqualToString:[currSolStep menuType]]) {
                                //Reset allRelationships arrray
                                if ([allRelationships count]) {
                                    [allRelationships removeAllObjects];
                                }
                                
                                PossibleInteraction *interaction;
                                NSMutableArray *interactions = [[NSMutableArray alloc]init ];
                                
                                if (currSolSteps.count != 0 && (currSolSteps.count + 1 - stepContext.currentStep) >= minMenuItems) {
                                    for (int i = (int)(stepContext.currentStep - 1); i < (stepContext.currentStep - 1 + minMenuItems); i++) {
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
                                [pic rankPossibleInteractions:possibleInteractions];
                                
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
                            if (conditionSetup.appMode == ITS) {
                                [[ITSController sharedInstance] movedObjectIDs:[self.manipulationView getSetOfObjectsGroupedWithObject:movingObjectId] destinationIDs:overlappingWith isVerified:false actionStep:currSolStep manipulationContext:manipulationContext forSentence:sentenceContext.currentSentenceText withWordMapping:model.wordMapping];
                            }
                            
                            [self handleErrorForAction:MOVE_OBJECT];
                        }
                    }
                }
                //Not overlapping any object
                else {
                    [[ServerCommunicationController sharedInstance] logMoveObject:movingObjectId toDestination:@"NULL" ofType:@"Location" startPos:startLocation endPos:endLocation performedBy:USER context:manipulationContext];
                    
                    // Find the location if overlapping is nil;
                    if (overlappingWith == nil) {
                        //TODO: Find the object precent in destination location.
                        NSString *areaId = [model getObjectIdAtLocation:endLocation];
                        
                        if (areaId)
                            overlappingWith = @[areaId];
                        
                    }
                    
                    if (conditionSetup.appMode == ITS) {
                        [[ITSController sharedInstance] movedObjectIDs:[self.manipulationView getSetOfObjectsGroupedWithObject:movingObjectId] destinationIDs:overlappingWith isVerified:false actionStep:currSolStep manipulationContext:manipulationContext forSentence:sentenceContext.currentSentenceText withWordMapping:model.wordMapping];
                    }
                    
                    [self handleErrorForAction:MOVE_OBJECT];
                }
            }
        }
        
        if (!menuExpanded) {
            //No longer moving object
            movingObject = FALSE;
            movingObjectId = nil;
        }
        
        [self.manipulationView clearAllHighLighting];
    }
}

/*
 * Handles a pan gesture in progress
 */
- (void)panGestureInProgress:(UIPanGestureRecognizer *)recognizer :(CGPoint)location {
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
                [self.manipulationView highLightObject:objId];
            }
        }
    }
}

/*
 * Pan gesture. Used to move objects from one location to another.
 */
- (IBAction)panGesturePerformed:(UIPanGestureRecognizer *)recognizer {
    //get current coordinate point of gesture
    CGPoint location = [recognizer locationInView:self.view];
    
    //TODO: pinchig functionality currently not utilized
    if (!pinching && allowInteractions) {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            [self panGestureBegan: location];
        }
        //Pangesture has ended: user has removed finger from
        else if (recognizer.state == UIGestureRecognizerStateEnded) {
            [self panGestureEnded: location];
        }
        //If we're in the middle of moving the object, just call the JS to move it.
        else if (movingObject)  {
            [self panGestureInProgress:recognizer:location];
        }
    }
}

//Reset object to start location recorded at beginning of pan gesture
- (void)resetObjectLocation {
    if (allowSnapback) {
        //Snap the object back to its original location
        [self moveObject:movingObjectId :startLocation :CGPointMake(0, 0) :false];
        
        //If it was an animation object, animate it again after snapping back
        if ([animatingObjects objectForKey:movingObjectId] && [[animatingObjects objectForKey:movingObjectId] containsString: PAUSE]) {
            NSArray *animation = [[animatingObjects objectForKey:movingObjectId] componentsSeparatedByString: @","];
            NSString *animationType = animation[1];
            NSString *animationAreaId = animation[2];
        
            [self.manipulationView animateObject:movingObjectId
                                  from:startLocation
                                    to:CGPointZero
                                action:animationType
                                areaId:animationAreaId];
           
            [animatingObjects setObject:[NSString stringWithFormat:@"%@,%@,%@", ANIMATE, animationType, animationAreaId] forKey:movingObjectId];
        }
        
        [[ServerCommunicationController sharedInstance] logResetObject:movingObjectId startPos:endLocation endPos:startLocation context:manipulationContext];
    }
}

/*
 *  Generates a random color for building paths and areas for debugging
 */
- (UIColor *)generateRandomColor {
    NSInteger aRedValue = arc4random() % 255;
    NSInteger aGreenValue = arc4random() % 255;
    NSInteger aBlueValue = arc4random() % 255;
    
    UIColor *randColor = [UIColor colorWithRed:aRedValue/255.0f green:aGreenValue/255.0f blue:aBlueValue/255.0f alpha:1.0f];
    
    return randColor;
}

/*
 *  Returns the current background image of the webview to be utilized for other pages
 */
- (UIImage *)getBackgroundImage{
    return [self.manipulationView getBackgroundImage];
}

/*
 * Gets the necessary information from the JS for this particular image id and creates a
 * MenuItemImage out of that information. If FLIP is TRUE, the image will be horizontally
 * flipped. If the image src isn't found, returns nil. Otherwise, returned the MenuItemImage
 * that was created.
 */
- (MenuItemImage *)createMenuItemForImage:(NSString *)objId :(NSString *)FLIP {
    return [self.manipulationView createMenuItemForImage:objId flip:FLIP];
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


/*
 *  Simulate grouping objects together and calculate the change in position and bounding box
 */
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

/*
 *  Simulate grouping multiple objects (objects that are grouped) and calculate the change in position and bounding box
 */
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

/*
 *  Simulate ungrouping two objects and new positions of each object
 */
- (void)simulateUngrouping:(NSString *)obj1 :(NSString *)obj2 :(NSMutableDictionary *)images :(float)GAP {
    [self.manipulationView simulateUngrouping:obj1 object2:obj2 images:images gap:GAP];
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
 * Calls the JS function to swap an object's image with its alternate one
 */
- (void)swapObjectImage {
    //Check solution only if it exists for the sentence
    if (stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:SWAPIMAGE] || [[currSolStep stepType] isEqualToString:CHECKANDSWAP]) {
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
        
            [self.manipulationView swapImages:object1Id
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
    if (stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:APPEAR] ||
            [[currSolStep stepType] isEqualToString:APPEARAUTOWITHDELAY]) {
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
            
        
            if ([[currSolStep stepType] isEqualToString:APPEAR]) {
               [self.manipulationView loadImage:object1Id
                         alternateSrc:altSrc
                                width:width
                               height:height
                             location:location
                            className:className
                               zIndex:zPosition];
                
                [[ServerCommunicationController sharedInstance] logAppearOrDisappearObject:object1Id ofType:APPEAR_OBJECT context:manipulationContext];
            }
            else if ([[currSolStep stepType] isEqualToString:APPEARAUTOWITHDELAY]) {
                NSInteger delay = [[currSolStep object2Id] intValue];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [self.manipulationView loadImage:object1Id
                              alternateSrc:altSrc
                                     width:width
                                    height:height
                                  location:location
                                 className:className
                                    zIndex:zPosition];
                    
                    [[ServerCommunicationController sharedInstance] logAppearOrDisappearObject:object1Id ofType:APPEAR_OBJECT context:manipulationContext];
                });
            }
        }
    }
}

/*
 * Calls the removeImage from the ImageManipulation.js file
 */
- (void)hideImage {
    if (stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:DISAPPEARAUTO]) {
            NSString *object2Id = [currSolStep object2Id];
            
            //Hide image
            [self.manipulationView removeObject:object2Id];
            [[ServerCommunicationController sharedInstance] logAppearOrDisappearObject:object2Id ofType:DISAPPEAR_OBJECT context:manipulationContext];
        }
        else if ([[currSolStep stepType] isEqualToString:DISAPPEARAUTOWITHDELAY]) {
            NSString *object1Id = [currSolStep object1Id];
            NSInteger delay = [[currSolStep object2Id] intValue];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                //Hide image
                [self.manipulationView removeObject:object1Id];
                
                [[ServerCommunicationController sharedInstance] logAppearOrDisappearObject:object1Id ofType:DISAPPEAR_OBJECT context:manipulationContext];
            });
        }
    }
}

/*
 * Calls the changeZIndex from ImageManipulation.js file
 */
- (void)changeZIndex {
    if (stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:CHANGEZINDEX]) {
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
            [self.manipulationView loadImage:object1Id
                      alternateSrc:altSrc
                             width:width
                            height:EMPTYSTRING
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
- (BOOL)isHotspotInsideLocation:(BOOL)isPreviousStep {
    //Check solution only if it exists for the sentence
    if (stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep;
        if (isPreviousStep) {
            currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 2];
        }
        else{
            currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        }
        
        if ([[currSolStep stepType] isEqualToString:CHECK] ||
            [[currSolStep stepType] isEqualToString:CHECKPATH] ||
            [[currSolStep stepType] isEqualToString:SHAKEORTAP]) {
            //Get information for check step type
            NSString *objectId = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            NSString *locationId = [currSolStep locationId];
            
            //Get hotspot location of correct subject
            Hotspot *hotspot = [model getHotspotforObjectWithActionAndRole:objectId :action :SUBJECT];
            CGPoint hotspotLocation = [self.manipulationView getHotspotLocation:hotspot];
            
            //Get location that hotspot should be inside
            Location *location = [model getLocationWithId:locationId];
            
            //Calculate the x,y coordinates and the width and height in pixels from %
            float locationX = [location.originX floatValue] / 100.0 * [bookView frame].size.width;
            float locationY = [location.originY floatValue] / 100.0 * [bookView frame].size.height;
            float locationWidth = [location.width floatValue] / 100.0 * [bookView frame].size.width;
            float locationHeight = [location.height floatValue] / 100.0 * [bookView frame].size.height;
            
            //Check if hotspot is inside location
            if (((hotspotLocation.x < locationX + locationWidth) && (hotspotLocation.x > locationX)
                 && (hotspotLocation.y < locationY + locationHeight) && (hotspotLocation.y > locationY)) || [locationId isEqualToString:ANYWHERE]) {
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
    if (stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:CHECK] || [[currSolStep stepType] isEqualToString:CHECKPATH]) {
            //Get information for check step type
            NSString *objectId = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            NSString *areaId = [currSolStep areaId];
            
            //Get hotspot location of correct subject
            Hotspot *hotspot = [model getHotspotforObjectWithActionAndRole:objectId :action :SUBJECT];
            CGPoint hotspotLocation = [self.manipulationView getHotspotLocation:hotspot];
            
            //Get area that hotspot should be inside
            Area* area = [model getArea:areaId:pageContext.currentPageId];
            
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
    if (stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:SHAKEORTAP]) {
            //Get information for check step type
            NSString *objectId = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            NSString *areaId = [currSolStep areaId];
            
            //Get hotspot location of correct subject
            Hotspot *hotspot = [model getHotspotforObjectWithActionAndRole:objectId :action :SUBJECT];
            CGPoint hotspotLocation = [self.manipulationView getHotspotLocation:hotspot];
            
            //Get area that hotspot should be inside
            Area *area = [model getArea:areaId : pageContext.currentPageId];
            
            if (([area.aPath containsPoint:hotspotLocation] && [area.aPath containsPoint:startLocation]) || [areaId isEqualToString:ANYWHERE]) {
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
    if (stepContext.numSteps > 0) {
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
        
        //Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        
        if ([[currSolStep stepType] isEqualToString:CHECKPATH]) {
            //Get information for check step type
            NSString *objectId = [currSolStep object1Id];
            NSString *action = [currSolStep action];
            NSString *areaId = [currSolStep areaId];
            
            //Get hotspot location of correct subject
            Hotspot *hotspot = [model getHotspotforObjectWithActionAndRole:objectId :action :SUBJECT];
            CGPoint hotspotLocation = [self.manipulationView getHotspotLocation:hotspot];
            
            //Get area that hotspot should be inside
            Area *area = [model getArea:areaId :pageContext.currentPageId];
            
            if ([area.aPath containsPoint:hotspotLocation]) {
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
    [self.manipulationView hideCanvas];
    
    //Retrieve the elements at this location and see if it's an element that is moveable
    NSString *imageAtPoint = [self.manipulationView getElementAtLocation:location];
    NSString *imageAtPointClass = [self.manipulationView getClassForElemAtLocation:location];
    
    //Bring the canvas back to where it should be.
    [self.manipulationView showCanvas];
    
    //Check if the object has the correct class, or if no class was specified before returning
    if (((class == nil) || (![imageAtPointClass isEqualToString:EMPTYSTRING] && [imageAtPointClass containsString:class]))) {
        //Any subject can be used, so just return the object id
        if (useSubject == ALL_ENTITIES)
            return imageAtPoint;
        //Check if the subject is correct before returning the object id
        else if (useSubject == ONLY_CORRECT) {
            if ([ssc checkSolutionForSubject:imageAtPoint])
                return imageAtPoint;
        }
       
    }
    
    return nil;
}

/*
 * Checks if an interaction is correct by comparing it to the solution. If it is correct, the interaction is performed and
 * the current step is incremented. If it is incorrect, an error noise is played, and the objects snap back to their
 * original positions.
 */
//TODO: move logic in if else statements into new functions
- (void)checkSolutionForInteraction:(PossibleInteraction *)interaction {
    //Get correct interaction to compare
    PossibleInteraction *correctInteraction = [pic getCorrectInteraction];
    
    //Check if selected interaction is correct
    if ([interaction isEqual:correctInteraction]) {
        if (conditionSetup.condition == EMBRACE && conditionSetup.currentMode == IM_MODE) {
            [[ServerCommunicationController sharedInstance] logVerification:true forAction:SELECT_MENU_ITEM context:manipulationContext];
            
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
        }
        else if (conditionSetup.condition == EMBRACE && conditionSetup.currentMode == PM_MODE) {
            if (menu) {
                [[ServerCommunicationController sharedInstance] logVerification:true forAction:SELECT_MENU_ITEM context:manipulationContext];
                
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
            }
            
            if (conditionSetup.appMode == ITS) {
                Connection *con = [interaction.connections objectAtIndex:0];
                NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
                ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
                
                [[ITSController sharedInstance] movedObjectIDs:[self.manipulationView getSetOfObjectsGroupedWithObject:[con.objects objectAtIndex:0]] destinationIDs:@[[con.objects objectAtIndex:1]] isVerified:true actionStep:currSolStep manipulationContext:manipulationContext forSentence:sentenceContext.currentSentenceText withWordMapping:model.wordMapping];
            }
            
            [pic performInteraction:interaction];
        }
        
        if (conditionSetup.condition == EMBRACE && conditionSetup.currentMode == PM_MODE) {
            [ssc incrementCurrentStep];
        }
        
        //Transference counts as two steps, so we must increment again
        if ([interaction interactionType] == TRANSFERANDGROUP ||
            [interaction interactionType] == TRANSFERANDDISAPPEAR) {
            if (conditionSetup.condition == EMBRACE && conditionSetup.currentMode == PM_MODE) {
                [ssc incrementCurrentStep];
            }
        }
    }
    else {
        NSString *action;
        
        if (menu != nil) {
            action = SELECT_MENU_ITEM;
        }
        else {
            action = MOVE_OBJECT;
        }
        
        if (conditionSetup.appMode == ITS) {
            Connection *con = [interaction.connections objectAtIndex:0];
            NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
            ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
            
            [[ITSController sharedInstance] movedObjectIDs:[self.manipulationView getSetOfObjectsGroupedWithObject:[con.objects objectAtIndex:0]] destinationIDs:@[[con.objects objectAtIndex:1]] isVerified:false actionStep:currSolStep manipulationContext:manipulationContext forSentence:sentenceContext.currentSentenceText withWordMapping:model.wordMapping];
        }
        
        [self handleErrorForAction:action];
    }
    
    //Clear any remaining highlighting
    [self.manipulationView clearAllHighLighting];
}

/*
 * Handles errors by logging the action, playing a noise, and resetting the object location.
 * The ITS will check if the user's number of attempts has reached the maximum number of attempts; if so, it will
 * automatically perform the step.
 */
- (void)handleErrorForAction:(NSString *)action {
    allowInteractions = FALSE;
    [self.view setUserInteractionEnabled:NO];
    
    [[ServerCommunicationController sharedInstance] logVerification:false forAction:action context:manipulationContext];
    
    [self playNoiseName:ERROR_NOISE];
    [self resetObjectLocation];
    
    stepContext.numAttempts++;
    
    double delay = 0.0;
    
    if (conditionSetup.appMode == ITS && conditionSetup.shouldShowITSMessages == YES) {
        delay = 5.5;
    }
    
    if (stepContext.numAttempts >= stepContext.maxAttempts) {
        stepContext.numAttempts = 0;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self provideFeedbackForErrorType:@"usability"];
        });
    }
    else {
        if (conditionSetup.appMode == ITS) {
            BOOL showDemo = FALSE;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                NSString *mostProbableErrorType = [[ITSController sharedInstance] getMostProbableErrorType];
                
                // NOTE: Temporary UIAlertView to select most appropriate error feedback type
                if (showDemo) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Select the most probable error type:" preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"Vocabulary" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                        [self provideFeedbackForErrorType:@"vocabulary"];
                    }]];
                    [alert addAction:[UIAlertAction actionWithTitle:@"Syntax" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                        [self provideFeedbackForErrorType:@"syntax"];
                    }]];
                    [alert addAction:[UIAlertAction actionWithTitle:@"Usability" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                        [self provideFeedbackForErrorType:@"usability"];
                    }]];
                    [alert addAction:[UIAlertAction actionWithTitle:@"None" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                        allowInteractions = TRUE;
                        [self.view setUserInteractionEnabled:YES];
                    }]];
                    [self presentViewController:alert animated:YES completion:nil];
                }
                else {
                    if (mostProbableErrorType != nil) {
                        [self provideFeedbackForErrorType:mostProbableErrorType];
                    }
                    else {
                        allowInteractions = TRUE;
                        [self.view setUserInteractionEnabled:YES];
                    }
                }
            });
        }
        else {
            allowInteractions = TRUE;
            [self.view setUserInteractionEnabled:YES];
        }
    }
}

// TODO: Change error type NSString to enum
- (void)provideFeedbackForErrorType:(NSString *)errorType {
    if ([errorType isEqualToString:@"vocabulary"]) {
        [self playNoiseName:ERROR_FEEDBACK_NOISE];
        
        // Record highlighted objects/locations for logging
        NSMutableArray *highlightedItems = [[NSMutableArray alloc] init];
        
        // Get steps for current sentence
        NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
        
        // Get current step to be completed
        ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
        NSString *stepType = [currSolStep stepType];
        
        // Highlight correct object and location
        if ([stepType isEqualToString:CHECK] || [stepType isEqualToString:CHECKLEFT] || [stepType isEqualToString:CHECKRIGHT] || [stepType isEqualToString:CHECKUP] || [stepType isEqualToString:CHECKDOWN] || [stepType isEqualToString:CHECKANDSWAP] || [stepType isEqualToString:TAPTOANIMATE] || [stepType isEqualToString:CHECKPATH] || [stepType isEqualToString:SHAKEORTAP] || [stepType isEqualToString:TAPWORD] ) {
            
            NSString *object1Id = [currSolStep object1Id];
            NSString *locationId = [currSolStep locationId];
            
            if ([locationId isEqualToString:EMPTYSTRING]) {
                locationId = [currSolStep areaId];
            }
            
            [highlightedItems addObject:object1Id];
            [highlightedItems addObject:locationId];
            
            [[ServerCommunicationController sharedInstance] logVocabularyErrorFeedback:highlightedItems context:manipulationContext];
            
            [self highlightImageForText:object1Id];
            
            if ([model getLocationWithId:locationId] || [model getAreaWithId:locationId]) {
                [self highlightObject:locationId :1.5];
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                allowInteractions = TRUE;
                [self.view setUserInteractionEnabled:YES];
            });
        }
        // Highlight correct objects for transference
        else if ([stepType isEqualToString:TRANSFERANDGROUP_TXT] || [stepType isEqualToString:TRANSFERANDDISAPPEAR_TXT]) {
            NSString *object1Id = [currSolStep object1Id];
            ActionStep *nextSolStep = [currSolSteps objectAtIndex:stepContext.currentStep];
            
            if (nextSolStep != nil && ([[nextSolStep stepType] isEqualToString:TRANSFERANDGROUP_TXT] || [stepType isEqualToString:TRANSFERANDDISAPPEAR_TXT])) {
                NSString *nextObject1Id = [nextSolStep object1Id];
                
                if ([nextObject1Id isEqualToString:[currSolStep object2Id]]) {
                    nextObject1Id = [nextSolStep object2Id];
                }
                
                [highlightedItems addObject:object1Id];
                [highlightedItems addObject:nextObject1Id];
                
                [[ServerCommunicationController sharedInstance] logVocabularyErrorFeedback:highlightedItems context:manipulationContext];
                
                [self highlightImageForText:object1Id];
                [self highlightImageForText:nextObject1Id];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    allowInteractions = TRUE;
                    [self.view setUserInteractionEnabled:YES];
                });
            }
        }
        // Highlight correct objects
        else {
            NSString *object1Id = [currSolStep object1Id];
            NSString *object2Id = [currSolStep object2Id];
            
            [highlightedItems addObject:object1Id];
            [highlightedItems addObject:object2Id];
            
            [[ServerCommunicationController sharedInstance] logVocabularyErrorFeedback:highlightedItems context:manipulationContext];
            
            [self highlightImageForText:object1Id];
            [self highlightImageForText:object2Id];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                allowInteractions = TRUE;
                [self.view setUserInteractionEnabled:YES];
            });
        }
    }
    else if ([errorType isEqualToString:@"syntax"]) {
        NSMutableArray *simplerSentences = [[NSMutableArray alloc] init];
        
        if (currentComplexity > 1) {
            Chapter *chapter = [book getChapterWithTitle:chapterTitle]; // Get current chapter
            PhysicalManipulationActivity *PMActivity = (PhysicalManipulationActivity *)[chapter getActivityOfType:PM_MODE]; // Get PM Activity from chapter
            
            // Get steps for current sentence
            NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
            
            // Get current step to be completed
            ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
            
            // Look for simpler version of the current sentence
            for (AlternateSentence *alternateSentence in [[PMActivity alternateSentences] objectForKey:pageContext.currentPageId]) {
                if ([alternateSentence complexity] == currentComplexity - 1) {
                    for (NSNumber *idea in [[sentenceContext.pageSentences objectAtIndex:sentenceContext.currentSentence - 1] ideas]) {
                        if ([[alternateSentence ideas] containsObject:idea]) {
                            // Add sentences with no solution steps if they share the same idea
                            if ([[alternateSentence solutionSteps] count] == 0) {
                                [simplerSentences addObject:[alternateSentence text]];
                                break;
                            }
                            else {
                                // Add sentences with solution steps only if they share the same idea and current step
                                for (ActionStep *solutionStep in [alternateSentence solutionSteps]) {
                                    if ([solutionStep stepNumber] == [currSolStep stepNumber]) {
                                        [simplerSentences addObject:[alternateSentence text]];
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                allowInteractions = TRUE;
                [self.view setUserInteractionEnabled:YES];
            });
        }
        
        // Present simpler sentence(s)
        if ([simplerSentences count] > 0) {
            // Join sentences together and remove any slash characters
            NSString *message = [[simplerSentences componentsJoinedByString:@" "] stringByReplacingOccurrencesOfString:@"\\" withString:EMPTYSTRING];
            
            [[ServerCommunicationController sharedInstance] logSyntaxErrorFeedback:message context:manipulationContext];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:action];
            [self presentViewController:alert animated:YES completion:nil];
            
            [self playNoiseName:ERROR_FEEDBACK_NOISE];
            allowInteractions = TRUE;
            [self.view setUserInteractionEnabled:YES];
        }
        // Default to usability error feedback if there are no simpler sentences available
        else {
            // Log attempted syntax error feedback
            [[ServerCommunicationController sharedInstance] logSyntaxErrorFeedback:@"NULL" context:manipulationContext];
            
            [self provideFeedbackForErrorType:@"usability"];
        }
    }
    else if ([errorType isEqualToString:@"usability"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Need help? The iPad will show you how to complete this step." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action)
                          {
                              [self animatePerformingStep];
                          }]];
        [self presentViewController:alert animated:YES completion:nil];
        
        [self playNoiseName:ERROR_FEEDBACK_NOISE];
    }
}

/*
 * Checks if one object is contained inside another object and returns the contained object
 */
- (NSString *)findContainedObject:(NSArray *)objects {
    return [self.manipulationView findContainedObject:objects];
}

/*
 *  Returns an msmutablearray if possible interactions based on objects in proximity and current item groupings
 */
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
    BOOL objectIDUsed = false;
    NSString *tempCollisionObject = nil;
    
    if (overlappingWith != nil) {
        for (NSString *objId in overlappingWith) {
            //If only the correct object can be used, then check if the overlapping object is correct. If it is not, do not get any possible interactions for it.
            BOOL getInteractions = TRUE;
            
            if (useObject == ONLY_CORRECT) {
                if (![ssc checkSolutionForObject:objId]) {
                    getInteractions = FALSE;
                    
                    if (!objectIDUsed) {
                        objectIDUsed = true;
                        tempCollisionObject = objId;
                    }
                }
            }
            
            if (getInteractions) {
                objectIDUsed = true;
                tempCollisionObject = objId;
                
                NSMutableArray *hotspots = [model getHotspotsForObject:objId OverlappingWithObject:obj];
                NSMutableArray *movingObjectHotspots = [model getHotspotsForObject:obj OverlappingWithObject:objId];
                
                //Compare hotspots of the two objects.
                for (Hotspot *hotspot in hotspots) {
                    for (Hotspot *movingObjectHotspot in movingObjectHotspots) {
                        //Need to calculate exact pixel locations of both hotspots and then make sure they're within a specific distance of each other.
                        CGPoint movingObjectHotspotLoc = [self.manipulationView getHotspotLocation:movingObjectHotspot];
                        CGPoint hotspotLoc = [self.manipulationView getHotspotLocation:hotspot];
                        
                        NSString *isHotspotConnectedObjectString = [self.manipulationView groupedObject:objId atHotSpot:hotspotLoc];
                        NSString *isHotspotConnectedMovingObjectString  = [self.manipulationView groupedObject:obj atHotSpot:movingObjectHotspotLoc];
                        bool rolesMatch = [[hotspot role] isEqualToString:[movingObjectHotspot role]];
                        bool actionsMatch = [[hotspot action] isEqualToString:[movingObjectHotspot action]];
                        
                        //Make sure the two hotspots have the same action. It may also be necessary to ensure that the roles do not match. Also make sure neither of the hotspots are connected to another object.
                        if (actionsMatch
                            && ![self.manipulationView isObjectGrouped:obj atHotSpot:movingObjectHotspotLoc]
                            && ![self.manipulationView isObjectGrouped:objId atHotSpot:hotspotLoc]
                            && !rolesMatch) {
                            //Although the matching hotspots are free, transference may still be possible if one of the objects is connected at a different hotspot that must be ungrouped first.
                            NSString *objTransferringObj = [self getObjectPerformingTransference:obj :objId :OBJECT];
                            NSString *objTransferringObjId = [self getObjectPerformingTransference:objId :obj :SUBJECT];
                            
                            //Transference is possible
                            if (objTransferringObj != nil && objTransferringObjId == nil) {
                                [groupings addObjectsFromArray:[pic getPossibleTransferInteractionsforObjects:obj :objTransferringObj :objId :movingObjectHotspot :hotspot]];
                            }
                            else if (objTransferringObjId != nil && objTransferringObj == nil) {
                                [groupings addObjectsFromArray:[pic getPossibleTransferInteractionsforObjects:objId :objTransferringObjId :obj :hotspot :movingObjectHotspot]];
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
                                    
                                    if ([[relationshipBetweenObjects actionType] isEqualToString:GROUP_TXT]) {
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
                                    else if ([[relationshipBetweenObjects actionType] isEqualToString:DISAPPEAR_TXT]) {
                                        PossibleInteraction *interaction = [[PossibleInteraction alloc] initWithInteractionType:DISAPPEAR];
                                        
                                        //Add the subject of the disappear interaction before the object
                                        if ([[movingObjectHotspot role] isEqualToString:SUBJECT]) {
                                            objects = [[NSArray alloc] initWithObjects:obj, objId, nil];
                                            hotspotsForInteraction = [[NSArray alloc] initWithObjects:movingObjectHotspot, hotspot, nil];
                                        }
                                        else if ([[movingObjectHotspot role] isEqualToString:OBJECT]) {
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
                                 && ![isHotspotConnectedMovingObjectString isEqualToString:EMPTYSTRING]
                                 && [isHotspotConnectedObjectString isEqualToString:EMPTYSTRING]
                                 && !rolesMatch) {
                            [groupings addObjectsFromArray:[pic getPossibleTransferInteractionsforObjects:obj :isHotspotConnectedMovingObjectString :objId :movingObjectHotspot :hotspot]];
                        }
                        else if (actionsMatch
                                 && [isHotspotConnectedMovingObjectString isEqualToString:EMPTYSTRING]
                                 && ![isHotspotConnectedObjectString isEqualToString:EMPTYSTRING]
                                 && !rolesMatch) {
                            [groupings addObjectsFromArray:[pic getPossibleTransferInteractionsforObjects:objId :isHotspotConnectedObjectString :obj :hotspot :movingObjectHotspot]];
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
            CGPoint transferredObjHotspotLoc = [self.manipulationView getHotspotLocation:transferredObjHotspot];
            
            //Get the object that the transferred object is connected to at this hotspot
            NSString *isHotspotConnectedString = [self.manipulationView groupedObject:transferredObj atHotSpot:transferredObjHotspotLoc];
            
            if (![isHotspotConnectedString isEqualToString:EMPTYSTRING]) {
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

/*
 * Returns an array containing pairs of grouped objects (with the format "hay, farmer") connected to the object specified
 */
- (NSArray *)getObjectsGroupedWithObject:(NSString *)object {
    return [self.manipulationView getObjectsGroupedWithObject:object];
}

/*
 * Returns an array containing objects that are overlapping with the object specified
 */
- (NSArray *)getObjectsOverlappingWithObject:(NSString *)object {
    return [self.manipulationView getObjectsOverlappingWithObject:object movingObject:movingObjectId];
}

/*
 * Checks an object's array of hotspots to determine if one is connected to a specific object and returns that hotspot
 */
- (Hotspot *)findConnectedHotspot:(NSMutableArray *)movingObjectHotspots :(NSString *)objConnectedTo {
    Hotspot *connectedHotspot = NULL;
    
    for (Hotspot *movingObjectHotspot in movingObjectHotspots) {
        //Get the hotspot location
        CGPoint movingObjectHotspotLoc = [self.manipulationView getHotspotLocation:movingObjectHotspot];
        
        //Check if this hotspot is currently in use
        NSString *isHotspotConnectedMovingObjectString  = [self.manipulationView groupedObject:movingObjectId atHotSpot:movingObjectHotspotLoc];
        
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
                        CGPoint hotspotLocation = [self.manipulationView getHotspotLocation:hotspot];
                        
                        //Check if this hotspot is currently connected to another object
                        NSString *isHotspotConnectedString = [self.manipulationView groupedObject:object atHotSpot:hotspotLocation];
                        //Hotspot is connected to another object
                        if (![isHotspotConnectedString isEqualToString:EMPTYSTRING]) {
                            for (ComboConstraint *comboConstraint in objectComboConstraints) {
                                //Get the list of actions for the combo constraint
                                NSMutableArray *comboActions = [comboConstraint comboActions];
                                
                                for (NSString *comboAction in comboActions) {
                                    //Get the hotspot associated with the action, assuming the
                                    //role as subject. Also get the hotspot location.
                                    Hotspot *comboHotspot = [model getHotspotforObjectWithActionAndRole:[comboConstraint objId] :comboAction :SUBJECT];
                                    CGPoint comboHotspotLocation;
                                    
                                    if (comboHotspot != nil) {
                                        comboHotspotLocation = [self.manipulationView getHotspotLocation:comboHotspot];
                                    }
                                    else {
                                        //If no hotspot was found assuming the role as subject,
                                        //then the role must be object.
                                        comboHotspot = [model getHotspotforObjectWithActionAndRole:[comboConstraint objId] :comboAction :OBJECT];
                                        comboHotspotLocation = [self.manipulationView getHotspotLocation:comboHotspot];
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
 * Checks to see whether two hotspots are within grouping proximity.
 * Returns true if they are, false otherwise.
 */
- (BOOL)hotspotsWithinGroupingProximity:(Hotspot *)hotspot1 :(Hotspot *)hotspot2 {
    CGPoint hotspot1Loc = [self.manipulationView getHotspotLocation:hotspot1];
    CGPoint hotspot2Loc = [self.manipulationView getHotspotLocation:hotspot2];
    
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
    return [self.manipulationView deltaForMovingObjectAtPoint:location];
}

/*
 * Calculates the delta pixel change for the object that is being moved
 * and changes the lcoation from relative % to pixels if necessary.
 */
- (CGPoint)calculateDeltaForMovingObjectAtPointWithCenter:(NSString *)object :(CGPoint)location {
    return [self.manipulationView deltaForMovingObjectAtPointWithCenter:object :location];
}

/*
 * Moves the object passed in to the location given. Calculates the difference between the point touched and the
 * top-left corner of the image, which is the x,y coordate that's actually used when moving the object.
 * Also ensures that the image is not moved off screen or outside of any specified bounding boxes for the image.
 * Updates the JS Connection hotspot locations if necessary.
 */
- (void)moveObject:(NSString *)object :(CGPoint)location :(CGPoint)offset :(BOOL)updateCon {
    endLocation = [self.manipulationView moveObject:object
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
    [self.manipulationView groupObjects:object1
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
    
    [self.manipulationView ungroupObjects:object1 object2:object2];
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

    [self.manipulationView ungroupObjectsAndStay:object1 object2:object2];
}

/*
 * Call JS code to cause the object to disappear, then calculate where it needs to re-appear and call the JS code to make
 * it re-appear at the new location.
 */
- (void)consumeAndReplenishSupply:(NSString *)disappearingObject {
    CGPoint point = [self.manipulationView consumeAndReplenishSupply:disappearingObject
                                           shouldReplenish:replenishSupply
                                                     model:model
                                              movingObject:movingObjectId
                                             startLocation:startLocation
                                                 shouldPan:NO];
    if (point.x != -99) {
        endLocation = point;
    }
}

/*
 * Calls the JS function to draw each individual hotspot in the array provided
 * with the color specified.
 */
- (void)drawHotspots:(NSMutableArray *)hotspots :(NSString *)color{
    [self.manipulationView drawHotspots:hotspots color:color];
}


/*
 * Returns the hotspot location in pixels based on the object image size
 */
- (CGPoint)getHotspotLocationOnImage:(Hotspot *)hotspot {
    return [self.manipulationView getHotspotLocationOnImage:hotspot];
}

/*
 * Returns the waypoint location in pixels based on the background size
 */
- (CGPoint)getWaypointLocation:(Waypoint *)waypoint {
    return [self.manipulationView getWaypointLocation:waypoint];
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

- (void)pressedNextIntro {
    if (sentenceContext.currentSentence > sentenceContext.totalSentences) {
        [self.playaudioClass stopPlayAudioFile];
        
        sentenceContext.currentSentence = 1;
        
        manipulationContext.sentenceNumber = sentenceContext.currentSentence;
        manipulationContext.sentenceComplexity = [sc getComplexityOfCurrentSentence];
        manipulationContext.sentenceText = sentenceContext.currentSentenceText;
        manipulationContext.manipulationSentence = [sc isManipulationSentence:sentenceContext.currentSentence];
        
        [pc loadNextPage];
    }
    else if (sentenceContext.currentSentence == sentenceContext.totalSentences &&
             [bookTitle containsString:@"Introduction to EMBRACE - Unknown"]) {
        [self.playaudioClass stopPlayAudioFile];
        
        sentenceContext.currentSentence = 1;
        
        manipulationContext.sentenceNumber = sentenceContext.currentSentence;
        manipulationContext.sentenceComplexity = [sc getComplexityOfCurrentSentence];
        manipulationContext.sentenceText = sentenceContext.currentSentenceText;
        manipulationContext.manipulationSentence = [sc isManipulationSentence:sentenceContext.currentSentence];
        
        [pc loadNextPage];
    }
    else {
        [self.view setUserInteractionEnabled:YES];
    }
}

/*
 *  Handles moving to next sentence, page, IMMenu, or assessment
 */
- (void)pressedNextStory{
    NSString *sentenceClass = [self.manipulationView getSentenceClass:sentenceContext.currentSentence];
    
    if ((conditionSetup.condition == EMBRACE && conditionSetup.currentMode == IM_MODE) && ([sentenceClass containsString: @"sentence actionSentence"] || [sentenceClass containsString: @"sentence IMactionSentence"])) {
        //Reset allRelationships arrray
        if ([allRelationships count]) {
            [allRelationships removeAllObjects];
        }
        
        //Get steps for current sentence
        NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
        
        if (currSolSteps.count != 0 && !didSelectCorrectMenuOption) {
            [self createIMMenuPage];
        }
        else {
            //For the moment just move through the sentences, until you get to the last one, then move to the next activity.
            if (sentenceContext.currentSentence > 0) {
                sentenceContext.currentIdea++;
                manipulationContext.ideaNumber = sentenceContext.currentIdea;
            }
            
            didSelectCorrectMenuOption = false;
            sentenceContext.currentSentence++;
            sentenceContext.currentSentenceText = [self.manipulationView getCurrentSentenceAt:sentenceContext.currentSentence];
            manipulationContext.sentenceNumber = sentenceContext.currentSentence;
            manipulationContext.sentenceComplexity = [sc getComplexityOfCurrentSentence];
            manipulationContext.sentenceText = sentenceContext.currentSentenceText;
            manipulationContext.manipulationSentence = [sc isManipulationSentence:sentenceContext.currentSentence];
            [[ServerCommunicationController sharedInstance] logLoadSentence:sentenceContext.currentSentence withComplexity:manipulationContext.sentenceComplexity withText:sentenceContext.currentSentenceText manipulationSentence:manipulationContext.manipulationSentence context:manipulationContext];
            
            //currentSentence is 1 indexed.
            if (sentenceContext.currentSentence > sentenceContext.totalSentences) {
                [pc loadNextPage];
            }
            else {
                //Set up current sentence appearance and solution steps
                [sc setupCurrentSentence];
                [sc colorSentencesUponNext];
                [self playCurrentSentenceAudio];
            }
        }
    }
    else if (stepContext.stepsComplete || stepContext.numSteps == 0 || (allowInteractions && ([chapterTitle isEqualToString:@"The Naughty Monkey"] && [pageContext.currentPageId containsString:PM2] && conditionSetup.condition == EMBRACE && !stepContext.stepsComplete && sentenceContext.currentSentence == 2)) || (!allowInteractions && ![chapterTitle isEqualToString:@"The Naughty Monkey"]) || (!allowInteractions && ([chapterTitle isEqualToString:@"The Naughty Monkey"] && [pageContext.currentPageId containsString:PM2] && conditionSetup.condition == CONTROL && stepContext.stepsComplete && sentenceContext.currentSentence == 2)) || (!allowInteractions && ([chapterTitle isEqualToString:@"The Naughty Monkey"] && conditionSetup.condition == CONTROL && !stepContext.stepsComplete && sentenceContext.currentSentence != 2))) {
        if (sentenceContext.currentSentence > 0) {
            sentenceContext.currentIdea++;
            manipulationContext.ideaNumber = sentenceContext.currentIdea;
        }
        
        sentenceContext.currentSentence++;
        sentenceContext.currentSentenceText = [self.manipulationView getCurrentSentenceAt:sentenceContext.currentSentence];
        manipulationContext.sentenceNumber = sentenceContext.currentSentence;
        manipulationContext.sentenceComplexity = [sc getComplexityOfCurrentSentence];
        manipulationContext.sentenceText = sentenceContext.currentSentenceText;
        manipulationContext.manipulationSentence = [sc isManipulationSentence:sentenceContext.currentSentence];
        [[ServerCommunicationController sharedInstance] logLoadSentence:sentenceContext.currentSentence withComplexity:manipulationContext.sentenceComplexity withText:sentenceContext.currentSentenceText manipulationSentence:manipulationContext.manipulationSentence context:manipulationContext];
        
        //currentSentence is 1 indexed
        if (sentenceContext.currentSentence > sentenceContext.totalSentences) {
            [pc loadNextPage];
        }
        else {
            //Set up current sentence appearance and solution steps
            [sc setupCurrentSentence];
            [sc colorSentencesUponNext];
            [self playCurrentSentenceAudio];
        }
    }
    else {
        [[ServerCommunicationController sharedInstance] logVerification:false forAction:@"Press Next" context:manipulationContext];
        
        //Play noise if not all steps have been completed
        [self playNoiseName:ERROR_NOISE];
        [self.view setUserInteractionEnabled:YES];
    }
}

/*
 *  Creates the IMMenu page for im solutions
 */
- (void)createIMMenuPage{
    //Get steps for current sentence
    NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
    
    PossibleInteraction *interaction;
    NSMutableArray *interactions = [[NSMutableArray alloc] init];
    
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
    IMViewMenu = [[UIView alloc] initWithFrame:[bookView frame]];
    IMViewMenu.backgroundColor = [UIColor whiteColor];
    UILabel *IMinstructions = [[UILabel alloc] initWithFrame:CGRectMake(200, 10, IMViewMenu.frame.size.width, 40)];
    
    IMinstructions.center = CGPointMake(IMViewMenu.frame.size.width  / 2, 40);
    IMinstructions.text = IM_INSTRUCTIONS;
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

/*
 * Button listener for the "Next" button. This function moves to the next active sentence in the story, or to the
 * next story if at the end of the current story. Eventually, this function will also ensure that the correctness
 * of the interaction is checked against the current sentence before moving on to the next sentence. If the manipulation
 * is correct, then it will move on to the next sentence. If the manipulation is not current, then feedback will be provided.
 */
- (IBAction)pressedNext:(id)sender {
    @synchronized(self) {
        if (!pressedNextLock && !isLoadPageInProgress) {
            pressedNextLock = true;
            [self.view setUserInteractionEnabled:NO];
            
            [[ServerCommunicationController sharedInstance] logPressNextInManipulationActivity:manipulationContext];
            
            //NSString *preAudio = [bookView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById(preaudio)"]];
            
            if ([pageContext.currentPageId containsString:DASH_INTRO]) {
                [self pressedNextIntro];
            }
            else {
                [self pressedNextStory];
            }
            
            pressedNextLock = false;
        }
    }
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

- (void)playNoiseName:(NSString *)name {
    if ([name isEqualToString:ERROR_NOISE]) {
        [self.playaudioClass playErrorNoise];
        
        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:ERROR_NOISE inLanguage:NULL_TXT ofType:PLAY_ERROR_NOISE :manipulationContext];
    }
    else if ([name isEqualToString:ERROR_FEEDBACK_NOISE]) {
        [self.playaudioClass playErrorFeedbackNoise];
        
        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:ERROR_FEEDBACK_NOISE inLanguage:NULL_TXT ofType:ERROR_FEEDBACK_NOISE :manipulationContext];
    }
}

- (void)animatePerformingStep {
    // Get steps for current sentence
    NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
    
    // Get current step to be completed
    ActionStep *currSolStep = [currSolSteps objectAtIndex:stepContext.currentStep - 1];
    NSString *stepType = [currSolStep stepType];
    
    // Record animated objects/locations for logging
    NSMutableArray *animatedItems;
    
    if (conditionSetup.appMode == ITS) {
        animatedItems = [[NSMutableArray alloc] init];
    }
    
    // Animate moving object to location
    if ([stepType isEqualToString:CHECK] || [stepType isEqualToString:CHECKLEFT] || [stepType isEqualToString:CHECKRIGHT] || [stepType isEqualToString:CHECKUP] || [stepType isEqualToString:CHECKDOWN] || [stepType isEqualToString:CHECKANDSWAP] || [stepType isEqualToString:TAPTOANIMATE] || [stepType isEqualToString:CHECKPATH] || [stepType isEqualToString:SHAKEORTAP] || [stepType isEqualToString:TAPWORD] ) {
        if ([stepType isEqualToString:CHECK]) {
            NSString *object1Id = [currSolStep object1Id];
            ActionStep *nextSolStep = [currSolSteps objectAtIndex:stepContext.currentStep];
            
            if (nextSolStep != nil && [[nextSolStep stepType] isEqualToString:MOVE] && [[nextSolStep object1Id] isEqualToString:object1Id]) {
                Hotspot *object1Hotspot = [model getHotspotforObjectWithActionAndRole:object1Id :[currSolStep action] :SUBJECT];
                CGPoint object1HotspotLocation = [self.manipulationView getHotspotLocation:object1Hotspot];
                
                Waypoint *waypoint = [model getWaypointWithId:[nextSolStep waypointId]];
                CGPoint waypointLocation = [self getWaypointLocation:waypoint];
                
                if (conditionSetup.appMode == ITS) {
                    [animatedItems addObject:object1Id];
                    [animatedItems addObject:[waypoint waypointId]];
                    
                    [[ServerCommunicationController sharedInstance] logUsabilityErrorFeedback:animatedItems context:manipulationContext];
                }
                
                [self highlightObject:object1Id :2.0];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    movingObjectId = object1Id;
                    
                    [self.manipulationView animateObject:object1Id from:object1HotspotLocation to:waypointLocation action:MOVETOLOCATION areaId:EMPTYSTRING];
                    [[ServerCommunicationController sharedInstance] logAnimateObject:object1Id forAction:[currSolStep action] context:manipulationContext];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        [self highlightObject:object1Id :2.0];
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            allowInteractions = TRUE;
                            [self.view setUserInteractionEnabled:YES];
                            [ssc incrementCurrentStep];
                        });
                    });
                });
            }
            else {
                if (conditionSetup.appMode == ITS) {
                    // Log attempted usability error feedback
                    [[ServerCommunicationController sharedInstance] logUsabilityErrorFeedback:animatedItems context:manipulationContext];
                }
                
                allowInteractions = TRUE;
                [self.view setUserInteractionEnabled:YES];
                [ssc incrementCurrentStep];
            }
        }
        else {
            if (conditionSetup.appMode == ITS) {
                // Log attempted usability error feedback
                [[ServerCommunicationController sharedInstance] logUsabilityErrorFeedback:animatedItems context:manipulationContext];
            }
            
            allowInteractions = TRUE;
            [self.view setUserInteractionEnabled:YES];
            
            if ([stepType isEqualToString:CHECKANDSWAP]) {
                [self swapObjectImage];
            }
            
            [ssc incrementCurrentStep];
        }
    }
    // Animate moving object for transference
    else if ([stepType isEqualToString:TRANSFERANDGROUP_TXT] || [stepType isEqualToString:TRANSFERANDDISAPPEAR_TXT]) {
        ActionStep *nextSolStep = [currSolSteps objectAtIndex:stepContext.currentStep];
        
        if (nextSolStep != nil && ([[nextSolStep stepType] isEqualToString:TRANSFERANDGROUP_TXT] || [stepType isEqualToString:TRANSFERANDDISAPPEAR_TXT])) {
            NSString *objectId;
            NSString *nextObjectId;
            NSString *objectAction;
            NSString *nextObjectAction;
            
            // Try to select the distinct objects in the transference steps.
            // NOTE: This is a somewhat hardcoded solution to possible inconsistencies in the way solutions and hotspots are encoded.
            if ([[currSolStep object2Id] isEqualToString:[nextSolStep object2Id]]) {
                objectId = [currSolStep object1Id];
                nextObjectId = [nextSolStep object1Id];
                objectAction = [currSolStep action];
                nextObjectAction = [nextSolStep action];
            }
            else if ([[currSolStep object2Id] isEqualToString:[nextSolStep object1Id]]) {
                objectId = [currSolStep object1Id];
                nextObjectId = [nextSolStep object2Id];
                objectAction = [currSolStep action];
                nextObjectAction = [nextSolStep action];
            }
            else if ([[currSolStep object1Id] isEqualToString:[nextSolStep object2Id]]) {
                objectId = [nextSolStep object1Id];
                nextObjectId = [currSolStep object2Id];
                objectAction = [nextSolStep action];
                nextObjectAction = [currSolStep action];
            }
            
            Hotspot *objectHotspot = [model getHotspotforObjectWithActionAndRole:objectId :objectAction :SUBJECT];
            
            // Default to "getIn" hotspot since most objects should have one...
            if (objectHotspot == nil) {
                objectHotspot = [model getHotspotforObjectWithActionAndRole:objectId :@"getIn" :SUBJECT];
            }
            
            Hotspot *nextObjectHotspot = [model getHotspotforObjectWithActionAndRole:nextObjectId :nextObjectAction :SUBJECT];
            
            // Default to "getIn" hotspot since most objects should have one...
            if (nextObjectHotspot == nil) {
                nextObjectHotspot = [model getHotspotforObjectWithActionAndRole:nextObjectId :@"getIn" :SUBJECT];
            }
            
            CGPoint objectHotspotLocation = [self.manipulationView getHotspotLocation:objectHotspot];
            CGPoint nextObjectHotspotLocation = [self.manipulationView getHotspotLocation:nextObjectHotspot];
            
            if (conditionSetup.appMode == ITS) {
                [animatedItems addObject:objectId];
                [animatedItems addObject:nextObjectId];
                
                [[ServerCommunicationController sharedInstance] logUsabilityErrorFeedback:animatedItems context:manipulationContext];
            }
            
            [self highlightObject:objectId :2.0];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                movingObjectId = objectId;
                
                [self.manipulationView animateObject:objectId from:objectHotspotLocation to:nextObjectHotspotLocation action:MOVETOLOCATION areaId:EMPTYSTRING];
                [[ServerCommunicationController sharedInstance] logAnimateObject:objectId forAction:[objectHotspot action] context:manipulationContext];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    allowInteractions = TRUE;
                    [self.view setUserInteractionEnabled:YES];
                    
                    //Get the interaction to be performed
                    PossibleInteraction *interaction = [pic getCorrectInteraction];
                    
                    //Perform the interaction and increment the step
                    [pic performInteraction:interaction];
                    [ssc incrementCurrentStep];
                    
                    if ([interaction interactionType] == TRANSFERANDGROUP || [interaction interactionType] == TRANSFERANDDISAPPEAR) {
                        [ssc incrementCurrentStep];
                    }
                    
                    [self highlightObject:objectId :2.0];
                });
            });
        }
        
    }
    // Animate object moving to object
    else {
        NSString *object1Id = [currSolStep object1Id];
        NSString *object2Id = [currSolStep object2Id];
        
        Hotspot *object1Hotspot = [model getHotspotforObjectWithActionAndRole:object1Id :[currSolStep action] :SUBJECT];
        Hotspot *object2Hotspot = [model getHotspotforObjectWithActionAndRole:object2Id :[currSolStep action] :OBJECT];
        
        CGPoint object1HotspotLocation = [self.manipulationView getHotspotLocation:object1Hotspot];
        CGPoint object2HotspotLocation = [self.manipulationView getHotspotLocation:object2Hotspot];
        
        if (conditionSetup.appMode == ITS) {
            [animatedItems addObject:object1Id];
            [animatedItems addObject:object2Id];
            
            [[ServerCommunicationController sharedInstance] logUsabilityErrorFeedback:animatedItems context:manipulationContext];
        }
        
        [self highlightObject:object1Id :2.0];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            movingObjectId = object1Id;
            
            [self.manipulationView animateObject:object1Id from:object1HotspotLocation to:object2HotspotLocation action:MOVETOLOCATION areaId:EMPTYSTRING];
            [[ServerCommunicationController sharedInstance] logAnimateObject:object1Id forAction:[currSolStep action] context:manipulationContext];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                allowInteractions = TRUE;
                [self.view setUserInteractionEnabled:YES];
                
                //Get the interaction to be performed
                PossibleInteraction *interaction = [pic getCorrectInteraction];
                
                //Perform the interaction and increment the step
                [pic performInteraction:interaction];
                [ssc incrementCurrentStep];
                
                if ([interaction interactionType] == TRANSFERANDGROUP || [interaction interactionType] == TRANSFERANDDISAPPEAR) {
                    [ssc incrementCurrentStep];
                }
                
                [self highlightObject:object1Id :2.0];
            });
        });
    }
}

/*
 *  Plays audio for the current sentence
 */
- (void)playCurrentSentenceAudio {
    //disable user interactions when preparing to play audio to prevent users from skipping audio
    [self.view setUserInteractionEnabled:NO];
    
    NSString *sentenceAudioFile = nil;
    
    //TODO: move chapter checks to new class or function
    //Only play sentence audio if system is reading
    if (conditionSetup.reader == SYSTEM) {
        //If we are on the first or second manipulation page of The Contest, play the audio of the current sentence
        if ([chapterTitle isEqualToString:@"The Contest"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2])) {
            if ((conditionSetup.language == BILINGUAL)) {
                sentenceAudioFile = [NSString stringWithFormat:@"BFEC%d.m4a", sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"BFTC%d.m4a", sentenceContext.currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of Cleaning Up, play the audio of the current sentence
        if ([chapterTitle isEqualToString:@"Cleaning Up"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2])) {
            sentenceAudioFile = [NSString stringWithFormat:@"CleaningUpS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of Getting Ready, play the audio of the current sentence
        if ([chapterTitle isEqualToString:@"Getting Ready"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2])) {
            sentenceAudioFile = [NSString stringWithFormat:@"GettingReadyS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of Who is the Best Animal?, play the audio of the current sentence
        if ([chapterTitle isEqualToString:@"Who is the Best Animal?"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2])) {
            sentenceAudioFile = [NSString stringWithFormat:@"WhoIsTheBestAnimalS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of The Wise Owl, play the audio of the current sentence
        if ([chapterTitle isEqualToString:@"The Wise Owl"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2])) {
            sentenceAudioFile = [NSString stringWithFormat:@"TheWiseOwlS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of Everyone Helps, play the audio of the current sentence
        if ([chapterTitle isEqualToString:@"Everyone Helps"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2])) {
            sentenceAudioFile = [NSString stringWithFormat:@"EveryoneHelpsS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of The Best Farm Award, play the audio of the current sentence
        if ([chapterTitle isEqualToString:@"The Best Farm Award"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2])) {
            sentenceAudioFile = [NSString stringWithFormat:@"TheBestFarmAwardS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of Why We Breathe, play the audio of the current sentence
        if ([chapterTitle isEqualToString:@"Why We Breathe"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3])) {
            if ((conditionSetup.language == BILINGUAL)) {
                sentenceAudioFile = [NSString stringWithFormat:@"CPQR%d.m4a", sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"CWWB%d.m4a", sentenceContext.currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of The Lopez Family, play the current sentence
        if ([chapterTitle isEqualToString:@"The Lopez Family"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3])) {
            if (conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"TheLopezFamilyS%dS.mp3", sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"TheLopezFamilyS%dE.mp3", sentenceContext.currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of Is Paco a Thief?, play the current sentence
        if ([chapterTitle isEqualToString:@"Is Paco a Thief?"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3])) {
            sentenceAudioFile = [NSString stringWithFormat:@"IsPacoAThiefS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of Missing Keys, play the current sentence
        if ([chapterTitle isEqualToString:@"Missing Keys"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3])) {
            sentenceAudioFile = [NSString stringWithFormat:@"MissingKeysS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of More is Missing!, play the current sentence
        if ([chapterTitle isEqualToString:@"More is Missing!"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3])) {
            sentenceAudioFile = [NSString stringWithFormat:@"MoreIsMissingS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of The Baby's Rattle is Gone, Too!, play the current sentence
        if ([chapterTitle isEqualToString:@"The Baby's Rattle is Gone, Too!"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3])) {
            sentenceAudioFile = [NSString stringWithFormat:@"TheBaby'sRattleIsGoneTooS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of The Mystery is Solved, play the current sentence
        if ([chapterTitle isEqualToString:@"The Mystery is Solved"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3])) {
            sentenceAudioFile = [NSString stringWithFormat:@"TheMysteryIsSolvedS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of The Lucky Stone, play the current sentence
        if ([chapterTitle isEqualToString:@"The Lucky Stone"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2])) {
            if (conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"TheLuckyStoneS%dS.mp3", sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"TheLuckyStoneS%dE.mp3", sentenceContext.currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of Baby Brother, play the current sentence
        if ([chapterTitle isEqualToString:@"Baby Brother"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3])) {
            sentenceAudioFile = [NSString stringWithFormat:@"BabyBrotherS%dE.mp3", sentenceContext.currentSentence];
            
        }
        
        //If we are on the first or second manipulation page of Catch!, play the current sentence
        if ([chapterTitle isEqualToString:@"Catch!"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3])) {
            sentenceAudioFile = [NSString stringWithFormat:@"CatchS%dE.mp3", sentenceContext.currentSentence];
            
        }
        
        //If we are on the first or second manipulation page of Magic Toys, play the current sentence
        if ([chapterTitle isEqualToString:@"Magic Toys"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2])) {
            sentenceAudioFile = [NSString stringWithFormat:@"MagicToysS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of Words of Wisdom, play the current sentence
        if ([chapterTitle isEqualToString:@"Words of Wisdom"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3])) {
            sentenceAudioFile = [NSString stringWithFormat:@"WordsOfWisdomS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of The Naughty Monkey, play the current sentence
        if ([chapterTitle isEqualToString:@"The Naughty Monkey"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3]) && sentenceContext.currentSentence != 1) {
            if (conditionSetup.language == BILINGUAL && sentenceContext.currentSentence < 8) {
                sentenceAudioFile = [NSString stringWithFormat:@"TheNaughtyMonkeyS%dS.mp3", sentenceContext.currentSentence - 2];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"TheNaughtyMonkeyS%dE.mp3", sentenceContext.currentSentence - 2 ];
            }
        }
        
        //If we are on the first or second manipulation page of How Do Objects Move, play the current sentence
        if ([chapterTitle isEqualToString:@"How do Objects Move?"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2])) {
            if (conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"HowDoObjectsMoveS%dS.mp3", sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"HowDoObjectsMoveS%dE.mp3", sentenceContext.currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of The Navajo Hogan, play the current sentence
        if ([chapterTitle isEqualToString:@"The Navajo Hogan"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3])) {
            if (conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"TheNavajoHoganS%dS.mp3", sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"TheNavajoHoganS%dE.mp3", sentenceContext.currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of Native Intro, play the current sentence
        if ([chapterTitle isEqualToString:@"Introduction to Native American Homes"] && ([pageContext.currentPageId containsString:@"PM"] || [pageContext.currentPageId containsString:PM2])) {
            if (conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"NativeIntroS%dS.mp3", sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"NativeIntroS%dE.mp3", sentenceContext.currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of Key Ingredients, play the current sentence
        if ([chapterTitle isEqualToString:@"Key Ingredients"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3])) {
            if (conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"KeyIngredientsS%dS.mp3", sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"KeyIngredientsS%dE.mp3", sentenceContext.currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of Mancha the Horse, play the current sentence
        if ([chapterTitle isEqualToString:@"Mancha the Horse"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3])) {
            sentenceAudioFile = [NSString stringWithFormat:@"ManchaTheHorseS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of A Friend in Need, play the current sentence
        if ([chapterTitle isEqualToString:@"A Friend in Need"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3])) {
            sentenceAudioFile = [NSString stringWithFormat:@"AFriendInNeedS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of Shopping at the Market, play the current sentence
        if ([chapterTitle isEqualToString:@"Shopping at the Market"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3] || [pageContext.currentPageId containsString:PM4])) {
            sentenceAudioFile = [NSString stringWithFormat:@"ShoppingAtTheMarketS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of A Gift for the Bride, play the current sentence
        if ([chapterTitle isEqualToString:@"A Gift for the Bride"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3] || [pageContext.currentPageId containsString:PM4] || [pageContext.currentPageId containsString:PM5])) {
            sentenceAudioFile = [NSString stringWithFormat:@"AGiftForTheBrideS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of Homecoming, play the current sentence
        if ([chapterTitle isEqualToString:@"Homecoming"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3] || [pageContext.currentPageId containsString:PM4])) {
            sentenceAudioFile = [NSString stringWithFormat:@"HomecomingS%dE.mp3", sentenceContext.currentSentence];
        }
        
        //If we are on the first or second manipulation page of Disasters Intro, play the current sentence
        if ([chapterTitle isEqualToString:@"Introduction to Natural Disasters"] && ([pageContext.currentPageId containsString:@"PM"] || [pageContext.currentPageId containsString:PM2])) {
            if (conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"DisastersIntroS%dS.mp3", sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"DisastersIntroS%dE.mp3", sentenceContext.currentSentence];
            }
        }
        
        //If we are on the first or second manipulation page of The Moving Earth, play the current sentence
        if ([chapterTitle isEqualToString:@"The Moving Earth"] && ([pageContext.currentPageId containsString:PM1] || [pageContext.currentPageId containsString:PM2] || [pageContext.currentPageId containsString:PM3])) {
            if (conditionSetup.language == BILINGUAL) {
                sentenceAudioFile = [NSString stringWithFormat:@"TheMovingEarthS%dS.mp3", sentenceContext.currentSentence];
            }
            else {
                sentenceAudioFile = [NSString stringWithFormat:@"TheMovingEarthS%dE.mp3", sentenceContext.currentSentence];
            }
        }
    }
    
    NSMutableArray *array = [NSMutableArray array];
    Chapter *chapter = [book getChapterWithTitle:chapterTitle];
    ScriptAudio *script = nil;
    NSString *introAudio = nil;
    LibraryViewController *vc = (LibraryViewController *)libraryViewController;
    ActivitySequenceController *seqController = vc.sequenceController;
    
    if (seqController && [seqController.sequences count] > 1) {
        ActivitySequence *seq = [seqController.sequences objectAtIndex:1];
        ActivityMode *mode = [seq getModeForChapter:chapterTitle];
        
        if ([pageContext.currentPageId containsString:DASH_INTRO] &&
           [pageContext.currentPageId containsString:@"story1"] &&
           ([chapterTitle isEqualToString:@"The Lucky Stone"] || [chapterTitle isEqualToString:@"The Lopez Family"])
           && [bookTitle containsString:seq.bookTitle]) {
            introAudio = @"splWordsIntro";
            
            [array addObject:[NSString stringWithFormat:@"%@.mp3",introAudio]];
            
            if (mode.language == BILINGUAL && mode.newInstructions) {
                introAudio = [NSString stringWithFormat:@"%@_S",introAudio];
                [array addObject:[NSString stringWithFormat:@"%@.mp3",introAudio]];
            }
        }
    }
    
    if ([ConditionSetup sharedInstance].condition == EMBRACE) {
        script = [chapter embraceScriptFor:[NSString stringWithFormat:@"%lu", (unsigned long)sentenceContext.currentSentence]];
    }
    else {
        script = [chapter controlScriptFor:[NSString stringWithFormat:@"%lu", (unsigned long)sentenceContext.currentSentence]];
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
            if ([audio containsString:INTRO]) {
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
            [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:[preAudioFile stringByDeletingPathExtension] inLanguage:[conditionSetup returnLanguageEnumtoString:[conditionSetup language]] ofType:PRESENTENCE_SCRIPT_AUDIO :manipulationContext];
        }
    }
    
    if (sentenceAudioFile != nil) {
        [array addObject:sentenceAudioFile];
        
        [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:[sentenceAudioFile stringByDeletingPathExtension] inLanguage:[conditionSetup returnLanguageEnumtoString:[conditionSetup language]] ofType:SENTENCE_AUDIO :manipulationContext];
    }
    
    if (postAudio != nil) {
        [array addObjectsFromArray:postAudio];
        
        for (NSString *postAudioFile in postAudio) {
            [[ServerCommunicationController sharedInstance] logPlayManipulationAudio:[postAudioFile stringByDeletingPathExtension] inLanguage:[conditionSetup returnLanguageEnumtoString:[conditionSetup language]] ofType:POSTSENTENCE_SCRIPT_AUDIO :manipulationContext];
        }
    }
    
    if ([array count] > 0) {
        [self.playaudioClass playAudioInSequence:array :self];
    }
    else {
        //there are no audio files to play so allow interactions
        [self.view setUserInteractionEnabled:YES];
    }
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
        [pic simulatePossibleInteractionForMenuItem:interaction :[relationships objectAtIndex:interactionNum - 1]];
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
    [self.manipulationView clearAllHighLighting];
}

/*
 *  Highlights object or area
 */
- (void)highlightObject:(NSString *)object :(double)delay {
    if ([model getArea:object:pageContext.currentPageId]) {
        //Highlight the tapped object
        [self.manipulationView highLightArea:object];
    }
    else if ([model getLocationWithId:object]){
        Location *loc = [model getLocationWithId:object];
        
        //Calculate the x,y coordinates and the width and height in pixels from %
        float locationX = [loc.originX floatValue] / 100.0 * [self.view frame].size.width;
        float locationY = [loc.originY floatValue] / 100.0 * [self.view frame].size.height;
        float locationWidth = [loc.width floatValue] / 100.0 * [self.view frame].size.width;
        float locationHeight = [loc.height floatValue] / 100.0 * [self.view frame].size.height;
        
        [self.manipulationView highlightLocation:lroundf(locationX):lroundf(locationY):lroundf(locationWidth):lroundf(locationHeight)];
    }
    else {
        //Highlight the tapped object
        [self.manipulationView highlightObjectOnWordTap:object];
    }
    
    //Clear highlighted object
    [self performSelector:@selector(clearHighlightedObject) withObject:nil afterDelay:delay];
}

/*
 * Expands the contextual menu, allowing the user to select a possible grouping/ungrouping.
 * This function is called after the data source is created.
 */
//TODO: simplify im and pm menu logic
- (void)expandMenu {
    menu = [[PieContextualMenu alloc] initWithFrame:[bookView frame]];
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
            
            [connectionData setObject:objects forKey:OBJECTS];
            [connectionData setObject:hotspot forKey:HOTSPOT];
            [connectionData setObject:interactionType forKey:INTERACTIONTYPE];
            
            [menuItemData addObject:connectionData];
        }
        
        [menuItemsData addObject:menuItemData];
    }
    
    if (([chapterTitle isEqualToString:@"The Naughty Monkey"]) && sentenceContext.currentSentence == 6 && stepContext.currentStep == 2) {
        if (conditionSetup.language == ENGLISH) {
            [self.playaudioClass playAudioFile:self :@"NaughtyMonkey_Script5.mp3"];
        }
        else {
            [self.playaudioClass playAudioFile:self :@"NaughtyMonkey_Script5_S.mp3"];
        }
    } else if (([chapterTitle isEqualToString:@"The Naughty Monkey"]) && sentenceContext.currentSentence == 7 && stepContext.currentStep == 3 ) {
        if (conditionSetup.language == ENGLISH) {
            [self.playaudioClass playAudioFile:self :@"NaughtyMonkey_Script7.mp3"];
        }
        else {
            [self.playaudioClass playAudioFile:self :@"NaughtyMonkey_Script7_S.mp3"];
        }
    }
    
    [[ServerCommunicationController sharedInstance] logDisplayMenuItems:menuItemsData context:manipulationContext];
}

/*
 *  Set the current manipulation context.
 */
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
    NSArray *currentPageIdComponents = [pageContext.currentPageId componentsSeparatedByString:@"-"];
    
    manipulationContext.chapterNumber = [[[currentPageIdComponents objectAtIndex:0] stringByReplacingOccurrencesOfString:@"story" withString:EMPTYSTRING] intValue];
    manipulationContext.pageNumber = [currentPageIdComponents count] == 3 ? [[currentPageIdComponents objectAtIndex:2] intValue] : 0;
    
    if ([[currentPageIdComponents objectAtIndex:1] isEqualToString:INTRO]) {
        manipulationContext.pageMode = INTRO;
    }
    else {
        manipulationContext.pageMode = INTERVENTION;
    }
}

#pragma mark - ManipulationAnalyserProtocol

- (CGPoint)locationOfObject:(NSString *)object analyzer:(ManipulationAnalyser *)analyzer {
    CGPoint location = [self.manipulationView getObjectPosition:object];
    
    if (CGPointEqualToPoint(location, CGPointZero)) {
        Location *loc = [model getLocationWithId:object];
        
        if (loc != nil) {
            float locX = [loc.originX floatValue] / 100.0 * [bookView frame].size.width;
            float locY = [loc.originY floatValue] / 100.0 * [bookView frame].size.height;
            
            location = CGPointMake(locX, locY);
        }
    }
    
    return location;
}

- (CGSize)sizeOfObject:(NSString *)object analyzer:(ManipulationAnalyser *)analyzer {
    CGSize size = [self.manipulationView sizeOfObject:object];
    
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        Location *loc = [model getLocationWithId:object];
        
        if (loc != nil) {
            float locWidth = [loc.width floatValue] / 100.0 * [bookView frame].size.width;
            float locHeight = [loc.height floatValue] / 100.0 * [bookView frame].size.height;
            
            size = CGSizeMake(locWidth, locHeight);
        }
    }
    
    return size;
}

- (void)analyzer:(ManipulationAnalyser *)analyzer showMessage:(NSString *)message {
    if (conditionSetup.shouldShowITSMessages == NO)
        return;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
    
    int duration = 5; // duration in seconds
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
}

- (NSArray *)getNextStepsForCurrentSentence:(ManipulationAnalyser *)analyzer {
    NSMutableArray *currSolSteps = [ssc returnCurrentSolutionSteps];
    NSArray *nextSteps = nil;
    
    if ([currSolSteps count] > stepContext.currentStep) {
        NSRange range = NSMakeRange(stepContext.currentStep, [currSolSteps count] - stepContext.currentStep);
        nextSteps = [currSolSteps subarrayWithRange:range];
    }
    
    return nextSteps;
}

- (NSArray *)getStepsForCurrentSentence:(ManipulationAnalyser *)analyzer {
    return [ssc returnCurrentSolutionSteps];
}

- (EMComplexity)analyzer:(ManipulationAnalyser *)analyzer getComplexityForSentence:(int)sentenceNumber {
    return self.currentComplexityLevel;
}

@end
