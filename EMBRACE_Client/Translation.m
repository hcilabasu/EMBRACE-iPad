//
//  Translation.m
//  EMBRACE
//
//  Created by Jonatan Lemos Zuluaga (Student) on 5/13/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "Translation.h"

@implementation Translation

+(NSDictionary *) translationWords {
    static NSDictionary * inst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inst = @{
                 @"barn": @"establo",
                 @"bucket": @"cubeta",
                 @"cart": @"carreta",
                 @"combed": @"peinar",
                 @"contest": @"concurso",
                 @"corral": @"corral",
                 @"farm": @"granja",
                 @"farmer": @"granjero",
                 @"gate": @"puerta",
                 @"hay": @"paja",
                 @"hayloft": @"pajar",
                 @"healthy": @"saludable",
                 @"judge": @"juez",
                 @"jump": @"salto",
                 @"nest": @"nido",
                 @"owl": @"búho",
                 @"pen": @"cuarto",
                 @"prize": @"premio",
                 @"pumpkin": @"calabaza",
                 @"purr": @"ronronear",
                 @"shiny": @"brillante",
                 @"tractor": @"tractor",
                 @"trophy": @"trofeo",
                 @"weeds": @"maleza",
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
                 @"cilia": @"cilias",
                 @"dirt": @"mugre",
                 @"dust": @"polvo",
                 @"energy": @"energía",
                 @"heart": @"corazón",
                 @"lungs": @"pulmones",
                 @"molecules": @"moléculas",
                 @"muscles": @"músculos",
                 @"oxygen": @"oxígeno",
                 @"pumps": @"bombear",
                 @"rushes": @"fluye",
                 @"squeeze": @"apretar",
                 @"stiff": @"rígido",
                 @"toward": @"hacia",
                 @"trapped": @"atrapada",
                 @"tubes": @"tubos",
                 @"valve": @"válvula",
                 @"veins": @"venas",
                 @"ventricle": @"ventrículo"
        };
    });
    return inst;
}

+(NSDictionary *) translationImages {
    static NSDictionary * inst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inst = @{
                 @"barn": @"barn",
                 @"bucket": @"bucket",
                 @"cart": @"cart",
                 @"combed": @"combed",
                 @"contest": @"contest",
                 @"corral": @"corral",
                 @"farm": @"farm",
                 @"farmer": @"farmer",
                 @"gate": @"pen4",
                 @"hay": @"hay",
                 @"hayloft": @"hayloft",
                 @"healthy": @"healthy",
                 @"judge": @"judge",
                 @"jump": @"jump",
                 @"nest": @"chickenNest",
                 @"owl": @"owl",
                 @"pen": @"pen4",
                 @"prize": @"prize",
                 @"pumpkin": @"pumpkin",
                 @"purr": @"purr",
                 @"shiny": @"shiny",
                 @"tractor": @"tractor",
                 @"trophy": @"award",
                 @"weeds": @"weeds",
                 @"around": @"around",
                 @"arteries": @"arteries",
                 @"atoms": @"atoms",
                 @"atrium": @"atrium",
                 @"beat": @"beat",
                 @"blood": @"bloodcell_1",
                 @"breathe": @"breathe",
                 @"carbon dioxide": @"CO2_1",
                 @"chest": @"chest",
                 @"cigarette": @"cigarette",
                 @"cilia": @"cilia",
                 @"dirt": @"dirt_1",
                 @"dust": @"dust",
                 @"energy": @"energy",
                 @"heart": @"heart",
                 @"lungs": @"lungs",
                 @"molecules": @"molecules",
                 @"muscles": @"muscles",
                 @"oxygen": @"O2_1",
                 @"pumps": @"pumps",
                 @"rushes": @"rushes",
                 @"squeeze": @"squeeze",
                 @"stiff": @"stiff",
                 @"toward": @"toward",
                 @"trapped": @"trapped",
                 @"tubes": @"tubes",
                 @"valve": @"handle",
                 @"veins": @"veins",
                 @"ventricle": @"ventricle"
                 };
    });
    return inst;
}

@end
