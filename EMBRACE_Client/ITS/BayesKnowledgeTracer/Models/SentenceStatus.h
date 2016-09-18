//
//  StatementStatus.h
//  EMBRACE
//
//  Created by Jithin on 6/15/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserAction.h"

/**
 Model to keep the status of a sentence, which includes the UserAction performed
 until it is verified.
 **/
@interface SentenceStatus : NSObject

@property (nonatomic, copy) NSString *chapterTitle;

@property (nonatomic, assign) NSInteger sentenceNumber;

@property (nonatomic, assign) NSInteger ideaNumber;

@property (nonatomic, assign) BOOL isCompleted;

- (void)addUserAction:(UserAction *)action;

- (NSArray *)userActions;

- (BOOL)containsAction:(UserAction *)action;

@end
