//
//  PageController.h
//  EMBRACE
//
//  Created by James Rodriguez on 8/10/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ManipulationViewController.h"

@interface PageController : NSObject

@property (nonatomic, weak) ManipulationViewController *mvc;
@property (nonatomic, weak) InteractionModel *model;
@property (nonatomic, weak) ConditionSetup *conditionSetup;
@property (nonatomic, weak) ManipulationContext *manipulationContext;
@property (nonatomic, weak) PageContext *pageContext;
@property (nonatomic, weak) SentenceContext *sentenceContext;
@property (nonatomic, weak) StepContext *stepContext;
@property (nonatomic, weak) EBookImporter *bookImporter;
@property (nonatomic, copy) NSString *bookTitle;
@property (nonatomic, copy) NSString *chapterTitle;
@property (nonatomic, weak) Book *book;
@property (nonatomic, weak) IBOutlet ManipulationView *manipulationView;
@property (nonatomic, weak) NSMutableDictionary *animatingObjects;
//@property (nonatomic) BOOL allowInteractions; //TRUE if objects can be manipulated; FALSE otherwise

- (id)initWithController: (ManipulationViewController*) superMvc;
- (void) loadFirstPage;
- (void) loadNextPage;
- (void) loadPreviousPage;
@end
