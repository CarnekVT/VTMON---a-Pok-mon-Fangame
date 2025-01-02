GameData::Status.register({
  :id            => :GLITCH,
  :name          => _INTL("Corrompido"),
  :animation     => "Glitched",
  :icon_position => 7
})

GameData::Evolution.register({
  :id            => :HasMoveTurnForm1,
  :parameter     => :Move,
  :any_level_up  => true,   # Needs any level up
  :level_up_proc => proc { |pkmn, parameter|
    next pkmn.moves.any? { |m| m && m.id == parameter }
  },
  :after_evolution_proc => proc { |pkmn, new_species, parameter, evo_species|
    next false if evo_species != new_species
    pkmn.form = 1 if  pkmn.moves.any? { |m| m && m.id == parameter }
    next true
  }
})