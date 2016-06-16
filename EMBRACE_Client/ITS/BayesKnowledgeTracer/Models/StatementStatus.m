//
//  StatementStatus.m
//  EMBRACE
//
//  Created by Jithin on 6/15/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import "StatementStatus.h"

@interface StatementStatus ()

@property (nonatomic, strong) NSMutableArray *userActionSteps;

@end

@implementation StatementStatus

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _userActionSteps = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addUserAction:(UserAction *)action {
    [self.userActionSteps addObject:action];
}

- (NSArray *)userActions {
    return [NSArray arrayWithArray:self.userActionSteps];
}


@end
