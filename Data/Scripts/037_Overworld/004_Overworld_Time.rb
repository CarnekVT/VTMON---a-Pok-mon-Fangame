#===============================================================================
# Day and night system
#===============================================================================
def pbGetTimeNow
  return Time.now
end

#===============================================================================
#
#===============================================================================
module PBDayNight
  HOURLY_TONES = [
    Tone.new(-30,   -70,   11,  68),   # Night     # Midnight
    Tone.new(-30,   -70,   11,  68),   # Night
    Tone.new(-30,   -70,   11,  68),   # Night
    Tone.new(-30,   -70,   11,  68),   # Night
    Tone.new(-30,   -70,   11,  68),   # Night
    Tone.new(-20,     -60,     -30,    17),   # Day/morning
    Tone.new(-20,     -60,     -30,    17),   # Day/morning    # 6AM
    Tone.new(-20,     -60,     -30,    17),   # Day/morning
    Tone.new(-20,     -60,     -30,    17),   # Day/morning
    Tone.new(0,     0,     0,    0),   # Day/morning
    Tone.new(0,     0,     0,    0),   # Day
    Tone.new(0,     0,     0,    0),   # Day
    Tone.new(0,     0,     0,    0),   # Day     # Noon
    Tone.new(0,     0,     0,    0),   # Day
    Tone.new(0,     0,     0,    0),   # Day/afternoon
    Tone.new(0,     0,     0,    0),   # Day/afternoon
    Tone.new(0,     0,     0,    0),   # Day/afternoon
    Tone.new(2,   -20,   3,  17),   # Day/afternoon
    Tone.new(2,   -20,   3,  17),   # Day/evening      # 6PM
    Tone.new(2,   -20,   3,  17),   # Day/evening
    Tone.new(2,   -20,   3,  17),   # Day/evening
    Tone.new(-30,   -70,   11,  68),   # Night
    Tone.new(-30,   -70,   11,  68),   # Night
    Tone.new(-30,   -70,   11,  68),   # Night
  ]
  CACHED_TONE_LIFETIME = 30   # In seconds; recalculates overworld tone once per this time
  @cachedTone = nil
  @dayNightToneLastUpdate = nil
  @oneOverSixty = 1 / 60.0

  # Returns true if it's day.
  def self.isDay?(time = nil)
    time = pbGetTimeNow if !time
    return (time.hour >= 5 && time.hour < 20)
  end

  # Returns true if it's night.
  def self.isNight?(time = nil)
    time = pbGetTimeNow if !time
    return (time.hour >= 20 || time.hour < 5)
  end

  # Returns true if it's morning.
  def self.isMorning?(time = nil)
    time = pbGetTimeNow if !time
    return (time.hour >= 5 && time.hour < 10)
  end

  # Returns true if it's the afternoon.
  def self.isAfternoon?(time = nil)
    time = pbGetTimeNow if !time
    return (time.hour >= 14 && time.hour < 17)
  end

  # Returns true if it's the evening.
  def self.isEvening?(time = nil)
    time = pbGetTimeNow if !time
    return (time.hour >= 17 && time.hour < 20)
  end

  # Gets a number representing the amount of daylight (0=full night, 255=full day).
  def self.getShade
    time = pbGetDayNightMinutes
    time = (24 * 60) - time if time > (12 * 60)
    return 255 * time / (12 * 60)
  end

  # Gets a Tone object representing a suggested shading
  # tone for the current time of day.
  def self.getTone
    @cachedTone = Tone.new(0, 0, 0) if !@cachedTone
    return @cachedTone if !Settings::TIME_SHADING
    if !@dayNightToneLastUpdate || (System.uptime - @dayNightToneLastUpdate >= CACHED_TONE_LIFETIME)
      getToneInternal
      @dayNightToneLastUpdate = System.uptime
    end
    return @cachedTone
  end

  def self.pbGetDayNightMinutes
    now = pbGetTimeNow   # Get the current in-game time
    return (now.hour * 60) + now.min
  end

  def self.getToneInternal
    # Calculates the tone for the current frame, used for day/night effects
    realMinutes = pbGetDayNightMinutes
    hour   = realMinutes / 60
    minute = realMinutes % 60
    tone         = PBDayNight::HOURLY_TONES[hour]
    nexthourtone = PBDayNight::HOURLY_TONES[(hour + 1) % 24]
    # Calculate current tint according to current and next hour's tint and
    # depending on current minute
    @cachedTone.red   = ((nexthourtone.red - tone.red) * minute * @oneOverSixty) + tone.red
    @cachedTone.green = ((nexthourtone.green - tone.green) * minute * @oneOverSixty) + tone.green
    @cachedTone.blue  = ((nexthourtone.blue - tone.blue) * minute * @oneOverSixty) + tone.blue
    @cachedTone.gray  = ((nexthourtone.gray - tone.gray) * minute * @oneOverSixty) + tone.gray
  end
end

#===============================================================================
#
#===============================================================================
def pbDayNightTint(object)
  return if !$scene.is_a?(Scene_Map)
  if Settings::TIME_SHADING && $game_map.metadata&.outdoor_map
    tone = PBDayNight.getTone
    object.tone.set(tone.red, tone.green, tone.blue, tone.gray)
  else
    object.tone.set(0, 0, 0, 0)
  end
end

