package advisors

/*-
 * #%L
 * Codenjoy - it's a dojo-like platform from developers to developers.
 * %%
 * Copyright (C) 2018 - 2021 Codenjoy
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

import (
	"log"

	"github.com/ahmetb/go-linq"
	"github.com/arukim/expansion/game"
	m "github.com/arukim/expansion/models"
)

// GoldHunter is advisor with main focus to get gold mines ASAP
type GoldHunter struct {
	target   *m.Point
	forces   *m.Point
	finished bool
}

func NewGoldHunter() *GoldHunter {
	return &GoldHunter{}
}

func (gh *GoldHunter) MakeTurn(b *game.Board, t *m.Turn) {
	if gh.finished {
		return
	}

findTarget:
	// it there is no target, find new one
	if gh.target == nil {
		if len(b.FreeMines) == 0 {
			log.Println("GH: no new targets, I'm done")
			gh.finished = true
			return
		}

		p := linq.From(b.FreeMines).SelectT(func(x linq.KeyValue) m.Point {
			return x.Key.(m.Point)
		}).OrderByT(func(x m.Point) int {
			return b.OutsideMap.Get(x) - 1
		}).First().(m.Point)
		log.Printf("GH: found new target at %+v\n", p)
		gh.target = &p
	}

	if b.PlayersMap.Get(*gh.target) != -1 {
		gh.target = nil
		goto findTarget
	}

	maxForce := 0
	maxForcePos := 0
	for i, v := range b.ForcesMap.Data {
		// check only my force
		if b.PlayersMap.Data[i] == b.TurnInfo.MyColor && v > maxForce {
			maxForce = v
			maxForcePos = i
		}
	}

	from := m.NewPoint(maxForcePos, b.Width)
	move := *b.GetDirectionFromTo(from, *gh.target)

	forces := b.ForcesMap.Get(from)
	dist := b.OutsideMap.Get(*gh.target) - 1

	if dist > forces {
		move.Count = forces
	} else {
		move.Count = dist
	}

	b.ForcesMap.Data[maxForce] -= move.Count
	log.Printf("GH: moving %d forces to target %+v\n", move.Count, *gh.target)
	t.Movements = append(t.Movements, move)
}
