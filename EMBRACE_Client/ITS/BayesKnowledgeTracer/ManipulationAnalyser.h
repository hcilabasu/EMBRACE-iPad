//
//  ManipulationAnalyser.h
//  EMBRACE
//
//  Created by Jithin on 6/15/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UserAction;
@class ManipulationContext;
@protocol ManipulationAnalyserProtocol;

@interface ManipulationAnalyser : NSObject

@property (nonatomic, weak) id <ManipulationAnalyserProtocol> delegate;

- (void)actionPerformed:(UserAction *)userAction
    manipulationContext:(ManipulationContext *)context;

- (void)userDidPlayWord:(NSString *)word;

- (void)pressedNextWithManipulationContext:(ManipulationContext *)context
                               forSentence:(NSString *)sentence
                                isVerified:(BOOL)verified;

@end


@protocol ManipulationAnalyserProtocol <NSObject>

- (CGPoint)locationOfObject:(NSString *)object analyzer:(ManipulationAnalyser *)analyzer;

- (void)analyzer:(ManipulationAnalyser *)analyzer showMessage:(NSString *)message;

@end