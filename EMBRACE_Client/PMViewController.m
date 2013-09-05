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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    bookView.frame = self.view.bounds;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    //For the moment, lets go ahead and draw all the hotspots now.
    /*InteractionModel *model = [book model];
    
    NSMutableArray* hotspots = [model getAllHotspots];
    [self drawHotspots:hotspots];*/
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
 Tap gesture. Currently only used for menu selection. 
 */
- (IBAction)tapGesturePerformed:(UITapGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];
    
    //check to see if we have a menu open. If so, process menu click. 
    if(menu != nil) {
        int menuItem = [menu pointInMenuItem:location];
        
        //If we've selected a menuItem.
        if(menuItem != -1) {
            NSLog(@"selected menu item: %d with value: %@", menuItem, [menuDataSource dataObjectAtIndex:menuItem]);
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
    /*else {
        NSString* requestImageAtPoint = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).id", location.x, location.y];

        NSString* imageAtPoint = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPoint];
    }*/
}

/*
 Long press gesture. Either tap or long press can be used for definitions. 
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
 Pinch gesture. Used to ungroup two images from each other.
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
                
                [self expandMenu];
            }
            else if([itemPairArray count] == 1) {
                NSArray *pair = [[itemPairArray objectAtIndex:0] componentsSeparatedByString:@", "];
                
                NSString* obj1 = [pair objectAtIndex:0]; //get object 1
                NSString* obj2 = [pair objectAtIndex:1]; //get object 2
                
                [self ungroupObjects:obj1 :obj2]; //ungroup the objects.
            }
        }
        pinching = FALSE;
    }
}

/*
 Pan gesture. Used to move objects from one location to another.
 */
-(IBAction)panGesturePerformed:(UIPanGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.view];
    
    if(!pinching) { //This should work with requireGestureRecognizerToFail:pinchRecognizer but it doesn't currently.
        if(recognizer.state == UIGestureRecognizerStateBegan) {
            //NSLog(@"pan gesture began at location: (%f, %f)", location.x, location.y);
            
            //Temporarily hide the overlay canvas to get the object we need
            NSString* hideCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.display = 'none';", @"'overlay'"];
            //NSString* hideCanvas = [NSString stringWithFormat:@"document.getElementById(%@).style.zIndex = 0;", @"'overlay'"];
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
            
            NSLog(@"imageAtPoint: %@", imageAtPoint);
            //if it's an image that can be moved, then start moving it.
            if([imageAtPointClass isEqualToString:@"manipulationObject"]) {
                movingObject = TRUE;
                movingObjectId = imageAtPoint;
                
                //Calculate offset between top-left corner of image and the point clicked.
                NSString* requestImageAtPointTop = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).offsetTop", location.x, location.y];
                NSString* requestImageAtPointLeft = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).offsetLeft", location.x, location.y];
                
                NSString* imageAtPointTop = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointTop];
                NSString* imageAtPointLeft = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointLeft];
                
                NSLog(@"location of %@: (%@, %@)", imageAtPoint, imageAtPointLeft, imageAtPointTop);
                
                //Check to see if the locations returned are in percentages. If they are, change them to pixel values based on the size of the screen.
                NSRange rangePercentTop = [imageAtPointTop rangeOfString:@"%"];
                NSRange rangePercentLeft = [imageAtPointLeft rangeOfString:@"%"];
                
                if(rangePercentTop.location != NSNotFound) {
                    delta.y = location.y - ([imageAtPointTop floatValue] / 100.0 * [bookView frame].size.height);
                    //NSLog(@"location top specified in percent. calculated location: %f", [imageAtPointTop floatValue] / 100.0 * [bookView frame].size.height);
                }
                else
                    delta.y = location.y - [imageAtPointTop floatValue];
                
                if(rangePercentLeft.location != NSNotFound) {
                    delta.x = location.x - ([imageAtPointLeft floatValue] / 100.0 * [bookView frame].size.width);
                    //NSLog(@"location left specified in percent. calculated location: %f", [imageAtPointLeft floatValue] / 100.0 * [bookView frame].size.width);
                }
                else
                    delta.x = location.x - [imageAtPointLeft floatValue];
            }
        }
        else if(recognizer.state == UIGestureRecognizerStateEnded) {
            //NSLog(@"pan gesture ended at location (%f, %f)", location.x, location.y);
            //if moving object, move object to final position.
            if(movingObject) {
                [self moveObject:movingObjectId :location];
                
                //If we've dropped the object, we want to check and see if it's overlapping with another object.
                //If it is, we have to make sure that the hotspots for the two objects are within a certain radius of each other for the grouping to occur.
                //If they are, we want to go ahead and group the objects.
                //NSString *checkObjectOverlap = [NSString stringWithFormat:@"checkObjectOverlap(%@)", movingObjectId];
                
                //NSString *groupOverlappingObjects = [NSString stringWithFormat:@"groupOverlappingObjects(%@)", movingObjectId];
                //[bookView stringByEvaluatingJavaScriptFromString:groupOverlappingObjects];
                
                NSString *overlappingObjects = [NSString stringWithFormat:@"checkObjectOverlapString(%@)", movingObjectId];
                NSString* overlapArrayString = [bookView stringByEvaluatingJavaScriptFromString:overlappingObjects];
                
                if(![overlapArrayString isEqualToString:@""]) {
                    NSLog(@"overlapping with: %@", overlapArrayString);
                    
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
                                
                                //For the moment, we'll use 50 px as the acceptable radius to snap two objects together.
                                if(deltaX <= 50 && deltaY <= 50) {
                                    //We also want to go ahead and snap the objects in place based on the hotspots so we need to calculate the (x,y) positions of each of these objects such that the hotspots are in the same spot. How do we do this?
                                    
                                    NSString *groupObjects = [NSString stringWithFormat:@"groupObjectsAtLoc(%@, %f, %f, %@, %f, %f)", movingObjectId, movingObjectHotspotLoc.x, movingObjectHotspotLoc.y, objId, hotspotLoc.x, hotspotLoc.y];
                                    [bookView stringByEvaluatingJavaScriptFromString:groupObjects];
                                }
                                    
                            }
                        }
                    }
