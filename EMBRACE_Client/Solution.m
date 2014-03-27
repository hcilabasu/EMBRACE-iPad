//
//  Solution.m
//  EMBRACE
//
//  Created by Andreea Danielescu on 11/20/13.
//  Copyright (c) 2013 Andreea Danielescu. All rights reserved.
//

#import "Solution.h"

@implementation Solution
@synthesize solutionsteps;

-(void) addSolutionsteps:(SolutionSteps*) solstep {
    [solutionsteps addObject:solstep];
}
@end
