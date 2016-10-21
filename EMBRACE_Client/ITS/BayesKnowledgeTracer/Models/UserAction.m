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

@property (nonatomic, copy) NSString *movedObjectId;

@property (nonatomic, copy) NSString *destinationObjectId;

@property (nonatomic, assign) BOOL isVerified;

@property (nonatomic, copy) NSString *actionStepMovedObjectId;

@property (nonatomic, copy) NSString *actionStepDestinationObjectId;

@property (nonatomic, copy) NSString *sentenceText;

@end

@implementation UserAction

- (instancetype)initWithMovedObjectId:(NSString *)movedObjId
                        destinationId:(NSString *)destinationId
                           isVerified:(BOOL)isverified
              actionStepMovedObjectId:(NSString *)actionStepMovedObjectId
        actionStepDestinationObjectId:(NSString *)actionStepDestinationObjectId
                          forSentence:(NSString *)sentenceText {
    self = [super init];
    
    if (self) {
        _movedObjectId = [movedObjId copy];
        _destinationObjectId = [destinationId copy];

        _isVerified = isverified;
        _sentenceText = [sentenceText copy];
        
        _actionStepMovedObjectId = [actionStepMovedObjectId copy];
        _actionStepDestinationObjectId = [actionStepDestinationObjectId copy];
    }
    
    return self;
}

@end
