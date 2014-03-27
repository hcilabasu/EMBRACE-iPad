//
//  SolutionSteps.h
//  EMBRACE
//
//  Created by Rishabh Chaudhry on 2/24/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

/*typedef enum InteractionType {
    GROUP,
    UNGROUP,
    DISAPPEAR,
    TRANSFERANDGROUP,
    TRANSFERANDDISAPPEAR,
    NONE
} InteractionType;
*/
@interface SolutionSteps : NSObject {
NSString* interactionType;
NSNumber* stepNum ;
NSString* obj1Id ;
NSString* action ;
NSString* obj2Id ;
}

@property (nonatomic, strong) NSString* interactionType;
@property (nonatomic, strong) NSNumber* stepNum;
@property (nonatomic, strong) NSString* obj1Id;
@property (nonatomic, strong) NSString* action;
@property (nonatomic, strong) NSString* obj2Id;


- (id) initWithValues:(NSString*)type :(NSString*) obj1 :(NSString*) obj2 :(NSString*) act :(NSNumber*)num;
@end
