//
//  KnowledgeTracer.h
//  EMBRACE
//
//  Created by Jithin on 6/2/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UserAction;

@protocol KnowledgeTracerProtocol;

@interface KnowledgeTracer : NSObject

@property (nonatomic, weak) id <KnowledgeTracerProtocol> delegate;

- (void)updateSkillFor:(NSString *)action isVerified:(BOOL)isVerified;
- (void)updateSyntaxSkill:(BOOL)isVerified;
- (void)updatePronounSkill:(BOOL)isVerified;


@end


@protocol KnowledgeTracerProtocol <NSObject>


@end