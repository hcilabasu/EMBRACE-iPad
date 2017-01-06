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

@property (nonatomic, strong) ManipulationViewController *mvc;
@property (nonatomic, strong) InteractionModel *model;
@property (nonatomic, strong) ConditionSetup *conditionSetup;
@property (nonatomic, strong) ManipulationContext *manipulationContext;
@property (nonatomic, strong) PageContext *pageContext;
@property (nonatomic, strong) SentenceContext *sentenceContext;
@property (nonatomic, strong) StepContext *stepContext;
@property (nonatomic, strong) EBookImporter *bookImporter;
@property (nonatomic, strong) NSString *bookTitle;
@property (nonatomic, strong) NSString *chapterTitle;
@property (nonatomic, strong) Book *book;
@property (nonatomic, strong) IBOutlet ManipulationView *manipulationView;
@property (nonatomic, strong) NSMutableDictionary *animatingObjects;
//@property (nonatomic) BOOL allowInteractions; //TRUE if objects can be manipulated; FALSE otherwise

- (id)initWithController: (ManipulationViewController*) superMvc;
- (void) loadFirstPage;
- (void) loadNextPage;
- (void) loadPreviousPage;
@end
