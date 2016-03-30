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
                 @"jumped": @"saltó",
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
                 @"ventricle": @"ventrículo",
                 
                 @"hook": @"gancho",
                 @"lawyer": @"abogado",
                 @"pets": @"mascotas",
                 @"mystery": @"misterio",
                 @"solve": @"resolver",
                 @"highchair": @"silla alta",
                 @"sniffed": @"olfatear",
                 @"thief": @"ladron",
                 @"stealing": @"robar",
                 @"rattle": @"sonaja",
                 @"silver": @"plateado",
                 @"comfort": @"calmar",
                 @"rattled": @"angustiado",
                 @"shiny": @"brillante",
                 @"breakfast": @"desayuno",
                 @"comfort": @"calmar",
                 @"drove": @"manejar",
                 @"hero": @"héroe",
                 @"kitchen": @"cocina",
                 @"pancakes": @"panqueques",
                 @"policeman": @"policía",
                 @"suddenly": @"de repente",
                 @"toward": @"hacia",
                 
                 @"spin": @"gire",
                 
                 @"banana": @"plátano",
                 @"coco": @"coco",
                 @"empty": @"vacío",
                 @"handle": @"manija",
                 @"jumps": @"salto",
                 @"lifts": @"levanta",
                 @"lisa": @"lisa",
                 @"monkey": @"chango",
                 @"naughty": @"travieso",
                 @"throws": @"lanza",
                 @"trough": @"bebedero",
                 @"zebra's": @"cebra",
                 
                 @"algonquian" : @"algonquian",
                 @"algonquians" : @"algonquians",
                 @"arrow" : @"flecha",
                 @"arrows" : @"flechas",
                 @"bark" : @"corteza",
                 @"bows" : @"arcos",
                 @"branches" : @"ramas",
                 @"buffalo" : @"búfalo",
                 @"canoes" : @"canoas",
                 @"carving" : @"tallar",
                 @"cedar" : @"cedro",
                 @"ceremonies" : @"ceremonias",
                 @"chickee" : @"chickee",
                 @"chickees" : @"chickees",
                 @"comfortable" : @"cómodos",
                 @"community" : @"comunidad",
                 @"entryway" : @"entrada",
                 @"everglades" : @"marismas",
                 @"flexible" : @"flexible",
                 @"frame" : @"estructura",
                 @"haida" : @"haida",
                 @"haidas" : @"haidas",
                 @"hogan" : @"hogan",
                 @"hunted" : @"cazar",
                 @"igloo" : @"iglú",
                 @"igloos" : @"iglús",
                 @"inuit" : @"inuit",
                 
                 @"modern" : @[@"modernas", @"moderno"],
                 
                 @"mosquitos" : @"mosquitos",
                 @"narrow" : @"angosto",
                 @"navajo" : @"navajo",
                 @"navajos" : @"navajos",
                 @"octagon" : @"octágono",
                 @"opposite" : @"opuesto",
                 @"pacific" : @"pacífico",
                 @"plagued" : @"plagados",
                 @"plank" : @"tablón",
                 @"planks" : @"tablónes",
                 
                 @"protect" : @[@"proteger", @"protegen"],
                 
                 @"protected" : @"protegía",
                 @"seminole" : @"seminole",
                 @"seminoles" : @"seminoles",
                 @"sioux" : @"sioux",
                 @"slanted" : @"inclinado",
                 @"sled" : @"trineo",
                 @"sophisticated" : @"sofisticado",
                 @"stilts" : @"estacas",
                 @"swamps" : @"ciénagas",
                 @"teepee" : @"tipi",
                 @"teepees" : @"tipis",
                 @"totem poles" : @"tótem",
                 @"upright" : @"verticales",
                 @"wigwam" : @"wigwam",
                 @"wigwams" : @"wigwams"
                 
        };
    });
    return inst;
}

