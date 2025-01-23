#===============================================================================
# User takes recoil damage equal to 1/3 of the damage this move dealt.
# Raise Speed if Binught Glitch Form does it. (Data Overcharge)
#===============================================================================
class Battle::Move::RecoilThirdOfDamageDealtBinught < Battle::Move::RecoilMove
  def pbRecoilDamage(user, target)
    # Daño de retroceso: 1/3 del daño infligido
    return (target.damageState.totalHPLost / 3.0).round
  end

  def pbAdditionalEffect(user, target)
    # Depuración de especie, forma, y estado
    puts "Especie de usuario: #{user.species} (esperado :BINUGHT)"
    puts "Forma de usuario: #{user.form} (esperado 1)"
    puts "¿Puede aumentar la velocidad? #{user.pbCanRaiseStatStage?(:SPEED, user, self)}"

    # Verificar si la especie es Binught y la forma es 1
    if user.species != :BINUGHT
      puts "¡El Pokémon no es Binught! Es #{user.species}"
    elsif user.form != 1
      puts "¡La forma del Pokémon no es 1! Es #{user.form}"
    else
      puts "¡Binught tiene la forma 1!"
      # Aumenta la Velocidad si es posible
      if user.pbCanRaiseStatStage?(:SPEED, user, self)
        user.pbRaiseStatStage(:SPEED, 1, user)
        @battle.pbDisplay(_INTL("¡{1} aumentó su Velocidad gracias a la sobrecarga de datos!", user.pbThis))
      else
        puts "No se puede aumentar la Velocidad."  # Mostrar si no se puede aumentar la Velocidad
      end
    end
  end
end

#===============================================================================
# Glitch the target.
#===============================================================================
class Battle::Move::GlitchTarget < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    return false if damagingMove? # Si es un movimiento dañino, nunca falla aquí
    return !target.pbCanGlitch?(user, show_message, self) # Verifica si se puede aplicar "Glitch"
  end

  def pbEffectAgainstTarget(user, target)
    return if damagingMove? # Evita efecto doble si es dañino
    target.pbGlitch(user) if target.pbCanGlitch?(user, false, self)
  end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute # Evita efectos si hay un sustituto
    target.pbGlitch(user) if target.pbCanGlitch?(user, false, self)
  end
end

#===============================================================================
# Cures user of permanent status problems.
# Reset user stat changes. (Reboot)
#===============================================================================  # Arreglar
class Battle::Move::RebootUser < Battle::Move
  def pbEffectGeneral(user)
    # Variables para rastrear si se hizo algún cambio
    status_cured = user.pbHasAnyStatus?
    stats_reset = user.hasAlteredStatStages?

    # Elimina estados alterados si los hay
    user.pbCureStatus if status_cured

    # Reinicia cambios de estadísticas si los hay
    user.pbResetStatStages if stats_reset

    # Mostrar mensaje según el resultado
    if status_cured || stats_reset
      @battle.pbDisplay(_INTL("¡{1} reinició su sistema con éxito!", user.pbThis))
    else
      @battle.pbDisplay(_INTL("¡{1} reinició su sistema, pero no había nada que eliminar!", user.pbThis))
    end
  end
end

#===============================================================================
# Causes Poison, Paralysis, or Sleep. Fails if this isn't the user's first turn.
# (Mayimpresion)
#===============================================================================
class Battle::Move::Mayimpresion < Battle::Move::FlinchTarget
  def pbMoveFailed?(user, targets)
    # Verificamos si no es el primer turno del usuario
    if user.turnCount > 1
      @battle.pbDisplay(_INTL("¡Pero ha fallado!", user.pbThis, @name))
      return true
    end
    return false
  end

  def pbAdditionalEffect(user, target)
    # Aplicar el efecto de flinch
    super(user, target)  # Llama al método de la clase base para aplicar flinch

    # Ahora, aplicar un estado alterado aleatorio
    return if target.damageState.substitute
    case @battle.pbRandom(3)
    when 0
      target.pbPoison(user) if target.pbCanPoison?(user, false, self)
    when 1
      target.pbParalyze(user) if target.pbCanParalyze?(user, false, self)
    when 2
      target.pbSleep if target.pbCanSleep?(user, false, self)
    end
  end
end