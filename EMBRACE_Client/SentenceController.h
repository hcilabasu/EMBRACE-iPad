//
//  SentenceController.h
//  EMBRACE
//
//  Created by James Rodriguez on 8/10/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ManipulationViewController.h"

@interface SentenceController : NSObject

@property (nonatomic, weak) ManipulationViewController *mvc;
@property (nonatomic, weak) ConditionSetup *conditionSetup;
@property (nonatomic, weak) ManipulationContext *manipulationContext;
@property (nonatomic, weak) PageContext *pageContext;
@property (nonatomic, weak) SentenceContext *sentenceContext;
@property (nonatomic, weak) StepContext *stepContext;
@property (nonatomic, weak) EBookImporter *bookImporter;
@property (nonatomic, strong) NSString *bookTitle;
@property (nonatomic, strong) NSString *chapterTitle;
@property (nonatomic, weak) IBOutlet ManipulationView *manipulationView;
@property (nonatomic, weak) NSMutableDictionary *animatingObjects;

- (id) initWithController: (ManipulationViewController *) superMvc;
- (void) setupCurrentSentenceColor;
- (void) setupCurrentSentence;
- (BOOL)isManipulationSentence:(NSInteger)sentenceNumber;
- (NSInteger)getComplexityOfCurrentSentence;
- (void)colorSentencesUponNext;
- (void)colorSentencesUponBack;
- (NSString *)getSpanishTranslation:(NSString *)sentence;
- (NSString *)getEnglishTranslation:(NSString *)sentence;
- (void) setupSentencesForPage;

@end
