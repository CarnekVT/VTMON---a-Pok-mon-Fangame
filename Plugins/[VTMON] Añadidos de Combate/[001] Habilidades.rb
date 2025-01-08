class HandlerHashSymbol
  def remove(key)
    echoln "Removing #{key}"
    @hash.delete(key)
    @add_ifs.delete(key)
  end
end

# Poder Solar sin Recoil
Battle::AbilityEffects::EndOfRoundWeather.remove(:SOLARPOWER)

# Corruptor
Battle::AbilityEffects::OnDealingHit.add(:CORRUPTOR,
  proc { |ability, user, target, move, battle|
    # Validar que el movimiento sea físico
    next if !move.physicalMove?

    # Probabilidad de activación (30%)
    next if battle.pbRandom(100) >= 30

    # Bloqueo por el objeto Covert Cloak
    next if target.hasActiveItem?(:COVERTCLOAK)

    # Mostrar el splash de la habilidad del usuario
    battle.pbShowAbilitySplash(user)

    # Bloqueo por la habilidad Shield Dust (si no está Mold Breaker activo)
    if target.hasActiveAbility?(:SHIELDDUST) && !battle.moldBreaker
      battle.pbShowAbilitySplash(target)
      if !Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡{1} no se ve afectado!", target.pbThis))
      end
      battle.pbHideAbilitySplash(target)
    # Aplicar efecto de "corrupción" si es posible
    elsif target.pbCanGlitch?(user, Battle::Scene::USE_ABILITY_SPLASH)
      msg = nil
      if !Battle::Scene::USE_ABILITY_SPLASH
        msg = _INTL("¡La habilidad {2} de {1} corrompió a {3}!", user.pbThis, user.abilityName, target.pbThis(true))
      end
      target.pbGlitch(user, msg)
    end

    # Ocultar el splash de la habilidad del usuario
    battle.pbHideAbilitySplash(user)
  }
)

# Epidemia Viral
Battle::AbilityEffects::OnEndOfUsingMove.add(:VIRALGROWTH,
  proc { |ability, user, targets, move, battle|
    next if battle.pbAllFainted?(user.idxOpposingSide) # Si todos los oponentes ya están debilitados, no hace nada

    numFainted = 0
    superEffective = false

    # Contar objetivos debilitados y verificar si hubo algún golpe súper efectivo
    targets.each do |target|
      numFainted += 1 if target.damageState.fainted
      if Effectiveness.super_effective?(target.damageState.typeMod)
        superEffective = true
      end
    end

    # Aumentar el Ataque por cada enemigo debilitado
    if numFainted > 0 && user.pbCanRaiseStatStage?(:ATTACK, user)
      user.pbRaiseStatStageByAbility(:ATTACK, numFainted, user)
    end

    # Recuperar HP si hubo al menos un golpe súper efectivo
    if superEffective
      user.pbRecoverHP(user.totalhp / 4)
      battle.pbDisplay(_INTL("{1} recovered some HP due to its Viral Growth!", user.pbThis))
    end
  }
)


# Bala Cítrica
Battle::AbilityEffects::OnDealingHit.add(:CITRUSBULLET,
  proc do |ability, user, target, move, battle|
    next if target.fainted?
    next if !target.pbCanLowerStatStage?(:EVASION, user)
    battle.pbShowAbilitySplash(user)
    target.pbLowerStatStage(:EVASION, 1, user, true)
    msg =
      _INTL("¡La cría de {1} redujo la evasión de {2}!", user.pbThis, target.pbThis)
    battle.pbDisplay(msg)
    battle.pbHideAbilitySplash(user)
  end
)

# Jugueteo Abisal
Battle::AbilityEffects::OnDealingHit.add(:ABYSSALROMP,
  proc do |ability, user, target, move, battle|
    next if !move.calcType == :WATER
    next if target.fainted?
    battle.pbShowAbilitySplash(user)
    target.effects[PBEffects::TrappingMove] = :WHIRLPOOL
    target.effects[PBEffects::TrappingUser] = user.index
    target.effects[PBEffects::Trapping] = 2
    msg = _INTL("¡{1} atrapó a su presa en un torbellino!", target.pbThis)
    battle.pbDisplay(msg)
    battle.pbHideAbilitySplash(user)
  end
)

