//
//  MainMenu.m
//  Bombermen
//
//  Created by Hell_Ghost on 10.09.13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "Drawer.h"
#define ALERT_NAME 100
#define X_OFFSET 215
#define Y_OFFSET (768-87)
#define TILE_SILE 18


@implementation Drawer
+ (CCScene*)scene {
	CCScene * scene = [CCScene node];
	[scene addChild:[Drawer node]];
	return scene;
}

- (id)init
{
    self = [super init];
    if (self) {
		CGSize size = [[CCDirector sharedDirector] winSize];
		CCSprite *background;
		background = [CCSprite spriteWithFile:@"NONE.png"];
		background.position = ccp(size.width/2, size.height/2);
		background.scaleX = size.width/background.contentSize.width;
		background.scaleY = size.height/background.contentSize.height;
		// add the label as a child to this Layer
		[self addChild: background];

		redrawingObject = [[NSMutableArray alloc] init];
		pathArray = [[NSMutableArray alloc] init];
		[HeroAPI sharedApi].delegate = self;
		//[AIAnalyzer sharedAnalizer].delegate = self;
        UIAlertView *nameAlert = [[[UIAlertView alloc] initWithTitle:@"Enter your name" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil] autorelease];
		nameAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
		nameAlert.tag = ALERT_NAME;
		[nameAlert show];
		
    }
    return self;
}

#pragma mark - UIAlertViewDelegate -
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (alertView.tag) {
		case ALERT_NAME:
			if (buttonIndex) {
				NSString *userName = [alertView textFieldAtIndex:0].text;
				[[HeroAPI sharedApi] newGameWithUserName:userName];
			}
			break;
			
		default:
			break;
	}
}

#pragma mark - HeroAPIDelegate -
- (void)stepIsOver {
	//[[AIAnalyzer sharedAnalizer] analyze];
}

#if DRAW_MODE
- (void)wallDataReceived:(NSArray*)wallData {
	for (GameObject * obj in wallData) {
		CCSprite * wall = [CCSprite spriteWithFile:@"WALL.png"];
		[self addChild:wall];
		wall.position = CGPointMake(X_OFFSET + obj.x*wall.boundingBox.size.width, Y_OFFSET - obj.y*wall.boundingBox.size.height);
	}
}

- (void)clearField {
	for (CCSprite * old in redrawingObject) {
		[old removeFromParentAndCleanup:YES];
	}
	[redrawingObject removeAllObjects];
	
	for (CCSprite *old in pathArray) {
		[old removeFromParentAndCleanup:YES];
	}
	[pathArray removeAllObjects];
}