+(NSDictionary *) translationWordsSpanish {
    static NSDictionary * inst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inst = @{
                 @"establo": @"barn",
                 @"cubeta": @"bucket",
                 @"carreta": @"cart",
                 @"peinar": @"combed",
                 @"concurso": @"contest",
                 @"corral": @"corral",
                 @"granja": @"farm",
                 @"granjero": @"farmer",
                 @"puerta": @"gate",
                 @"paja": @"hay",
                 @"pajar": @"hayloft",
                 @"saludable": @"healthy",
                 @"juez": @"judge",
                 @"salto": @"jump",
                 @"saltó": @"jumped",
                 @"nido": @"nest",
                 @"búho": @"owl",
                 @"cuarto": @"pen",
                 @"premio": @"prize",
                 @"calabaza": @"pumpkin",
                 @"ronronear": @"purr",
                 @"brillante": @"shiny",
                 @"tractor": @"tractor",
                 @"trofeo": @"trophy",
                 @"maleza": @"weeds",
                 
                 @"alrededor": @"around",
                 @"arterias": @"arteries",
                 @"átomos": @"atoms",
                 @"atrio": @"atrium",
                 @"latir": @"beat",
                 @"sangre": @"blood",
                 @"respirar": @"breathe",
                 @"dióxido de carbono": @"carbon dioxide",
                 @"pecho": @"chest",
                 @"cigarrillo": @"cigarette",
                 @"cilias": @"cilia",
                 @"mugre": @"dirt",
                 @"polvo": @"dust",
                 @"energía": @"energy",
                 @"corazón": @"heart",
                 @"pulmones": @"lungs",
                 @"moléculas": @"molecules",
                 @"músculos": @"muscles",
                 @"oxígeno": @"oxygen",
                 @"bombear": @"pumps",
                 @"fluye": @"rushes",
                 @"apretar": @"squeeze",
                 @"rígido": @"stiff",
                 @"hacia": @"toward",
                 @"atrapada": @"trapped",
                 @"tubos": @"tubes",
                 @"válvula": @"valve",
                 @"venas": @"veins",
                 @"ventrículo": @"ventricle",
                 
                 @"gancho": @"hook",
                 @"abogado": @"lawyer",
                 @"mascotas": @"pets",
                 @"misterio": @"mystery",
                 @"resolver": @"solve",
                 @"silla alta": @"highchair",
                 @"olfatear": @"sniffed",
                 @"ladron": @"thief",
                 @"robar": @"stealing",
                 @"sonaja": @"rattle",
                 @"plateado": @"silver",
                 @"calmar": @"comfort",
                 @"angustiado": @"rattled",
                 @"brillante": @"shiny",
                 @"desayuno": @"breakfast",
                 @"calmar": @"comfort",
                 @"manejar": @"drove",
                 @"héroe": @"hero",
                 @"cocina": @"kitchen",
                 @"panqueques": @"pancakes",
                 @"policía": @"policeman",
                 @"de repente": @"suddenly",
                 @"hacia": @"toward",
                 
                 @"gire": @"spin",
                 
                 @"plátano": @"banana",
                 @"coco": @"coco",
                 @"vacío": @"empty",
                 @"manija": @"handle",
                 @"salto": @"jumps",
                 @"levanta": @"lifts",
                 @"lisa": @"lisa",
                 @"chango": @"monkey",
                 @"travieso": @"naughty",
                 @"lanza": @"throws",
                 @"bebedero": @"trough",
                 @"cebra": @"zebra's",
                 
                 @"algonquian" : @"algonquian",
                 @"algonquians" : @"algonquians",
                 @"flecha": @"arrow" ,
                 @"flechas": @"arrows",
                 @"corteza": @"bark",
                 @"arcos": @"bows",
                 @"ramas": @"branches",
                 @"búfalo": @"buffalo",
                 @"canoas": @"canoes",
                 @"tallar": @"carving" ,
                 @"cedro": @"cedar" ,
                 @"ceremonias": @"ceremonies",
                 @"chickee": @"chickee" ,
                 @"chickees" : @"chickees",
                 @"cómodos":  @"comfortable",
                 @"comunidad": @"community" ,
                 @"entrada": @"entryway" ,
                 @"marismas": @"everglades",
                 @"flexible" : @"flexible",
                 @"estructura": @"frame" ,
                 @"haida" : @"haida",
                 @"haidas" : @"haidas",
                 @"hogan" : @"hogan",
                 @"cazar": @"hunted" ,
                 @"iglú": @"igloo" ,
                 @"iglús": @"igloos" ,
                 @"inuit" : @"inuit",
                 @"modernas": @"modern",
                 @"moderno": @"modern",
                 @"mosquitos" : @"mosquitos",
                 @"angosto": @"narrow" ,
                 @"navajo" : @"navajo",
                 @"navajos" : @"navajos",
                 @"octágono": @"octagon" ,
                 @"opuesto": @"opposite" ,
                 @"pacífico": @"pacific" ,
                 @"plagados": @"plagued" ,
                 @"tablón": @"plank" ,
                 @"tablónes": @"planks" ,
                 @"proteger": @"protect",
                 @"protegen": @"protect" ,
                 @"protegía": @"protected" ,
                 @"seminole" : @"seminole",
                 @"seminoles" : @"seminoles",
                 @"sioux" : @"sioux",
                 @"inclinado": @"slanted" ,
                 @"trineo": @"sled" ,
                 @"sofisticado": @"sophisticated" ,
                 @"estacas": @"stilts" ,
                 @"ciénagas": @"swamps" ,
                 @"tipi": @"teepee" ,
                 @"tipis": @"teepees",
                 @"tótem": @"totem poles",
                 @"verticales": @"upright",
                 @"wigwam" : @"wigwam",
                 @"wigwams" : @"wigwams"
                 
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
                 @"gate": @"pen2",
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
                 @"atrium": @[@"atrium_1",@"atrium_2"],
                 @"beat": @"beat",
                 @"blood": @"bloodcell_1",
                 @"breathe": @"breathe",
                 @"carbon dioxide": @[@"CO2_1",@"CO2_2",@"CO2_3"],
                 @"chest": @"chest",
                 @"cigarette": @"cigarette",
                 @"cilia": @[@"cilia1",@"cilia2"],
                 @"dirt": @[@"dirt_1",@"dirt_3",@"dirt_4",@"dirt_5",@"dirt_6",@"dirt_7"],
                 @"dust": @"dust",
                 @"energy": @"energy",
                 @"heart": @"heart",
                 @"lungs": @"lungs",
                 @"molecules": @[@"CO2_1",@"CO2_2",@"CO2_3",@"O2_1"],
                 @"muscles": @"muscles",
                 @"oxygen": @"O2_1",
                 @"pumps": @"pumps",
                 @"rushes": @"rushes",
                 @"squeeze": @"squeeze",
                 @"stiff": @"stiff",
                 @"toward": @"toward",
                 @"trapped": @"trapped",
                 @"tubes": @"tubes",
                 @"valve": @[@"handle",@"handle_close",@"handle_1",@"gray_handle"],
                 @"veins": @"veins",
                 @"ventricle": @[@"ventricle_1", @"ventricle_2"],
                 
                 @"baby": @"baby",
                 @"car": @"car",
                 @"highchair": @"highchairb",
                 @"hook": @"hook",
                 @"keys": @"keys2",
                 @"lola": @"rabbit",
                 @"martin": @"man",
                 @"paco": @"dog",
                 @"pets": @[@"dog", @"rabbit"],
                 @"rattle": @"rattle",
                 @"rosa": @"woman",
                 
                 @"banana": @"banana",
                 @"coco": @"monkey",
                 @"empty": @"empty",
                 @"handle": @"handle",
                 @"jumps": @"jumps",
                 @"lifts": @"lifts",
                 @"lisa": @"lisa",
                 @"monkey": @"monkey",
                 @"naughty": @"naughty",
                 @"throws": @"throws",
                 @"trough": @"trough",
                 @"zebra's": @"zebra",
                 
                 @"algonquian" : @"algonquian",
                 @"algonquians" : @"algonquians",
                 @"arrow" : @"arrow",
                 @"arrows" : @"arrows",
                 @"bark" : @"bark",
                 @"bows" : @"bows",
                 @"branches" : @"branches",
                 @"buffalo" : @"buffalo",
                 @"canoes" : @"canoes",
                 @"carving" : @"carving",
                 @"cedar" : @"cedar",
                 @"ceremonies" : @"ceremonies",
                 @"chickee" : @"chickee",
                 @"chickees" : @"chickees",
                 @"comfortable" : @"comfortable",
                 @"community" : @"community",
                 @"entryway" : @"entryway",
                 @"everglades" : @"everglades",
                 @"flexible" : @"flexible",
                 @"frame" : @"frame",
                 @"haida" : @"haida",
                 @"haidas" : @"haidas",
                 @"hogan" : @"hogan",
                 @"hunted" : @"hunted",
                 @"igloo" : @"igloo",
                 @"igloos" : @"igloos",
                 @"inuit" : @"inuit",
                 @"modern" : @"modern",
                 @"mosquitos" : @"mosquitos",
                 @"narrow" : @"narrow",
                 @"navajo" : @"navajo",
                 @"navajo" : @"navajos",
                 @"octagon" : @"octagon",
                 @"opposite" : @"opposite",
                 @"pacific" : @"pacific",
                 @"plagued" : @"plagued",
                 @"plank" : @"plank",
                 @"planks" : @"planks",
                 @"protect" : @"protect",
                 @"protected" : @"protected",
                 @"seminole" : @"seminole",
                 @"seminoles" : @"seminoles",
                 @"sioux" : @"sioux",
                 @"slanted" : @"slanted",
                 @"sled" : @"sled",
                 @"sophisticated" : @"sophisticated",
                 @"stilts" : @"stilts",
                 @"swamps" : @"swamps",
                 @"teepee" : @"teepee",
                 @"teepees" : @"teepees",
                 @"totem poles" : @"totem poles",
                 @"upright" : @"upright",
                 @"wigwam" : @"wigwam",
                 @"wigwams" : @"wigwams"
                 
                 
                 };
    });
    return inst;
}

@end
