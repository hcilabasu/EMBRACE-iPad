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

@property (nonatomic, weak) ManipulationViewController *mvc;
@property (nonatomic, weak) SolutionStepController *ssc;
@property (nonatomic, weak) StepContext *stepContext;
//@property (nonatomic, strong) ConditionSetup *conditionSetup;
//@property (nonatomic, strong) PageContext *pageContext;
//@property (nonatomic, strong) SentenceContext *sentenceContext;
@property (nonatomic, weak) ManipulationContext *manipulationContext;

- (void)performInteraction:(PossibleInteraction *)interaction;
- (void)rankPossibleInteractions:(NSMutableArray *)possibleInteractions;
- (NSMutableArray *)getPossibleTransferInteractionsforObjects:(NSString *)objConnected :(NSString *)objConnectedTo :(NSString *)currentUnconnectedObj :(Hotspot *)objConnectedHotspot :(Hotspot *)currentUnconnectedObjHotspot;
- (void)simulatePossibleInteractionForMenuItem:(PossibleInteraction *)interaction :(Relationship *)relationship;
- (PossibleInteraction *)getCorrectInteraction;

@end
