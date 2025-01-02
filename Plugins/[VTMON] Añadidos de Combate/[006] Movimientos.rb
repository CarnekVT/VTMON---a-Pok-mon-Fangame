#===============================================================================
# User takes recoil damage equal to 1/3 of the damage this move dealt.
# Raise Speed if Binught Glitch Form does it. (Data Overcharge)
#===============================================================================
class Battle::Move::RecoilThirdOfDamageDealtBinught < Battle::Move::RecoilMove
    def pbRecoilDamage(user, target)
      return (target.damageState.totalHPLost / 3.0).round
    end
  
    def pbAdditionalEffect(user, target)
        return if !user.isSpecies?(:BINUGHT) && pkmn.form == 1 || !user.pbCanRaiseStatStage?(:SPEED, user, self)
        target.pbRaiseStatStage(:SPEED, 1, user)   
    end
  end
  
#===============================================================================
# Glitch the target.
#===============================================================================
class Battle::Move::GlitchTarget < Battle::Move
    def canMagicCoat?; return true; end
  
    def pbFailsAgainstTarget?(user, target, show_message)
      return false if damagingMove?
      return !target.pbCanGlitch?(user, show_message, self)
    end
  
    def pbEffectAgainstTarget(user, target)
      return if damagingMove?
      target.pbGlitch(user)
    end
  
    def pbAdditionalEffect(user, target)
      return if target.damageState.substitute
      target.pbGlitch(user) if target.pbCanGlitch?(user, false, self)
    end
  end
  
#===============================================================================
# Cures user of permanent status problems.
# Reset user stat changes. (Reboot)
#===============================================================================  # Arreglar
class Battle::Move::RebootUser < Battle::Move::MultiStatUpMove
    def pbEffectGeneral(user)
      user.pbCureStatus if user.pbHasAnyStatus?
      tuser.pbResetStatStages if user.hasAlteredStatStages?
      @battle.pbDisplay(_INTL("¡Se ha reiniciado el sistema del usuario!"))
    end 
  end
  
#===============================================================================
