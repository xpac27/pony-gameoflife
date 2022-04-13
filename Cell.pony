use "promises"

primitive Dead
primitive Alive
primitive Unchanged
type State is (Dead | Alive | Unchanged)
type UpdateStateResult is (State, Index, Position)
type UpdateStateResultPromise is Promise[(UpdateStateResult)]

actor Cell
  let env: Env
  let index: USize
  let position: Position // TODO no need for position i guess? since it can be deduced

  var alive: Bool = false
  var alive_neighbour: U8 = 0

  new create(env': Env, index': USize, position': Position) =>
    env = env'
    index = index'
    position = position'

  be increment_alive_neighbour_count() =>
    alive_neighbour = alive_neighbour + 1

  be decrement_alive_neighbour_count() =>
    alive_neighbour = alive_neighbour - 1

  be spawn(p: UpdateStateResultPromise) =>
    alive = true
    p((Alive, index, position))

  be update_state(p: UpdateStateResultPromise) =>
    if (alive == true) and ((alive_neighbour < 2) or (alive_neighbour > 3)) then
      alive = false
      p((Dead, index, position))
    elseif (alive == false) and (alive_neighbour == 3) then
      alive = true
      p((Alive, index, position))
    else
      p((Unchanged, index, position))
    end

