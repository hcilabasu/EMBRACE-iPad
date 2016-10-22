//
//  UserAction.h
//  EMBRACE
//
//  Created by Jithin on 6/15/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ActionStep;

/*
 * Class stores the single action performed by the user.
 * It also has the actual actionstep that to be performed.
 */
@interface UserAction : NSObject

- (instancetype)initWithMovedObjectIDs:(NSMutableSet*)movedObjectIDs
                        destinationIDs:(NSString *)destinationID
                            isVerified:(BOOL)verified
               actionStepMovedObjectID:(NSString *)actionStepMovedObjectID
               actionStepDestinationID:(NSString *)actionStepDestinationID
                           forSentence:(NSString *)sentence;

@property (nonatomic, readonly) NSMutableSet *movedObjectIDs;
@property (nonatomic, readonly) NSString *destinationID;
@property (nonatomic, readonly) BOOL isVerified;
@property (nonatomic, readonly) NSString *actionStepMovedObjectID;
@property (nonatomic, readonly) NSString *actionStepDestinationID;
@property (nonatomic, readonly) NSString *sentenceText;
@property (nonatomic, assign) NSInteger sentenceNumber;
@property (nonatomic, assign) NSInteger ideaNumber;

@end
