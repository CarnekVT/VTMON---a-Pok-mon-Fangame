#===============================================================================
# Visible Overworld Wild Encounters + Enhanced Encounter Types
# Script derivado para permitir combinaciones de encuentros normales y visibles.
# Basado en los scripts proporcionados.
#===============================================================================

module EnhancedVisibleEncounterSettings
  LET_NORMAL_ENCOUNTERS_SPAWN = true  # Permitir encuentros normales si no hay OW definidos
end

#===============================================================================
# Extiende la clase PokemonEncounters para reconocer nuevos tipos de encuentros
#===============================================================================
class PokemonEncounters
  # Sobrescribe encounter_type_on_tile para incluir tipos Overworld
  def encounter_type_on_tile(x, y)
    time = pbGetTimeNow
    ret = nil

    if $game_map.terrain_tag(x, y)&.can_surf_freely
      # Encuentros en agua
      ret = find_valid_encounter_type_for_time(:OverworldWater, time)
      ret = find_valid_encounter_type_for_time(:Water, time) if !ret && EnhancedVisibleEncounterSettings::LET_NORMAL_ENCOUNTERS_SPAWN
    else
      # Encuentros terrestres y en cuevas
      if has_land_encounters?
        ret = find_valid_encounter_type_for_time(:OverworldLand, time) if !ret
        ret = find_valid_encounter_type_for_time(:Land, time) if !ret && EnhancedVisibleEncounterSettings::LET_NORMAL_ENCOUNTERS_SPAWN
      end
      if has_cave_encounters?
        ret = find_valid_encounter_type_for_time(:OverworldCave, time) if !ret
        ret = find_valid_encounter_type_for_time(:Cave, time) if !ret && EnhancedVisibleEncounterSettings::LET_NORMAL_ENCOUNTERS_SPAWN
      end
    end

    return ret
  end
end

#===============================================================================
# Gestiona encuentros normales vs overworld en cada paso, según el tipo de encuentro
#===============================================================================
def pbBattleOrSpawnOnStepTaken(repel_active)
  encounter_type = $PokemonEncounters.encounter_type_on_tile($game_player.x, $game_player.y)
  if encounter_type && encounter_type.to_s.start_with?("Overworld")
    pbSpawnOnStepTaken(repel_active)
    return false
  else
    return true
  end
end

#===============================================================================
# Genera encuentros overworld según las configuraciones del PBS
#===============================================================================
def pbSpawnOnStepTaken(repel_active)
  return if $player.able_pokemon_count == 0  # Asegura que el jugador tiene Pokémon
  pos = pbChooseTileOnStepTaken
  if !pos
    puts "No se encontró una posición válida para spawnear" # Depuración
    return
  end

  encounter_type = $PokemonEncounters.encounter_type_on_tile(pos[0], pos[1])
  if !encounter_type
    puts "No se encontró un tipo de encuentro válido en #{pos}" # Depuración
    return
  end

  pokemon = $PokemonEncounters.choose_wild_pokemon(encounter_type)
  if !pokemon
    puts "No se pudo generar un Pokémon para el tipo de encuentro #{encounter_type}" # Depuración
    return
  end

  $PokemonGlobal.creatingSpawningPokemon = true
  pbPlaceEncounter(pos[0], pos[1], pokemon)
  $PokemonGlobal.creatingSpawningPokemon = false
  puts "Pokémon #{pokemon.species} spawneado en posición #{pos}" # Depuración
end

#===============================================================================
# Coloca un Pokémon OW en la posición seleccionada
#===============================================================================
def pbPlaceEncounter(x, y, pokemon)
  puts "Colocando Pokémon #{pokemon.species} en #{x}, #{y}" # Depuración
  $game_map.spawnPokeEvent(x, y, pokemon)
  pbPlayCryOnOverworld(pokemon.species, pokemon.form) # Reproduce el grito del Pokémon
end

#===============================================================================
# Configura los nuevos tipos de encuentros
#===============================================================================
GameData::EncounterType.register({
  :id             => :OverworldLand,
  :type           => :land,
  :trigger_chance => 50,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

GameData::EncounterType.register({
  :id             => :OverworldCave,
  :type           => :cave,
  :trigger_chance => 25,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

GameData::EncounterType.register({
  :id             => :OverworldWater,
  :type           => :water,
  :trigger_chance => 30,
  :old_slots      => [60, 30, 5, 4, 1]
})

#===============================================================================
# Revisión de tiles para spawn
#===============================================================================
def pbChooseTileOnStepTaken
  x, y = $game_player.x, $game_player.y
  range = 4 # Configura el rango de búsqueda de tiles
  50.times do # Intentos máximos para encontrar un tile válido
    new_x = x + rand(-range..range)
    new_y = y + rand(-range..range)
    if pbTileIsPossible(new_x, new_y)
      puts "Tile válido encontrado en #{new_x}, #{new_y}" # Depuración
      return [new_x, new_y]
    end
  end
  puts "No se encontraron tiles válidos" # Depuración
  return nil
end

def pbTileIsPossible(x, y)
  return false if !$game_map.valid?(x, y)  # Fuera del mapa
  terrain = $game_map.terrain_tag(x, y)
  return false if terrain&.ledge || terrain&.ice  # Prohibidos
  return true # Permitir cualquier terreno válido
end
