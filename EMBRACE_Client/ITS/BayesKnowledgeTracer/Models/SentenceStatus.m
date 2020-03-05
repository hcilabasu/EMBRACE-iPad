//
//  StatementStatus.m
//  EMBRACE
//
//  Created by Jithin on 6/15/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "SentenceStatus.h"
#import "ActionStep.h"

@interface SentenceStatus ()

@property (nonatomic, strong) NSMutableArray *userActionSteps;

@end

@implementation SentenceStatus

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _userActionSteps = [[NSMutableArray alloc] init];
        _numOfSyntaxErrors = 0;
        _numOfVocabErrors = 0;
        _numOfUsabilityErrors = 0;
        _numOfAttempts = 0;
    }
    
    return self;
}

- (void)addUserAction:(UserAction *)action {
    if (action.isVerified) {
        self.isCompleted = YES;
    }
    
    [self.userActionSteps addObject:action];
}

- (NSArray *)userActions {
    return [NSArray arrayWithArray:self.userActionSteps];
}

- (BOOL)containsAction:(UserAction *)action {
    for (UserAction *exAction in self.userActionSteps) {
        if (exAction.sentenceNumber == action.sentenceNumber && exAction.ideaNumber == action.ideaNumber && exAction.stepNumber == action.stepNumber) {
            return YES;
        }
    }
    
    return NO;
}

@end
