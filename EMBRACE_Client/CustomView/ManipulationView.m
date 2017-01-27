//
//  ManipulationView.m
//  EMBRACE
//
//  Created by Jithin on 7/6/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "ManipulationView.h"
#import "InteractionModel.h"
#import "NSString+HTML.h"
#import "Book.h"
#import "MenuItemImage.h"
#import "ITSController.h"
#import "Translation.h"

@interface ManipulationView()<UIScrollViewDelegate, UIWebViewDelegate>

@end

@implementation ManipulationView
@synthesize bookView;

- (instancetype)initWithFrameAndView:(CGRect)frame : (UIWebView *) bv{
    self = [super initWithFrame:frame];
    if (self) {
        
        bookView = bv;
        
        //bookview = [[UIWebView alloc] initWithFrame:frame];
        /*bookview.scalesPageToFit = YES;
        bookview.scrollView.delegate = self;
        bookview.delegate = self;
        
        [[bookview scrollView] setBounces: NO];
        [[bookview scrollView] setScrollEnabled:NO];
        [self addSubview:bookview];
        
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:bookview
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:0.0]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:bookview
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self
                                                              attribute:NSLayoutAttributeLeading
                                                             multiplier:1.0
                                                               constant:0.0]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:bookview
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0.0]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:bookview
                                                              attribute:NSLayoutAttributeTrailing
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self
                                                              attribute:NSLayoutAttributeTrailing
                                                             multiplier:1.0
                                                               constant:0.0]];
         */

        
    }
    return self;
}

/*
- (void)addGesture:(UIGestureRecognizer *)recogniser {
    [self.bookView addGestureRecognizer:recogniser];
}*/

#pragma mark -

- (void)loadPageFor:(Book *)book andCurrentPage:(NSString *)page {
    NSURL *baseURL = [NSURL fileURLWithPath:[book getHTMLURL]];
    
    if (baseURL == nil)
        NSLog(@"did not load baseURL");
    
    NSError *error;
    NSString *pageContents = [[NSString alloc] initWithContentsOfFile:page encoding:NSASCIIStringEncoding error:&error];
    if (error != nil)
        NSLog(@"problem loading page contents");
    
    [self.bookView loadHTMLString:pageContents baseURL:baseURL];
    [self.bookView stringByEvaluatingJavaScriptFromString:@"document.body.style.webkitTouchCallout='none';"];
    
}

#pragma mark - JS methods

- (void)loadJsFiles {
    
    //Load the js files.
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ImageManipulation" ofType:@"js"];
    
    if (filePath == nil) {
        NSLog(@"Cannot find js file: ImageManipulation");
    }
    else {
        NSData *fileData = [NSData dataWithContentsOfFile:filePath];
        NSString *jsString = [[NSMutableString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
        [self.bookView stringByEvaluatingJavaScriptFromString:jsString];
    }
    
    //Load the animator js file
    NSString *animatorFilePath = [[NSBundle mainBundle] pathForResource:@"Animator" ofType:@"js"];
    
    if (animatorFilePath == nil) {
        NSLog(@"Cannot find js file: Animator");
    }
    else {
        NSData *animatorFileData = [NSData dataWithContentsOfFile:animatorFilePath];
        NSString *animatorJsString = [[NSMutableString alloc] initWithData:animatorFileData encoding:NSUTF8StringEncoding];
        [self.bookView stringByEvaluatingJavaScriptFromString:animatorJsString];
    }
    
    //Load the vector js file
    NSString *vectorFilePath = [[NSBundle mainBundle] pathForResource:@"Vector" ofType:@"js"];
    
    if (vectorFilePath == nil) {
        NSLog(@"Cannot find js file: Vector");
    }
    else {
        NSData *vectorFileData = [NSData dataWithContentsOfFile:vectorFilePath];
        NSString *vectorJsString = [[NSMutableString alloc] initWithData:vectorFileData encoding:NSUTF8StringEncoding];
        [self.bookView stringByEvaluatingJavaScriptFromString:vectorJsString];
    }
}

- (NSInteger)getSentenceCount {
    NSString *requestSentenceCount = [NSString stringWithFormat:@"document.getElementsByClassName('sentence').length"];
    NSInteger sentenceCount = [[self.bookView stringByEvaluatingJavaScriptFromString:requestSentenceCount] integerValue];
    return sentenceCount;
}

- (NSInteger)getIdForSentence:(NSInteger)sentenceNumber {
    NSString *requestLastSentenceId = [NSString stringWithFormat:@"document.getElementsByClassName('sentence')[%ld].id", (long)sentenceNumber];
    NSString *lastSentenceId = [self.bookView stringByEvaluatingJavaScriptFromString:requestLastSentenceId];
    NSInteger lastSentenceIdNumber = [[lastSentenceId substringFromIndex:1] intValue];
    return lastSentenceIdNumber;
}

- (NSInteger)totalSentences {
    //Get the number of sentences on the page
    NSInteger sentenceCount = [self getSentenceCount];
    
    //Get the id number of the last sentence on the page and set it equal to the total number of sentences.
    //Because the PMActivity may have multiple pages, this id number may not match the sentence count for the page.
    //   Ex. Page 1 may have three sentences: 1, 2, and 3. Page 2 may also have three sentences: 4, 5, and 6.
    //   The total number of sentences is like a running total, so by page 2, there are 6 sentences instead of 3.
    //This is to make sure we access the solution steps for the correct sentence on this page, and not a sentence on
    //a previous page.
    return [self getIdForSentence:sentenceCount - 1];
}

- (NSString *)getCurrentSentenceAt:(NSInteger)sentenceNumber {
    NSString *request = [NSString stringWithFormat:@"document.getElementById('s%ld').textContent", (long)sentenceNumber];
    return [[self.bookView stringByEvaluatingJavaScriptFromString:request] stringByConvertingHTMLToPlainText];
}

- (NSString *)getVocabAtId:(NSInteger)idNum {
    NSString *requestSentenceText = [NSString stringWithFormat:@"document.getElementById('%ld').innerHTML", (long)idNum];
    NSString *sentenceText = [self.bookView stringByEvaluatingJavaScriptFromString:requestSentenceText];
    return sentenceText;
}

- (void)removePMInstructions:(NSInteger)totalSentences {
    
    NSString* requestSentenceCount = [NSString stringWithFormat:@"document.getElementsByClassName('PM_TEXT').length"];
    int sentenceCount = [[self.bookView stringByEvaluatingJavaScriptFromString:requestSentenceCount] intValue];
    
    if(sentenceCount > 0) {
        NSString* removeSentenceString;
        
        //Remove PM specific sentences on the page
        for (int i = 0; i <= totalSentences; i++) {
            removeSentenceString = [NSString stringWithFormat:@"removeSentence('PMs%d')", i];
            [self.bookView stringByEvaluatingJavaScriptFromString:removeSentenceString];
        }
    }
}

- (BOOL)isActionSentence:(NSInteger)sentenceNumber {
    NSString *actionSentence = [NSString stringWithFormat:@"getSentenceClass(s%ld)", (long)sentenceNumber];
    NSString *sentenceClass = [self.bookView stringByEvaluatingJavaScriptFromString:actionSentence];
    return ([sentenceClass  containsString: @"sentence actionSentence"]);
}

- (BOOL)isObjectCenter:(NSString *)objectId {
    NSString *objectClassName = [NSString stringWithFormat:@"document.getElementById('%@').className", objectId];
    objectClassName = [self.bookView stringByEvaluatingJavaScriptFromString:objectClassName];
    
    return ([objectClassName rangeOfString:@"center"].location != NSNotFound);
}

- (NSString *)getElementAtLocation:(CGPoint)location {
    NSString *requestImageAtPoint = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).id", location.x, location.y];
    return  [self.bookView stringByEvaluatingJavaScriptFromString:requestImageAtPoint];
}

- (NSString *)getClassForElemAtLocation:(CGPoint)location {
    NSString *requestImageAtPointClass = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).className", location.x, location.y];
    return [self.bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointClass];
}

