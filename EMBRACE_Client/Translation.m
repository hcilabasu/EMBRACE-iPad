//
//  Translation.m
//  EMBRACE
//
//  Created by Jonatan Lemos Zuluaga (Student) on 5/13/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "Translation.h"

@implementation Translation

+(NSDictionary *) translations {

    static NSDictionary * inst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inst = @{
                                       @"hay": @"paja",
                                       @"cart": @"carro",
                                       @"barn": @"establo",
                                       @"hayloft": @"pajar"
        };
    });
    return inst;
}

@end