#===============================================================================
# Days of the week
#===============================================================================
def pbIsWeekday(wdayVariable, *arg)
  timenow = pbGetTimeNow
  wday = timenow.wday
  ret = false
  arg.each do |wd|
    ret = true if wd == wday
  end
  if wdayVariable > 0
    $game_variables[wdayVariable] = [
      _INTL("Domingo"),
      _INTL("Lunes"),
      _INTL("Martes"),
      _INTL("Miércoles"),
      _INTL("Jueves"),
      _INTL("Viernes"),
      _INTL("Sábado")
    ][wday]
    $game_map.need_refresh = true if $game_map
  end
  return ret
end

#===============================================================================
# Months
#===============================================================================
def pbIsMonth(monVariable, *arg)
  timenow = pbGetTimeNow
  thismon = timenow.mon
  ret = false
  arg.each do |wd|
    ret = true if wd == thismon
  end
  if monVariable > 0
    $game_variables[monVariable] = pbGetMonthName(thismon)
    $game_map.need_refresh = true if $game_map
  end
  return ret
end

def pbGetMonthName(month)
  return [_INTL("Enero"),
          _INTL("Febrero"),
          _INTL("Marzo"),
          _INTL("Abril"),
          _INTL("Mayo"),
          _INTL("Junio"),
          _INTL("Julio"),
          _INTL("Agosto"),
          _INTL("September"),
          _INTL("Octubre"),
          _INTL("Noviembre"),
          _INTL("Diciembre")][month - 1]
end

def pbGetAbbrevMonthName(month)
  return [_INTL("Ene."),
          _INTL("Feb."),
          _INTL("Mar."),
          _INTL("Abr."),
          _INTL("May"),
          _INTL("Jun."),
          _INTL("Jul."),
          _INTL("Ago."),
          _INTL("Sep."),
          _INTL("Oct."),
          _INTL("Nov."),
          _INTL("Dic.")][month - 1]
end

#===============================================================================
# Seasons
#===============================================================================
def pbGetSeason
  return (pbGetTimeNow.mon - 1) % 4
end

def pbIsSeason(seasonVariable, *arg)
  thisseason = pbGetSeason
  ret = false
  arg.each do |wd|
    ret = true if wd == thisseason
  end
  if seasonVariable > 0
    $game_variables[seasonVariable] = [_INTL("Primavera"),
                                       _INTL("Verano"),
                                       _INTL("Otoño"),
                                       _INTL("Invierno")][thisseason]
    $game_map.need_refresh = true if $game_map
  end
  return ret
end

def pbIsSpring; return pbIsSeason(0, 0); end # Jan, May, Sep
def pbIsSummer; return pbIsSeason(0, 1); end # Feb, Jun, Oct
def pbIsAutumn; return pbIsSeason(0, 2); end # Mar, Jul, Nov
def pbIsFall; return pbIsAutumn; end
def pbIsWinter; return pbIsSeason(0, 3); end # Apr, Aug, Dec

def pbGetSeasonName(season)
  return [_INTL("Primavera"),
          _INTL("Verano"),
          _INTL("Otoño"),
          _INTL("Invierno")][season]
end

#===============================================================================
# Moon phases and Zodiac
#===============================================================================
# Calculates the phase of the moon. time is in UTC.
# 0 - New Moon
# 1 - Waxing Crescent
# 2 - First Quarter
# 3 - Waxing Gibbous
# 4 - Full Moon
# 5 - Waning Gibbous
# 6 - Last Quarter
# 7 - Waning Crescent
def moonphase(time = nil)
  time = pbGetTimeNow if !time
  transitions = [
    1.8456618033125,
    5.5369854099375,
    9.2283090165625,
    12.9196326231875,
    16.6109562298125,
    20.3022798364375,
    23.9936034430625,
    27.6849270496875
  ]
  yy = time.year - ((12 - time.mon) / 10.0).floor
  j = (365.25 * (4712 + yy)).floor + ((((time.mon + 9) % 12) * 30.6) + 0.5).floor + time.day + 59
  j -= (((yy / 100.0) + 49).floor * 0.75).floor - 38 if j > 2_299_160
  j += (((time.hour * 60) + (time.min * 60)) + time.sec) / 86_400.0
  v = (j - 2_451_550.1) / 29.530588853
  v = ((v - v.floor) + (v < 0 ? 1 : 0))
  ag = v * 29.53
  transitions.length.times do |i|
    return i if ag <= transitions[i]
  end
  return 0
end

# Calculates the zodiac sign based on the given month and day:
# 0 is Aries, 11 is Pisces. Month is 1 if January, and so on.
def zodiac(month, day)
  time = [
    3, 21, 4, 19,   # Aries
    4, 20, 5, 20,   # Taurus
    5, 21, 6, 20,   # Gemini
    6, 21, 7, 20,   # Cancer
    7, 23, 8, 22,   # Leo
    8, 23, 9, 22,   # Virgo
    9, 23, 10, 22,  # Libra
    10, 23, 11, 21, # Scorpio
    11, 22, 12, 21, # Sagittarius
    12, 22, 1, 19,  # Capricorn
    1, 20, 2, 18,   # Aquarius
    2, 19, 3, 20    # Pisces
  ]
  (time.length / 4).times do |i|
    return i if month == time[i * 4] && day >= time[(i * 4) + 1]
    return i if month == time[(i * 4) + 2] && day <= time[(i * 4) + 3]
  end
  return 0
end

# Returns the opposite of the given zodiac sign.
# 0 is Aries, 11 is Pisces.
def zodiacOpposite(sign)
  return (sign + 6) % 12
end

# 0 is Aries, 11 is Pisces.
def zodiacPartners(sign)
  return [(sign + 4) % 12, (sign + 8) % 12]
end

# 0 is Aries, 11 is Pisces.
def zodiacComplements(sign)
  return [(sign + 1) % 12, (sign + 11) % 12]
end

