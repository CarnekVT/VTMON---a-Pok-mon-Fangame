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

# Habilidad: Parche
Battle::AbilityEffects::EndOfRoundHealing.add(:PATCH,
  proc { |ability, battler, battle|
    if battler.status != :NONE
      if battle.pbRandom(100) < 30
        battle.pbShowAbilitySplash(battler)
        oldStatus = battler.status
        battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
        if !Battle::Scene::USE_ABILITY_SPLASH
          case oldStatus
          when :SLEEP
            battle.pbDisplay(_INTL("¡La habilidad {2} de {1} le despertó!", battler.pbThis, battler.abilityName))
          when :POISON
            battle.pbDisplay(_INTL("¡La habilidad {2} de {1} curó su envenenamiento!", battler.pbThis, battler.abilityName))
          when :BURN
            battle.pbDisplay(_INTL("¡La habilidad {2} de {1} curó su quemadura!", battler.pbThis, battler.abilityName))
          when :PARALYSIS
            battle.pbDisplay(_INTL("¡La habilidad {2} de {1} curó su parálisis!", battler.pbThis, battler.abilityName))
          when :FROZEN, :FROSTBITE
            battle.pbDisplay(_INTL("¡La habilidad {2} de {1} le descongeló!", battler.pbThis, battler.abilityName))
          end
        end
        battle.pbHideAbilitySplash(battler)
      end
    elsif battle.pbRandom(100) < 30
      battle.pbShowAbilitySplash(battler)
      showAnim = true
      [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
        next if !battler.pbCanRaiseStatStage?(stat, nil, nil, true)
        if battler.pbRaiseStatStage(stat, 1, battler, showAnim)
          showAnim = false
        end
      end
      battle.pbHideAbilitySplash(battler)
    end
  }
)

# Habilidad: Zona Corrupta
Battle::AbilityEffects::OnSwitchIn.add(:BUGGEDAURA,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler, true)
    battle.pbDisplay(_INTL("¡Un aura corrupta se propaga por toda la zona!"))
    battle.allBattlers.each do |b|
      next if b.hasActiveItem?(:ABILITYSHIELD)
      b.effects[PBEffects::GastroAcid] = true
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchOut.add(:BUGGEDAURA,
  proc { |ability, battler, battle|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡Las habilidades de los Pokémon en el campo han sido restauradas!"))
    battle.eachBattler { |b| b.effects[PBEffects::GastroAcid] = false }
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnBattlerFainting.add(:BUGGEDAURA,
  proc { |ability, battler, fainted, battle|
    next if battler.index != fainted.index
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡Las habilidades de los Pokémon en el campo han sido restauradas!"))
    battle.eachBattler { |b| b.effects[PBEffects::GastroAcid] = false }
    battle.pbHideAbilitySplash(battler)
  }
)

# Habilidad: Encriptado
Battle::AbilityEffects::StatLossImmunityNonIgnorable.copy(:FULLMETALBODY, :ENCRYPTED)

Battle::AbilityEffects::MoveBlocking.copy(:DAZZLING, :QUEENLYMAJESTY, :ENCRYPTED, :ARMORTAIL)

# Habilidad: Antivirus
Battle::AbilityEffects::DamageCalcFromTarget.add(:ANTIVIRUS,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= 0.9
  }
)

Battle::AbilityEffects::OnBeingHit.add(:ANTIVIRUS,
  proc { |ability, user, target, move, battle|
    if Effectiveness.super_effective?(target.damageState.typeMod)
      target.pbRaiseStatStageByAbility(:SPEED, 2, target)
      battle.pbDisplay(_INTL("¡La velocidad de {1} aumentó gracias a {2}!", 
        target.pbThis(true), target.abilityName))
    end
  }
)

# Habilidad: Inspiración Divina
Battle::AbilityEffects::OnSwitchIn.add(:DIVINEINSPIRATION,
  proc { |ability, battler, battle, switch_in|
    # Mostrar animación global de la habilidad
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡Los aliados de {1} se inspiraron con su presencia!", battler.pbThis(true), battler.abilityName))

    # Iterar sobre los aliados del mismo lado
    battle.eachSameSideBattler(battler.index) do |ally|
      next if ally == battler  # Saltar al usuario de la habilidad

      # Variable para controlar si se muestra la animación
      showAnim = true
      [:SPECIAL_ATTACK, :SPECIAL_DEFENSE].each do |stat|
        next if !ally.pbCanRaiseStatStage?(stat, nil, nil, true)
        # Subir estadísticas con una sola animación
        if ally.pbRaiseStatStage(stat, 1, battler, showAnim)
          showAnim = false
        end
      end
    end

    # Ocultar animación global de la habilidad
    battle.pbHideAbilitySplash(battler)
  }
)

# Habilidad: Canto Milagroso
Battle::AbilityEffects::OnDealingHit.add(:MIRACULOUSSONG, proc { |ability, user, target, move, battle|
  # Verificar si el movimiento es de tipo Hada o tiene la propiedad 'soundMove'
  if move.type == :FAIRY || move.soundMove?
    ability_activated = false

    # Verificar si el usuario puede curarse
    if user.hp < user.totalhp
      battle.pbShowAbilitySplash(user)
      ability_activated = true
      hp_recovery_user = (user.totalhp / 10).floor
      user.pbRecoverHP(hp_recovery_user)
      # Mensaje de recuperación del usuario
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡Los PS de {1} han sido restaurados!", user.pbThis))
      else
        battle.pbDisplay(_INTL("¡{1} ha restaurado sus PS gracias a {2}!", user.pbThis, user.abilityName))
      end
    end

    # Curar a los aliados (excluyendo al usuario)
    battle.eachSameSideBattler(user.index) do |ally|
      next if ally.fainted? || ally.index == user.index # Excluir al usuario

      # Curar solo si el aliado tiene menos PS que su total
      if ally.hp < ally.totalhp
        battle.pbShowAbilitySplash(user) if !ability_activated
        ability_activated = true
        hp_recovery_ally = (ally.totalhp / 10).floor
        ally.pbRecoverHP(hp_recovery_ally)
        # Mostrar mensaje de recuperación para el aliado
        if Battle::Scene::USE_ABILITY_SPLASH
          battle.pbDisplay(_INTL("¡Los PS de {1} han sido restaurados!", ally.pbThis))
        else
          battle.pbDisplay(_INTL("¡{1} ha restaurado los PS de {2} gracias a {3}!", user.pbThis, ally.pbThis, user.abilityName))
        end
      end
    end

    # Ocultar la animación de la habilidad si se activó
    battle.pbHideAbilitySplash(user) if ability_activated
  end
})

# Habilidad: Gran Encore
Battle::AbilityEffects::OnEndOfUsingMove.add(:GREATENCORE,
  proc { |ability, user, targets, move, battle|
    PBDebug.log("[Great Encore] Iniciando efecto de la habilidad.")

    user.effects ||= []

    if user.effects[PBEffects::GreatEncoreTriggered]
      PBDebug.log("[Great Encore] La habilidad ya se activó para este movimiento.")
      next
    end

    unless move.is_a?(Battle::Move)
      PBDebug.log("[Great Encore] Movimiento inválido. No es un objeto Battle::Move.")
      next
    end

    if battle.pbRandom(100) >= 40
      PBDebug.log("[Great Encore] La habilidad no se activó por probabilidad.")
      next
    end

    if move.pbNumHits(user, targets) > 1
      PBDebug.log("[Great Encore] Movimiento golpea múltiples veces. Habilidad no activada.")
      next
    end

    if move.function_code == "AttackAndSkipNextTurn" || move.function_code == "SwitchOutUserDamagingMove" || move.function_code == "FailsIfNotUserFirstTurn" ||
      move.id == :FAKEOUT || move.id == :MAYIMPRESION
      PBDebug.log("[Great Encore] Movimiento bloqueado detectado. Habilidad no activada.")
      next
    end

    # Verificar si algún objetivo fue afectado
    targets = [targets] unless targets.is_a?(Array)  # Asegura que targets sea siempre un arreglo
    all_unaffected = targets.all? { |target| target.damageState.unaffected }
    if all_unaffected
      PBDebug.log("[Great Encore] Ningún objetivo fue afectado. Habilidad no activada.")
      next
    end

    # Verificar si algún objetivo atacado fue debilitado
    original_target = targets.find { |target| !target.fainted? }
    if !original_target
      PBDebug.log("[Great Encore] Todos los objetivos atacados fueron debilitados. Habilidad no activada.")
      next
    end

    user.effects[PBEffects::GreatEncoreTriggered] = true
    battle.pbShowAbilitySplash(user)

    battle.pbDisplay(_INTL("¡El público aclama a {1} para realizar otro ataque más!", user.pbThis(true)))
    battle.pbHideAbilitySplash(user)

    # Seleccionar el objetivo del nuevo ataque
    new_target = original_target
    if new_target.fainted?
      # Elegir otro objetivo aleatorio válido si el original fue debilitado
      potential_targets = battle.pbAbleOpposingBattlers(user.index)
      if potential_targets.empty?
        PBDebug.log("[Great Encore] No hay otros objetivos válidos. Habilidad no activada.")
        next
      end
      new_target = potential_targets.sample
    end

    # Ejecutar nuevamente el movimiento dirigido al nuevo objetivo
    new_move = user.moves.find { |m| m.id == move.id }
    if new_move
      PBDebug.log("[Great Encore] Forzando uso del movimiento #{new_move.id} contra el objetivo #{new_target.pbThis}.")
      user.pbUseMoveSimple(new_move.id, new_target.index)
      PBDebug.log("[Great Encore] Movimiento ejecutado exitosamente.")
    else
      PBDebug.log("[Great Encore] No se pudo encontrar un movimiento válido para repetir.")
    end

    user.effects[PBEffects::GreatEncoreTriggered] = false
  }
)

module PBEffects
  GreatEncoreTriggered = 1000 # Un número suficientemente alto para evitar conflictos
  DelusiveFlameTriggered = 1001
  DelusiveFlameUsed = 1002
  IllusionDamage = 1003
end

class Battle
  alias great_encore_end_of_turn pbEndOfRoundPhase
  def pbEndOfRoundPhase
    # Reseteo de la habilidad Great Encore
    eachBattler do |battler|
      next unless battler.effects
      battler.effects[PBEffects::GreatEncoreTriggered] = false
    end
    great_encore_end_of_turn # Llamar al método original
  end
end

# Habilidad: Sagacidad
Battle::AbilityEffects::OnSwitchIn.add(:SAGACITY, proc { |ability, battler, battle|
  battle.pbShowAbilitySplash(battler)
  battle.eachOtherSideBattler(battler.index) do |other_battler|
    next if !other_battler || other_battler.fainted? # Verifica si el rival es válido y no está debilitado
    if other_battler.pbCanLowerStatStage?(:SPECIAL_ATTACK, battler)
      other_battler.pbLowerStatStage(:SPECIAL_ATTACK, 1, battler)
    end
  end
  battle.pbHideAbilitySplash(battler)
})

# Habilidad: Brasa Ilusoria
#===============================================================================
# Activa la ilusión visual y aplica los efectos adicionales.
#===============================================================================
Battle::AbilityEffects::OnSwitchIn.add(:DELUSIVEFLAME,
  proc { |ability, battler, battle|
    idx_last_party = battle.pbLastInTeam(battler.index)
    last_pokemon = (idx_last_party >= 0) ? battle.pbParty(battler.index)[idx_last_party] : nil

    # Activar ilusión si hay un Pokémon válido para copiar
    if last_pokemon && last_pokemon != battler.pokemon && last_pokemon.able?
      battler.effects[PBEffects::Illusion] = last_pokemon
      battle.scene.pbChangePokemon(battler, last_pokemon)
    end
  }
)

#===============================================================================
# Al recibir un ataque: desactivar ilusión, quemar al atacante y recuperar PS.
#===============================================================================
Battle::AbilityEffects::OnBeingHit.add(:DELUSIVEFLAME,
  proc { |ability, user, target, move, battle|
    # Verificar si la ilusión está activa
    if target.effects[PBEffects::Illusion]
      # Animación de la ilusión rota
      target.effects[PBEffects::Illusion] = nil

      # Actualizar el sprite al original inmediatamente
      target.mosaicChange = true
      battle.scene.pbAnimateSubstitute(target, :hide)  # Ocultar el sprite de sustituto
      battle.scene.pbChangePokemon(target, target.pokemon)  # Actualizar el Pokémon con su forma real
      battle.scene.pbAnimateSubstitute(target, :show, true)  # Mostrar el sprite del Pokémon original
      battle.scene.pbRefreshOne(target.index)
      target.pbUpdate(false)
      # Mensaje de ruptura
      battle.pbDisplay(_INTL("¡La ilusión de {1} fue rota!", target.pbThis))

      # Quemar al atacante si el movimiento tiene contacto físico
      # Verificar si el movimiento es de contacto (físico)
      if move.pbContactMove?(user) && !user.burned?  # Si el movimiento es de contacto y el atacante no está quemado
        # Quemar al atacante
        msg = _INTL("La ilusión de {1} ha quemado a {2}!", target.pbThis, user.pbThis(true))  # Mensaje de quemadura
        user.pbBurn(target, msg)  # Aplicar la quemadura
      end

      # Recuperar todos los PS del usuario
      battle.pbCommonAnimation("DelusiveFlame", target) if battle.showAnims
      hp_lost = target.totalhp - target.hp  # Cantidad de HP que perdió
      target.pbRecoverHP(hp_lost)  # Recuperar la vida perdida sin 
      battle.scene.pbRefreshOne(target.index)
      battle.pbDisplay(_INTL("¡{1} absorbió la esencia de la ilusión rota!", target.pbThis))
    end
  }
)

# Origami Letal
Battle::AbilityEffects::OnBeingHit.copy(:IRONBARBS, :ROUGHSKIN, :PAPERCUTTING)

# Plano Impecable
Battle::AbilityEffects::AccuracyCalcFromTarget.add(:PERFECTPLANE,
  proc { |ability, mods, user, target, move, type|
    # Reduce la precisión de los ataques hacia el objetivo con la habilidad Perfect Plane
    mods[:accuracy_multiplier] *= 0.8
  }
)

# Defensa Plegable
Battle::AbilityEffects::DamageCalcFromTarget.copy(:FILTER, :SOLIDROCK, :PERFECTFOLDING)