- (NSString *)getTextAtLocation:(CGPoint)location {
    NSString *requestString = [NSString stringWithFormat:@"getTextAtLocation(%f, %f)", location.x, location.y];
    NSString *textAtLocation = [self.bookView stringByEvaluatingJavaScriptFromString:requestString];

    return textAtLocation;
}

- (NSString *)getSpanishExtention:(CGPoint)location {
    NSString *spanishExtTag = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).getAttribute(\"spanishExt\")", location.x, location.y];
    return [self.bookView stringByEvaluatingJavaScriptFromString:spanishExtTag];
}

- (UIImage *)getBackgroundImage {
    
    NSString *imageSrc = [self.bookView stringByEvaluatingJavaScriptFromString:@"document.body.background"];
    NSString *imageFileName = [imageSrc substringFromIndex:10];
    imageFileName = [imageFileName substringToIndex:[imageFileName length] - 4];
    
    NSString *url = [[NSBundle mainBundle] pathForResource:imageFileName ofType:@"png"];
    
    NSString *imagePath = [url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    UIImage *rawImage = [[UIImage alloc] initWithContentsOfFile:imagePath];
    
    return rawImage;
}

- (void)hideCanvas {
    
    NSString *hideCanvas = [NSString stringWithFormat:@"document.getElementById('%@').style.display = 'none';", @"'overlay'"];
    NSString *hideHighlight = [NSString stringWithFormat:@"document.getElementById('%@').style.display = 'none';", @"'highlight'"];
    NSString *hideAnimation = [NSString stringWithFormat:@"document.getElementById('%@').style.display = 'none';", @"'animation'"];
    [self.bookView stringByEvaluatingJavaScriptFromString:hideCanvas];
    [self.bookView stringByEvaluatingJavaScriptFromString:hideHighlight];
    [self.bookView stringByEvaluatingJavaScriptFromString:hideAnimation];
}

- (void)showCanvas {
    
    NSString *showCanvas = [NSString stringWithFormat:@"document.getElementById('%@').style.display = 'block';", @"'overlay'"];
    NSString *showHighlight = [NSString stringWithFormat:@"document.getElementById('%@').style.display = 'block';", @"'highlight'"];
    NSString *showAnimation = [NSString stringWithFormat:@"document.getElementById('%@').style.display = 'block';", @"'animation'"];
    [self.bookView stringByEvaluatingJavaScriptFromString:showCanvas];
    [self.bookView stringByEvaluatingJavaScriptFromString:showHighlight];
    [self.bookView stringByEvaluatingJavaScriptFromString:showAnimation];
}

/*
 * Checks if one object is contained inside another object and returns the contained object
 */
- (NSString *)findContainedObject:(NSArray *)objects {
    NSString *containedObject = @"";
    
    //Check the first object
    NSString *isContained = [NSString stringWithFormat:@"objectContainedInObject(%@,%@)", objects[0], objects[1]];
    NSString *isContainedString = [self.bookView stringByEvaluatingJavaScriptFromString:isContained];
    
    //First object in array is contained in second object in array
    if ([isContainedString isEqualToString:@"true"]) {
        containedObject = objects[0];
    }
    //Check the second object
    else if ([isContainedString isEqualToString:@"false"]) {
        isContained = [NSString stringWithFormat:@"objectContainedInObject(%@,%@)", objects[1], objects[0]];
        isContainedString = [self.bookView stringByEvaluatingJavaScriptFromString:isContained];
    }
    
    //Second object in array is contained in first object in array
    if ([containedObject isEqualToString:@""] && [isContainedString isEqualToString:@"true"]) {
        containedObject = objects[1];
    }
    
    return containedObject;
}

- (BOOL)isObjectGrouped:(NSString *)objectId atHotSpot:(CGPoint)location {
    //Check to see if either of these hotspots are currently connected to another objects.
    NSString *result  = [self groupedObject:objectId atHotSpot:location];
    return ![result isEqualToString:@""];
}

- (NSString *)groupedObject:(NSString *)objectId atHotSpot:(CGPoint)location {
    NSString *query = [NSString stringWithFormat:@"objectGroupedAtHotspot(%@, %f, %f)", objectId, location.x, location.y];
    return [self.bookView stringByEvaluatingJavaScriptFromString:query];
}

- (void)removeObject:(NSString *)objectId {
    NSString *hideImage = [NSString stringWithFormat:@"removeImage('%@')", objectId];
    [self.bookView stringByEvaluatingJavaScriptFromString:hideImage];
}

- (CGSize)sizeOfObject:(NSString *)objectId {
    NSString *requestImageHeight = [NSString stringWithFormat:@"%@.height", objectId];
    NSString *requestImageWidth = [NSString stringWithFormat:@"%@.width", objectId];
    
    float imageHeight = [[self.bookView stringByEvaluatingJavaScriptFromString:requestImageHeight] floatValue];
    float imageWidth = [[self.bookView stringByEvaluatingJavaScriptFromString:requestImageWidth] floatValue];
    return CGSizeMake(imageWidth, imageHeight);
}

/*
 * Returns an array containing pairs of grouped objects (with the format "hay, farmer") connected to the object specified
 */
- (NSArray *)getObjectsGroupedWithObject:(NSString *)object {
    NSArray *itemPairArray; //contains grouped objects split by pairs
    
    //Get other objects grouped with this object.
    NSString *requestGroupedImages = [NSString stringWithFormat:@"getGroupedObjectsString(%@)", object];
    
    /*
     * Say the cart is connected to the tractor and the tractor is "connected" to the farmer,
     * then groupedImages will be a string in the following format: "cart, tractor; tractor, farmer"
     * if the only thing you currently have connected to the hay is the farmer, then you'll get
     * a string back that is: "hay, farmer" or "farmer, hay"
     */
    NSString *groupedImages = [self.bookView stringByEvaluatingJavaScriptFromString:requestGroupedImages];
    
    //If there is an array, split the array based on pairs.
    if (![groupedImages isEqualToString:@""]) {
        itemPairArray = [groupedImages componentsSeparatedByString:@"; "];
    }
    
    return itemPairArray;
}

- (NSMutableSet *)getSetOfObjectsGroupedWithObject:(NSString *)object {
    NSMutableSet *objectsInGroup = [[NSMutableSet alloc] initWithObjects:object, nil];
    NSArray *itemPairArray = [self getObjectsGroupedWithObject:object];
    
    for (NSString *itemPair in itemPairArray) {
        NSArray *objects = [itemPair componentsSeparatedByString:@", "];
        
        for (NSString *object in objects) {
            [objectsInGroup addObject:object];
        }
    }
    
    return objectsInGroup;
}

/*
 * Returns an array containing objects that are overlapping with the object specified
 */
- (NSArray *)getObjectsOverlappingWithObject:(NSString *)object movingObject:(NSString *)movingObjectId {
    NSArray *overlappingWith; //contains overlapping objects
    
    //Check if object is overlapping anything
    NSString *overlappingObjects = [NSString stringWithFormat:@"checkObjectOverlapString(%@)", movingObjectId];
    NSString *overlapArrayString = [self.bookView stringByEvaluatingJavaScriptFromString:overlappingObjects];
    
    if (![overlapArrayString isEqualToString:@""]) {
        overlappingWith = [overlapArrayString componentsSeparatedByString:@", "];
    }
    
    return overlappingWith;
}

- (NSSet *)getSetOfObjectsOverlappingWithObject:(NSString *)object {
    
}

- (NSString *)getSentenceClass:(NSInteger)sentenceNumber {
    NSString *actionSentence = [NSString stringWithFormat:@"getSentenceClass(s%ld)", (long)sentenceNumber];
    return [self.bookView stringByEvaluatingJavaScriptFromString:actionSentence];
}

- (void)addVocabularyWithID:(NSInteger)vocabID englishText:(NSString *)engText spanishText:(NSString *)spanText {
    NSString *addVocabularyString = [NSString stringWithFormat:@"addVocabulary('s%d', '%@', '%@')", vocabID, engText, spanText];
    [self.bookView stringByEvaluatingJavaScriptFromString:addVocabularyString];
}

/*
#pragma mark - UIScrollView delegates

//Remove zoom in scroll view for UIWebView
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return nil;
}*/

#pragma mark - Webview delegates

/*
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
    
    [self loadJsFiles];
    [self.delegate manipulationViewDidLoad:self];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
}*/

#pragma mark - Positions

/*
 * Returns a CGPoint containing the x and y coordinates of the position of an object
 */
- (CGPoint)getObjectPosition:(NSString *)object {
    NSArray *position;
    
    NSString *positionObject = [NSString stringWithFormat:@"getImagePosition(%@)", object];
    NSString *positionString = [self.bookView stringByEvaluatingJavaScriptFromString:positionObject];
    
    if (![positionString isEqualToString:@""]) {
        position = [positionString componentsSeparatedByString:@", "];
    }
    CGPoint point = CGPointMake([position[0] floatValue], [position[1] floatValue]);
    return point;
}

/*
 * Calculates the delta pixel change for the object that is being moved
 * and changes the lcoation from relative % to pixels if necessary.
 */
- (CGPoint)deltaForMovingObjectAtPoint:(CGPoint)location {
    CGPoint change;
    
    //Calculate offset between top-left corner of image and the point clicked.
    NSString *requestImageAtPointTop = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).offsetTop", location.x, location.y];
    NSString *requestImageAtPointLeft = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).offsetLeft", location.x, location.y];
    
    NSString *imageAtPointTop = [self.bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointTop];
    NSString *imageAtPointLeft = [self.bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointLeft];
    
    //Check to see if the locations returned are in percentages. If they are, change them to pixel values based on the size of the screen.
    NSRange rangePercentTop = [imageAtPointTop rangeOfString:@"%"];
    NSRange rangePercentLeft = [imageAtPointLeft rangeOfString:@"%"];
    
    if (rangePercentTop.location != NSNotFound)
        change.y = location.y - ([imageAtPointTop floatValue] / 100.0 * [self.bookView frame].size.height);
    else
        change.y = location.y - [imageAtPointTop floatValue];
    
    if (rangePercentLeft.location != NSNotFound)
        change.x = location.x - ([imageAtPointLeft floatValue] / 100.0 * [self.bookView frame].size.width);
    else
        change.x = location.x - [imageAtPointLeft floatValue];
    
    return change;
}