# Normalidad Nuevo

def eachBattler
  if @battlers.is_a?(Array) && !@battlers.empty?
    @battlers.each { |b| yield b if b && !b.fainted? }
  else
    puts "Error: @battlers no es una lista válida o está vacía."
  end
end


Battle::AbilityEffects::OnSwitchIn.add(:NORMALIZE,
  proc { |ability, battler, battle|
    # Verificar si el Pokémon tiene la habilidad Normalidad
    return unless battler.ability == :NORMALIZE
    
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡Todos los Pokémon en el campo se vuelven del tipo Normal debido a {1}!", battler.pbThis))

    # Cambiar el tipo de todos los Pokémon en el campo a Normal
    battle.eachBattler do |b|
      next if b == battler  # No cambiar el tipo del Pokémon que tiene Normalidad
      b.instance_variable_set(:@original_types, b.types)  # Guardar los tipos originales
      b.types = [:NORMAL]  # Cambiar los tipos de los demás Pokémon a Normal
    end

    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchOut.add(:NORMALIZE,
  proc { |ability, battler, battle|
    # Verificar si el Pokémon tiene la habilidad Normalidad
    return unless battler.ability == :NORMALIZE
    
    # Restaurar los tipos originales de todos los Pokémon al salir
    battle.eachBattler do |b|
      next unless b.instance_variable_get(:@original_types)  # Verificar que los tipos fueron modificados
      b.types = b.instance_variable_get(:@original_types)  # Restaurar los tipos originales
      b.instance_variable_set(:@original_types, nil)  # Limpiar la variable interna
    end
  }
)

####################################
# Codigo aparte para Normalidad
####################################

def pbRecallAndReplace(idxBattler, idxParty, randomReplacement = false, batonPass = false)
  battler = @battlers[idxBattler]
  is_player = (idxBattler % 2 == 0)  # Suponiendo que los índices pares son los del jugador

  # Verificar tipos antes de cambiar
  pbDisplay("#{battler.pbName} tipos antes del cambio: #{battler.type1}, #{battler.type2}")

  # Si el Pokémon tiene la habilidad Normalidad
  if battler.hasAbility?(:NORMALIDAD)
    original_type1 = battler.pokemon.speciesData.types[0]
    original_type2 = battler.pokemon.speciesData.types[1] || nil

    # Restablecer los tipos
    battler.type1 = original_type1
    battler.type2 = original_type2

    # Mostrar los tipos después del cambio
    pbDisplay("#{battler.pbName} tipos después del cambio: #{battler.type1}, #{battler.type2}")
  end

  # Aquí verificamos si el cambio ocurrió en un Pokémon del jugador o del oponente
  if is_player
    pbDisplay("¡El Pokémon del jugador ha restaurado su tipo original!")
  else
    pbDisplay("¡El Pokémon enemigo ha restaurado su tipo original!")
  end

  @scene.pbRecall(idxBattler) if !battler.fainted?
  battler.pbAbilitiesOnSwitchOut
  @scene.pbShowPartyLineup(idxBattler & 1) if pbSideSize(idxBattler) == 1
  pbMessagesOnReplace(idxBattler, idxParty) if !randomReplacement
  pbReplace(idxBattler, idxParty, batonPass)
end


class Battle::Battler
  # Método para verificar si el Pokémon tiene una habilidad específica
  def hasAbility?(ability)
    self.ability == ability
  end
end


def activate_normalidad_effects
  # Iterar sobre todos los Pokémon en combate
  @battlers.each do |battler|
    next if !battler # Si no hay battler, continuar
    next if battler.fainted? # Si el Pokémon está debilitado, continuar

    # Si el Pokémon tiene la habilidad Normalidad, se cambia su tipo
    if battler.hasAbility?(:NORMALIDAD)
      pbDisplay("#{battler.pbName} ha activado Normalidad, todos los Pokémon se vuelven tipo Normal!")

      # Cambiar el tipo de todos los Pokémon a Normal
      @battlers.each do |other_battler|
        next if !other_battler || other_battler.fainted?

        other_battler.type1 = :NORMAL
        other_battler.type2 = :NORMAL
      end
    end
  end
end

################################################################################







