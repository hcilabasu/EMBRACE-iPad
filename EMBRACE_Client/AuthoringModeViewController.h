//
//  AuthoringModeViewController.h
//  EMBRACE
//
//  Created by James Rodriguez on 4/3/15.
//  Copyright (c) 2015 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIKit.h>
#import "PieContextualMenuDelegate.h"
#import "EbookImporter.h"
#import "Book.h"
#import "AVFoundation/AVSpeechSynthesis.h"
#import "IntroductionViewController.h"
#import "AssessmentActivityViewController.h"

//This enum defines the action types that exist in every intro or vocab step
//typedef enum Action {
//    SELECTION,
//    EXP_ACTION,
//    INPUT
//}Action;

@interface AuthoringModeViewController : UIViewController <UIGestureRecognizerDelegate, UIScrollViewDelegate, UIPickerViewDelegate>{
    EBookImporter *bookImporter;
    Book* book;
    
    IBOutlet UIPinchGestureRecognizer *pinchRecognizer;
    IBOutlet UIPanGestureRecognizer *panRecognizer;
    IBOutlet UITapGestureRecognizer *tapRecognizer;
    IBOutlet UISwipeGestureRecognizer *swipeRecognizer;
}

@property (strong, nonatomic) id dataObject;
@property (nonatomic, strong) EBookImporter *bookImporter;
@property (nonatomic, strong) NSString *bookTitle;
@property (nonatomic, strong) NSString *chapterTitle;
@property (nonatomic, strong) Book* book;
@property (nonatomic, strong) AVSpeechSynthesizer* syn;
@property (nonatomic, strong) IntroductionViewController *IntroductionClass;
@property (nonatomic, strong) BuildHTMLString *buildstringClass;
@property(nonatomic,strong) PlayAudioFile *playaudioClass;
@property(nonatomic, strong) UIViewController *libraryViewController;
@property(nonatomic, strong) UIPickerView *picker;
@property(nonatomic, retain) NSArray *ImageOptions;
@property(nonatomic, strong) UIView *entryview;
@property(nonatomic) NSInteger TapLocationX;
@property(nonatomic) NSInteger TapLocationY;

-(void) loadFirstPage;
-(void) loadNextPage;
-(void) loadPage;

@end
