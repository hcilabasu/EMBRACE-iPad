//
//  LogContext.h
//  EMBRACE
//
//  Created by aewong on 3/3/16.
//  Copyright © 2016 Andreea Danielescu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Context : NSObject

@property (nonatomic, assign) NSString *timestamp;

+ (NSString *)generateTimestamp;

@end
