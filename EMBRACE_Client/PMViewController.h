//
//  BookViewController.h
//  eBookReader
//
//  Created by Andreea Danielescu on 2/12/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PieContextualMenuDelegate.h"
#import "EbookImporter.h"
#import "Book.h"
#import "AVFoundation/AVSpeechSynthesis.h"
#import "IntroductionViewController.h"

typedef enum Condition {
    MENU,
    HOTSPOT,
    CONTROL,
    OTHER,
} Condition;

typedef enum InteractionRestriction {
    ALL_ENTITIES, //Any object can be used
    ONLY_CORRECT, //Only the correct object can be used
    NO_ENTITIES //No object can be used
} InteractionRestriction;

typedef enum Language {
    ENGLISH,
    BILINGUAL
} Language;

typedef enum InteractionMode {
    NO_INTERACTION,
    INTERACTION
} InteractionMode;

@interface PMViewController : UIViewController <UIGestureRecognizerDelegate, UIScrollViewDelegate, PieContextualMenuDelegate> {
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

-(void) loadFirstPage;
-(void) loadNextPage;
-(void) loadPage;

@end
