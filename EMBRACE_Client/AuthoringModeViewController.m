//
//  AuthoringModeViewController.m
//  EMBRACE
//
//  Created by James Rodriguez on 4/3/15.
//  Copyright (c) 2015 Andreea Danielescu. All rights reserved.
//

#import "AuthoringModeViewController.h"
#import "ContextualMenuDataSource.h"
#import "PieContextualMenu.h"
#import "Translation.h"
#import "ServerCommunicationController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "ConditionSetup.h"
#import "IntroductionViewController.h"
#import "foundation/foundation.h"

DDXMLDocument *xmlDocTemp;

typedef enum InteractionRestriction {
    ALL_ENTITIES, //Any object can be used
    ONLY_CORRECT, //Only the correct object can be used
    NO_ENTITIES //No object can be used
} InteractionRestriction;

//This enum will be used in the future to define if a condition has or not image manipulation
typedef enum InteractionMode {
    NO_INTERACTION,
    INTERACTION
} InteractionMode;

@interface AuthoringModeViewController (){
    NSString* currentPage; //The current page being shown, so that the next page can be requested.
    NSString* currentPageId; //The id of the current page being shown
    
    NSString* pageContents;
    
    NSUInteger currentSentence; //Active sentence to be completed.
    NSUInteger totalSentences; //Total number of sentences on this page.
    
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
    
    NSMutableDictionary *currentGroupings;
    
    BOOL replenishSupply; //TRUE if object should reappear after disappearing
    BOOL allowSnapback; //TRUE if objects should snap back to original location upon error
    
    CGPoint startLocation; //initial location of an object before it is moved
    CGPoint delta; //distance between the top-left corner of the image being moved and the point clicked.
    
    ContextualMenuDataSource *menuDataSource;
    PieContextualMenu *menu;
    
    //imcode
    UIView *IMViewMenu;
    
    BOOL menuExpanded;
    
    InteractionModel *model;
    
    //Condition condition; //Study condition to run the app (e.g. MENU, HOTSPOT, etc.)
    InteractionRestriction useSubject; //Determines which objects the user can manipulate as the subject
    InteractionRestriction useObject; //Determines which objects the user can interact with as the object
    
    NSString* actualPage; //Stores the address of the current page we are at
    NSString* actualWord; //Stores the current word that was clicked
    NSTimer* timer; //Controls the timing of the audio file that is playing
    BOOL isAudioLeft;
}

@property (nonatomic, strong) IBOutlet UIWebView *bookView;
@property (strong) AVAudioPlayer *audioPlayer;
@property (strong) AVAudioPlayer *audioPlayerAfter; // Used to play sounds after the first audio player has finished playing

@end

@implementation AuthoringModeViewController


@synthesize book;

@synthesize bookTitle;
@synthesize chapterTitle;

@synthesize bookImporter;
@synthesize bookView;

@synthesize libraryViewController;

@synthesize IntroductionClass;
@synthesize buildstringClass;
@synthesize playaudioClass;

@synthesize ImageOptions;
@synthesize picker;
@synthesize TapLocationX;
@synthesize TapLocationY;

@synthesize entryview;
@synthesize isEntryViewVisible;
@synthesize isAreaViewVisible;
@synthesize areaSpace;
@synthesize HotspotEntry;
@synthesize SingleEntry;
@synthesize LocationEntry;
@synthesize WaypointEntry;
@synthesize xcord;
@synthesize ycord;
@synthesize waypointID;
@synthesize hotspotID;
@synthesize locationID;
@synthesize width;
@synthesize height;
@synthesize top;
@synthesize left;
@synthesize hotspotWidth;
@synthesize hotspotHeight;
@synthesize hotspotTop;
@synthesize hotspotLeft;
@synthesize zindex;
@synthesize objectID;
@synthesize manipulationType;
@synthesize action;
@synthesize role;

@synthesize syn;

// Create an instance of  ConditionSetup
ConditionSetup *conditionSetup;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    bookView.frame = self.view.bounds;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect pickerFrame = CGRectMake(200, 200, 320, 216);
    picker = [[UIPickerView alloc] initWithFrame:pickerFrame];
    picker.delegate=self;
    picker.showsSelectionIndicator = YES;
    TapLocationX = 0;
    TapLocationY = 0;
    isEntryViewVisible = false;
    
    self.ImageOptions = [NSArray arrayWithObjects: @"Save Waypoint", @"Save Hotspot", @"Save Location", @"Save Z-Index", @"Save Width", @"Save Height", @"Save Manipulation Type", @"FR: Save Animation", nil];
    
    //creates instance of introduction class
    IntroductionClass = [[IntroductionViewController alloc]init];
    //creates an instance of condition setup class
    conditionSetup = [[ConditionSetup alloc] init];
    //creates an instance of buildstringclass
    buildstringClass = [[BuildHTMLString alloc]init];
    //creates an instance of playaudioclass
    playaudioClass = [[PlayAudioFile alloc]init];
    
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
    [bookView scrollView].clipsToBounds = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    movingObject = FALSE;
    pinching = FALSE;
    menuExpanded = FALSE;
    
    movingObjectId = nil;
    collisionObjectId = nil;
    lastRelationship = nil;
    allRelationships = [[NSMutableArray alloc] init];
    separatingObjectId = nil;
    
    currentPage = nil;
    
    IntroductionClass.languageString = @"E";
    IntroductionClass.allowInteractions = TRUE;
    IntroductionClass.sameWordClicked = false;

    useSubject = ALL_ENTITIES;
    useObject = ONLY_CORRECT;
    pinchToUngroup = FALSE;
    replenishSupply = FALSE;
    allowSnapback = TRUE;

    currentGroupings = [[NSMutableDictionary alloc] init];
    
    //Create contextualMenuController
    menuDataSource = [[ContextualMenuDataSource alloc] init];
    
    //Ensure that the pinch recognizer gets called before the pan gesture recognizer.
    //That way, if a user is trying to ungroup objects, they can do so without the objects moving as well.
    //TODO: Figure out how to get the pan gesture to still properly recognize the begin and continue actions.
    //[panRecognizer requireGestureRecognizerToFail:pinchRecognizer];
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // Disable user sevlection
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
    
    if ([IntroductionClass.introductions objectForKey:chapterTitle] || ([IntroductionClass.vocabularies objectForKey:chapterTitle] && [currentPageId rangeOfString:@"Intro"].location != NSNotFound)) {
        IntroductionClass.allowInteractions = FALSE;
    }
    
    //Load the first step for the current chapter
    if ([IntroductionClass.introductions objectForKey:chapterTitle]) {
        [IntroductionClass loadIntroStep:bookView: currentSentence];
    }
    
    //Create UIView for textbox area to recognize swipe gesture
    //NOTE: Currently not in use because it disables tap gesture recognition over the textbox area and we haven't
    //found a way to fix this yet.
    //[self createTextboxView];
    
    //Load the first vocabulary step for the current chapter (hard-coded for now)
    if ([IntroductionClass.vocabularies objectForKey:chapterTitle] && [currentPageId rangeOfString:@"Intro"].location != NSNotFound) {
        [IntroductionClass loadVocabStep:bookView: currentSentence: chapterTitle];
    }
    
    isAudioLeft = false;
    
    //Perform setup for activity
    //[self performSetupForActivity];
    
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
            //PossibleInteraction* interaction = [self convertActionStepToPossibleInteraction:setupStep];
            //[self performInteraction:interaction]; //groups the objects
        }
        else if ([[setupStep stepType] isEqualToString:@"move"]) {
            //Get information for move step type
            NSString* object1Id = [setupStep object1Id];
            NSString* action = [setupStep action];
            NSString* object2Id = [setupStep object2Id];
            NSString* waypointId = [setupStep waypointId];
            
            //Move either requires object1 to move to object2 (which creates a group interaction) or it requires object1 to move to a waypoint
            if (object2Id != nil) {
              //  PossibleInteraction* correctInteraction = [self getCorrectInteraction];
                //[self performInteraction:correctInteraction]; //performs solution step
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
    
    //instantiates all introduction variables
    [IntroductionClass loadFirstPageIntroduction:model :chapterTitle];
    
    [self loadPage];
}

/*
 * Loads the next page for the current chapter based on the current activity.
 * If the activity has multiple pages, it would load the next page in the activity.
 * Otherwise, it will load the next chaper.
 */
-(void) loadNextPage {
    currentPage = [book getNextPageForChapterAndActivity:chapterTitle :PM_MODE :currentPage];
    
    //No more pages in chapter
    if (currentPage == nil) {
        //return to library view
        //load assessment activity screen
        if([chapterTitle isEqualToString:@"Introduction to The Best Farm"] || [chapterTitle isEqualToString:@"Introduction to The House"])
        {   [self.navigationController popViewControllerAnimated:YES];
            return;
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
            return;
        }
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
    pageContents = [[NSString alloc] initWithContentsOfFile:currentPage encoding:NSASCIIStringEncoding error:&error];
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
    
    //instantiates all vocab variables
    [IntroductionClass loadFirstPageVocabulary:model :chapterTitle];
    
    IntroductionClass.allowInteractions = TRUE;
    
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
        currentStep++;
    }
    else {
        stepsComplete = TRUE; //no more steps to complete
    }
}

#pragma mark - Responding to gestures
/*
 * User pressed Back button. Write log data to file.
 */
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (![[self.navigationController viewControllers] containsObject:self])
    {
        
    }
}

