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
    next if !move.physicalMove?
    next if !move.physicalMove?
    next if battle.pbRandom(100) >= 30
    next if target.hasActiveItem?(:COVERTCLOAK)
    battle.pbShowAbilitySplash(user)
    if target.hasActiveAbility?(:SHIELDDUST) && !battle.moldBreaker
      battle.pbShowAbilitySplash(target)
      if !Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡{1} no se ve afectado!", target.pbThis))
      end
      battle.pbHideAbilitySplash(target)
    elsif target.pbCanGlitch?(user, Battle::Scene::USE_ABILITY_SPLASH)
      msg = nil
      if !Battle::Scene::USE_ABILITY_SPLASH
        msg = _INTL("¡La habilidad {2} de {1} corrompió a {3}!", user.pbThis, user.abilityName, target.pbThis(true))
      end
      target.pbGlitch(user, msg)
    end
    battle.pbHideAbilitySplash(user)
  }
)

# Epidemia Viral
Battle::AbilityEffects::OnEndOfUsingMove.add(:VIRALGROWTH, # Arreglar
  proc { |ability, user, targets, move, battle|
    next if battle.pbAllFainted?(user.idxOpposingSide)
    numFainted = 0
    targets.each { |b| numFainted += 1 if b.damageState.fainted }
    next if numFainted == 0 || !user.pbCanRaiseStatStage?(:ATTACK, user)
    user.pbRaiseStatStageByAbility(:ATTACK, numFainted, user)
    battler.pbRecoverHP(battler.totalhp / 4) if Effectiveness.super_effective?(target.damageState.typeMod)
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

class PokeBattle_Battler
  def type1
    @battle.eachBattler do |battler|
      return :NORMAL if battler.hasActiveAbility?(:NORMALIZE)
    end
    return @type1
  end

  def type2
    @battle.eachBattler do |battler|
      return :NORMAL if battler.hasActiveAbility?(:NORMALIZE)
    end
    return @type2
  end

  def pbTypes(withType3=false)
    @battle.eachBattler do |battler|
      return [:NORMAL] if battler.hasActiveAbility?(:NORMALIZE)
    end
    
    ret = [@type1]
    ret.push(@type2) if @type2!=@type1
    # Burn Up erases the Fire-type.
    ret.delete(:FIRE) if @effects[PBEffects::BurnUp]
    # Roost erases the Flying-type. If there are no types left, adds the Normal-
    # type.
    if @effects[PBEffects::Roost]
      ret.delete(:FLYING)
      ret.push(:NORMAL) if ret.length == 0
    end
    # Add the third type specially.
    if withType3 && @effects[PBEffects::Type3]
      ret.push(@effects[PBEffects::Type3]) if !ret.include?(@effects[PBEffects::Type3])
    end
    return ret
  end
end