/*
 * Calculates the delta pixel change for the object that is being moved
 * and changes the lcoation from relative % to pixels if necessary.
 */
- (CGPoint)deltaForMovingObjectAtPointWithCenter:(NSString *)object :(CGPoint)location {
    CGPoint change;
    
    //Calculate offset between top-left corner of image and the point clicked.
    NSString *requestImageAtPointTop = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).offsetTop", location.x, location.y];
    NSString *requestImageAtPointLeft = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).offsetLeft", location.x, location.y];
    
    NSString *imageAtPointTop = [self.bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointTop];
    NSString *imageAtPointLeft = [self.bookView stringByEvaluatingJavaScriptFromString:requestImageAtPointLeft];
    
    //Get the width and height of the image to ensure that the image is not being moved off screen and that the image is being moved in accordance with all movement constraints.
    NSString *requestImageHeight = [NSString stringWithFormat:@"%@.height", object];
    NSString *requestImageWidth = [NSString stringWithFormat:@"%@.width", object];
    
    float imageHeight = [[self.bookView stringByEvaluatingJavaScriptFromString:requestImageHeight] floatValue];
    float imageWidth = [[self.bookView stringByEvaluatingJavaScriptFromString:requestImageWidth] floatValue];
    
    //Check to see if the locations returned are in percentages. If they are, change them to pixel values based on the size of the screen.
    NSRange rangePercentTop = [imageAtPointTop rangeOfString:@"%"];
    NSRange rangePercentLeft = [imageAtPointLeft rangeOfString:@"%"];
    
    if (rangePercentTop.location != NSNotFound)
        change.y = location.y - ([imageAtPointTop floatValue] / 100.0 * [self.bookView frame].size.height) - (imageHeight / 2);
    else
        change.y = location.y - [imageAtPointTop floatValue] - (imageHeight / 2);
    
    if (rangePercentLeft.location != NSNotFound)
        change.x = location.x - ([imageAtPointLeft floatValue] / 100.0 * [self.bookView frame].size.width) - (imageWidth / 2);
    else
        change.x = location.x - [imageAtPointLeft floatValue] - (imageWidth / 2);
    
    return change;
}

/*
 * Returns the pixel location of the hotspot based on the location of the image and the relative location of the
 * hotspot to that image.
 */
- (CGPoint)getHotspotLocation:(Hotspot *)hotspot {
    //Get the height and width of the image.
    NSString *requestImageHeight = [NSString stringWithFormat:@"%@.offsetHeight", [hotspot objectId]];
    NSString *requestImageWidth = [NSString stringWithFormat:@"%@.offsetWidth", [hotspot objectId]];
    
    float imageWidth = [[self.bookView stringByEvaluatingJavaScriptFromString:requestImageWidth] floatValue];
    float imageHeight = [[self.bookView stringByEvaluatingJavaScriptFromString:requestImageHeight] floatValue];
    
    //If image height and width are 0 then the image doesn't exist on this page.
    if (imageWidth > 0 && imageHeight > 0) {
        //Get the location of the top left corner of the image.
        NSString *requestImageTop = [NSString stringWithFormat:@"%@.offsetTop", [hotspot objectId]];
        NSString *requestImageLeft = [NSString stringWithFormat:@"%@.offsetLeft", [hotspot objectId]];
        
        NSString *imageTop = [self.bookView stringByEvaluatingJavaScriptFromString:requestImageTop];
        NSString *imageLeft = [self.bookView stringByEvaluatingJavaScriptFromString:requestImageLeft];
        
        //Check to see if the locations returned are in percentages. If they are, change them to pixel values based on the size of the screen.
        NSRange rangePercentTop = [imageTop rangeOfString:@"%"];
        NSRange rangePercentLeft = [imageLeft rangeOfString:@"%"];
        float locY, locX;
        
        if (rangePercentLeft.location != NSNotFound) {
            locX = ([imageLeft floatValue] / 100.0 * [self.bookView frame].size.width);
        }
        else
            locX = [imageLeft floatValue];
        
        if (rangePercentTop.location != NSNotFound) {
            locY = ([imageTop floatValue] / 100.0 * [self.bookView frame].size.height);
        }
        else
            locY = [imageTop floatValue];
        
        //Now we've got the location of the top left corner of the image, the size of the image and the relative position of the hotspot. Need to calculate the pixel location of the hotspot and call the js to draw the hotspot.
        float hotspotX = locX  + (imageWidth * ([hotspot location].x / 100.0));
        float hotspotY = locY + (imageHeight * ([hotspot location].y / 100.0));
        
        return CGPointMake(hotspotX, hotspotY);
    }
    
    return CGPointMake(-1, -1);
}