/*
 * Pinch gesture. Used to ungroup two images from each other.
 */
-(IBAction)pinchGesturePerformed:(UIPinchGestureRecognizer *)recognizer {
    /*CGPoint location = [recognizer locationInView:self.view];
    
    if(recognizer.state == UIGestureRecognizerStateBegan && IntroductionClass.allowInteractions && pinchToUngroup) {
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
     */
}

-(void)saveHotspot:(id)sender{
    /*convert px values to percentages*/
    
    /*recieve the height and width of the object and convert */
    NSString *xcordPercent = [NSString stringWithFormat:@"%ld", (long)[xcord.text integerValue]];
    NSString *ycordPercent = [NSString stringWithFormat:@"%ld", (long)[ycord.text integerValue]];
    
    //NSInteger hleft = [hotspotLeft.text integerValue];
    //NSInteger htop = [hotspotTop.text integerValue];
    //NSInteger hwidth = [hotspotWidth.text integerValue];
    //NSInteger hheight = [hotspotHeight.text integerValue];
    //NSInteger xpercent = hleft + hwidth * [xcordPercent integerValue]/100;
    //NSInteger ypercent = htop + hheight * [ycordPercent integerValue]/100;
    
    NSString* newHotspot = [NSString stringWithFormat:@"hotspot objId=\"%@\" action=\"%@\" role=\"%@\" x=\"%@%%\" y=\"%@%%\"", hotspotID.text, action.text, role.text, xcordPercent, ycordPercent];
    NSLog(@"%@", newHotspot);
    
    //set file path to access introduction metadata
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"Hotspots-MetaData.xml"];
    
    NSString *filepath = [[book mainContentPath] stringByAppendingString:@"Hotspots-MetaData.xml"];
    
    //Get xml data of the metadata file.
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:path];
    
    if (xmlData == NULL)
    {
        xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    }
    
    
    NSError *error;
    
    //break out metadata file into seperate components
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:&error];
    
    xmlDocTemp = [[DDXMLDocument alloc] initWithData:xmlData options:0 error:nil];
    
    //Reading in the location information.
    NSArray* hotspotElements = [metadataDoc nodesForXPath:@"//hotspots" error:nil];
    GDataXMLElement* hotspotElement = (GDataXMLElement*)[hotspotElements objectAtIndex:0];
    
    NSArray* hotspots = [hotspotElement elementsForName:@"hotspot"];
    
    bool doesHotspotExist = false;
    
    //Read in the location information.
    for (GDataXMLElement* hotspot in hotspots) {
        NSLog(@"%@", [hotspot XMLString]);
        
        if ([[hotspot XMLString] isEqualToString:newHotspot]) {
            NSLog(@"Error: Hotspot already exists");
            NSLog(@"%@",newHotspot);
            doesHotspotExist = true;
            return;
        }
    }
    
    if (doesHotspotExist == false) {
        NSArray *hotspots = [xmlDocTemp nodesForXPath:@"//hotspots" error:nil];
        DDXMLElement *hotspotElement = (DDXMLElement*)[hotspots objectAtIndex:0];
        DDXMLElement *newXMLHotspot = [DDXMLElement elementWithName:newHotspot];
        [hotspotElement addChild: newXMLHotspot];
        NSString *stringxml = [xmlDocTemp XMLStringWithOptions:DDXMLNodeCompactEmptyElement];
        NSLog(@"%@", stringxml);
        [self writeToFile: filepath : @"Hotspots-MetaData" ofType:@"xml"];
        NSLog(@"Success: Hotspot added");
        NSLog(@"%@",newHotspot);
        [entryview removeFromSuperview];
        isEntryViewVisible = false;
        
        if (isAreaViewVisible == true) {
            [areaSpace removeFromSuperview];
            self.isAreaViewVisible = false;
        }
    }
    
}

-(void)saveWaypoint:(id)sender {
    /*convert px values to percentages*/
    NSString *xcordPercent = [NSString stringWithFormat:@"%f", ([xcord.text integerValue] / [bookView frame].size.width * 100)];
    NSString *ycordPercent = [NSString stringWithFormat:@"%f", ([ycord.text integerValue] / [bookView frame].size.height * 100)];
    
    NSString* newWaypoint = [NSString stringWithFormat:@"waypoint waypointId=\"%@\" x=\"%@%%\" y=\"%@%%\"", waypointID.text, xcordPercent, ycordPercent];
    NSLog(@"%@", newWaypoint);
    
    //set file path to access introduction metadata
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"Waypoints-MetaData.xml"];
    
    NSString *filepath = [[book mainContentPath] stringByAppendingString:@"Waypoints-MetaData.xml"];
    
    //Get xml data of the metadata file.
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:path];
    
    if (xmlData == NULL)
    {
        xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    }
    
    //break out metadata file into seperate components
    GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:nil];
    
    xmlDocTemp = [[DDXMLDocument alloc] initWithData:xmlData options:0 error:nil];
    
    //Reading in the location information.
    NSArray* waypointElements = [metadataDoc nodesForXPath:@"//waypoints" error:nil];
    GDataXMLElement* waypointElement = (GDataXMLElement*)[waypointElements objectAtIndex:0];
    
    NSArray* waypoints = [waypointElement elementsForName:@"waypoint"];
    
    bool doesWaypointExist = false;
    
    //Read in the location information.
    for (GDataXMLElement* waypoint in waypoints) {
        NSLog(@"%@", [waypoint XMLString]);
        
        if ([[waypoint XMLString] isEqualToString:newWaypoint]) {
            NSLog(@"Error: Waypoint already exists");
            NSLog(@"%@",newWaypoint);
            doesWaypointExist = true;
            return;
        }
    }
    
    if (doesWaypointExist == false) {
        NSArray *waypoints = [xmlDocTemp nodesForXPath:@"//waypoints" error:nil];
        DDXMLElement *waypointElement = (DDXMLElement*)[waypoints objectAtIndex:0];
        DDXMLElement *newXMLWaypoint = [DDXMLElement elementWithName:newWaypoint];
        [waypointElement addChild: newXMLWaypoint];
        NSString *stringxml = [xmlDocTemp XMLStringWithOptions:DDXMLNodeCompactEmptyElement];
        NSLog(@"%@", stringxml);
        [self writeToFile: filepath : @"Waypoints-MetaData" ofType:@"xml"];
        NSLog(@"Success: Waypoint added");
        NSLog(@"%@",newWaypoint);
        [entryview removeFromSuperview];
        isEntryViewVisible = false;
        
        if (isAreaViewVisible == true) {
            [areaSpace removeFromSuperview];
            self.isAreaViewVisible = false;
        }
    }
}

-(void)saveLocation:(id)sender{
    
    /*convert px values to percentages*/
    NSString *xcordPercent = [NSString stringWithFormat:@"%f", ([xcord.text integerValue] / [bookView frame].size.width * 100)];
    NSString *ycordPercent = [NSString stringWithFormat:@"%f", ([ycord.text integerValue] / [bookView frame].size.height * 100)];
    NSString *heightPercent = [NSString stringWithFormat:@"%f", ([height.text integerValue] / [bookView frame].size.width * 100)];
    NSString *widthPercent = [NSString stringWithFormat:@"%f", ([width.text integerValue] / [bookView frame].size.width * 100)];
    NSString* newLocation = [NSString stringWithFormat:@"location locationId=\"%@\" x=\"%@%%\" y=\"%@%%\" height=\"%@%%\" width=\"%@%%\"", locationID.text, xcordPercent, ycordPercent, heightPercent, widthPercent];

    //set file path to access introduction metadata
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"Locations-MetaData.xml"];
    
    NSString *filepath = [[book mainContentPath] stringByAppendingString:@"Locations-MetaData.xml"];
    
    //Get xml data of the metadata file.
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:path];
    
    if (xmlData == NULL)
    {
        xmlData = [[NSMutableData alloc] initWithContentsOfFile:filepath];
    }
    
     //break out metadata file into seperate components
     GDataXMLDocument *metadataDoc = [[GDataXMLDocument alloc] initWithData:xmlData error:nil];
    
     xmlDocTemp = [[DDXMLDocument alloc] initWithData:xmlData options:0 error:nil];
    
     //Reading in the location information.
     NSArray* locationElements = [metadataDoc nodesForXPath:@"//locations" error:nil];
     GDataXMLElement* locationElement = (GDataXMLElement*)[locationElements objectAtIndex:0];
     
     NSArray* locations = [locationElement elementsForName:@"location"];
    
     bool doesLocationExist = false;
    
     //Read in the location information.
     for (GDataXMLElement* location in locations) {
         NSLog(@"%@", [location XMLString]);
        
         if ([[location XMLString] isEqualToString:newLocation]) {
             NSLog(@"Error: Location already exists");
             NSLog(@"%@",newLocation);
             doesLocationExist = true;
             return;
         }
     }
    
    if (doesLocationExist == false) {
       
        NSArray *locations = [xmlDocTemp nodesForXPath:@"//locations" error:nil];
        DDXMLElement *locationElement = (DDXMLElement*)[locations objectAtIndex:0];
        DDXMLElement *newXMLLocation = [DDXMLElement elementWithName:newLocation];
        [locationElement addChild: newXMLLocation];
        NSString *stringxml = [xmlDocTemp XMLStringWithOptions:DDXMLNodeCompactEmptyElement];
        NSLog(@"%@", stringxml);
        [self writeToFile: filepath : @"Locations-MetaData" ofType:@"xml"];
        NSLog(@"Success: Location added");
        NSLog(@"%@",newLocation);
        [entryview removeFromSuperview];
        isEntryViewVisible = false;
        
        if (isAreaViewVisible == true) {
            [areaSpace removeFromSuperview];
            self.isAreaViewVisible = false;
        }
    }
    
    
}

