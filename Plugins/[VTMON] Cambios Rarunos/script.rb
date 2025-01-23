# Vuelo Modificado
def pbFlyToNewLocation(pkmn = nil, move = :FLY)
    return false if $game_temp.fly_destination.nil?
    # pkmn = $player.get_pokemon_with_move(move) if !pkmn
    # if !$DEBUG #&& !pkmn
    #   $game_temp.fly_destination = nil
    #   yield if block_given?
    #   return false
    # end
    # if !pkmn || !pbHiddenMoveAnimation(pkmn)
    #   name = pkmn&.name || $player.name
    #   pbMessage(_INTL("{1} used {2}!", name, GameData::Move.get(move).name))
    # end
    $stats.fly_count += 1
    pbFadeOutIn do
      pbSEPlay("Fly")
      $game_temp.player_new_map_id = $game_temp.fly_destination[0]
      $game_temp.player_new_x = $game_temp.fly_destination[1]
      $game_temp.player_new_y = $game_temp.fly_destination[2]
      $game_temp.player_new_direction = 2
      pbDismountBike
      $scene.transfer_player
      $game_map.autoplay
      $game_map.refresh
      yield if block_given?
      pbWait(0.25)
    end
    pbEraseEscapePoint
    $game_temp.fly_destination = nil
    return true
  end

  def pbCanFly?(pkmn = nil, show_messages = false)
    return true if $DEBUG
    if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_FLY, show_messages)
      return false
    end
    return false if !$DEBUG && !pkmn && !$player.get_pokemon_with_move(:FLY)
    if !$game_player.can_map_transfer_with_follower?
      if show_messages
        pbMessage(_INTL("It can't be used when you have someone with you."))
      end
      return false
    end
    if !$game_map.metadata&.outdoor_map
      pbMessage(_INTL("You can't use that here.")) if show_messages
      return false
    end
    return true
  end

# Nueva Caña
ItemHandlers::UseInField.add(:SUPERROD, proc { |item| 
  # Comprobación de si el jugador está en un área donde puede pescar
  notCliff = $game_map.passable?($game_player.x, $game_player.y, $game_player.direction, $game_player)
  
  # Comprobar si el terreno donde el jugador está no permite pescar
  if !$game_player.pbFacingTerrainTag.can_fish || (!$PokemonGlobal.surfing && !notCliff)
    pbMessage(_INTL("Aquí no se puede usar."))
    next false
  end

  # Iniciar el minijuego de pesca
  # Usamos pbPescaMinigame para activar el minijuego de pesca
  success = pbPescaMinigame  # Aquí se ejecuta el minijuego de pesca
  
  if success
    # Si el minijuego tiene éxito, simplemente muestra un mensaje de éxito
    # Aquí puedes incluir otras acciones adicionales si lo deseas
  else
    pbFishingEnd
    pbWait(0.2)
    pbMessage(_INTL("Parece que no hubo tanta suerte..."))
  end
  
  # Después de la pesca (exitosa o no), se regresa a la acción normal
  next true
})