/*
 * Returns the hotspot location in pixels based on the object image size
 */
- (CGPoint)getHotspotLocationOnImage:(Hotspot *)hotspot {
    
    //Get the width and height of the object image
    NSString *requestImageHeight = [NSString stringWithFormat:@"%@.height", [hotspot objectId]];
    NSString *requestImageWidth = [NSString stringWithFormat:@"%@.width", [hotspot objectId]];
    
    float imageHeight = [[self.bookView stringByEvaluatingJavaScriptFromString:requestImageHeight] floatValue];
    float imageWidth = [[self.bookView stringByEvaluatingJavaScriptFromString:requestImageWidth] floatValue];
    
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
- (CGPoint)getWaypointLocation:(Waypoint *)waypoint {
    
    //Get position of waypoint in pixels based on the background size
    CGPoint waypointLoc = [waypoint location];
    CGFloat waypointX = waypointLoc.x / 100.0 * [self.bookView frame].size.width;
    CGFloat waypointY = waypointLoc.y / 100.0 * [self.bookView frame].size.height;
    CGPoint waypointLocation = CGPointMake(waypointX, waypointY);
    
    return waypointLocation;
}

#pragma mark - Drawings

- (void)drawArea:(NSString *)areaName
         chapter:(NSString *)chapter
          pageId:(NSString *)pageId
       withModel:(InteractionModel *)model {
    
    
    //Get area that hotspot should be inside
    Area *area = [model getArea:areaName : pageId];
    
    //Apply path to shapelayer
    CAShapeLayer *path = [CAShapeLayer layer];
    path.lineWidth = 10.0;
    path.path = area.aPath.CGPath;
    [path setFillColor:[UIColor clearColor].CGColor];
    
    if (![areaName containsString:@"Path"]) {
        [path setStrokeColor:[UIColor greenColor].CGColor];
    }
    else {
        //If it is a path, paint it red
        [path setStrokeColor:[UIColor redColor].CGColor];
        [self.bookView.layer addSublayer:path];
    }
    
}

- (void)highlightSentenceToBlack:(NSInteger)sentenceNumber {
    NSString *setSentenceOpacity = [NSString stringWithFormat:@"setSentenceOpacity(s%ld, 1.0)", (long)sentenceNumber];
    [self.bookView stringByEvaluatingJavaScriptFromString:setSentenceOpacity];
    
    NSString *setSentenceColor = [NSString stringWithFormat:@"setSentenceColor(s%ld, 'black')", (long)sentenceNumber];
    [self.bookView stringByEvaluatingJavaScriptFromString:setSentenceColor];
}

- (void)highLightObject:(NSString *)objectId {
    NSString *highlight = [NSString stringWithFormat:@"highlightObject(%@)", objectId];
    [self.bookView stringByEvaluatingJavaScriptFromString:highlight];
}

- (void)clearAllHighLighting {
    NSString *clearHighlighting = [NSString stringWithFormat:@"clearAllHighlighted()"];
    [self.bookView stringByEvaluatingJavaScriptFromString:clearHighlighting];
}

- (void)setupCurrentSentenceColor:(NSInteger)currentSentence
                        condition:(Condition)condition
                          andMode:(Mode)mode {
    
    //Highlight the sentence and set its color to black
    [self highlightSentenceToBlack:currentSentence];
    

    //Check to see if it is an action sentence
    NSString *actionSentence = [NSString stringWithFormat:@"getSentenceClass(s%ld)", (long)currentSentence];
    NSString *sentenceClass = [self.bookView stringByEvaluatingJavaScriptFromString:actionSentence];
    
    //If it is a non-black action sentence (i.e., requires user manipulation), then set the color to blue
    if (![sentenceClass containsString:@"black"]) {
        if ([sentenceClass containsString: @"sentence actionSentence"] ||
            ([sentenceClass containsString: @"sentence IMactionSentence"] &&
             condition == EMBRACE && mode == IM_MODE)) {
                NSString *setSentenceColor = [NSString stringWithFormat:@"setSentenceColor(s%ld, 'blue')", (long)currentSentence];
                [self.bookView stringByEvaluatingJavaScriptFromString:setSentenceColor];
            }
    }
    
    //Set the opacity of all but the current sentence to .2
    NSInteger totalSentences = [self totalSentences];
    for (NSInteger i = currentSentence; i < totalSentences; i++) {
        NSString *setSentenceOpacity = [NSString stringWithFormat:@"setSentenceOpacity(s%d, .2)", i + 1];
        [self.bookView stringByEvaluatingJavaScriptFromString:setSentenceOpacity];
    }
}

/*
 * Calls the buildPath function on the JS file
 * Sends all the points in an area or path to the the JS to load them in memory
 */
- (void)buildPath:(NSString *)areaId
           pageId:(NSString *)pageId
        withModel:(InteractionModel *)model {
    
    Area *area = [model getArea:areaId: pageId];
    
    NSString *createPath = [NSString stringWithFormat:@"createPath('%@')", areaId];
    [self.bookView stringByEvaluatingJavaScriptFromString:createPath];
    
    for (int i = 0; i < area.points.count/2; i++) {
        NSString *xCoord = [area.points objectForKey:[NSString stringWithFormat:@"x%d", i]];
        NSString *yCoord = [area.points objectForKey:[NSString stringWithFormat:@"y%d", i]];
        
        NSString *buildPath = [NSString stringWithFormat:@"buildPath('%@', %f, %f)", areaId, [xCoord floatValue], [yCoord floatValue]];
        [self.bookView stringByEvaluatingJavaScriptFromString:buildPath];
    }
}

- (NSString *)imageMarginLeft:(NSString *)imageId {
    
    NSString *requestImageMarginLeft = [NSString stringWithFormat:@"%@.style.marginLeft", imageId];
    return [self.bookView stringByEvaluatingJavaScriptFromString:requestImageMarginLeft];
    
}

- (NSString *)imageMarginTop:(NSString *)imageId {
    
    NSString *requestImageMarginTop = [NSString stringWithFormat:@"%@.style.marginTop", imageId];
    return [self.bookView stringByEvaluatingJavaScriptFromString:requestImageMarginTop];
}

/*
 * Gets the necessary information from the JS for this particular image id and creates a
 * MenuItemImage out of that information. If FLIP is TRUE, the image will be horizontally
 * flipped. If the image src isn't found, returns nil. Otherwise, returned the MenuItemImage
 * that was created.
 */
- (MenuItemImage *)createMenuItemForImage:(NSString *)objId
                                     flip:(NSString *)FLIP {
    
    NSString *requestImageSrc = [NSString stringWithFormat:@"%@.src", objId];
    NSString *imageSrc = [self.bookView stringByEvaluatingJavaScriptFromString:requestImageSrc];
    
    NSRange range = [imageSrc rangeOfString:@"file:"];
    NSString *imagePath = [imageSrc substringFromIndex:range.location + range.length + 1];
    
    imagePath = [imagePath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    UIImage *rawImage = [[UIImage alloc] initWithContentsOfFile:imagePath];
    UIImage *image = [UIImage alloc];
    
    //Horizontally flip the image
    if ([FLIP isEqualToString:@"rotate"]) {
        image = [UIImage imageWithCGImage:rawImage.CGImage scale:rawImage.scale orientation:UIImageOrientationUpMirrored];
    }
    else if ([FLIP isEqualToString:@"flipHorizontal"]) {
        image = [UIImage imageWithCGImage:rawImage.CGImage scale:rawImage.scale orientation:UIImageOrientationUpMirrored];
    }
    //Use the unflipped image
    else {
        image = rawImage;
    }
    
    [image setAccessibilityIdentifier:objId];
    
    if (image == nil)
        NSLog(@"image is nil");
    else {
        MenuItemImage *itemImage = [[MenuItemImage alloc] initWithImage:image];
        
        //Get the z-index of the image.
        NSString *requestZIndex = [NSString stringWithFormat:@"%@.style.zIndex", objId];
        NSString *zIndex = [self.bookView stringByEvaluatingJavaScriptFromString:requestZIndex];
        
        [itemImage setZPosition:[zIndex floatValue]];
        
        //Get the location of the image, so we can position it appropriately.
        NSString *requestPositionX = [NSString stringWithFormat:@"%@.offsetLeft", objId];
        NSString *requestPositionY = [NSString stringWithFormat:@"%@.offsetTop", objId];
        
        NSString *positionX = [self.bookView stringByEvaluatingJavaScriptFromString:requestPositionX];
        NSString *positionY = [self.bookView stringByEvaluatingJavaScriptFromString:requestPositionY];
        
        //Get the size of the image, so that it can be scaled appropriately.
        NSString *requestWidth = [NSString stringWithFormat:@"%@.offsetWidth", objId];
        NSString *requestHeight = [NSString stringWithFormat:@"%@.offsetHeight", objId];
        
        NSString *width = [self.bookView stringByEvaluatingJavaScriptFromString:requestWidth];
        NSString *height = [self.bookView stringByEvaluatingJavaScriptFromString:requestHeight];
        
        [itemImage setBoundingBoxImage:CGRectMake([positionX floatValue], [positionY floatValue], [width floatValue], [height floatValue])];
        
        return itemImage;
    }
    
    return nil;
}

/*
 * Calls the JS function to draw each individual hotspot in the array provided
 * with the color specified.
 */
- (void)drawHotspots:(NSMutableArray *)hotspots color:(NSString *)color {
    for (Hotspot *hotspot in hotspots) {
        CGPoint hotspotLoc = [self getHotspotLocation:hotspot];
        
        if (hotspotLoc.x != -1) {
            NSString *drawHotspot = [NSString stringWithFormat:@"drawHotspot(%f, %f, \"%@\")",
                                     hotspotLoc.x, hotspotLoc.y, color];
            [self.bookView stringByEvaluatingJavaScriptFromString:drawHotspot];
        }
    }
}

- (void)colorSentencesUponNext:(NSInteger)currentSentence
                     condition:(Condition)condition
                       andMode:(Mode)mode {
    
    //Set the color of the current sentence to black by default
    NSString *setSentenceColor = [NSString stringWithFormat:@"setSentenceColor(s%ld, 'black')", (long)currentSentence];
    [self.bookView stringByEvaluatingJavaScriptFromString:setSentenceColor];
    
    //Change the opacity to 1
    NSString *setSentenceOpacity = [NSString stringWithFormat:@"setSentenceOpacity(s%ld, 1)", (long)currentSentence];
    [self.bookView stringByEvaluatingJavaScriptFromString:setSentenceOpacity];
    
    //Set the color of the previous sentence to black
    setSentenceColor = [NSString stringWithFormat:@"setSentenceColor(s%d, 'black')", currentSentence - 1];
    [self.bookView stringByEvaluatingJavaScriptFromString:setSentenceColor];
    
    //Decrease the opacity of the previous sentence
    setSentenceOpacity = [NSString stringWithFormat:@"setSentenceOpacity(s%d, .2)", currentSentence - 1];
    [self.bookView stringByEvaluatingJavaScriptFromString:setSentenceOpacity];
    
    //Get the sentence class
    NSString *actionSentence = [NSString stringWithFormat:@"getSentenceClass(s%ld)", (long)currentSentence];
    NSString *sentenceClass = [self.bookView stringByEvaluatingJavaScriptFromString:actionSentence];
    
    //If it is a non-black action sentence (i.e., requires user manipulation), then set the color to blue
    if (![sentenceClass containsString:@"black"]) {
        if ([sentenceClass containsString: @"sentence actionSentence"] ||
            ([sentenceClass containsString: @"sentence IMactionSentence"] && condition == EMBRACE && mode == IM_MODE)) {
            setSentenceColor = [NSString stringWithFormat:@"setSentenceColor(s%ld, 'blue')", (long)currentSentence];
            [self.bookView stringByEvaluatingJavaScriptFromString:setSentenceColor];
        }
    }
}

- (void)colorSentencesUponBack:(NSInteger)currentSentence
                     condition:(Condition)condition
                       andMode:(Mode)mode {
    
    //Set the color of the current sentence to black by default
    NSString *setSentenceColor = [NSString stringWithFormat:@"setSentenceColor(s%ld, 'black')", (long)currentSentence];
    [self.bookView stringByEvaluatingJavaScriptFromString:setSentenceColor];
    
    //Change the opacity to 1
    NSString *setSentenceOpacity = [NSString stringWithFormat:@"setSentenceOpacity(s%ld, 1)", (long)currentSentence];
    [self.bookView stringByEvaluatingJavaScriptFromString:setSentenceOpacity];
    
    //Set the color of the previous sentence to black
    setSentenceColor = [NSString stringWithFormat:@"setSentenceColor(s%d, 'black')", currentSentence + 1];
    [self.bookView stringByEvaluatingJavaScriptFromString:setSentenceColor];
    
    //Decrease the opacity of the previous sentence
    setSentenceOpacity = [NSString stringWithFormat:@"setSentenceOpacity(s%d, .2)", currentSentence + 1];
    [self.bookView stringByEvaluatingJavaScriptFromString:setSentenceOpacity];
    
    //Get the sentence class
    NSString *actionSentence = [NSString stringWithFormat:@"getSentenceClass(s%ld)", (long)currentSentence];
    NSString *sentenceClass = [self.bookView stringByEvaluatingJavaScriptFromString:actionSentence];
    
    //If it is a non-black action sentence (i.e., requires user manipulation), then set the color to blue
    if (![sentenceClass containsString:@"black"]) {
        if ([sentenceClass containsString: @"sentence actionSentence"] ||
            ([sentenceClass containsString: @"sentence IMactionSentence"] && condition == EMBRACE && mode == IM_MODE)) {
            setSentenceColor = [NSString stringWithFormat:@"setSentenceColor(s%ld, 'blue')", (long)currentSentence];
            [self.bookView stringByEvaluatingJavaScriptFromString:setSentenceColor];
        }
    }
}

- (void)highLightArea:(NSString *)objectId {
    NSString *highlight = [NSString stringWithFormat:@"highlightArea('%@')", objectId];
    [self.bookView stringByEvaluatingJavaScriptFromString:highlight];
}

- (void)highlightLocation:(int)originX : (int)originY : (int)width : (int)height {
    NSString *highlight = [NSString stringWithFormat:@"highlightLocation(%d, %d, %d, %d)", originX, originY, width, height];
    [self.bookView stringByEvaluatingJavaScriptFromString:highlight];
}

- (void)highlightObjectOnWordTap:(NSString *)objectId {
    NSString *highlight = [NSString stringWithFormat:@"highlightObjectOnWordTap(%@)", objectId];
    [self.bookView stringByEvaluatingJavaScriptFromString:highlight];
}

#pragma mark - Animation

- (void)animateObject:(NSString *)objectId
                 from:(CGPoint)fromPos
                   to:(CGPoint)toPos
               action:(NSString *)action
               areaId:(NSString *)areaId{
    
    
    NSString *animate = [NSString stringWithFormat:@"animateObject(%@, %f, %f, %f, %f, '%@', '%@')",
                         objectId, fromPos.x, fromPos.y, toPos.x, toPos.y, action, areaId];
    [self.bookView stringByEvaluatingJavaScriptFromString:animate];
}

- (void)simulateUngrouping:(NSString *)obj1
                   object2:(NSString *)obj2
                    images:(NSMutableDictionary *)images
                       gap:(float)gap {
    
    //See if one object is contained in the other.
    NSString *requestObj1ContainedInObj2 = [NSString stringWithFormat:@"objectContainedInObject(%@, %@)", obj1, obj2];
    NSString *obj1ContainedInObj2 = [self.bookView stringByEvaluatingJavaScriptFromString:requestObj1ContainedInObj2];
    
    NSString *requestObj2ContainedInObj1 = [NSString stringWithFormat:@"objectContainedInObject(%@, %@)", obj2, obj1];
    NSString *obj2ContainedInObj1 = [self.bookView stringByEvaluatingJavaScriptFromString:requestObj2ContainedInObj1];
    
    CGFloat obj1FinalPosX, obj2FinalPosX; //For ungrouping we only ever change X.
    
    //Get the locations and widths of objects 1 and 2.
    MenuItemImage *obj1Image = [images objectForKey:obj1];
    MenuItemImage *obj2Image = [images objectForKey:obj2];
    
    CGFloat obj1PositionX = [obj1Image boundingBoxImage].origin.x;
    CGFloat obj2PositionX = [obj2Image boundingBoxImage].origin.x;
    
    CGFloat obj1Width = [obj1Image boundingBoxImage].size.width;
    CGFloat obj2Width = [obj2Image boundingBoxImage].size.width;
    
    if ([obj1ContainedInObj2 isEqualToString:@"true"]) {
        obj1FinalPosX = obj2PositionX - obj2Width - gap;
        obj2FinalPosX = obj2PositionX;
    }
    else if ([obj2ContainedInObj1 isEqualToString:@"true"]) {
        obj1FinalPosX = obj1PositionX;
        obj2FinalPosX = obj1PositionX + obj1Width + gap;
    }
    
    //Otherwise, partially overlapping or connected on the edges.
    else {
        //Figure out which is the leftmost object. Unlike the animate ungrouping function, we're just going to move the leftmost object to the left so that it's not overlapping with the other one unless it's a TRANSFERANDDISAPPEAR interaction
        if (obj1PositionX < obj2PositionX) {
            obj1FinalPosX = obj2PositionX - obj2Width - gap;
            
            //A negative GAP indicates a TRANSFERANDDISAPPEAR interaction, so we want to adjust the rightmost object so that it is slightly overlapping the right side of the leftmost object
            if (gap < 0) {
                obj2FinalPosX = obj1FinalPosX + obj1Width + gap;
            }
            //A positive GAP indicates a normal ungrouping interaction, so the leftmost object was moved to the left. If it's still overlapping, we move the rightmost object to the left of the leftmost object. Otherwise, we leave it alone.
            else {
                //Objects are overlapping
                if (obj2PositionX < obj1FinalPosX + obj1Width) {
                    obj2FinalPosX = obj1PositionX - obj1Width - gap;
                }
                //Objects are not overlapping
                else {
                    obj2FinalPosX = obj2PositionX;
                }
            }
        }
        else {
            obj1FinalPosX = obj1PositionX;
            obj2FinalPosX = obj1PositionX + obj1Width + gap;
        }
    }
    
    [obj1Image setBoundingBoxImage:CGRectMake(obj1FinalPosX, [obj1Image boundingBoxImage].origin.y, [obj1Image boundingBoxImage].size.width, [obj1Image boundingBoxImage].size.height)];
    [obj2Image setBoundingBoxImage:CGRectMake(obj2FinalPosX, [obj2Image boundingBoxImage].origin.y, [obj2Image boundingBoxImage].size.width, [obj2Image boundingBoxImage].size.height)];
}

- (void)swapImages:(NSString *)object1Id
      alternateSrc:(NSString *)altSrc
             width:(NSString *)width
            height:(NSString *)height
          location:(CGPoint)location
            zIndex:(NSString *)zIndex {
    
    //Swap images using alternative src
    NSString *swapImages;
    
    if ([height isEqualToString:@""]) {
        swapImages = [NSString stringWithFormat:@"swapImageSrc('%@', '%@', '%@', %f, %f, '%@')", object1Id, altSrc, width, location.x, location.y, zIndex];
    }
    else {
        swapImages = [NSString stringWithFormat:@"swapImageSrc('%@', '%@', '%@', '%@', %f, %f, '%@')", object1Id, altSrc, width, height, location.x, location.y, zIndex];
    }
    
    [self.bookView stringByEvaluatingJavaScriptFromString:swapImages];
}

- (void)loadImage:(NSString *)object1Id
     alternateSrc:(NSString *)altSrc
            width:(NSString *)width
           height:(NSString *)height
         location:(CGPoint)location
        className:(NSString *)className
           zIndex:(NSString *)zPosition {
    
    
    NSString *loadImage;
    
    if ([height isEqualToString:@""]) {
        loadImage = [NSString stringWithFormat:@"loadImage('%@', '%@', '%@', %f, %f, '%@', %d)", object1Id, altSrc, width, location.x, location.y, className, zPosition.intValue];
    }
    else {
        loadImage = [NSString stringWithFormat:@"loadImage('%@', '%@', '%@', '%@', %f, %f, '%@', %d)", object1Id, altSrc, width, height, location.x, location.y, className, zPosition.intValue];
    }
    
    [self.bookView stringByEvaluatingJavaScriptFromString:loadImage];
}

/*
 * Moves the object passed in to the location given. Calculates the difference between the point touched and the
 * top-left corner of the image, which is the x,y coordate that's actually used when moving the object.
 * Also ensures that the image is not moved off screen or outside of any specified bounding boxes for the image.
 * Updates the JS Connection hotspot locations if necessary.
 */
- (CGPoint)moveObject:(NSString *)object
          location:(CGPoint)location
            offset:(CGPoint)offset
shouldUpdateConnection:(BOOL)updateCon
         withModel:(InteractionModel *)model
      movingObject:(NSString *)movingObjectId
     startLocation:(CGPoint)startLocation
         shouldPan:(BOOL)isPanning {
    
    //Change the location to accounting for the different between the point clicked and the top-left corner which is used to set the position of the image.
    CGPoint adjLocation = CGPointMake(location.x - offset.x, location.y - offset.y);
    
    //Get the width and height of the image to ensure that the image is not being moved off screen and that the image is being moved in accordance with all movement constraints.
    
    CGSize size = [self sizeOfObject:object];
    float imageHeight = size.height;
    float imageWidth = size.width;
    
    //Check to see if the image is being moved outside of any bounding boxes. At this point in time, each object only has 1 movemet constraint associated with it and the movement constraint is a bounding box. The bounding box is in relative (percentage) values to the background object.
    NSArray *constraints = [model getMovementConstraintsForObjectId:object];
    
    //If there are movement constraints for this object.
    if ([constraints count] > 0) {
        MovementConstraint *constraint = (MovementConstraint *)[constraints objectAtIndex:0];
        
        //Calculate the x,y coordinates and the width and height in pixels from %
        float boxX = [constraint.originX floatValue] / 100.0 * [self.bookView frame].size.width;
        float boxY = [constraint.originY floatValue] / 100.0 * [self.bookView frame].size.height;
        float boxWidth = [constraint.width floatValue] / 100.0 * [self.bookView frame].size.width;
        float boxHeight = [constraint.height floatValue] / 100.0 * [self.bookView frame].size.height;
        
        //Ensure that the image is not being moved outside of its bounding box.
        if (adjLocation.x + imageWidth > boxX + boxWidth)
            adjLocation.x = boxX + boxWidth - imageWidth;
        else if (adjLocation.x < boxX)
            adjLocation.x = boxX;
        if (adjLocation.y + imageHeight > boxY + boxHeight)
            adjLocation.y = boxY + boxHeight - imageHeight;
        else if (adjLocation.y < boxY)
            adjLocation.y = boxY;
    }
    NSString *imageMarginLeft = [self imageMarginLeft:movingObjectId];
    NSString *imageMarginTop = [self imageMarginTop:movingObjectId];
    if (![imageMarginLeft isEqualToString:@""] && ![imageMarginTop isEqualToString:@""]) {
        //Check to see if the image is being moved off screen. If it is, change it so that the image cannot be moved off screen.
        if (adjLocation.x + (imageWidth/2) > [self.bookView frame].size.width)
            adjLocation.x = [self.bookView frame].size.width - (imageWidth/2);
        else if (adjLocation.x-(imageWidth/2)  < 0)
            adjLocation.x = (imageWidth/2);
        if (adjLocation.y + (imageHeight/2) > [self.bookView frame].size.height)
            adjLocation.y = [self.bookView frame].size.height - (imageHeight/2);
        else if (adjLocation.y-(imageHeight/2) < 0)
            adjLocation.y = (imageHeight/2);
    }
    else {
        //Check to see if the image is being moved off screen. If it is, change it so that the image cannot be moved off screen.
        if (adjLocation.x + imageWidth > [self.bookView frame].size.width)
            adjLocation.x = [self.bookView frame].size.width - imageWidth;
        else if (adjLocation.x < 0)
            adjLocation.x = 0;
        if (adjLocation.y + imageHeight > [self.bookView frame].size.height)
            adjLocation.y = [self.bookView frame].size.height - imageHeight;
        else if (adjLocation.y < 0)
            adjLocation.y = 0;
    }
    
    CGPoint endLocation = adjLocation;
    
    //Call the moveObject function in the js file.
    NSString *move = [NSString stringWithFormat:@"moveObject(%@, %f, %f, %@)", object, adjLocation.x, adjLocation.y, updateCon ? @"true" : @"false"];
    [self.bookView stringByEvaluatingJavaScriptFromString:move];
    
    //Update the JS Connection manually only if we have stopped moving the object
    if (updateCon && !isPanning) {
        //Calculate difference between start and end positions of the object
        float deltaX = adjLocation.x - startLocation.x;
        float deltaY = adjLocation.y - startLocation.y;
        
        [self updateConnection:object deltaX:deltaX deltaY:deltaY];
    }
    return endLocation;
}

- (void)updateConnection:(NSString *)object deltaX:(float)deltaX deltaY:(float)deltaY {
    NSString *updateConnection = [NSString stringWithFormat:@"updateConnection(%@, %f, %f)", object, deltaX, deltaY];
    [self.bookView stringByEvaluatingJavaScriptFromString:updateConnection];
}

- (void)groupObjects:(NSString *)object1
      object1HotSpot:(CGPoint)object1Hotspot
             object2:(NSString *)object2
      object2Hotspot:(CGPoint)object2Hotspot {
    
    NSString *groupObjects = [NSString stringWithFormat:@"groupObjectsAtLoc(%@, %f, %f, %@, %f, %f)", object1, object1Hotspot.x, object1Hotspot.y, object2, object2Hotspot.x, object2Hotspot.y];
    [self.bookView stringByEvaluatingJavaScriptFromString:groupObjects];
}

- (void)ungroupObjects:(NSString *)object1 object2:(NSString *)object2 {
    NSString *ungroup = [NSString stringWithFormat:@"ungroupObjects(%@, %@)", object1, object2];
    [self.bookView stringByEvaluatingJavaScriptFromString:ungroup];
}

- (void)ungroupObjectsAndStay:(NSString *)object1 object2:(NSString *)object2 {
    NSString *ungroup = [NSString stringWithFormat:@"ungroupObjectsAndStay(%@, %@)", object1, object2];
    [self.bookView stringByEvaluatingJavaScriptFromString:ungroup];
}

/*
 * Call JS code to cause the object to disappear, then calculate where it needs to re-appear and call the JS code to make
 * it re-appear at the new location.
 */
- (CGPoint)consumeAndReplenishSupply:(NSString *)disappearingObject
                  shouldReplenish:(BOOL)replenishSupply
                            model:(InteractionModel *)model
                     movingObject:(NSString *)movingObjectId
                    startLocation:(CGPoint)startLocation
                        shouldPan:(BOOL)isPanning {
    
    //Replenish supply of disappearing object only if allowed
    if (replenishSupply) {
        //Move the object to the "appear" hotspot location. This means finding the hotspot that specifies this information for the object, and also finding the relationship that links this object to the other object it's supposed to appear at/in.
        Hotspot *hiddenObjectHotspot = [model getHotspotforObjectWithActionAndRole:disappearingObject :@"appear" :@"subject"];
        
        //Get the relationship between this object and the other object specifying where the object should appear. Even though the call is to a general function, there should only be 1 valid relationship returned.
        NSMutableArray *relationshipsForHiddenObject = [model getRelationshipForObjectForAction:disappearingObject :@"appear"];
        
        //There should be one and only one valid relationship returned, but we'll double check anyway.
        if ([relationshipsForHiddenObject count] > 0) {
            Relationship *appearRelation = [relationshipsForHiddenObject objectAtIndex:0];
            
            //Now we have to pull the hotspot at which this relationship occurs.
            //Note: We may at one point want to programmatically determine the role, but for now, we'll hard code it in.
            Hotspot *appearHotspot = [model getHotspotforObjectWithActionAndRole:[appearRelation object2Id] :@"appear" :@"object"];
            
            //Make sure that the hotspot was found and returned.
            if (appearHotspot != nil) {
                //Use the hotspot returned to calculate the location at which the disappearing object should appear.
                //The two hotspots need to match up, so we need to figure out how far away the top-left corner of the disappearing object needs to be from the location it needs to appear at.
                CGPoint appearLocation = [self getHotspotLocation:appearHotspot];
                
                //Next we have to move the apple to that location. Need the pixel location of the hotspot of the disappearing object.
                //Again, double check to make sure this isn't nil.
                if (hiddenObjectHotspot != nil) {
                    CGPoint hiddenObjectHotspotLocation = [self getHotspotLocation:hiddenObjectHotspot];
                    
                    //With both hotspot pixel values we can calcuate the distance between the top-left corner of the hidden object and it's hotspot.
                    CGPoint change = [self deltaForMovingObjectAtPoint:hiddenObjectHotspotLocation];
                    
                    //Now move the object taking into account the difference in change.

                    CGPoint endlocation = [self moveObject:disappearingObject
                            location:appearLocation
                              offset:change
              shouldUpdateConnection:NO
                           withModel:model
                        movingObject:movingObjectId
                       startLocation:startLocation
                           shouldPan:isPanning];
                    return endlocation;
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
        NSString *hideObj = [NSString stringWithFormat:@"document.getElementById('%@').style.display = 'none';", disappearingObject];
        [self.bookView stringByEvaluatingJavaScriptFromString:hideObj];
    }
    return CGPointMake(-99, -99);
}

- (void)removeAllSentences {
    //Get the number of sentences on the page
    NSString *requestSentenceCount = [NSString stringWithFormat:@"document.getElementsByClassName('sentence').length"];
    int sentenceCount = [[self.bookView stringByEvaluatingJavaScriptFromString:requestSentenceCount] intValue];
    
    //Get the id number of the last sentence on the page
    NSString *requestLastSentenceId = [NSString stringWithFormat:@"document.getElementsByClassName('sentence')[%d - 1].id", sentenceCount];
    NSString *lastSentenceId = [self.bookView stringByEvaluatingJavaScriptFromString:requestLastSentenceId];
    int lastSentenceIdNumber = [[lastSentenceId substringFromIndex:1] intValue];
    
    //Get the id number of the first sentence on the page
    NSString *requestFirstSentenceId = [NSString stringWithFormat:@"document.getElementsByClassName('sentence')[0].id"];
    NSString *firstSentenceId = [self.bookView stringByEvaluatingJavaScriptFromString:requestFirstSentenceId];
    int firstSentenceIdNumber = [[firstSentenceId substringFromIndex:1] intValue];
    
    NSString *removeSentenceString;
    
    //Remove all sentences on page
    for (int i = firstSentenceIdNumber; i <= lastSentenceIdNumber; i++) {
        //Skip the title (sentence 0) if it's the first on the page
        if (i > 0) {
            removeSentenceString = [NSString stringWithFormat:@"removeSentence('s%d')", i];
            [self.bookView stringByEvaluatingJavaScriptFromString:removeSentenceString];
        }
    }
}

- (void)addSentence:(AlternateSentence *)sentenceToAdd withSentenceNumber:(int)sentenceNumber andVocabulary:(NSMutableSet *)vocabulary {
    NSString *addSentenceString;
    //Get alternate sentence information
    BOOL action = [sentenceToAdd actionSentence];
    NSString *text = [sentenceToAdd text];
    
    
    // Fix for double quotes missplacing.
    NSArray *tTokens = [text componentsSeparatedByString:@" "];
    NSMutableArray *tempArray = [NSMutableArray array];
    
    for (NSString *t in tTokens) {
        NSArray *insideArray = [t componentsSeparatedByString:@"\\\""];
       
        if ([insideArray count] > 1) {
            for (NSString *insideT in insideArray) {
                [tempArray addObject:insideT];
                [tempArray addObject:@"\\\""];
            }
            [tempArray removeLastObject];
        } else {
            [tempArray addObject:t];
        }
        
    }
    //Split sentence text into individual tokens (words)
    NSArray *textTokens = [NSArray arrayWithArray:tempArray];
    
    //Contains the vocabulary words that appear in the sentence
    NSMutableArray *words = [[NSMutableArray alloc] init];
    
    //Contains the sentence text split around vocabulary words
    NSMutableArray *splitText = [[NSMutableArray alloc] init];
    
    //Combines tokens into the split sentence text
    NSString *currentSplit = @"";
    
    for (NSString *textToken in textTokens) {
        NSString *modifiedTextToken = textToken;
        
        //Replaces the ' character if it exists in the token
        if ([modifiedTextToken rangeOfString:@"'"].location != NSNotFound) {
            modifiedTextToken = [modifiedTextToken stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
        }
        
        BOOL addedWord = false; //whether token contains vocabulary word
        
        for (NSString *vocab in vocabulary) {
            // Match the whole vocabulary word only
            NSString *regex = [NSString stringWithFormat:@"\\b%@\\b", vocab];
            
            NSRange range = [modifiedTextToken rangeOfString:regex options:NSRegularExpressionSearch|NSCaseInsensitiveSearch];
            
            // Token contains vocabulary word
            if (range.location != NSNotFound) {
                [words addObject:[modifiedTextToken substringWithRange:range]]; // Add word to list
                addedWord = true;
                
                [splitText addObject:currentSplit];
                
                // Reset current split to be anything that appears after the vocabulary word and add a space in the beginning
                currentSplit = [[modifiedTextToken stringByReplacingCharactersInRange:range withString:@""] stringByAppendingString:@" "];
                
                break;
            }
        }
        
        //Token does not contain vocabulary word
        if (!addedWord) {
            //Add token to current split with a space after it
            NSString *textTokenSpace = [NSString stringWithFormat:@"%@ ", modifiedTextToken];
            currentSplit = [currentSplit stringByAppendingString:textTokenSpace];
        }
    }
    
    [splitText addObject:currentSplit]; //make sure to add the last split
    
    //Create array strings for vocabulary and split text to send to JS function
    NSString *wordsArrayString = [words componentsJoinedByString:@"','"];
    NSString *splitTextArrayString = [splitText componentsJoinedByString:@"','"];
    
    ConditionSetup *conditionSetup = [ConditionSetup sharedInstance];
    //Add alternate sentence to page
    addSentenceString = [NSString stringWithFormat:@"addSentence('s%d', %@, ['%@'], ['%@'], %@)", sentenceNumber++, action ? @"true" : @"false", splitTextArrayString, wordsArrayString, conditionSetup.isOnDemandVocabEnabled ? @"true" : @"false"];
    [self.bookView stringByEvaluatingJavaScriptFromString:addSentenceString];
    
}



@end
