class Battle::Scene
  def pbCreateBackdropSprites
    case @battle.time
    when 1 then time = "eve"
    when 2 then time = "night"
    end
    # Put everything together into backdrop, bases and message bar filenames
    backdropFilename = @battle.backdrop
    baseFilename = @battle.backdrop
    baseFilename = sprintf("%s_%s", baseFilename, @battle.backdropBase) if @battle.backdropBase
    messageFilename = @battle.backdrop
    if time
      trialName = sprintf("%s_%s", backdropFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/%s_bg", trialName))
        backdropFilename = trialName
      end
      trialName = sprintf("%s_%s", baseFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/%s_base0", trialName))
        baseFilename = trialName
      end
      trialName = sprintf("%s_%s", messageFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/%s_message", trialName))
        messageFilename = trialName
      end
    end
    if !pbResolveBitmap(sprintf("Graphics/Battlebacks/%s_base0", baseFilename)) &&
       @battle.backdropBase
      baseFilename = @battle.backdropBase
      if time
        trialName = sprintf("%s_%s", baseFilename, time)
        if pbResolveBitmap(sprintf("Graphics/Battlebacks/%s_base0", trialName))
          baseFilename = trialName
        end
      end
    end
# Finalise filenames
battleBG   = "Graphics/Battlebacks/" + backdropFilename + "_bg"
playerBase = "Graphics/Battlebacks/" + baseFilename + "_base0"
enemyBase  = "Graphics/Battlebacks/" + baseFilename + "_base1"
messageBG  = "Graphics/Battlebacks/" + messageFilename + "_message"
# Apply graphics
bg = pbAddSprite("battle_bg", 0, 0, battleBG, @viewport)
bg.z = 0
bg = pbAddSprite("battle_bg2", -Graphics.width, 0, battleBG, @viewport)
bg.z = 0
bg.mirror = true
2.times do |side|
  baseX, baseY = Battle::Scene.pbBattlerPosition(side)
  if side == 0
    baseY += 128 - 18  # Ajuste para mover el jugador más abajo y luego 15 píxeles más arriba
  else
    baseY -= 5  # Ajuste para mover el enemigo más abajo
  end
  base = pbAddSprite("base_#{side}", baseX, baseY,
                     (side == 0) ? playerBase : enemyBase, @viewport)
  base.z = 1
  if base.bitmap
    base.ox = base.bitmap.width / 2
    base.oy = (side == 0) ? base.bitmap.height : base.bitmap.height / 2
  end
end
cmdBarBG = pbAddSprite("cmdBar_bg", 0, Graphics.height - 96, messageBG, @viewport)
cmdBarBG.z = 180
  end

def pbCreateTrainerBackSprite(idxTrainer, trainerType, numTrainers = 1)
  if idxTrainer == 0  
    trainerFile = GameData::TrainerType.player_back_sprite_filename(trainerType)
  else  
    trainerFile = GameData::TrainerType.back_sprite_filename(trainerType)
  end
  spriteX, spriteY = Battle::Scene.pbTrainerPosition(0, idxTrainer, numTrainers)
  spriteY += 113
  trainer = pbAddSprite("player_#{idxTrainer + 1}", spriteX, spriteY, trainerFile, @viewport)
  return if !trainer.bitmap
  trainer.z = 80 + idxTrainer
  if trainer.bitmap.width > trainer.bitmap.height * 2
    trainer.src_rect.x     = 0
    trainer.src_rect.width = trainer.bitmap.width / 5
  end
  trainer.ox = trainer.src_rect.width / 2
  trainer.oy = trainer.bitmap.height
end
end