-(void)changeZIndex:(id)sender{
    
    NSString* changeZindexAtPoint = [NSString stringWithFormat:@"%@.style.zIndex = %@", objectID.text, zindex.text];
    
    NSString *zindexAtPoint = [bookView stringByEvaluatingJavaScriptFromString:changeZindexAtPoint];
    NSLog(@"%@", zindexAtPoint);
    [entryview removeFromSuperview];
    isEntryViewVisible = false;
}

-(void)changeWidth:(id)sender{
    NSString* changeWidthAtPoint = [NSString stringWithFormat:@"%@.style.width = \"%@px\"", objectID.text, width.text];
    NSString *WidthAtPoint = [bookView stringByEvaluatingJavaScriptFromString:changeWidthAtPoint];
    NSLog(@"%@", WidthAtPoint);
    [entryview removeFromSuperview];
    isEntryViewVisible = false;
}

-(void)changeHeight:(id)sender{
    NSString* changeHeightAtPoint = [NSString stringWithFormat:@"%@.style.height = \"%@px\"", objectID.text, height.text];
    NSString *HeightAtPoint = [bookView stringByEvaluatingJavaScriptFromString:changeHeightAtPoint];
    NSLog(@"%@", HeightAtPoint);
    [entryview removeFromSuperview];
    isEntryViewVisible = false;
}

-(void)changeManipulationType:(id)sender {
    NSString* changeManipulationType = [NSString stringWithFormat:@"%@.className = \"%@\";", objectID.text, manipulationType.text];
    NSString* ManipulationType = [bookView stringByEvaluatingJavaScriptFromString:changeManipulationType];
    NSLog(@"%@", ManipulationType);
    
    [entryview removeFromSuperview];
    isEntryViewVisible = false;
}

