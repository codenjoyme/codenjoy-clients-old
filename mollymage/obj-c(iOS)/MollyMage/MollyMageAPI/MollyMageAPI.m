//
//  HeroAPI.m
//  Bombermen
//
//  Created by Hell_Ghost on 11.09.13.
//
//

#import "HeroAPI.h"
static HeroAPI *heroAPI = nil;
@implementation HeroAPI
@synthesize boardSize;
@synthesize userName;
@synthesize delegate;
@synthesize hero;
@synthesize isDead;

#pragma mark - Init -
+ (HeroAPI*)sharedApi {
	if (!heroAPI) {
		heroAPI = [[HeroAPI alloc] init];
	}
	return heroAPI;
}

- (void)newGameWithUserName:(NSString*)name {
	if (name && [name length]) {
		[userName autorelease];
		userName = [name retain];
	}
	_webSocket.delegate = nil;
    [_webSocket close];
	NSString *server = [NSString stringWithFormat:@"ws://codenjoy.com:80/codenjoy-contest/ws?user=%@",userName];
	_webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:server]]];
	_webSocket.delegate = self;
	[_webSocket open];
}

#pragma mark - WebSocketDelegate -
- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
	ghosts = [[NSMutableArray alloc] init];
	destroyWalls = [[NSMutableArray alloc] init];
	allObjects = [[NSMutableArray alloc] init];
	allBarriers = [[NSMutableArray alloc] init];
	enemies = [[NSMutableArray alloc] init];
	potions = [[NSMutableArray alloc] init];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
	[[[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] autorelease] show];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
	[[[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Close with code %d",code] message:reason delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] autorelease] show];
}


- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
	[self clearValues];
	NSRange range = [message rangeOfString:@"board="];
	NSString *substring = [message substringFromIndex:NSMaxRange(range)];
	if (boardSize == 0) {
		boardSize = sqrt([substring length]);
	}
	BOOL wallNeedPost = NO;
	if (!walls) {
		wallNeedPost = YES;
		walls = [[NSMutableArray alloc] init];
	}
	substring = [substring stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	for (int i = 0; i<[substring length]; i++) {
		NSRange range = NSMakeRange(i, 1);
		NSString *symbol = [substring substringWithRange:range];
		int x = i%boardSize;
		int y = i/boardSize;
		GameObject *obj = [GameObject createWithSymbol:symbol];
		obj.x = x;
		obj.y = y;
		if (obj.type == NONE) {
			NSAssert(0, @"Object not created");
		} else
		if (obj.type == WALL && wallNeedPost) {
			[walls addObject:obj];
		} else
		if (DRAW_MODE && obj.type != WALL) {
			if (DRAW_MODE && [delegate respondsToSelector:@selector(redrawElemet:)]) {
				[delegate redrawElemet:obj];
			}
		}
		[self validateObject:obj];
	}
	
	if (wallNeedPost && [delegate respondsToSelector:@selector(wallDataReceived:)]) {
		[delegate wallDataReceived:walls];
	}
	
	if ([delegate respondsToSelector:@selector(stepIsOver)]) {
		[delegate stepIsOver];
	}
}

#pragma mark - PARSING -
- (void)validateObject:(GameObject*)obj {
	[allObjects addObject:obj];
	if (obj.isBarrier) {
		[allBarriers addObject:obj];
	}
	switch (obj.type) {
		case HERO:
			hero = [obj retain];
			isDead = NO;
			break;
		case DEAD_HERO:
			isDead = YES;
			[hero release];
			hero = nil;
			break;
		case GHOST:
			[ghosts addObject:obj];
			break;
		case TREASURE_BOX:
			[destroyWalls addObject:obj];
			break;
		case OTHER_HERO:
			[enemies addObject:obj];
			break;
		default:
			break;
	}
	if (obj.type == OTHER_POTION_HERO || obj.type == POTION_HERO ||
		obj.type == POTION_TIMER_1 || obj.type == POTION_TIMER_2 ||
		obj.type == POTION_TIMER_3 || obj.type == POTION_TIMER_4 || obj.type == POTION_TIMER_5) {
		[potions addObject:obj];
	}
}

- (void)clearValues {
	if (DRAW_MODE && [delegate respondsToSelector:@selector(clearField)]) {
		[delegate clearField];
	}
	if (hero) {
		[hero release];
		hero = nil;
	}
	isDead = YES;
	[ghosts removeAllObjects];
	[destroyWalls removeAllObjects];
	[allObjects removeAllObjects];
	[allBarriers removeAllObjects];
	[enemies removeAllObjects];
	[potions removeAllObjects];
}

#pragma mark - GETTERS -
- (NSArray*)getWalls {
	return walls;
}

- (NSArray*)getGhosts {
	return ghosts;
}

- (NSArray*)getTreasureBoxes {
	return destroyWalls;
}

- (NSArray*)getOtherBombers {
	return enemies;
}

- (NSArray*)getBombs {
	return potions;
}

- (NSArray*)getBarriers {
	return allBarriers;
}

- (BOOL)isBarrierAtPointX:(int)x y:(int)y {
	return (BOOL)[self objectInCoordinates:x y:y fromArray:allBarriers];
}

- (BOOL)isElementsInPositionX:(int)x y:(int)y ofElementsType:(NSArray*)elements {
	GameObject *obj = [self objectInCoordinates:x y:y fromArray:allObjects];
	for (NSNumber *num in elements) {
		if (obj.type == [num intValue]) {
			return YES;
		}
	}
	return NO;
}

- (GameObject*)objectInCoordinates:(int)x y:(int)y {
	return [self objectInCoordinates:x y:y fromArray:allObjects];
}

- (GameObject*)objectInCoordinates:(int)x y:(int)y fromArray:(NSArray*)inputArray {
	if (x>=boardSize || y>=boardSize) {
		NSAssert(0, @"y or x more board size");
	}
	for (GameObject *obj in inputArray) {
		if (x == obj.x && y == obj.y) {
			return obj;
		}
	}
	return nil;
}

- (BOOL)isElementNear:(GameObjectType)element atX:(int)x y:(int)y {
	return [self nearCountOfElementType:element atX:x y:y];
}

- (NSArray*)nearElementsAtX:(int)x y:(int)y {
	NSMutableArray * objArray = [NSMutableArray array];
	[objArray addObject:[self objectInCoordinates:x+1 y:y]];
	[objArray addObject:[self objectInCoordinates:x-1 y:y]];
	[objArray addObject:[self objectInCoordinates:x y:y+1]];
	[objArray addObject:[self objectInCoordinates:x y:y-1]];
	return objArray;
}

- (int)nearCountOfElementType:(GameObjectType)element atX:(int)x y:(int)y {
	NSArray * nearArray = [self nearElementsAtX:x y:y];
	int counter = 0;
	for (GameObject *obj in nearArray) {
		if (obj.type == element) {
			counter++;
		}
	}
	return counter;
}

- (int)nearCountAtX:(int)x y:(int)y ofElementsType:(NSArray*)elements {
	int counter = 0;
	for (NSNumber *num in elements) {
		counter += [self nearCountOfElementType:[num intValue] atX:x y:y];
	}
	return counter;
}

- (NSArray*)getFutureBlasts {
	NSMutableArray * array = [NSMutableArray array];
	for (GameObject *obj in potions) {
		NSArray * near = [self nearElementsAtX:obj.x y:obj.y];
		for (GameObject * nearObj in near) {
			if (nearObj.type != WALL) {
				[array addObject:nearObj];
			}
		}
	}
	return array;
}

- (BOOL)isElement:(GameObjectType)type atX:(int)x y:(int)y {
	GameObject *obj = [self objectInCoordinates:x y:y];
	return obj.type == type;
}

#pragma mark - SETTER -
- (void)setDirection:(Direction)dir withAction:(BOOL)act {
	if (!_webSocket) {
		return;
	}
	if (act) {
		[_webSocket send:@"act"];
	}
	switch (dir) {
		case Down:
			[_webSocket send:@"down"];
			break;
		case Up:
			[_webSocket send:@"up"];
			break;
		case Left:
			[_webSocket send:@"left"];
			break;
		case Right:
			[_webSocket send:@"right"];
			break;
		case Idle:
			[_webSocket send:@"stop"];
			break;
	}
}
@end
