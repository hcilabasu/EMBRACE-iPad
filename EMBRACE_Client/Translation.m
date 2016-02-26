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
                 @"barn": @"establo",
                 @"bucket": @"cubeta",
                 @"cart": @"carro",
                 @"combed": @"peinado",
                 @"contest": @"concurso",
                 @"corral": @"corral",
                 @"farm": @"granja",
                 @"gate": @"puerta",
                 @"hay": @"heno",
                 @"hayloft": @"pajar",
                 @"healthy": @"sano",
                 @"judge": @"juez",
                 @"jumped": @"saltó",
                 @"nest": @"nido",
                 @"owl": @"búho",
                 @"pen": @"cuarto",
                 @"prize": @"premio",
                 @"pumpkins": @"calabazas",
                 @"purr": @"ronronear",
                 @"shiny": @"brillante",
                 @"tractor": @"tractor",
                 @"trophy": @"trofeo",
                 @"weeds": @"mala hierba",
                 @"arteries": @"arterias",
                 @"atoms": @"átomos",
                 @"blood": @"sangre",
                 @"carbon dioxide": @"dióxido de carbono",
                 @"energy": @"energía",
                 @"lungs": @"pulmones",
                 @"molecule": @"molécula",
                 @"oxygen": @"oxígeno",
                 @"tubes": @"tubos"
        };
    });
    return inst;
}

@end
