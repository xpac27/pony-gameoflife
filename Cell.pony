primitive DeadCell
primitive LivingCell
primitive UnchangedCell
type CellShouldBe is (DeadCell | LivingCell | UnchangedCell)

struct Cell
  var _alive: Bool = false
  var _alive_neighbour: U8 = 0

  fun ref add_neighbour() =>
    _alive_neighbour = _alive_neighbour + 1

  fun ref remove_neighbour() =>
    _alive_neighbour = _alive_neighbour - 1

  fun ref live() =>
    _alive = true

  fun ref die() =>
    _alive = false

  fun should_be(): CellShouldBe =>
    if (_alive == true) and ((_alive_neighbour < 2) or (_alive_neighbour > 3)) then
      DeadCell
    elseif (_alive == false) and (_alive_neighbour == 3) then
      LivingCell
    else
      UnchangedCell
    end

