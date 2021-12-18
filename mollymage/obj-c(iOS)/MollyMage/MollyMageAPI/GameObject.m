//
//  GameObject.m
//  Bombermen
//
//  Created by Hell_Ghost on 11.09.13.
//
//

#import "GameObject.h"

@implementation GameObject
@synthesize x;
@synthesize y;
@synthesize type;
@synthesize isBarrier;

+ (GameObject*)createWithSymbol:(NSString*)symbol {
		return [[[GameObject alloc] initWithSymbol:symbol] autorelease];
}

- (GameObject*)initWithSymbol:(NSString*)symbol {
	self = [super init];
	if (self) {
		type = NONE;
		isBarrier = NO;
		if ([symbol isEqualToString:@" "]) {
			type = NONE;
		} else
			if ([symbol isEqualToString:@"☼"]) {
				type = WALL;
				isBarrier = YES;
			} else
				if ([symbol isEqualToString:@"#"]) {
					type = TREASURE_BOX;
					isBarrier = YES;
				} else
					if ([symbol isEqualToString:@"H"]) {
						type = OPENING_TREASURE_BOX;
						isBarrier = YES;
					} else
						if ([symbol isEqualToString:@"&"]) {
							type = GHOST;
							isBarrier = YES;
						} else
							if ([symbol isEqualToString:@"x"]) {
								type = DEAD_GHOST;
							} else
								if ([symbol isEqualToString:@"☻"]) {
									type = POTION_HERO;
									isBarrier = YES;
								} else
									if ([symbol isEqualToString:@"☺"]) {
										type = HERO;
										//isBarier = YES;
									} else
										if ([symbol isEqualToString:@"Ѡ"]) {
											type = DEAD_HERO;
										} else
											if ([symbol isEqualToString:@"♥"]) {
												type = OTHER_HERO;
												isBarrier = YES;
											} else
												if ([symbol isEqualToString:@"♠"]) {
													type = OTHER_POTION_HERO;
													isBarrier = YES;
												} else
													if ([symbol isEqualToString:@"♣"]) {
														type = OTHER_DEAD_HERO;
													} else
														if ([symbol isEqualToString:@"҉"]) {
															type = BLAST;
														} else
															if ([symbol isEqualToString:@"1"]) {
																type = POTION_TIMER_1;
																isBarrier = YES;
															} else
																if ([symbol isEqualToString:@"2"]) {
																	type = POTION_TIMER_2;
																	isBarrier = YES;
																} else
																	if ([symbol isEqualToString:@"3"]) {
																		type = POTION_TIMER_3;
																		isBarrier = YES;
																	} else
																		if ([symbol isEqualToString:@"4"]) {
																			type = POTION_TIMER_4;
																			isBarrier = YES;
																		} else
																			if ([symbol isEqualToString:@"5"]) {
																				type = POTION_TIMER_5;
																				isBarrier = YES;
																			} else
                                                                                if ([symbol isEqualToString:@"+"]) {
                                                                                    type = POTION_BLAST_RADIUS_INCREASE;
                                                                                    isBarrier = NO;
                                                                                } else
                                                                                    if ([symbol isEqualToString:@"c"]) {
                                                                                        type = POTION_COUNT_INCREASE;
                                                                                        isBarrier = NO;
                                                                                    } else
                                                                                        if ([symbol isEqualToString:@"r"]) {
                                                                                            type = POTION_REMOTE_CONTROL;
                                                                                            isBarrier = NO;
                                                                                        } else
                                                                                            if ([symbol isEqualToString:@"i"]) {
                                                                                                type = POTION_IMMUNE;
                                                                                                isBarrier = NO;
                                                                                            } else
                                                                                                if ([symbol isEqualToString:@"T"]) {
                                                                                                    type = POISON_THROWER;
                                                                                                    isBarrier = NO;
                                                                                            } else
                                                                                                if ([symbol isEqualToString:@"A"]) {
                                                                                                    type = POTION_EXPLODER;
                                                                                                    isBarrier = NO;
                                                                                            }

	}
	return self;
}
@end