- (BOOL) writeToFile:(NSString *) toLocation : (NSString *)fileName ofType:(NSString *)type
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //
    NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", fileName, type]];
    //toggle for saving to logging location or to overide current file
    //NSString *path = toLocation;
    
    NSString *stringxml = [xmlDocTemp XMLStringWithOptions:DDXMLNodeCompactEmptyElement];
    
    if (![stringxml writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
        NSLog(@"Could not write document out...");
        NSLog(@"%@", stringxml);
        return NO;
    }
    NSLog(@"%@", stringxml);
    NSLog(@"Successfully wrote to file");
    return YES;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return [ImageOptions count];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return  [ImageOptions objectAtIndex:row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    /*@"Save Waypoint", @"Save Hotspot", @"Save Location", @"Save Z-Index", @"Save Width", @"Save Height", @"Save Manipulation Type"*/
    
    /*
     textbox subview
     */
    
    [pickerView removeFromSuperview];
    isEntryViewVisible = true;
    isAreaViewVisible = false;
    
    if (row == 0) {
        //save waypoint
        /*
         add new sub view with textboxes, cancel button, and save button
         */
        entryview = [[UIView alloc] initWithFrame:CGRectMake(670, 10, 200, 200)];
        entryview.backgroundColor = [UIColor whiteColor];

        waypointID = [[UITextField alloc] initWithFrame:CGRectMake(10, 20, 180, 30)];
        waypointID.text = @"WaypointID";
        waypointID.textColor = [UIColor blackColor];
        waypointID.borderStyle = UITextBorderStyleRoundedRect;
        
        xcord = [[UITextField alloc] initWithFrame:CGRectMake(10, 60, 180, 30)];
        xcord.text = [NSString stringWithFormat:@"%d", TapLocationX];
        xcord.textColor = [UIColor blackColor];
        xcord.borderStyle = UITextBorderStyleRoundedRect;
        
        ycord = [[UITextField alloc] initWithFrame:CGRectMake(10, 100, 180, 30)];
        ycord.text = [NSString stringWithFormat:@"%d",TapLocationY];
        ycord.textColor = [UIColor blackColor];
        ycord.borderStyle = UITextBorderStyleRoundedRect;
        
        width = [[UITextField alloc] initWithFrame:CGRectMake(10, 60, 180, 30)];
        width.text = @"25";
        height = [[UITextField alloc] initWithFrame:CGRectMake(10, 60, 180, 30)];
        height.text = @"25";
        
        UIButton *cancel = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [cancel addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        cancel.frame = CGRectMake(10, 140, 80, 50);
        [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
        
        UIButton *createVisibleArea = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [createVisibleArea addTarget:self action:@selector(Create:) forControlEvents:UIControlEventTouchUpInside];
        createVisibleArea.frame = CGRectMake(65, 140, 80, 50);
        [createVisibleArea setTitle:@"Create" forState:UIControlStateNormal];
        
        UIButton *save = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [save addTarget:self action:@selector(saveWaypoint:) forControlEvents:UIControlEventTouchUpInside];
        save.frame = CGRectMake(115, 140, 80, 50);
        [save setTitle:@"Save" forState:UIControlStateNormal];
        
        WaypointEntry = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        WaypointEntry.backgroundColor = [UIColor whiteColor];
        [WaypointEntry addSubview:waypointID];
        [WaypointEntry addSubview:xcord];
        [WaypointEntry addSubview:ycord];
        [WaypointEntry addSubview:cancel];
        [WaypointEntry addSubview:createVisibleArea];
        [WaypointEntry addSubview:save];
        [entryview addSubview:WaypointEntry];
        [self.view addSubview:entryview];
        
    }
    else if (row ==1)
    {
        //save hotspot
        /*
         add new sub view with textboxes, cancel button, and save button
         //NSString* hotspot = [NSString stringWithFormat:@"<hotspot objId=\"%@\" action=\"%@\" role=\"%@\" x=\"%d\" y=\"%d\"/>", hotspotID.text, action, role, xcord.text, ycord.text];
         */
        entryview = [[UIView alloc] initWithFrame:CGRectMake(670, 10, 200, 290)];
        entryview.backgroundColor = [UIColor whiteColor];
        
        hotspotID = [[UITextField alloc] initWithFrame:CGRectMake(10, 20, 180, 30)];
        
        NSString *objectAtPoint= nil;
        objectAtPoint = [self getObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"manipulationObject"];
        
        if (objectAtPoint == nil) {
            objectAtPoint = [self getObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"backgroundObject"];
            
            NSString *objectWidth = [self getwidthOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"manipulationObject"];
            NSString *objectHeight = [self getheightOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"manipulationObject"];
            NSString *objectTop = [self getTopOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"manipulationObject"];
            NSString *objectLeft = [self getLeftOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"manipulationObject"];
            
            if (objectWidth == nil && objectHeight == nil && objectTop == nil && objectLeft == nil)
            {
                objectWidth = [self getwidthOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"backgroundObject"];
                objectHeight = [self getheightOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"backgroundObject"];
                objectTop = [self getTopOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"backgroundObject"];
                objectLeft = [self getLeftOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"backgroundObject"];
                
                hotspotTop = [[UITextField alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
                hotspotLeft = [[UITextField alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
                hotspotWidth = [[UITextField alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
                hotspotHeight = [[UITextField alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
                hotspotTop.text = objectTop;
                hotspotLeft.text = objectLeft;
                hotspotWidth.text = objectWidth;
                hotspotHeight.text = objectHeight;
            }
            else
            {
                hotspotTop = [[UITextField alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
                hotspotLeft = [[UITextField alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
                hotspotWidth = [[UITextField alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
                hotspotHeight = [[UITextField alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
                hotspotTop.text = objectTop;
                hotspotLeft.text = objectLeft;
                hotspotWidth.text = objectWidth;
                hotspotHeight.text = objectHeight;
            }
            
            if (objectAtPoint == nil) {
                hotspotID.text = @"HotspotID";
                //may actually just want to return at this point because we did not press on any manipulation or background object
            }
            else
            {
                hotspotID.text = objectAtPoint;
            }
        }
        else
        {
            hotspotID.text = objectAtPoint;
            
            NSString *objectWidth = [self getwidthOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"manipulationObject"];
            NSString *objectHeight = [self getheightOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"manipulationObject"];
            NSString *objectTop = [self getTopOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"manipulationObject"];
            NSString *objectLeft = [self getLeftOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"manipulationObject"];
            
            if (objectWidth == nil && objectHeight == nil && objectTop == nil && objectLeft == nil)
            {
                objectWidth = [self getwidthOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"backgroundObject"];
                objectHeight = [self getheightOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"backgroundObject"];
                objectTop = [self getTopOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"backgroundObject"];
                objectLeft = [self getLeftOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"backgroundObject"];
                
                hotspotTop = [[UITextField alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
                hotspotLeft = [[UITextField alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
                hotspotWidth = [[UITextField alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
                hotspotHeight = [[UITextField alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
                hotspotTop.text = objectTop;
                hotspotLeft.text = objectLeft;
                hotspotWidth.text = objectWidth;
                hotspotHeight.text = objectHeight;
            }
            else
            {
                hotspotTop = [[UITextField alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
                hotspotLeft = [[UITextField alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
                hotspotWidth = [[UITextField alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
                hotspotHeight = [[UITextField alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
                hotspotTop.text = objectTop;
                hotspotLeft.text = objectLeft;
                hotspotWidth.text = objectWidth;
                hotspotHeight.text = objectHeight;
            }
        }
        
        hotspotID.textColor = [UIColor blackColor];
        hotspotID.borderStyle = UITextBorderStyleRoundedRect;
        
        action = [[UITextField alloc] initWithFrame:CGRectMake(10, 60, 180, 30)];
        action.text = @"action";
        action.textColor = [UIColor blackColor];
        action.borderStyle = UITextBorderStyleRoundedRect;
        
        role = [[UITextField alloc] initWithFrame:CGRectMake(10, 100, 180, 30)];
        role.text = @"role: Subject/Object";
        role.textColor = [UIColor blackColor];
        role.borderStyle = UITextBorderStyleRoundedRect;
        
        xcord = [[UITextField alloc] initWithFrame:CGRectMake(10, 140, 180, 30)];
        xcord.text = @"X%";//[NSString stringWithFormat:@"%d", xcordLocationOnObject];
        xcord.textColor = [UIColor blackColor];
        xcord.borderStyle = UITextBorderStyleRoundedRect;
        
        ycord = [[UITextField alloc] initWithFrame:CGRectMake(10, 180, 180, 30)];
        ycord.text = @"Y%";//[NSString stringWithFormat:@"%d", ycordLocationOnObject];
        ycord.textColor = [UIColor blackColor];
        ycord.borderStyle = UITextBorderStyleRoundedRect;
        
        width = [[UITextField alloc] initWithFrame:CGRectMake(10, 60, 180, 30)];
        width.text = @"25";
        height = [[UITextField alloc] initWithFrame:CGRectMake(10, 60, 180, 30)];
        height.text = @"25";
        
        UIButton *cancel = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [cancel addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        cancel.frame = CGRectMake(10, 220, 80, 50);
        [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
        
        UIButton *createVisibleArea = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [createVisibleArea addTarget:self action:@selector(CreateHotspot:) forControlEvents:UIControlEventTouchUpInside];
        createVisibleArea.frame = CGRectMake(65, 220, 80, 50);
        [createVisibleArea setTitle:@"Create" forState:UIControlStateNormal];
        
        UIButton *save = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [save addTarget:self action:@selector(saveHotspot:) forControlEvents:UIControlEventTouchUpInside];
        save.frame = CGRectMake(115, 220, 80, 50);
        [save setTitle:@"Save" forState:UIControlStateNormal];
        
        HotspotEntry = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 290)];
        HotspotEntry.backgroundColor = [UIColor whiteColor];
        [HotspotEntry addSubview:hotspotID];
        [HotspotEntry addSubview:action];
        [HotspotEntry addSubview:role];
        [HotspotEntry addSubview:xcord];
        [HotspotEntry addSubview:ycord];
        [HotspotEntry addSubview:cancel];
        [HotspotEntry addSubview:createVisibleArea];
        [HotspotEntry addSubview:save];
        [entryview addSubview:HotspotEntry];
        [self.view addSubview:entryview];
        
    }
    else if (row ==2)
    {
        //save location
        /*
         add new sub view with textboxes, cancel button, and save button
         locationid, xcord, ycord, height, width
         */
        entryview = [[UIView alloc] initWithFrame:CGRectMake(670, 10, 200, 290)];
        entryview.backgroundColor = [UIColor whiteColor];

        locationID = [[UITextField alloc] initWithFrame:CGRectMake(10, 20, 180, 30)];
        locationID.text = @"LocationID";
        locationID.textColor = [UIColor blackColor];
        locationID.borderStyle = UITextBorderStyleRoundedRect;
        
        xcord = [[UITextField alloc] initWithFrame:CGRectMake(10, 60, 180, 30)];
        xcord.text = [NSString stringWithFormat:@"%d", TapLocationX];
        xcord.textColor = [UIColor blackColor];
        xcord.borderStyle = UITextBorderStyleRoundedRect;
        
        ycord = [[UITextField alloc] initWithFrame:CGRectMake(10, 100, 180, 30)];
        ycord.text = [NSString stringWithFormat:@"%d",TapLocationY];
        ycord.textColor = [UIColor blackColor];
        ycord.borderStyle = UITextBorderStyleRoundedRect;
        
        width = [[UITextField alloc] initWithFrame:CGRectMake(10, 140, 180, 30)];
        width.text= @"Width";
        width.textColor = [UIColor blackColor];
        width.borderStyle = UITextBorderStyleRoundedRect;
        
        height = [[UITextField alloc] initWithFrame:CGRectMake(10, 180, 180, 30)];
        height.text= @"Height";
        height.textColor = [UIColor blackColor];
        height.borderStyle = UITextBorderStyleRoundedRect;
        
        UIButton *cancel = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [cancel addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        cancel.frame = CGRectMake(10, 220, 80, 50);
        [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
        
        UIButton *createVisibleArea = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [createVisibleArea addTarget:self action:@selector(Create:) forControlEvents:UIControlEventTouchUpInside];
        createVisibleArea.frame = CGRectMake(65, 220, 80, 50);
        [createVisibleArea setTitle:@"Create" forState:UIControlStateNormal];
        
        UIButton *save = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [save addTarget:self action:@selector(saveLocation:) forControlEvents:UIControlEventTouchUpInside];
        save.frame = CGRectMake(115, 220, 80, 50);
        [save setTitle:@"Save" forState:UIControlStateNormal];
        
        LocationEntry = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 290)];
        LocationEntry.backgroundColor = [UIColor whiteColor];
        [LocationEntry addSubview:locationID];
        [LocationEntry addSubview:xcord];
        [LocationEntry addSubview:ycord];
        [LocationEntry addSubview:width];
        [LocationEntry addSubview:height];
        [LocationEntry addSubview:cancel];
        [LocationEntry addSubview:createVisibleArea];
        [LocationEntry addSubview:save];
        [entryview addSubview:LocationEntry];
        [self.view addSubview:entryview];
    }
    else if (row ==3)
    {
        //save z-index
        /*
         add new sub view with textboxes, cancel button, and save button
         */
        entryview = [[UIView alloc] initWithFrame:CGRectMake(670, 10, 200, 160)];
        entryview.backgroundColor = [UIColor whiteColor];
        
        objectID = [[UITextField alloc] initWithFrame:CGRectMake(10, 20, 180, 30)];
        
        NSString *objectAtPoint= nil;
        objectAtPoint = [self getObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"manipulationObject"];
        
        if (objectAtPoint == nil) {
            objectAtPoint = [self getObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"backgroundObject"];
            
            if (objectAtPoint == nil) {
                objectID.text = @"HotspotID";
                //may actually just want to return at this point because we did not press on any manipulation or background object
            }
            else
            {
                objectID.text = objectAtPoint;
            }
        }
        else
        {
            objectID.text = objectAtPoint;
        }
        
        objectID.textColor = [UIColor blackColor];
        objectID.borderStyle = UITextBorderStyleRoundedRect;
        
        zindex = [[UITextField alloc] initWithFrame:CGRectMake(10, 60, 180, 30)];
        
        //need to return current zindex
        NSString *zindexOfObjectAtPoint= nil;
        zindexOfObjectAtPoint = [self getzindexOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"manipulationObject"];
        
        if (zindexOfObjectAtPoint == nil) {
           zindexOfObjectAtPoint = [self getzindexOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"backgroundObject"];
            
            if (objectAtPoint == nil) {
                zindex.text = @"zindex";
                //may actually just want to return at this point because we did not press on any manipulation or background object
            }
            else
            {
                zindex.text = zindexOfObjectAtPoint;
            }
        }
        else
        {
            zindex.text = zindexOfObjectAtPoint;
        }
        
        
        zindex.textColor = [UIColor blackColor];
        zindex.borderStyle = UITextBorderStyleRoundedRect;
        
        UIButton *cancel = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [cancel addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        cancel.frame = CGRectMake(10, 100, 80, 50);
        [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
        
        UIButton *save = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [save addTarget:self action:@selector(changeZIndex:) forControlEvents:UIControlEventTouchUpInside];
        save.frame = CGRectMake(115, 100, 80, 50);
        [save setTitle:@"Save" forState:UIControlStateNormal];
        
        SingleEntry = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 160)];
        SingleEntry.backgroundColor = [UIColor whiteColor];
        [SingleEntry addSubview:objectID];
        [SingleEntry addSubview:zindex];
        [SingleEntry addSubview:cancel];
        [SingleEntry addSubview:save];
        [entryview addSubview:SingleEntry];
        [self.view addSubview:entryview];
    }
    else if (row ==4)
    {
        //save width
        /*
         add new sub view with textboxes, cancel button, and save button
         */
       
        entryview = [[UIView alloc] initWithFrame:CGRectMake(670, 10, 200, 160)];
        entryview.backgroundColor = [UIColor whiteColor];
        
        objectID = [[UITextField alloc] initWithFrame:CGRectMake(10, 20, 180, 30)];
        
        NSString *objectAtPoint= nil;
        objectAtPoint = [self getObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"manipulationObject"];
        
        if (objectAtPoint == nil) {
            objectAtPoint = [self getObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"backgroundObject"];
            
            if (objectAtPoint == nil) {
                objectID.text = @"HotspotID";
                //may actually just want to return at this point because we did not press on any manipulation or background object
            }
            else
            {
                objectID.text = objectAtPoint;
            }
        }
        else
        {
            objectID.text = objectAtPoint;
        }
        
        objectID.textColor = [UIColor blackColor];
        objectID.borderStyle = UITextBorderStyleRoundedRect;
        
        width = [[UITextField alloc] initWithFrame:CGRectMake(10, 60, 180, 30)];
        
        //need to return current width
        NSString *widthOfObjectAtPoint= nil;
        widthOfObjectAtPoint = [self getwidthOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"manipulationObject"];
        
        if (widthOfObjectAtPoint == nil) {
            widthOfObjectAtPoint = [self getwidthOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"backgroundObject"];
            
            if (objectAtPoint == nil) {
                width.text = @"width";
                //may actually just want to return at this point because we did not press on any manipulation or background object
            }
            else
            {
                width.text = widthOfObjectAtPoint;
            }
        }
        else
        {
            width.text = widthOfObjectAtPoint;
        }
        
        
        width.textColor = [UIColor blackColor];
        width.borderStyle = UITextBorderStyleRoundedRect;
        
        UIButton *cancel = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [cancel addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        cancel.frame = CGRectMake(10, 100, 80, 50);
        [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
        
        UIButton *save = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [save addTarget:self action:@selector(changeWidth:) forControlEvents:UIControlEventTouchUpInside];
        save.frame = CGRectMake(100, 100, 80, 50);
        [save setTitle:@"Save" forState:UIControlStateNormal];
        
        SingleEntry = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 160)];
        SingleEntry.backgroundColor = [UIColor whiteColor];
        [SingleEntry addSubview:objectID];
        [SingleEntry addSubview:width];
        [SingleEntry addSubview:cancel];
        [SingleEntry addSubview:save];
        [entryview addSubview:SingleEntry];
        [self.view addSubview:entryview];
    }
    else if (row ==5)
    {
        //save height
        /*
         add new sub view with textboxes, cancel button, and save button
         */
        
        entryview = [[UIView alloc] initWithFrame:CGRectMake(670, 10, 200, 160)];
        entryview.backgroundColor = [UIColor whiteColor];
        
        objectID = [[UITextField alloc] initWithFrame:CGRectMake(10, 20, 180, 30)];
        
        NSString *objectAtPoint= nil;
        objectAtPoint = [self getObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"manipulationObject"];
        
        if (objectAtPoint == nil) {
            objectAtPoint = [self getObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"backgroundObject"];
            
            if (objectAtPoint == nil) {
                objectID.text = @"HotspotID";
                //may actually just want to return at this point because we did not press on any manipulation or background object
            }
            else
            {
                objectID.text = objectAtPoint;
            }
        }
        else
        {
            objectID.text = objectAtPoint;
        }
        
        objectID.textColor = [UIColor blackColor];
        objectID.borderStyle = UITextBorderStyleRoundedRect;
        
        height = [[UITextField alloc] initWithFrame:CGRectMake(10, 60, 180, 30)];
        
        //need to return current width
        NSString *heightOfObjectAtPoint= nil;
        heightOfObjectAtPoint = [self getheightOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"manipulationObject"];
        
        if (heightOfObjectAtPoint == nil) {
            heightOfObjectAtPoint = [self getheightOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"backgroundObject"];
            
            if (objectAtPoint == nil) {
                height.text = @"width";
                //may actually just want to return at this point because we did not press on any manipulation or background object
            }
            else
            {
                height.text = heightOfObjectAtPoint;
            }
        }
        else
        {
            height.text = heightOfObjectAtPoint;
        }
        
        
        height.textColor = [UIColor blackColor];
        height.borderStyle = UITextBorderStyleRoundedRect;
        
        UIButton *cancel = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [cancel addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        cancel.frame = CGRectMake(10, 100, 80, 50);
        [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
        
        UIButton *save = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [save addTarget:self action:@selector(changeHeight:) forControlEvents:UIControlEventTouchUpInside];
        save.frame = CGRectMake(100, 100, 80, 50);
        [save setTitle:@"Save" forState:UIControlStateNormal];
        
        SingleEntry = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 160)];
        SingleEntry.backgroundColor = [UIColor whiteColor];
        [SingleEntry addSubview:objectID];
        [SingleEntry addSubview:height];
        [SingleEntry addSubview:cancel];
        [SingleEntry addSubview:save];
        [entryview addSubview:SingleEntry];
        [self.view addSubview:entryview];
    }
    else if (row == 6)
    {
        //save manipulaiton type
        /*
         add new sub view with textboxes, cancel button, and save button
         */
        
        entryview = [[UIView alloc] initWithFrame:CGRectMake(670, 10, 200, 160)];
        entryview.backgroundColor = [UIColor whiteColor];
        
        objectID = [[UITextField alloc] initWithFrame:CGRectMake(10, 20, 180, 30)];
        
        NSString *objectAtPoint= nil;
        objectAtPoint = [self getObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"manipulationObject"];
        
        if (objectAtPoint == nil) {
            objectAtPoint = [self getObjectAtPoint:CGPointMake(TapLocationX, TapLocationY) ofType:@"backgroundObject"];
            
            if (objectAtPoint == nil) {
                objectID.text = @"HotspotID";
                //may actually just want to return at this point because we did not press on any manipulation or background object
            }
            else
            {
                objectID.text = objectAtPoint;
            }
        }
        else
        {
            objectID.text = objectAtPoint;
        }
        
        objectID.textColor = [UIColor blackColor];
        objectID.borderStyle = UITextBorderStyleRoundedRect;
        
        manipulationType = [[UITextField alloc] initWithFrame:CGRectMake(10, 60, 180, 30)];
        
        //need to return current manipulation type
        NSString *manipulationTypeOfObjectAtPoint= nil;
        manipulationTypeOfObjectAtPoint = [self getManipulationTypeOfObjectAtPoint:CGPointMake(TapLocationX, TapLocationY)];
        
        if (manipulationTypeOfObjectAtPoint == nil) {
            
            if (objectAtPoint == nil)
            {
                manipulationType.text = @"manipulationType";
                //may actually just want to return at this point because we did not press on any manipulation or background object
            }
            else
            {
                manipulationType.text = manipulationTypeOfObjectAtPoint;
            }
        }
        else
        {
            manipulationType.text = manipulationTypeOfObjectAtPoint;
        }
        
        
        manipulationType.textColor = [UIColor blackColor];
        manipulationType.borderStyle = UITextBorderStyleRoundedRect;
        
        UIButton *cancel = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [cancel addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        cancel.frame = CGRectMake(10, 100, 80, 50);
        [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
        
        UIButton *save = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [save addTarget:self action:@selector(changeManipulationType:) forControlEvents:UIControlEventTouchUpInside];
        save.frame = CGRectMake(100, 100, 80, 50);
        [save setTitle:@"Save" forState:UIControlStateNormal];
        
        SingleEntry = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 160)];
        SingleEntry.backgroundColor = [UIColor whiteColor];
        [SingleEntry addSubview:objectID];
        [SingleEntry addSubview:manipulationType];
        [SingleEntry addSubview:cancel];
        [SingleEntry addSubview:save];
        [entryview addSubview:SingleEntry];
        [self.view addSubview:entryview];
        
    }
    else if(row == 7)
    {
        /*
         TODO: add functionality to save animations
         
         */
        
    }
}

-(void)save:(id)sender{

}

-(void)Create:(id)sender{
    if (isAreaViewVisible != false) {
        [areaSpace removeFromSuperview];
    }
    
    areaSpace = [[UIView alloc]initWithFrame:CGRectMake([xcord.text floatValue], [ycord.text floatValue], [width.text floatValue], [height.text floatValue])];
    areaSpace.backgroundColor = [UIColor whiteColor];
    self.isAreaViewVisible = true;
    [self.view addSubview:areaSpace];
    
    [self.view bringSubviewToFront:entryview];
}

-(void)CreateHotspot:(id)sender{
    if (isAreaViewVisible != false) {
        [areaSpace removeFromSuperview];
    }
    
    NSString *xcordPercent = [NSString stringWithFormat:@"%ld", (long)[xcord.text integerValue]];
    NSString *ycordPercent = [NSString stringWithFormat:@"%ld", (long)[ycord.text integerValue]];
    
    NSInteger hleft = [hotspotLeft.text integerValue];
    NSInteger htop = [hotspotTop.text integerValue];
    NSInteger hwidth = [hotspotWidth.text integerValue];
    NSInteger hheight = [hotspotHeight.text integerValue];
    NSInteger xpercent = hleft + hwidth * [xcordPercent integerValue]/100;
    NSInteger ypercent = htop + hheight * [ycordPercent integerValue]/100;
    
    areaSpace = [[UIView alloc]initWithFrame:CGRectMake(xpercent, ypercent, [width.text floatValue], [height.text floatValue])];
    areaSpace.backgroundColor = [UIColor whiteColor];
    self.isAreaViewVisible = true;
    [self.view addSubview:areaSpace];
    
}

-(void)cancel:(id)sender{
    [entryview removeFromSuperview];
    self.isEntryViewVisible = false;
    
    if (isAreaViewVisible == true) {
        [areaSpace removeFromSuperview];
        self.isAreaViewVisible = false;
    }
}

/*
 * Tap gesture. Currently only used for menu selection.
 */
- (IBAction)tapGesturePerformed:(UITapGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];
    
    TapLocationX = location.x;
    TapLocationY = location.y;
    
    /*add an if statement to see if x and y cords will cause the picker to go off the screen if it will adjust size appropriately for x and y cords*/
    picker.frame = CGRectMake(670, 10, 320, 216);
    
    if (isEntryViewVisible == false) {
        [self.view addSubview:picker];
    }
    
    /*
     when tapping anywhere on screen see if it is an object, if it is pop up a new menu
     
     New menu: 
     
     If background
     Save as Waypoint: saves current position and prompts for waypointid name,x, y
     Save as Location: saves current position and prompts for locationid name, x,y height, width
     
     If Image object
     Change Z-Index: enter any number
     Change Height:
     Change Width:
     Change Manipulation type: backgroundObject/manipulationObject
     Save as Hotspot:obj1id(return name of tapped image), action(getIn/pickUp/sit/grab/moveTo/visit) role(subject/object), x, y
     
     */
    
    
    /*CGPoint location = [recognizer locationInView:self.view];
    
        IntroductionClass.allowInteractions = true;
        allowSnapback = false;
    
        
        //No longer moving object
        movingObject = FALSE;
        movingObjectId = nil;
        
        //Re-add the tap gesture recognizer before the menu is removed
        [self.view addGestureRecognizer:tapRecognizer];
    
        
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
    */
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
    
        [self loadNextPage];
}

/*
 * Pan gesture. Used to move objects from one location to another.
 */
-(IBAction)panGesturePerformed:(UIPanGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];
    
    //This should work with requireGestureRecognizerToFail:pinchRecognizer but it doesn't currently.
    if(!pinching && IntroductionClass.allowInteractions) {
        BOOL useProximity = NO;
        
        if(recognizer.state == UIGestureRecognizerStateBegan) {
            //NSLog(@"pan gesture began at location: (%f, %f)", location.x, location.y);
            panning = TRUE;
            
            //Get the object at that point if it's a manipulation object.
            NSString* imageAtPoint = [self getObjectAtPoint:location ofType:@"manipulationObject"];
            
            if(imageAtPoint == nil)
            {
                imageAtPoint = [self getObjectAtPoint:location ofType:@"backgroundObject"];
            }
            //if it's an image that can be moved, then start moving it.
            if(imageAtPoint != nil ) {
                
                //add logging: began object move ?
                
                movingObject = TRUE;
                movingObjectId = imageAtPoint;
                
                
                 NSString* requestImageMarginLeft = [NSString stringWithFormat:@"%@.style.marginLeft", movingObjectId];
                 NSString* requestImageMarginTop = [NSString stringWithFormat:@"%@.style.marginTop", movingObjectId];
                 
                 NSString* imageMarginLeft = [bookView stringByEvaluatingJavaScriptFromString:requestImageMarginLeft];
                 NSString* imageMarginTop = [bookView stringByEvaluatingJavaScriptFromString:requestImageMarginTop];
                 
                 if(![imageMarginLeft isEqualToString:@""] && ![imageMarginTop isEqualToString:@""])
                 {
                     //Calulate offset between top-left corner of image and the point clicked for centered images
                    delta = [self calculateDeltaForMovingObjectAtPointWithCenter:movingObjectId :location];
                 }
                 else
                 {
                 
                     //Calculate offset between top-left corner of image and the point clicked.
                     delta = [self calculateDeltaForMovingObjectAtPoint:location];
                 }
                
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
    //temporarily hide the textbox
    NSString* hideTextbox = [NSString stringWithFormat:@"document.getElementsByClassName(%@).style.display = 'none';", @"'textbox'"];
    //
    
    
    [bookView stringByEvaluatingJavaScriptFromString:hideCanvas];
    [bookView stringByEvaluatingJavaScriptFromString:hideTextbox];
    
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
        else
            return nil;
    }
    else
        return nil;
}

//
-(NSString*) getzindexOfObjectAtPoint:(CGPoint) location ofType:(NSString*)class {
    //Temporarily hide the overlay canvas to get the object we need
    NSString* hideCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.display = 'none';", @"'overlay'"];
    [bookView stringByEvaluatingJavaScriptFromString:hideCanvas];
    
    //Retrieve the elements at this location and see if it's an element that is moveable.
    NSString* requestImageAtPoint = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).id", location.x, location.y];
    
    NSString* requestImageAtPointClass = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).className", location.x, location.y];
    
    
    NSString* imageAtPoint = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPoint];
    
    NSString* requestZindexAtPoint = [NSString stringWithFormat:@"%@.style.zIndex", imageAtPoint];
                                      
    NSString *zindexAtPoint = [bookView stringByEvaluatingJavaScriptFromString:requestZindexAtPoint];
                                      
    NSString* imageAtPointClass = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointClass];
    
    //Bring the canvas back to where it should be.
    //NSString* showCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.zIndex = 100;", @"'overlay'"];
    NSString* showCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.display = 'block';", @"'overlay'"];
    [bookView stringByEvaluatingJavaScriptFromString:showCanvas];
    
    //Check if the object has the correct class, or if no class was specified before returning
    if([imageAtPointClass isEqualToString:class] || class == nil) {
        //Any subject can be used, so just return the object id
        if (useSubject == ALL_ENTITIES)
            return zindexAtPoint;
        else
            return nil;
    }
    else
        return nil;
}


//
-(NSString*) getwidthOfObjectAtPoint:(CGPoint) location ofType:(NSString*)class {
    //Temporarily hide the overlay canvas to get the object we need
    NSString* hideCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.display = 'none';", @"'overlay'"];
    [bookView stringByEvaluatingJavaScriptFromString:hideCanvas];
    
    //Retrieve the elements at this location and see if it's an element that is moveable.
    NSString* requestImageAtPoint = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).id", location.x, location.y];
    
    NSString* requestImageAtPointClass = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).className", location.x, location.y];
    
    
    NSString* imageAtPoint = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPoint];
    
    NSString* requestWidthAtPoint = [NSString stringWithFormat:@"%@.offsetWidth", imageAtPoint];
    
    NSString *widthAtPoint = [bookView stringByEvaluatingJavaScriptFromString:requestWidthAtPoint];
    
    NSString* imageAtPointClass = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointClass];
    
    //Bring the canvas back to where it should be.
    //NSString* showCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.zIndex = 100;", @"'overlay'"];
    NSString* showCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.display = 'block';", @"'overlay'"];
    [bookView stringByEvaluatingJavaScriptFromString:showCanvas];
    
    //Check if the object has the correct class, or if no class was specified before returning
    if([imageAtPointClass isEqualToString:class] || class == nil) {
        //Any subject can be used, so just return the object id
        if (useSubject == ALL_ENTITIES)
            return widthAtPoint;
        else
            return nil;
    }
    else
        return nil;
}

//
-(NSString*) getheightOfObjectAtPoint:(CGPoint) location ofType:(NSString*)class {
    //Temporarily hide the overlay canvas to get the object we need
    NSString* hideCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.display = 'none';", @"'overlay'"];
    [bookView stringByEvaluatingJavaScriptFromString:hideCanvas];
    
    //Retrieve the elements at this location and see if it's an element that is moveable.
    NSString* requestImageAtPoint = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).id", location.x, location.y];
    
    NSString* requestImageAtPointClass = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).className", location.x, location.y];
    
    NSString* imageAtPoint = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPoint];
    
    NSString* requestHeightAtPoint = [NSString stringWithFormat:@"%@.offsetHeight", imageAtPoint];
    
    NSString *heightAtPoint = [bookView stringByEvaluatingJavaScriptFromString:requestHeightAtPoint];
    
    NSString* imageAtPointClass = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointClass];
    
    //Bring the canvas back to where it should be.
    //NSString* showCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.zIndex = 100;", @"'overlay'"];
    NSString* showCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.display = 'block';", @"'overlay'"];
    [bookView stringByEvaluatingJavaScriptFromString:showCanvas];
    
    //Check if the object has the correct class, or if no class was specified before returning
    if([imageAtPointClass isEqualToString:class] || class == nil) {
        //Any subject can be used, so just return the object id
        if (useSubject == ALL_ENTITIES)
            return heightAtPoint;
        else
            return nil;
    }
    else
        return nil;
}

-(NSString*) getTopOfObjectAtPoint:(CGPoint) location ofType:(NSString*)class {
    //Temporarily hide the overlay canvas to get the object we need
    NSString* hideCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.display = 'none';", @"'overlay'"];
    [bookView stringByEvaluatingJavaScriptFromString:hideCanvas];
    
    //Retrieve the elements at this location and see if it's an element that is moveable.
    NSString* requestImageAtPoint = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).id", location.x, location.y];
    
    NSString* requestImageAtPointClass = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).className", location.x, location.y];
    
    NSString* imageAtPoint = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPoint];
    
    NSString* requestTopAtPoint = [NSString stringWithFormat:@"%@.offsetTop", imageAtPoint];
    
    NSString *topAtPoint = [bookView stringByEvaluatingJavaScriptFromString:requestTopAtPoint];
    
    NSString* imageAtPointClass = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointClass];
    
    //Bring the canvas back to where it should be.
    //NSString* showCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.zIndex = 100;", @"'overlay'"];
    NSString* showCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.display = 'block';", @"'overlay'"];
    [bookView stringByEvaluatingJavaScriptFromString:showCanvas];
    
    //Check if the object has the correct class, or if no class was specified before returning
    if([imageAtPointClass isEqualToString:class] || class == nil) {
        //Any subject can be used, so just return the object id
        if (useSubject == ALL_ENTITIES)
            return topAtPoint;
        else
            return nil;
    }
    else
        return nil;
}

-(NSString*) getLeftOfObjectAtPoint:(CGPoint) location ofType:(NSString*)class {
    //Temporarily hide the overlay canvas to get the object we need
    NSString* hideCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.display = 'none';", @"'overlay'"];
    [bookView stringByEvaluatingJavaScriptFromString:hideCanvas];
    
    //Retrieve the elements at this location and see if it's an element that is moveable.
    NSString* requestImageAtPoint = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).id", location.x, location.y];
    
    NSString* requestImageAtPointClass = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).className", location.x, location.y];
    
    NSString* imageAtPoint = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPoint];
    
    NSString* requestLeftAtPoint = [NSString stringWithFormat:@"%@.offsetLeft", imageAtPoint];
    
    NSString *leftAtPoint = [bookView stringByEvaluatingJavaScriptFromString:requestLeftAtPoint];
    
    NSString* imageAtPointClass = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointClass];
    
    //Bring the canvas back to where it should be.
    //NSString* showCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.zIndex = 100;", @"'overlay'"];
    NSString* showCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.display = 'block';", @"'overlay'"];
    [bookView stringByEvaluatingJavaScriptFromString:showCanvas];
    
    //Check if the object has the correct class, or if no class was specified before returning
    if([imageAtPointClass isEqualToString:class] || class == nil) {
        //Any subject can be used, so just return the object id
        if (useSubject == ALL_ENTITIES)
            return leftAtPoint;
        else
            return nil;
    }
    else
        return nil;
}


-(NSString*) getManipulationTypeOfObjectAtPoint:(CGPoint) location {
    //Temporarily hide the overlay canvas to get the object we need
    NSString* hideCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.display = 'none';", @"'overlay'"];
    [bookView stringByEvaluatingJavaScriptFromString:hideCanvas];
    
    NSString* requestImageAtPointClass = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).className", location.x, location.y];
    
    NSString* imageAtPointClass = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointClass];
    
    //Bring the canvas back to where it should be.
    NSString* showCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.display = 'block';", @"'overlay'"];
    [bookView stringByEvaluatingJavaScriptFromString:showCanvas];
    
        //Any subject can be used, so just return the object id
        if (useSubject == ALL_ENTITIES)
            return imageAtPointClass;
        else
            return nil;
}

//save the current state of the xhtml page and overides the loaded page
-(void)saveCurrentHTML{
    //Temporarily hide the overlay canvas to get the object we need
    NSString* hideCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.display = 'none';", @"'overlay'"];
    [bookView stringByEvaluatingJavaScriptFromString:hideCanvas];
    
    //gets current state of html page with updated object locations
    NSString* returnHTML = [NSString stringWithFormat:@"document.documentElement.outerHTML"];
    NSString* currentHMTL = [bookView stringByEvaluatingJavaScriptFromString:returnHTML];
    NSLog(@"%@", currentHMTL);
    
    int startIndex =  [currentHMTL rangeOfString:@"<div id=\"images\" class=\"images\">"].location+20;
    int endIndex = [[currentHMTL substringFromIndex:startIndex] rangeOfString:@"</div>"].location;
    
    NSString *newImages = [currentHMTL substringFromIndex:startIndex];
    newImages = [newImages substringToIndex:endIndex];
    
    NSString *concatenatedString = @"";
    
    for(int i =0; i<newImages.length; i++)
    {
        NSString *curChar = [NSString stringWithFormat:@"%c", [newImages characterAtIndex:i]];
        
        if([curChar isEqualToString:@"<"])
        {
            NSRange range = NSMakeRange(i, newImages.length-i);
            int topStartIndex = [newImages rangeOfString:@"top:" options:0 range:range].location;
            int topEndIndex = [[newImages substringFromIndex:topStartIndex+4] rangeOfString:@";"].location;
            NSString *topString = [newImages substringFromIndex:topStartIndex+4];
            BOOL needsConversion = nil;
            topString = [topString substringToIndex:topEndIndex];
            
            if ([topString rangeOfString:@"px"].location != NSNotFound) {
                needsConversion = true;
                topString = [topString substringToIndex:topString.length-2];
            }
            else
            {
                needsConversion = false;
                topString = [topString substringToIndex:topString.length-1];
            }
            
            [topString stringByReplacingOccurrencesOfString:@" " withString:@""];
            
            int leftStartIndex = [newImages rangeOfString:@"left:" options:0 range:range].location;
            int leftEndIndex = [[newImages substringFromIndex:leftStartIndex+5] rangeOfString:@";"].location;
            NSString *leftString = [newImages substringFromIndex:leftStartIndex+5];
            leftString = [leftString substringToIndex:leftEndIndex];
            
            if ([leftString rangeOfString:@"px"].location != NSNotFound) {
                needsConversion = true;
                leftString = [leftString substringToIndex:leftString.length-2];
            }
            else
            {
                needsConversion=false;
                leftString = [leftString substringToIndex:leftString.length-1];
            }
            
            [leftString stringByReplacingOccurrencesOfString:@" " withString:@""];
            
            for(int j = i; j<newImages.length; j++)
            {
            
                NSString *nextChar = [NSString stringWithFormat:@"%c", [newImages characterAtIndex:j]];
                
                if ([nextChar isEqualToString:@">"]) {
                    concatenatedString = [concatenatedString stringByAppendingString:@"/"];
                    concatenatedString = [concatenatedString stringByAppendingString:nextChar];
                    i=j;
                    j=newImages.length;
                }
                else if(j==topStartIndex)
                {
                    float topPixelValue = [topString floatValue];
                    NSString *topPercentValueString;
                    
                    float viewH = [self areaSpace].frame.size.height;
                    float viewW = [self areaSpace].frame.size.width;
                    float bookH = [bookView frame].size.height;
                    float bookW = [bookView frame].size.width;
                    NSString *htmlH = [bookView stringByEvaluatingJavaScriptFromString:@"document.innerWidth"];
                    NSString *htmlW = [bookView stringByEvaluatingJavaScriptFromString:@"document.innerHeight"];
                    
                    
                    if (needsConversion) {
                        Float32  topPercentValue = ((topPixelValue / ([bookView frame].size.height))*100); //-32
                        topPercentValueString = [NSString stringWithFormat:@"top: %f%%",topPercentValue];
                    }
                    else
                    {
                        topPercentValueString = [NSString stringWithFormat:@"top: %f%%",topPixelValue];
                    }
                    
                    concatenatedString = [concatenatedString stringByAppendingString:topPercentValueString];
                    j=topEndIndex+topStartIndex+3;
                }
                else if(j == leftStartIndex)
                {
                    float leftPixelValue = [leftString floatValue];
                    NSString *leftPercentValueString;
                    
                    if (needsConversion) {
                        Float32 leftPercentValue = ((leftPixelValue / ([bookView frame].size.width))*100);//-12
                        leftPercentValueString = [NSString stringWithFormat:@"left: %f%%",leftPercentValue];
                    }
                    else
                    {
                        leftPercentValueString = [NSString stringWithFormat:@"left: %f%%",leftPixelValue];
                    }
                    
                    
                    concatenatedString = [concatenatedString stringByAppendingString:leftPercentValueString];
                    j=leftEndIndex+leftStartIndex+4;
                }
                else
                {
                    concatenatedString = [concatenatedString stringByAppendingString:nextChar];
                }
            }
        }
        else
        {
            concatenatedString = [concatenatedString stringByAppendingString:curChar];
        }
    }
    
    NSLog(@"%@", concatenatedString);
    
    startIndex = [pageContents rangeOfString:@"<div id=\"images\" class=\"images\">"].location+20;
    endIndex = [[pageContents substringFromIndex:startIndex] rangeOfString:@"</div>"].location+startIndex;
    NSString *finalHTML = [pageContents substringToIndex:startIndex];
    NSLog(@"%@", finalHTML);
    finalHTML = [finalHTML stringByAppendingString:concatenatedString];
    NSLog(@"%@", finalHTML);
    NSString *tempString = [pageContents substringFromIndex:endIndex];
    NSLog(@"%@", tempString);
    finalHTML = [finalHTML stringByAppendingString:tempString];
    NSLog(@"%@", finalHTML);
    
    //saves current state of html page with updated locations and overides file (overidding currently turned off to not loose data for finished stories and instead saves a copy into the same directly as the log files)
    //eventually will be changed to simply write to same directory that file actually exists in and will override it
    //will still have to rebuild the epubs inorder to see the new changes to the xhtml file
    
        //
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
        //
        NSString *documentsDirectory = [paths objectAtIndex:0];
    
        NSString* fileName = [NSString stringWithFormat:@"%@%@",[[currentPage lastPathComponent] substringToIndex:[currentPage lastPathComponent].length-6], @"copy"];
    
        //file path to save to
        NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", fileName, @"xhtml"]];
        //toggle to switch between saving at logging location or to overide file
        //NSString *path = [book mainContentPath] stringByAppendingString:fileName];
    
        if (![finalHTML writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
            NSLog(@"Could not write document out...");
            NSLog(@"%@", finalHTML);
        }
    
        NSLog(@"%@", finalHTML);
        NSLog(@"Successfully wrote file");
}

-(void)saveCurrentStep{
    
    /*
     steps should already be saved
     */
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
 * Calculates the delta pixel change for the object that is being moved
 * and changes the lcoation from relative % to pixels if necessary.
 */
-(CGPoint) calculateDeltaForMovingObjectAtPointWithCenter:(NSString*) object :(CGPoint) location {
    CGPoint change;
    
    //Calculate offset between top-left corner of image and the point clicked.
    NSString* requestImageAtPointTop = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).offsetTop", location.x, location.y];
    NSString* requestImageAtPointLeft = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).offsetLeft", location.x, location.y];
    
    NSString* imageAtPointTop = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointTop];
    NSString* imageAtPointLeft = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointLeft];
    
    //Get the width and height of the image to ensure that the image is not being moved off screen and that the image is being moved in accordance with all movement constraints.
    NSString* requestImageHeight = [NSString stringWithFormat:@"%@.height", object];
    NSString* requestImageWidth = [NSString stringWithFormat:@"%@.width", object];
    
    float imageHeight = [[bookView stringByEvaluatingJavaScriptFromString:requestImageHeight] floatValue];
    float imageWidth = [[bookView stringByEvaluatingJavaScriptFromString:requestImageWidth] floatValue];
    
    //Check to see if the locations returned are in percentages. If they are, change them to pixel values based on the size of the screen.
    NSRange rangePercentTop = [imageAtPointTop rangeOfString:@"%"];
    NSRange rangePercentLeft = [imageAtPointLeft rangeOfString:@"%"];
    
    if(rangePercentTop.location != NSNotFound)
        change.y = location.y - ([imageAtPointTop floatValue] / 100.0 * [bookView frame].size.height) -(imageHeight/2);
    else
        change.y = location.y - [imageAtPointTop floatValue]-(imageHeight/2);
    
    if(rangePercentLeft.location != NSNotFound)
        change.x = location.x - ([imageAtPointLeft floatValue] / 100.0 * [bookView frame].size.width) -(imageWidth/2);
    else
        change.x = location.x - [imageAtPointLeft floatValue]-(imageWidth/2);
    
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
    
    NSString* requestImageMarginLeft = [NSString stringWithFormat:@"%@.style.marginLeft", movingObjectId];
    NSString* requestImageMarginTop = [NSString stringWithFormat:@"%@.style.marginTop", movingObjectId];
    
    NSString* imageMarginLeft = [bookView stringByEvaluatingJavaScriptFromString:requestImageMarginLeft];
    NSString* imageMarginTop = [bookView stringByEvaluatingJavaScriptFromString:requestImageMarginTop];
    
    if(![imageMarginLeft isEqualToString:@""] && ![imageMarginTop isEqualToString:@""])
    {
        //Check to see if the image is being moved off screen. If it is, change it so that the image cannot be moved off screen.
        if(adjLocation.x + (imageWidth/2) > [bookView frame].size.width)
            adjLocation.x = [bookView frame].size.width - (imageWidth/2);
        else if(adjLocation.x-(imageWidth/2)  < 0)
            adjLocation.x = (imageWidth/2);
        if(adjLocation.y + (imageHeight/2) > [bookView frame].size.height)
            adjLocation.y = [bookView frame].size.height - (imageHeight/2);
        else if(adjLocation.y-(imageHeight/2) < 0)
            adjLocation.y = (imageHeight/2);
    }
    else
    {
        //Check to see if the image is being moved off screen. If it is, change it so that the image cannot be moved off screen.
        if(adjLocation.x + imageWidth > [bookView frame].size.width)
            adjLocation.x = [bookView frame].size.width - imageWidth;
        else if(adjLocation.x < 0)
            adjLocation.x = 0;
        if(adjLocation.y + imageHeight > [bookView frame].size.height)
            adjLocation.y = [bookView frame].size.height - imageHeight;
        else if(adjLocation.y < 0)
            adjLocation.y = 0;
    }
    
    //May want to add code to keep objects from moving to the location that the text is taking up on screen.
    
    //logs only if object is moved by computer action, user pan done outside of this function
    if (![waypointID isEqualToString:@"isMoving"]) {
        //Logging added by James for Automatic Computer Move Object
        
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
    if ([IntroductionClass.introductions objectForKey:chapterTitle]) {
        // If the user pressed next
            if (IntroductionClass.currentIntroStep > IntroductionClass.totalIntroSteps) {
                [self saveCurrentHTML];
                [self loadNextPage]; //logging done in loadNextPage
            }
            else {
                // Load the next step
                [IntroductionClass loadIntroStep:bookView: currentSentence];
                [self setupCurrentSentenceColor];
                
                //add logging: next intro step
            }
    }
    else if ([IntroductionClass.vocabularies objectForKey:chapterTitle] && [currentPageId rangeOfString:@"Intro"].location != NSNotFound) {
    
            [self saveCurrentHTML];
            [self loadNextPage]; //logging done in loadNextPage
    }
        else{
            //For the moment just move through the sentences, until you get to the last one, then move to the next activity.
            currentSentence++;
            
            //Set up current sentence appearance and solution steps
            [self saveCurrentHTML];
            [self setupCurrentSentence];
            [self colorSentencesUponNext];
            
            //currentSentence is 1 indexed.
            if(currentSentence > totalSentences) {
                [self loadNextPage];
                //logging done in loadNextPage
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



/* Clears the highlighting on the scene */
-(void)clearHighlightedObject {
    NSString *clearHighlighting = [NSString stringWithFormat:@"clearAllHighlighted()"];
    [bookView stringByEvaluatingJavaScriptFromString:clearHighlighting];
    
    //log clear
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



@end
