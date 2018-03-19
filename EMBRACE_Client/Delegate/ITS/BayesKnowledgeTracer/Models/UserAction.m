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
@property (nonatomic, copy) NSMutableSet *destinationIDs;
@property (nonatomic, assign) BOOL isVerified;
@property (nonatomic, copy) NSString *correctMovedObjectID;
@property (nonatomic, copy) NSString *correctDestinationID;
@property (nonatomic, copy) NSString *sentenceText;

@end

@implementation UserAction

- (instancetype)initWithMovedObjectIDs:(NSMutableSet*)movedObjectIDs
                        destinationIDs:(NSMutableSet *)destinationIDs
                            isVerified:(BOOL)verified
               correctMovedObjectID:(NSString *)correctMovedObjectID
               correctDestinationID:(NSString *)correctDestinationID
                           forSentence:(NSString *)sentence {
    self = [super init];

    if (self) {
        _movedObjectIDs = [movedObjectIDs copy];
        _destinationIDs = [destinationIDs copy];

        _isVerified = verified;
        _sentenceText = [sentence copy];

        _correctMovedObjectID = [correctMovedObjectID copy];
        _correctDestinationID = [correctDestinationID copy];
    }
    
    return self;
}

@end
