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
@interface PMViewController () {
    NSString* currentPage; //The current page being shown, so that the next page can be requested. 
    
    NSUInteger currentSentence; //Active sentence to be completed.
    NSUInteger totalSentences; //Total number of sentences on this page.
    
    NSString* movingObjectId; //Object currently being moved.
    NSString* separatingObjectId; //Object identified when pinch gesture performed.
    BOOL movingObject; //True if an object is currently being moved, false otherwise.
    BOOL sepearatingObject; //True if two objects are currently being ungrouped, false otherwise.
    
    BOOL pinching;
    
    CGPoint delta; //distance between the top-left corner of the image being moved and the point clicked.
    
    ContextualMenuDataSource *menuDataSource;
    PieContextualMenu *menu;
    
    InteractionModel *model;
}

@property (nonatomic, strong) IBOutlet UIWebView *bookView;

@end

@implementation PMViewController

@synthesize book;

@synthesize bookTitle;
@synthesize chapterTitle;

@synthesize bookImporter;
@synthesize bookView;

//Used to determine the required proximity of 2 hotspots to group two items together.
float const groupingProximity = 20.0;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    bookView.frame = self.view.bounds;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    movingObjectId = nil;
    separatingObjectId = nil;
    
    currentPage = nil;
    
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
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"jsDraw2D" ofType:@"js"];
    
    if(filePath == nil) {
        NSLog(@"Cannot find js file: jsDraw2D");
    }
    else {
        NSData *fileData = [NSData dataWithContentsOfFile:filePath];
        NSString *jsString = [[NSMutableString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
        [bookView stringByEvaluatingJavaScriptFromString:jsString];
    }

    filePath = [[NSBundle mainBundle] pathForResource:@"ImageManipulation" ofType:@"js"];
    
    if(filePath == nil) {
        NSLog(@"Cannot find js file: ImageManipulation");
    }
    else {
        NSData *fileData = [NSData dataWithContentsOfFile:filePath];
        NSString *jsString = [[NSMutableString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
        [bookView stringByEvaluatingJavaScriptFromString:jsString];
    }
    
    //Set the sentence count for this page.
    NSString* requestSentenceCount = [NSString stringWithFormat:@"document.getElementsByClassName('sentence').length"];
    NSString* sentenceCount = [bookView stringByEvaluatingJavaScriptFromString:requestSentenceCount];
    totalSentences = [sentenceCount intValue];
    
    //Set sentence color to blue for first sentence.
    NSString* setSentenceColor = [NSString stringWithFormat:@"setSentenceColor(s%d, 'blue')", currentSentence];
    [bookView stringByEvaluatingJavaScriptFromString:setSentenceColor];
    
    //Bold sentence
    NSString* setSentenceWeight = [NSString stringWithFormat:@"setSentenceFontWeight(s%d, 'bold')", currentSentence];
    [bookView stringByEvaluatingJavaScriptFromString:setSentenceWeight];
    
    //Set the opacity of all but the current sentence to .5
    //Color will default to blue. And be changed to green once it's been done. 
    for(int i = currentSentence; i < totalSentences; i++) {
        NSString* setSentenceOpacity = [NSString stringWithFormat:@"setSentenceOpacity(s%d, .5)", i + 1];
        [bookView stringByEvaluatingJavaScriptFromString:setSentenceOpacity];
    }
}

//creates pages and the content
- (void) loadFirstPage {
    book = [bookImporter getBookWithTitle:bookTitle]; //Get the book reference.
    model = [book model];
    
    currentPage = [book getNextPageForChapterAndActivity:chapterTitle :PM_MODE :nil];
    
    [self loadPage];
}

-(void) loadNextPage {    
    currentPage = [book getNextPageForChapterAndActivity:chapterTitle :PM_MODE :currentPage];
    
    while (currentPage == nil) {
        chapterTitle = [book getChapterAfterChapter:chapterTitle];
        
        if(chapterTitle == nil) { //no more chapters.
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
    
        currentPage = [book getNextPageForChapterAndActivity:chapterTitle :PM_MODE :nil];
    }
    [self loadPage];
}

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
    
    currentSentence = 1;
    self.title = chapterTitle;
}


#pragma mark - Responding to gestures
/*
 * Tap gesture. Currently only used for menu selection.
 * TODO: We need to come back to this function and figure out a way to distinguish between a menu that's created for disambiguation of possible grouping/disappearing interactions and a menu that's created for ungrouping objects. Right now this function only handles ungrouping. This will be directly relevant to both the conditions.
 */
- (IBAction)tapGesturePerformed:(UITapGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];
    
    //check to see if we have a menu open. If so, process menu click. 
    if(menu != nil) {
        int menuItem = [menu pointInMenuItem:location];
        
        //If we've selected a menuItem.
        if(menuItem != -1) {
            //NSLog(@"selected menu item: %d with value: %@", menuItem, [menuDataSource dataObjectAtIndex:menuItem]);
            MenuItemDataSource *dataForItem = [menuDataSource dataObjectAtIndex:menuItem];
            NSArray * objectIds = [dataForItem objectIds]; //get the object Ids for this particular menuItem.
            NSString* obj1 = [objectIds objectAtIndex:0]; //get object 1
            NSString* obj2 = [objectIds objectAtIndex:1]; //get object 2
                    
            [self ungroupObjects:obj1 :obj2]; //ungroup the objects.*/
        }
        
        //Remove menu. 
        [menu removeFromSuperview];
        menu = nil;
    }
    else {
        //Get the object at that point if it's a manipulation object.
        //NSString* imageAtPoint = [self getManipulationObjectAtPoint:location];
        //NSLog(@"location pressed: (%f, %f)", location.x, location.y);
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
 * Pinch gesture. Used to ungroup two images from each other.
 */
-(IBAction)pinchGesturePerformed:(UIPinchGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];

    if(recognizer.state == UIGestureRecognizerStateBegan) {
        pinching = TRUE;
        
        NSString* imageAtPoint = [self getManipulationObjectAtPoint:location];
        
        NSLog(@"imageAtPoint: %@", imageAtPoint);
        //if it's an image that can be moved, then start moving it.
        if(imageAtPoint != nil) {
            separatingObjectId = imageAtPoint;
        }
    }
    else if(recognizer.state == UIGestureRecognizerStateEnded) {
        //Get other objects grouped with this object.
        NSString* requestGroupedImages = [NSString stringWithFormat:@"getGroupedObjectsString(%@)", separatingObjectId];
        NSString* groupedImages = [bookView stringByEvaluatingJavaScriptFromString:requestGroupedImages];

        NSLog(@"in pinch gesture recognizer state ended, and got list of groupe images: %@", groupedImages);
        
        //If there is an array, split the array based on pairs.
        if(![groupedImages isEqualToString:@""]) {
            NSArray* itemPairArray = [groupedImages componentsSeparatedByString:@"; "];
            
            menuDataSource = [[ContextualMenuDataSource alloc] init];
            
            //Create the menu with the connections to allow the user to select which 2 objects they want to ungroup.
            if([itemPairArray count] > 1) {
                //NSMutableArray* items = [[NSMutableArray alloc] init];
                
                //[menuDataSource setData:items];
                
                for(NSString* pairStr in itemPairArray) {
                    //separate the objects in this pair.
                    NSArray *itemPair = [pairStr componentsSeparatedByString:@", "];
                    
                    NSLog(@"item: %@ is grouped with %@", [itemPair objectAtIndex:0], [itemPair objectAtIndex:1]);
                    
                    NSMutableArray* items = [[NSMutableArray alloc] init];
                    NSMutableArray* itemIds = [[NSMutableArray alloc] init];
                    
                    //Get the images associated with each item and create an array of images for the data source, then add to the menuItem.
                    for(NSString* item in itemPair) {
                        NSString* requestImageSrc = [NSString stringWithFormat:@"%@.src", item];
                        NSString* imageSrc = [bookView stringByEvaluatingJavaScriptFromString:requestImageSrc];
                        
                        //NSLog(@"imageSource: %@", imageSrc);
                        NSRange range = [imageSrc rangeOfString:@"file:"];
                        NSString* imagePath = [imageSrc substringFromIndex:range.location + range.length + 1];
                        //NSLog(@"imagePath: %@", imagePath);
                        
                        UIImage* image = [[UIImage alloc] initWithContentsOfFile:imagePath];
                        
                        if(image == nil)
                            NSLog(@"image is nil");
                        else
                            [items addObject:image];
                        
                        [itemIds addObject:item];
                    }
                    
                    //Create the menuItem object that will hold the data and add menuItem to the menuDataSource
                    //Eventually there should be a way to standardize the relationship information in the epub so that
                    //both the relationship type and what it means for the images can be pulled from there.
                    //This is assuming we'll be using this menu style for grouping images in different ways too. 
                    [menuDataSource addMenuItem:@"is grouped with" :itemIds :items];
                }
                
                NSLog(@"multiple ungrouping options...showing menu");
                
                [self expandMenu];
            }
            else if([itemPairArray count] == 1) {
                NSArray *pair = [[itemPairArray objectAtIndex:0] componentsSeparatedByString:@", "];
                
                NSString* obj1 = [pair objectAtIndex:0]; //get object 1
                NSString* obj2 = [pair objectAtIndex:1]; //get object 2
                
                [self ungroupObjects:obj1 :obj2]; //ungroup the objects.
                NSLog(@"ungrouping two objects");
            }
            else
                NSLog(@"no items grouped");
        }
        pinching = FALSE;
    }
}

/*
 Pan gesture. Used to move objects from one location to another.
 */
-(IBAction)panGesturePerformed:(UIPanGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];
    
    //This should work with requireGestureRecognizerToFail:pinchRecognizer but it doesn't currently.
    if(!pinching) {
        if(recognizer.state == UIGestureRecognizerStateBegan) {
            //NSLog(@"pan gesture began at location: (%f, %f)", location.x, location.y);
            
            //Get the object at that point if it's a manipulation object.
            NSString* imageAtPoint = [self getManipulationObjectAtPoint:location];
            //NSLog(@"location pressed: (%f, %f)", location.x, location.y);
            
            //if it's an image that can be moved, then start moving it.
            if(imageAtPoint != nil) {
                movingObject = TRUE;
                movingObjectId = imageAtPoint;
                
                //Calculate offset between top-left corner of image and the point clicked.
                delta = [self calculateDeltaForMovingObjectAtPoint:location];
            }
        }
        else if(recognizer.state == UIGestureRecognizerStateEnded) {
            //NSLog(@"pan gesture ended at location (%f, %f)", location.x, location.y);
            //if moving object, move object to final position.
            if(movingObject) {
                [self moveObject:movingObjectId :location :delta];
                
                //If the object was dropped, check if it's overlapping with any other objects that it could interact with.
                NSMutableArray* possibleInteractions = [self getPossibleInteractions];

                //If only 1 possible interaction was found, go ahead and perform that interaction.
                if([possibleInteractions count] == 1) {
                    //Check whether the type of interaction is a disappear or group interaction, and call the appropriate function.
                    
                    //TODO: Do we also need a specific way to encode a transfer interaction, and if so how do we do that both in the array that we return and when checking to see what we're doing.
                }
                //If more than 1 was found, prompt the user to disambiguate.
                else if ([possibleInteractions count] > 1){
                    //Create data source for menu.
                    
                    //Expand menu.
                    [self expandMenu];
                }
                
                //No longer moving object
                movingObject = FALSE;
                movingObjectId = nil;
            }
        }
        //If we're in the middle of moving the object, just call the JS to move it.
        else if(movingObject)  {
            //InteractionModel *model = [book model];
            
            //NSLog(@"pan gesture continued");
            [self moveObject:movingObjectId :location :delta];
            
            [self drawHotspots:[model getHotspotsForObjectId:movingObjectId]];
            //If we're overlapping with another object, then we need to figure out which hotspots are currently active and highlight those hotspots.
            //Starting with the simple case of moving an object that is not grouped to any other object, and then expanding from there.
            //When moving the object, we may have the JS return a list of all the objects that are currently grouped together so that we can process all of them.
            NSString *overlappingObjects = [NSString stringWithFormat:@"checkObjectOverlapString(%@)", movingObjectId];
            NSString* overlapArrayString = [bookView stringByEvaluatingJavaScriptFromString:overlappingObjects];
            
            if(![overlapArrayString isEqualToString:@""]) {
                //NSLog(@"overlapping with: %@", overlapArrayString);
            
                NSArray* overlappingWith = [overlapArrayString componentsSeparatedByString:@", "];
                            
                for(NSString* objId in overlappingWith) {
                    //we have the list of objects it's overlapping with, we now have to figure out which hotspots to draw.                    
                    NSMutableArray* hotspots = [model getHotspotsForObjectOverlappingWithObject:movingObjectId :objId];
                    [self drawHotspots:hotspots];
                }
            }
        }
    }
}

/* 
 * Sends the JS request for the element at the location provided, and takes care of moving any
 * canvas objects out of the way to get accurate information.
 * It also checks to make sure the object that is at that point is a manipulation object before returning it.
 */
-(NSString*) getManipulationObjectAtPoint:(CGPoint) location {
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
    
    if([imageAtPointClass isEqualToString:@"manipulationObject"])
        return imageAtPoint;
    else
        return nil;
}

/*
 * Returns all possible interactions that can occur between the object being moved and any other objects it's overlapping with.
 * This function takes into account all hotspots, both available and unavailable. It checkes cases in which all hotspots are 
 * available, as well as instances in which one hotspots is already taken up by a grouping but the other is not. The function
 * currently checks both group and disappear interaction types.
 */
-(NSMutableArray*) getPossibleInteractions {
    //TODO: This was copied over directly from the panGesturePerformed function condition in which the recognizer state has ended. Need to update this code to return a list of possible interactions that makes sense instead of doing all this work in this function. Some of this code may need to be moved back to the panGesturePerformed function, while other code may need to be split into other smaller functions. Still other code needs to be added to return the appropriate possible interactions.
    NSMutableArray* groupings = [[NSMutableArray alloc] init];
    
    //We also want to double check and make sure that neither of the objects is already grouped with another object at the relevant hotspots. If it is, that means we may need to transfer the grouping, instead of creating a new grouping.
    //If it is, we have to make sure that the hotspots for the two objects are within a certain radius of each other for the grouping to occur.
    //If they are, we want to go ahead and group the objects.
    NSString *overlappingObjects = [NSString stringWithFormat:@"checkObjectOverlapString(%@)", movingObjectId];
    NSString* overlapArrayString = [bookView stringByEvaluatingJavaScriptFromString:overlappingObjects];
    
    if(![overlapArrayString isEqualToString:@""]) {
        //NSLog(@"overlapping with: %@", overlapArrayString);
        
        NSArray* overlappingWith = [overlapArrayString componentsSeparatedByString:@", "];
        
        for(NSString* objId in overlappingWith) {
            NSMutableArray* hotspots = [model getHotspotsForObjectOverlappingWithObject:movingObjectId :objId];
            NSMutableArray* movingObjectHotspots = [model getHotspotsForObjectOverlappingWithObject:objId :movingObjectId];
            
            //Figure out if one of the hotspots from the object we're moving is within close distance of one of the hotspots from the overlapping object. If it is, then group them based on that hotspot.
            for(Hotspot* hotspot in hotspots) {
                for(Hotspot* movingObjectHotspot in movingObjectHotspots) {
                    //Need to calculate exact pixel locations of both hotspots and then make sure they're within a specific distance of each other.
                    CGPoint movingObjectHotspotLoc = [self getHotspotLocation:movingObjectHotspot];
                    CGPoint hotspotLoc = [self getHotspotLocation:hotspot];
                    
                    //calculate delta between the two hotspot locations.
                    float deltaX = fabsf(movingObjectHotspotLoc.x - hotspotLoc.x);
                    float deltaY = fabsf(movingObjectHotspotLoc.y - hotspotLoc.y);
                    
                    //Check to make sure that the two hotspots are in close proximity to each other.
                    //TODO: Possibly move a lot of this over the the JS side. Ask JS to come up with a list of reasonable connection points.
                    //TODO: There's a logic bug in the code currently, in which this code actually goes through all possible hotspots and checks them all, even if it found a hotspot that's reasonable. This both does and doesn't make sense at the same time. In order to figure out when transference has to occur, all hotspots must be checked. Similarly, in order to figure out when there's ambiguity in possible connections all hotspots must be checked. On the other hand, no more than 1 connection should be made per interaction. The current code is making multiple connections per interactions, and this is wrong.
                    if(deltaX <= groupingProximity && deltaY <= groupingProximity) {
                        //We also want to go ahead and snap the objects in place based on the hotspots so we need to calculate the (x,y) positions of each of these objects such that the hotspots are in the same spot. How do we do this?
                        
                        //Check to see if either of these hotspots are currently connected to another objects.
                        //If not, then go ahead and group...if they are, then we have to create a menu to show the possibilities of how the objects could be connected.
                        NSString *isHotspotConnectedMovingObject = [NSString stringWithFormat:@"isObjectGroupedAtHotspot(%@, %f, %f)", movingObjectId, movingObjectHotspotLoc.x, movingObjectHotspotLoc.y];
                        NSString* isHotspotConnectedMovingObjectString  = [bookView stringByEvaluatingJavaScriptFromString:isHotspotConnectedMovingObject];
                        
                        NSString *isHotspotConnectedObject = [NSString stringWithFormat:@"isObjectGroupedAtHotspot(%@, %f, %f)", objId, hotspotLoc.x, hotspotLoc.y];
                        NSString* isHotspotConnectedObjectString  = [bookView stringByEvaluatingJavaScriptFromString:isHotspotConnectedObject];
                        
                        NSLog(@"moving object hotspot connected: %@", isHotspotConnectedMovingObjectString);
                        NSLog(@"Static object hotspot connected: %@", isHotspotConnectedObjectString);
                        
                        //Only connect the two if the hotspots are free for the moment, and if the possible relationship between these two objects is of type "group".
                        //Get the relationship between these two objects so we can check to see what type of relationship it is.
                        //First we may need to disambiguate. If we do..then what? TODO: Figure this out...I think this is what's happening here. Also need to split this function into smaller pieces again.
                        Relationship* relationshipBetweenObjects = [model getRelationshipForObjectsForAction:movingObjectId :objId :[movingObjectHotspot action]];
                        
                        if([isHotspotConnectedMovingObjectString isEqualToString:@"false"] && [isHotspotConnectedObjectString isEqualToString:@"false"]) {
                            //TODO: Pretty sure this needs to be moved back up to the panGesturePerformed function, but I need to first establish what the mutable array is going to produce. Doing so may actually fix the bug that's causing the exception to be thrown in the case of disappearing items.
                            //If they're suppposed to be grouped, go ahead and group them.
                            if([[relationshipBetweenObjects  actionType] isEqualToString:@"group"]) {
                                [self groupObjects:movingObjectId :movingObjectHotspotLoc :objId :hotspotLoc];
                            }
                            //If one of the objects is supposed to disappear, then we're going to hide the object that is supposed to disappear and make it re-appear at it's "appear" hotspot location.
                            else if([[relationshipBetweenObjects actionType] isEqualToString:@"disappear"]) {
                                //Figure out which object is the one that needs to disappear. We can use the relationship information for this. In the relationship, object1 is the one causing the disappearing, and object2 is the one doing the disappearing.
                                [self consumeAndReplenishSupply:[relationshipBetweenObjects object2Id]];
                            }
                        }
                        else {
                            NSLog(@"at least one object's hotspot is already taken");
                        }
                    }
                    
                }
            }
        }
    }
    
    return groupings;
}

/*
 * Calculates the delta pixel change for the object that is being moved
 * and changes the lcoation from relative % to pixels if necessary.
 * TODO: Figure out why this isn't being called anywhere besides the new consumeAndReplenish function.
 */
-(CGPoint) calculateDeltaForMovingObjectAtPoint:(CGPoint) location {
    CGPoint change;
    
    //Calculate offset between top-left corner of image and the point clicked.
    NSString* requestImageAtPointTop = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).offsetTop", location.x, location.y];
    NSString* requestImageAtPointLeft = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).offsetLeft", location.x, location.y];
    
    NSString* imageAtPointTop = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointTop];
    NSString* imageAtPointLeft = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointLeft];
    
    //NSLog(@"location of %@: (%@, %@)", movingObjectId, imageAtPointLeft, imageAtPointTop);
    
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
 */
