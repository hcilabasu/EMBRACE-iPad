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

@end

@implementation UserAction

- (instancetype)initWithMovedObjectId:(NSString *)movedObjId
                        destinationId:(NSString *)destinationId
                           actionStep:(ActionStep *)actionStep
                           isVerified:(BOOL)isverified
                          forSentence:(NSString *)sentenceText {
    self = [super init];
    if (self) {
        
        _movedObjectId = [movedObjId copy];
        _destinationObjectId = [destinationId copy];
        _actionStep = actionStep;
        _isVerified = isverified;
        _sentenceText = [sentenceText copy];
        
    }
    return self;
}

@end
