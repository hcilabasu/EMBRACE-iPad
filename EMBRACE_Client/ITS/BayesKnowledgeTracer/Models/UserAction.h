//
//  UserAction.h
//  EMBRACE
//
//  Created by Jithin on 6/15/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ActionStep;

/**
 Class stores the single action performed by the user.
 It also has the actual actionstep that to be preformed.
 **/
@interface UserAction : NSObject


- (instancetype)initWithMovedObjectId:(NSString *)movedObjId
                        destinationId:(NSString *)destinationId
                           actionStep:(ActionStep *)actionStep
                           isVerified:(BOOL)isverified
                          forSentence:(NSString *)sentenceText;


@property (nonatomic, readonly) NSString *movedObjectId;

@property (nonatomic, readonly) NSString *destinationObjectId;

@property (nonatomic, readonly) BOOL isVerified;

@property (nonatomic, readonly) ActionStep *actionStep;

@property (nonatomic, readonly) NSString *sentenceText;


@end
