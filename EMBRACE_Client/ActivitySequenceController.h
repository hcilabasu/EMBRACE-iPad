//
//  ActivitySequenceController.h
//  EMBRACE
//
//  Created by aewong on 1/20/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ActivitySequence.h"
#import "GDataXMLNode.h"

@interface ActivitySequenceController : NSObject {
    NSMutableArray* sequences; //contains ActivitySequence objects for different books
}

@property (nonatomic, strong) NSMutableArray* sequences;

- (id) init;

- (BOOL) loadSequences;

- (ActivitySequence*) getSequenceForBook:(NSString*)title;

@end
