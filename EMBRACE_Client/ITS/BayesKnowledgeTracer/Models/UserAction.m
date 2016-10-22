//
//  UserAction.m
//  EMBRACE
//
//  Created by Jithin on 6/15/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "UserAction.h"
#import "ActionStep.h"

@interface UserAction()

@property (nonatomic, strong) ActionStep *actionStep;
@property (nonatomic, copy) NSMutableSet *movedObjectIDs;
@property (nonatomic, copy) NSString *destinationID;
@property (nonatomic, assign) BOOL isVerified;
@property (nonatomic, copy) NSString *actionStepMovedObjectID;
@property (nonatomic, copy) NSString *actionStepDestinationID;
@property (nonatomic, copy) NSString *sentenceText;

@end

@implementation UserAction

- (instancetype)initWithMovedObjectIDs:(NSMutableSet*)movedObjectIDs
                        destinationIDs:(NSString *)destinationID
                            isVerified:(BOOL)verified
               actionStepMovedObjectID:(NSString *)actionStepMovedObjectID
               actionStepDestinationID:(NSString *)actionStepDestinationID
                           forSentence:(NSString *)sentence {
    self = [super init];

    if (self) {
        _movedObjectIDs = [movedObjectIDs copy];
        _destinationID = [destinationID copy];

        _isVerified = verified;
        _sentenceText = [sentence copy];

        _actionStepMovedObjectID = [actionStepMovedObjectID copy];
        _actionStepDestinationID = [actionStepDestinationID copy];
    }
    
    return self;
}

@end
