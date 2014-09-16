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
                 @"farmer": @"granjero",
                 @"gate": @"puerta",
                 @"hay": @"heno",
                 @"hayloft": @"pajar",
                 @"healthy": @"sano",
                 @"judge": @"juez",
                 @"jump": @"salto",
                 @"jumped": @"salto",
                 @"nest": @"nido",
                 @"owl": @"búho",
                 @"pen": @"cuarto",
                 @"pen4": @"cuarto",
                 @"prize": @"premio",
                 @"pumpkin": @"calabaza",
                 @"purr": @"ronronear",
                 @"shiny": @"brillante",
                 @"tractor": @"tractor",
                 @"trophy": @"trofeo",
                 @"weeds": @"mala hierba",
                 @"around": @"alrededor",
                 @"arteries": @"arterias",
                 @"atoms": @"átomos",
                 @"atrium": @"atrio",
                 @"beat": @"latir",
                 @"blood": @"sangre",
                 @"breathe": @"respirar",
                 @"carbon dioxide": @"dióxido de carbono",
                 @"chest": @"pecho",
                 @"cigarette": @"cigarrillo",
                 @"cilia": @"cilia",
                 @"dirt": @"mugre",
                 @"dust": @"polvo",
                 @"energy": @"energía",
                 @"heart": @"corazón",
                 @"lungs": @"pulmones",
                 @"molecules": @"moléculas",
                 @"muscles": @"músculos",
                 @"oxygen": @"oxígeno",
                 @"pumps": @"bombea",
                 @"rushes": @"fluir",
                 @"squeeze": @"apretar",
                 @"stiff": @"rigidos",
                 @"toward": @"hacia",
                 @"trapped": @"atrapado",
                 @"tubes": @"tubos",
                 @"valve": @"válvula",
                 @"veins": @"venas",
                 @"ventricle": @"ventrículo"
        };
    });
    return inst;
}

@end
