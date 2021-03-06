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
#import "cocos2d.h"
#import "HeroAPI.h"
//#import "AIAnalyzer.h"

@interface Drawer : CCLayer <UIAlertViewDelegate,HeroAPIDelegate> {
	NSMutableArray *redrawingObject;
	NSMutableArray *pathArray;
}
+ (CCScene*)scene;
@end
