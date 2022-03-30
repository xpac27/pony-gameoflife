primitive DeadCell
primitive LivingCell
primitive UnchangedCell
type CellState is (DeadCell | LivingCell | UnchangedCell)

struct Cell
  var alive: Bool = false // only required to guard against reviving living cells from user input
  var alive_neighbour: U8 = 0

  fun should_be(): CellState =>
    if (alive == true) and ((alive_neighbour < 2) or (alive_neighbour > 3)) then
      DeadCell
    elseif (alive == false) and (alive_neighbour == 3) then
      LivingCell
    else
      UnchangedCell
    end