- (void)redrawElemet:(GameObject*)element {
		NSString *fileName;
		CCSprite *sprite;
		int zOrd = 1;
		switch (element.type) {
			case TREASURE_BOX:
				sprite = [CCSprite spriteWithFile:@"TREASURE_BOX.png"];
				break;
			case HERO:
				sprite = [CCSprite spriteWithFile:@"HERO.png"];
				zOrd = 2;
				break;
			case POTION_HERO: {
				sprite = [CCSprite spriteWithFile:fileName = @"POTION_TIMER.png"];
				CCSprite *men = [CCSprite spriteWithFile:@"HERO.png"];
				[sprite addChild:men];
				men.position = ccp(sprite.contentSize.width/2,sprite.contentSize.height/2);
				} break;
			case OTHER_POTION_HERO: {
				sprite = [CCSprite spriteWithFile:@"POTION_TIMER.png"];
				CCSprite *men = [CCSprite spriteWithFile:@"HERO.png"];
				[sprite addChild:men];
				men.position = ccp(sprite.contentSize.width/2,sprite.contentSize.height/2);
				men.color = ccc3(255, 0, 0);
			}
				break;
			case POTION_TIMER_1: {
				sprite = [CCSprite spriteWithFile:@"POTION_TIMER.png"];
				CCLabelTTF *label = [CCLabelTTF labelWithString:@"1" fontName:@"Arial-BoldMT" fontSize:12];
				[sprite addChild:label];
				label.position = ccp(sprite.contentSize.width/2,sprite.contentSize.height/2);
			}
				break;
			case POTION_TIMER_2: {
				sprite = [CCSprite spriteWithFile:@"POTION_TIMER.png"];
				CCLabelTTF *label = [CCLabelTTF labelWithString:@"2" fontName:@"Arial-BoldMT" fontSize:12];
				[sprite addChild:label];
				label.position = ccp(sprite.contentSize.width/2,sprite.contentSize.height/2);
			}
				break;
			case POTION_TIMER_3: {
				sprite = [CCSprite spriteWithFile:@"POTION_TIMER.png"];
				CCLabelTTF *label = [CCLabelTTF labelWithString:@"3" fontName:@"Arial-BoldMT" fontSize:12];
				[sprite addChild:label];
				label.position = ccp(sprite.contentSize.width/2,sprite.contentSize.height/2);
			}
				break;
			case POTION_TIMER_4: {
				sprite = [CCSprite spriteWithFile:@"POTION_TIMER.png"];
				CCLabelTTF *label = [CCLabelTTF labelWithString:@"4" fontName:@"Arial-BoldMT" fontSize:12];
				[sprite addChild:label];
				label.position = ccp(sprite.contentSize.width/2,sprite.contentSize.height/2);
			}
				break;
			case POTION_TIMER_5: {
				sprite = [CCSprite spriteWithFile:@"POTION_TIMER.png"];
				CCLabelTTF *label = [CCLabelTTF labelWithString:@"5" fontName:@"Arial-BoldMT" fontSize:12];
				[sprite addChild:label];
				label.position = ccp(sprite.contentSize.width/2,sprite.contentSize.height/2);
			}
				break;
			case GHOST:
				sprite = [CCSprite spriteWithFile:@"GHOST.png"];
				break;
			case NONE:
				return;
			case BLAST:
				sprite = [CCSprite spriteWithFile:@"BLAST.png"];
				break;
			case OPENING_TREASURE_BOX:
				sprite = [CCSprite spriteWithFile:@"OPENING_TREASURE_BOX.png"];
				break;
			case DEAD_HERO:
				sprite = [CCSprite spriteWithFile:@"DEAD_HERO.png"];
				break;
			case DEAD_GHOST:
				sprite = [CCSprite spriteWithFile:@"DEAD_GHOST.png"];
				break;
			case OTHER_HERO:
				sprite = [CCSprite spriteWithFile:@"HERO.png"];
				zOrd = 2;
				sprite.color = ccc3(255, 0, 0);
				break;
			case WALL:
				return;
			case OTHER_DEAD_HERO:
				sprite = [CCSprite spriteWithFile:@"DEAD_HERO.png"];
				zOrd = 2;
				sprite.color = ccc3(255, 0, 0);
				break;
			case NONE:
				NSAssert(0, @"Unknow error");
				break;
			
		}
		[self addChild:sprite z:zOrd];
		[redrawingObject addObject:sprite];
		sprite.position = CGPointMake(X_OFFSET + element.x*TILE_SILE, Y_OFFSET - element.y*TILE_SILE);
	
}
#endif

//#pragma mark - AIAnalyzerDelegate -
//
//- (void)drawPathPoint:(NSArray *)pathPoint {
//	
//	PathObject* po = [pathPoint objectAtIndex:0];
//	CCSprite * sprite = [CCSprite spriteWithFile:@"circle.png"];
//	[self addChild:sprite z:5];
//	sprite.position = CGPointMake(X_OFFSET + po.node.x*TILE_SILE, Y_OFFSET - po.node.y*TILE_SILE);
//	CCLabelTTF *label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d",po.f] fontName:@"Arial-BoldMT" fontSize:12];
//	[sprite addChild:label];
//	label.position = ccp(sprite.contentSize.width/2,sprite.contentSize.height/2);
//	
//	[pathArray addObject:sprite];
//	
//}

@end
