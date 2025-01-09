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