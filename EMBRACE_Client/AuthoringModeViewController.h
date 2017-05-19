//
//  AuthoringModeViewController.h
//  EMBRACE
//
//  Created by James Rodriguez on 4/3/15.
//  Copyright (c) 2015 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PieContextualMenuDelegate.h"
#import "EBookImporter.h"
#import "Book.h"
#import "AVFoundation/AVSpeechSynthesis.h"
#import "AssessmentActivityViewController.h"

@interface AuthoringModeViewController : UIViewController <UIGestureRecognizerDelegate, UIScrollViewDelegate, UIPickerViewDelegate>{
    EBookImporter __weak *bookImporter;
    Book *book;
    
    IBOutlet UIPinchGestureRecognizer *pinchRecognizer;
    IBOutlet UIPanGestureRecognizer *panRecognizer;
    IBOutlet UITapGestureRecognizer *tapRecognizer;
    IBOutlet UISwipeGestureRecognizer *swipeRecognizer;
}

@property (strong, nonatomic) id dataObject;
@property (nonatomic, weak) EBookImporter *bookImporter;
@property (nonatomic, copy) NSString *bookTitle;
@property (nonatomic, copy) NSString *chapterTitle;
@property (nonatomic, strong) Book *book;
@property (nonatomic, strong) AVSpeechSynthesizer *syn;
@property (nonatomic,strong) PlayAudioFile *playaudioClass;
@property (nonatomic, strong) UIViewController *libraryViewController;
@property (nonatomic, strong) UIPickerView *picker;
@property (nonatomic, retain) NSArray *ImageOptions;
@property (nonatomic, strong) UIView *entryview;
@property (nonatomic, strong) UIView *areaSpace;
@property (nonatomic) NSInteger TapLocationX;
@property (nonatomic) NSInteger TapLocationY;
@property (nonatomic, strong) UIView *HotspotEntry;
@property (nonatomic, strong) UIView *LocationEntry;
@property (nonatomic, strong) UIView *WaypointEntry;
@property (nonatomic, strong) UIView *SingleEntry;
@property (nonatomic, strong) UITextField *xcord;
@property (nonatomic, strong) UITextField *ycord;
@property (nonatomic, strong) UITextField *waypointID;
@property (nonatomic, strong) UITextField *locationID;
@property (nonatomic, strong) UITextField *hotspotID;
@property (nonatomic, strong) UITextField *areaID;
@property (nonatomic, strong) UITextField *pageID;
@property (nonatomic, strong) UITextField *width;
@property (nonatomic, strong) UITextField *height;
@property (nonatomic, strong) UITextField *top;
@property (nonatomic, strong) UITextField *left;
@property (nonatomic, strong) UITextField *hotspotWidth;
@property (nonatomic, strong) UITextField *hotspotHeight;
@property (nonatomic, strong) UITextField *hotspotTop;
@property (nonatomic, strong) UITextField *hotspotLeft;
@property (nonatomic, strong) UITextField *zindex;
@property (nonatomic, strong) UITextField *objectID;
@property (nonatomic, strong) UITextField *manipulationType;
@property (nonatomic, strong) UITextField *action;
@property (nonatomic, strong) UITextField *role;
@property (nonatomic, strong) UITextView *areaPoints;
@property (nonatomic) BOOL isEntryViewVisible;
@property (nonatomic) BOOL isAreaViewVisible;

- (void) loadFirstPage;
- (void) loadNextPage;
- (void) loadPage;
- (BOOL) writeToFile:(NSString *)toLocation :(NSString *)fileName ofType:(NSString *)type;

@end
