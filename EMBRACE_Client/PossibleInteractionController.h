//
//  PossibleInteractionController.h
//  EMBRACE
//
//  Created by James Rodriguez on 8/10/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ManipulationViewController.h"

@interface PossibleInteractionController : NSObject

-(id)initWithController:(ManipulationViewController *) superMvc;

@property (nonatomic, strong) ManipulationViewController *mvc;
@property (nonatomic, strong) SolutionStepController *ssc;
@property (nonatomic, strong) StepContext *stepContext;
//@property (nonatomic, strong) ConditionSetup *conditionSetup;
//@property (nonatomic, strong) PageContext *pageContext;
//@property (nonatomic, strong) SentenceContext *sentenceContext;
@property (nonatomic, strong) ManipulationContext *manipulationContext;

- (void)performInteraction:(PossibleInteraction *)interaction;
- (void)rankPossibleInteractions:(NSMutableArray *)possibleInteractions;
- (NSMutableArray *)getPossibleTransferInteractionsforObjects:(NSString *)objConnected :(NSString *)objConnectedTo :(NSString *)currentUnconnectedObj :(Hotspot *)objConnectedHotspot :(Hotspot *)currentUnconnectedObjHotspot;
- (void)simulatePossibleInteractionForMenuItem:(PossibleInteraction *)interaction :(Relationship *)relationship;
- (PossibleInteraction *)getCorrectInteraction;

@end
