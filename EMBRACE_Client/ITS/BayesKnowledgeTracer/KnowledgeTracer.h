//
//  KnowledgeTracer.h
//  EMBRACE
//
//  Created by Jithin on 6/2/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KnowledgeTracerProtocol;

@interface KnowledgeTracer : NSObject

@property (nonatomic, weak) id <KnowledgeTracerProtocol> delegate;

@end


@protocol KnowledgeTracerProtocol <NSObject>


@end