<<<<<<< HEAD
=======
                    
                    [self expandMenu];
>>>>>>> fdae863... Code cleanup
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
            [self moveObject:movingObjectId :location];
            
            [self drawHotspots:[model getHotspotsForObjectId:movingObjectId]];
            //If we're overlapping with another object, then we need to figure out which hotspots are currently active and highlight those hotspots.
            //Starting with the simple case of moving an object that is not grouped to any other object, and then expanding from there.
            //When moving the object, we may have the JS return a list of all the objects that are currently grouped together so that we can process all of them.
            NSString *overlappingObjects = [NSString stringWithFormat:@"checkObjectOverlapString(%@)", movingObjectId];
            NSString* overlapArrayString = [bookView stringByEvaluatingJavaScriptFromString:overlappingObjects];
            
            if(![overlapArrayString isEqualToString:@""]) {
                NSLog(@"overlapping with: %@", overlapArrayString);
            
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

-(void) calculateDeltaForMovingObjectAtPoint:(CGPoint) location {
    //Calculate offset between top-left corner of image and the point clicked.
    NSString* requestImageAtPointTop = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).offsetTop", location.x, location.y];
    NSString* requestImageAtPointLeft = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).offsetLeft", location.x, location.y];
    
    NSString* imageAtPointTop = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointTop];
    NSString* imageAtPointLeft = [bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointLeft];
    
    NSLog(@"location of %@: (%@, %@)", movingObjectId, imageAtPointLeft, imageAtPointTop);
    
    //Check to see if the locations returned are in percentages. If they are, change them to pixel values based on the size of the screen.
    NSRange rangePercentTop = [imageAtPointTop rangeOfString:@"%"];
    NSRange rangePercentLeft = [imageAtPointLeft rangeOfString:@"%"];
    
    if(rangePercentTop.location != NSNotFound) {
        delta.y = location.y - ([imageAtPointTop floatValue] / 100.0 * [bookView frame].size.height);
        //NSLog(@"location top specified in percent. calculated location: %f", [imageAtPointTop floatValue] / 100.0 * [bookView frame].size.height);
    }
    else
        delta.y = location.y - [imageAtPointTop floatValue];
    
    if(rangePercentLeft.location != NSNotFound) {
        delta.x = location.x - ([imageAtPointLeft floatValue] / 100.0 * [bookView frame].size.width);
        //NSLog(@"location left specified in percent. calculated location: %f", [imageAtPointLeft floatValue] / 100.0 * [bookView frame].size.width);
    }
    else
        delta.x = location.x - [imageAtPointLeft floatValue];
}

-(void) moveObject:(NSString*) object :(CGPoint) location {
    //Change the location to accounting for the different between the point clicked and the top-left corner which is used to set the position of the image.
    CGPoint adjLocation = CGPointMake(location.x - delta.x, location.y - delta.y);
    
    //Get the width and height of the image to ensure that the image is not being moved off screen.
    NSString* requestImageHeight = [NSString stringWithFormat:@"%@.height", object];
    NSString* requestImageWidth = [NSString stringWithFormat:@"%@.width", object];
    
    float imageHeight = [[bookView stringByEvaluatingJavaScriptFromString:requestImageHeight] floatValue];
    float imageWidth = [[bookView stringByEvaluatingJavaScriptFromString:requestImageWidth] floatValue];
    
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

    NSLog(@"new location of %@: (%f, %f)", object, adjLocation.x, adjLocation.y);
    //Call the moveObject function in the js file.
    NSString *move = [NSString stringWithFormat:@"moveObject(%@, %f, %f)", object, adjLocation.x, adjLocation.y];
    [bookView stringByEvaluatingJavaScriptFromString:move];
}

-(void) ungroupObjects:(NSString* )object1 :(NSString*) object2 {
    NSString* ungroup = [NSString stringWithFormat:@"ungroupObjects(%@, %@)", object1, object2];
    [bookView stringByEvaluatingJavaScriptFromString:ungroup];
}

-(void) drawHotspots:(NSMutableArray *)hotspots {
    for(Hotspot* hotspot in hotspots) {
        CGPoint hotspotLoc = [self getHotspotLocation:hotspot];
        
        if(hotspotLoc.x != -1) {
            NSString* drawHotspot = [NSString stringWithFormat:@"drawHotspot(%f, %f, \"red\")", hotspotLoc.x, hotspotLoc.y];
            [bookView stringByEvaluatingJavaScriptFromString:drawHotspot];
        }
    }
}

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
-(void) expandMenu {
    menu = [[PieContextualMenu alloc] initWithFrame:[[self view] frame]];
    [menu addGestureRecognizer:tapRecognizer];
    [[self view] addSubview:menu];
    
    menu.delegate = self;
    menu.dataSource = menuDataSource;
    
    //Calculate the radius of the circle
    CGFloat radius = (menuBoundingBox -  (itemRadius * 2)) / 2;
    [menu expandMenu:radius];
}


@end