-(void) moveObject:(NSString*) object :(CGPoint) location :(CGPoint)offset {
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
    //TODO: come back to this and figure out why the slight shift. 
    if([constraints count] > 0) {
        MovementConstraint* constraint = (MovementConstraint*)[constraints objectAtIndex:0];
    
        //Calculate the x,y coordinates and the width and height in pixels from %
        //TODO: See if I can list a width, height, x, and y for the background image and then retrieve the size of that image in order to calculate the
        //location of the bounding box. If this works we may consider using some sort of calculation based on the ratio of the background and the [bookView frame] size to calculate the point that should be used to identify the items being manipulated as well and see if this solves all the problems that we've been seeing.
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

    //NSLog(@"new location of %@: (%f, %f)", object, adjLocation.x, adjLocation.y);
    //Call the moveObject function in the js file.
    NSString *move = [NSString stringWithFormat:@"moveObject(%@, %f, %f)", object, adjLocation.x, adjLocation.y];
    [bookView stringByEvaluatingJavaScriptFromString:move];
}

/* 
 * Calls the JS function to group two objects at the specified hotspots.
 */
-(void) groupObjects:(NSString*)object1 :(CGPoint)object1Hotspot :(NSString*)object2 :(CGPoint)object2Hotspot {
    NSString *groupObjects = [NSString stringWithFormat:@"groupObjectsAtLoc(%@, %f, %f, %@, %f, %f)", object1, object1Hotspot.x, object1Hotspot.y, object2, object2Hotspot.x, object2Hotspot.y];
    [bookView stringByEvaluatingJavaScriptFromString:groupObjects];
}

/* 
 * Calls the JS function to ungroup two objects.
 */
-(void) ungroupObjects:(NSString* )object1 :(NSString*) object2 {
    NSString* ungroup = [NSString stringWithFormat:@"ungroupObjects(%@, %@)", object1, object2];
    [bookView stringByEvaluatingJavaScriptFromString:ungroup];
}

/*
 * Handles instances in which two objects are connected, but in which the user wants to transfer that grouping to a 
 * third object. (Example: the farmer puts the hay in the cart. In this case the user is not required to first ungroup the 
 * hay from the farmer before grouping it with the car, because it's the farmer that's actually doing the action. Instead, 
 * the application should automatically detect this case, and ungroup the hay from the farmer and group it to the cart directly.
 * object1 is the object that is doing the action. In this example, it's the farmer. object2 is the object that is being
 * transfered, in this case the hay. object3 is the object accepting the transfer, in this case the cart. 
 * In order to properly group the hay and the cart together, we need the hotspots at which they should be grouped.
 */
-(void) transferGrouping:(NSString*)object1 :(NSString*)object2 :(CGPoint)object2Hotspot :(NSString*)object3 :(CGPoint)object3Hotspot {
    //Ungroup object 1 from object 2.
    [self ungroupObjects:object1 :object2];
    
    //Group object 2 and object 3 at the specified hotspots.
    [self groupObjects:object2 :object2Hotspot :object3 :object3Hotspot];
}

/*
 * Call JS code to cause the object to disappear, then calculate where it needs to re-appear and call the JS code to make
 * it re-appear at the new location.
 * TODO: Figure out why the object isn't being moved appropriately once I get the new epub.
 * TODO: Figure out how to deal with instances of transferGrouping + consumeAndReplenishSupply
 */
- (void) consumeAndReplenishSupply:(NSString*)disappearingObject {
    //First hide the object that needs to disappear.
    NSString* hideObj = [NSString stringWithFormat:@"document.getElementById(%@).style.visibility = 'hidden';", disappearingObject];
    [bookView stringByEvaluatingJavaScriptFromString:hideObj];
    
    //Next move the object to the "appear" hotspot location. This means finding the hotspot that specifies this information for the object, and also finding the relationship that links this object to the other object it's supposed to appear at/in.
    //NSMutableArray *hiddenObjectHotspots = [model getHotspotsForObjectId:disappearingObject];
    Hotspot* hiddenObjectHotspot = [model getHotspotforObjectWithActionAndRole:disappearingObject :@"appear" :@"subject"];
    
    //Get the relationship between this object and the other object specifying where the object should appear. Even though the call is to a general function, there should only be 1 valid relationship returned.
    NSLog(@"disappearing object id: %@", disappearingObject);
    
    NSMutableArray* relationshipsForHiddenObject = [model getRelationshipForObjectForAction:disappearingObject :@"appear"];
    NSLog(@"number of relationships for Hidden Object: %d", [relationshipsForHiddenObject count]);

    //There should be one and only one valid relationship returned, but we'll double check anyway.
    if([relationshipsForHiddenObject count] > 0) {
        Relationship *appearRelation = [relationshipsForHiddenObject objectAtIndex:0];
    
        NSLog(@"find hotspot in %@ for %@ to appear in", [appearRelation object2Id], disappearingObject);
        
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
                NSLog(@"found hotspot on hidden object that we need to match to the other object.");
                
                //With both hotspot pixel values we can calcuate the distance between the top-left corner of the hidden object and it's hotspot.
                CGPoint change = [self calculateDeltaForMovingObjectAtPoint:hiddenObjectHotspotLocation];
                
                //Now move the object taking into account the difference in change.
                [self moveObject:disappearingObject :appearLocation :change];
                
                //Then show the object again.
                NSString* showObj = [NSString stringWithFormat:@"document.getElementById(%@).style.visibility = 'visible';", disappearingObject];
                [bookView stringByEvaluatingJavaScriptFromString:showObj];
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

/*
 * Calls the JS function to draw each individual hotspot in the array provided.
 */
-(void) drawHotspots:(NSMutableArray *)hotspots {
    for(Hotspot* hotspot in hotspots) {
        CGPoint hotspotLoc = [self getHotspotLocation:hotspot];
        
        if(hotspotLoc.x != -1) {
            NSString* drawHotspot = [NSString stringWithFormat:@"drawHotspot(%f, %f, \"red\")", hotspotLoc.x, hotspotLoc.y];
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
    //Check to make sure the answer is correct and act appropriately.
    //For the moment we assume the sentence is correct and set the sentence color to green.
    NSString* setSentenceColor = [NSString stringWithFormat:@"setSentenceColor(s%d, 'green')", currentSentence];
    [bookView stringByEvaluatingJavaScriptFromString:setSentenceColor];
    
    //Unbold sentence
    NSString* setSentenceWeight = [NSString stringWithFormat:@"setSentenceFontWeight(s%d, 'normal')", currentSentence];
    [bookView stringByEvaluatingJavaScriptFromString:setSentenceWeight];
    
    //For the moment just move through the sentences, until you get to the last one, then move to the next activity.
    currentSentence ++;
    
    //Highlight the next sentence and set its color to blue.
    setSentenceColor = [NSString stringWithFormat:@"setSentenceColor(s%d, 'blue')", currentSentence];
    [bookView stringByEvaluatingJavaScriptFromString:setSentenceColor];
    
    //Bold sentence
    setSentenceWeight = [NSString stringWithFormat:@"setSentenceFontWeight(s%d, 'bold')", currentSentence];
    [bookView stringByEvaluatingJavaScriptFromString:setSentenceWeight];
    
    NSString* setSentenceOpacity = [NSString stringWithFormat:@"setSentenceOpacity(s%d, 1.0)", currentSentence];
    [bookView stringByEvaluatingJavaScriptFromString:setSentenceOpacity];
    
    /*NSString* setSentenceColor = [NSString stringWithFormat:@"setSentenceColor(s%d, \"blue\")", currentSentence];
     
     [bookView stringByEvaluatingJavaScriptFromString:setSentenceColor];*/
    
    //currentSentence is 1 indexed.
    if(currentSentence > totalSentences) {
        [self loadNextPage];
    }
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
}

@end
