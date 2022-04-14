use "promises"

primitive Dead
primitive Alive
primitive Unchanged
type State is (Dead | Alive | Unchanged)
type UpdateStateResult is (State, Index )
type UpdateStateResultPromise is Promise[(UpdateStateResult)]

actor Cell
  let env: Env
  let index: USize

  var alive: Bool = false
  var alive_neighbour: U8 = 0

  new create(env': Env, index': USize) =>
    env = env'
    index = index'

  be increment_alive_neighbour_count() =>
    alive_neighbour = alive_neighbour + 1

  be decrement_alive_neighbour_count() =>
    alive_neighbour = alive_neighbour - 1

  be spawn(p: UpdateStateResultPromise) =>
    alive = true
    p((Alive, index))

  be update_state(p: UpdateStateResultPromise) =>
    if (alive == true) and ((alive_neighbour < 2) or (alive_neighbour > 3)) then
      alive = false
      p((Dead, index))
    elseif (alive == false) and (alive_neighbour == 3) then
      alive = true
      p((Alive, index))
    else
      p((Unchanged, index))
    end

