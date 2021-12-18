/*-
 * #%L
 * Codenjoy - it's a dojo-like platform from developers to developers.
 * %%
 * Copyright (C) 2018 Codenjoy
 * %%
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public
 * License along with this program.  If not, see
 * <http://www.gnu.org/licenses/gpl-3.0.html>.
 * #L%
 */

//  Created by Hell_Ghost on 10.09.13.

#import <Foundation/Foundation.h>

typedef enum{

/// your Molly

    // This is what she usually looks like.
    HERO = 0,

    // This is if she is sitting on own potion.
    POTION_HERO,

    // Oops, your Molly is dead (don't worry,
    // she will appear somewhere in next move).
    // You're getting penalty points for each death.
    DEAD_HERO,

/// other players heroes

    // This is what other heroes looks like.
    OTHER_HERO,

    // This is if player is sitting on own potion.
    OTHER_POTION_HERO,

    // Enemy corpse (it will disappear shortly,
    // right on the next move).
    // If you've done it you'll get score points.
    OTHER_DEAD_HERO,

/// the potions
    // After Molly set the potion, the timer starts (5 ticks).
    POTION_TIMER_5,

    // This will blow up after 4 ticks.
    POTION_TIMER_4,

    // This after 3...
    POTION_TIMER_3,

    // Two..
    POTION_TIMER_2,

    // One.
    POTION_TIMER_1,

    // Boom! this is what is potion does,
    // everything that is destroyable got destroyed.
    BLAST,

/// walls

    // Indestructible wall - it will not fall from potion.
    WALL,

    // this is a treasure box, it opens with an explosion.
    TREASURE_BOX,

    // this is like a treasure box opens looks
    // like, it will disappear on next move.
    // if it's you did it - you'll get score
    // points. Perhaps a prize will appear.
    OPENING_TREASURE_BOX,

/// soulless creatures

    // This guys runs over the board randomly
    // and gets in the way all the time.
    // If it will touch Molly - she will die.
    // You'd better kill this piece of ... soul,
    // you'll get score points for it.
    GHOST,

    // This is ghost corpse.
    DEAD_GHOST,

/// perks

    // Potion blast radius increase.
    // Applicable only to new potions.
    // The perk is temporary.
    POTION_BLAST_RADIUS_INCREASE,

    // Increase available potions count.
    // Number of extra potions can be set
    // in settings. Temporary.
    POTION_COUNT_INCREASE,

    // Potion blast not by timer but by second act.
    // Number of RC triggers is limited and c
    // an be set in settings.
    POTION_REMOTE_CONTROL,

    // Do not die after potion blast
    // (own potion and others as well). Temporary.
    POTION_IMMUNE,

    // Hero can shoot by poison cloud
    // Using Act(1) + Direction
    // Temporary.
    POISON_THROWER,

    // Hero can explode all potions on the field
    // Using: ACT(2)
    // Temporary.
    POTION_EXPLODER,

/// a void
    // This is the only place where you can move your Molly.
    NONE  = -1

}GameObjectType;

@interface GameObject : NSObject {
	int x;
	int y;
	GameObjectType type;
	BOOL isBarrier;
}

+ (GameObject*)createWithSymbol:(NSString*)symbol;
@property (nonatomic, readonly) BOOL isBarrier;
@property (nonatomic, readonly) GameObjectType type;
@property (nonatomic, assign) int x;
@property (nonatomic, assign) int y;

@end
