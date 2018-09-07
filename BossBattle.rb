################################################################################
# BOSS BATTLE
# For Pokèmon Essentials v17.2
# ######
# Version: 0.3 (3)
# Date: 07/09/2018
# Developer: Fuji97 (https://github.com/fuji97)
# Based on original code from Pokémon Xenoverse by WEEDle Team
# All rights reserved.
################################################################################

################################# REQUIREMENTS #################################
# Advanced Log
################################################################################

################################### SETTINGS ###################################
#
# HP bar height in pixels
HPBAR_HEIGHT = 6
#
# Dots width in pixels
DOTS_WIDTH = 14
# Space between dots
DOTS_SPACE = -2
#
################################################################################

$BossMultiplier = 0

class PokeBattle_Pokemon
	attr_accessor	:boss
	attr_accessor	:hpMultiplier
	attr_accessor	:bossBg
	attr_reader		:normalHp
	
	def setBoss(hpMultiplier,bossBg=nil)
		@boss = true
		@hpMultiplier = hpMultiplier
		@bossBg = bossBg
		calcStats
		Log.d("BOSS", "Set boss with hpMultiplier = #{hpMultiplier}")
	end
	
	alias :initializeBb :initialize
	def initialize(species,level,player=nil,withMoves=true)
		initializeBb(species,level,player,withMoves)
		@boss = false
		@hpMultiplier = 1
		@bossBg = nil
	end
	
	alias :calcStats_old :calcStats
	def calcStats
		# Keep track of current HP status
		hp = @hp
		diff = @totalhp - hp
		calcStats_old
		# Recalculate HP after the original calculation if it is a boss
		if @boss
      @normalHp = @totalhp
			@totalhp *= @hpMultiplier
			@hp=@totalhp-diff
			@hp=0 if @hp<=0
			@hp=@totalhp if @hp>@totalhp
		end
	end
  
  #~ def denyBoss
    #~ currHp = @hp
    #~ @boss = false
    #~ @hpMoltiplier = 0
    #~ @bossBg = nil
    #~ calcStats
    #~ @hp = currHp
  #~ end
  
  def canBeCaptured?
    return @hp <= @normalhp if @boss
  end
end

class PokeBattle_Battler
	attr_accessor	:boss
	attr_accessor	:hpMultiplier
	attr_accessor	:bossBg
	attr_reader		:normalHp
	
	alias :initializeBb :initialize
	def initialize(btl,index)
		initializeBb(btl,index)
		@boss = false
	end
	
	alias :pbInitPokemonBb :pbInitPokemon
	def pbInitPokemon(pkmn,pkmnIndex)
		pbInitPokemonBb(pkmn,pkmnIndex)
		Log.d("BOSS", "Called pbInitPokemon of PokeBattle_Battler [#{pkmn.boss.inspect}] for #{pkmn.name}")
		@boss = pkmn.boss
		@hpMultiplier = pkmn.hpMultiplier
		@bossBg = false #pkmn.bossBg
		@normalHp = pkmn.normalHp
	end
	
	def pbThis(lowercase=false)
    if @battle.pbIsOpposing?(@index)
      if @battle.opponent
        return lowercase ? _INTL("the opposing {1}",self.name) : _INTL("The opposing {1}",self.name)
			elsif @boss
				return lowercase ? _INTL("the boss {1}",self.name) : _INTL("The boss {1}",self.name)
      else
        return lowercase ? _INTL("the wild {1}",self.name) : _INTL("The wild {1}",self.name)
      end
    elsif @battle.pbOwnedByPlayer?(@index)
      return self.name
    else
      return lowercase ? _INTL("the ally {1}",self.name) : _INTL("The ally {1}",self.name)
    end
  end
end

class PokemonDataBox < SpriteWrapper
	def gaugePercentage(value)
		if value == 0
			return 0
		end
		
		res = value.to_f % (@battler.totalhp / @battler.hpMultiplier)
		if res == 0
			return 1
		else
			return res / (@battler.totalhp / @battler.hpMultiplier)
		end
	end
	
	alias :initializeBoss :initialize
	# Use boss_hp instead of overlay_hp if the pokemon is a boss
	def initialize(battler,doublebattle,viewport=nil)
		@hpdot = Bitmap.new("Graphics/Pictures/BossBattle/hp_dot")
		@hpbarBoss = Bitmap.new("Graphics/Pictures/BossBattle/boss_hp")
		initializeBoss(battler,doublebattle,viewport)
	end
	
	def refresh
    self.bitmap.clear
    return if !@battler.pokemon
    self.bitmap.blt(0,0,@databox.bitmap,Rect.new(0,0,@databox.width,@databox.height))
    base   = Color.new(72,72,72)
    shadow = Color.new(184,184,184)
    pbSetSystemFont(self.bitmap)
    textpos = []
    imagepos = []
    # Draw Pokémon's name
    textpos.push([@battler.name,@spritebaseX+8,6,false,base,shadow])
    # Draw Pokémon's gender symbol
    genderX = self.bitmap.text_size(@battler.name).width
    genderX += @spritebaseX+14
    case @battler.displayGender
    when 0 # Male
      textpos.push([_INTL("♂"),genderX,6,false,Color.new(48,96,216),shadow])
    when 1 # Female
      textpos.push([_INTL("♀"),genderX,6,false,Color.new(248,88,40),shadow])
    end
    pbDrawTextPositions(self.bitmap,textpos)
    # Draw Pokémon's level
    pbSetSmallFont(self.bitmap)
    imagepos.push(["Graphics/Pictures/Battle/overlay_lv",
       @spritebaseX+180-self.bitmap.text_size(@battler.level.to_s).width,16,0,0,-1,-1])
    textpos = [
       [@battler.level.to_s,@spritebaseX+202,8,true,base,shadow]
    ]
    # Draw Pokémon's HP numbers
    if @showhp
      hpstring = _ISPRINTF("{1: 2d}/{2: 2d}",self.hp,@battler.totalhp)
      textpos.push([hpstring,@spritebaseX+188,48,true,base,shadow])
    end
    pbDrawTextPositions(self.bitmap,textpos)
    # Draw shiny icon
    if @battler.isShiny?
      shinyX = ((@battler.index&1)==0) ? -6 : 206   # Player's/foe's
      imagepos.push(["Graphics/Pictures/shiny",@spritebaseX+shinyX,36,0,0,-1,-1])
    end
    # Draw Mega Evolution/Primal Reversion icon
    if @battler.isMega?
      imagepos.push(["Graphics/Pictures/Battle/icon_mega",@spritebaseX+8,34,0,0,-1,-1])
    elsif @battler.isPrimal?
      if isConst?(@battler.pokemon.species,PBSpecies,:KYOGRE)
        imagepos.push(["Graphics/Pictures/Battle/icon_primal_Kyogre",@spritebaseX+140,4,0,0,-1,-1])
      elsif isConst?(@battler.pokemon.species,PBSpecies,:GROUDON)
        imagepos.push(["Graphics/Pictures/Battle/icon_primal_Groudon",@spritebaseX+140,4,0,0,-1,-1])
      end
    end
    # Draw owned icon (foe Pokémon only)
    if @battler.owned && (@battler.index&1)==1
      imagepos.push(["Graphics/Pictures/Battle/icon_own",@spritebaseX+8,36,0,0,-1,-1])
    end
    # Draw status icon
    if @battler.status>0
      iconheight = 16
      self.bitmap.blt(@spritebaseX+24,36,@statuses.bitmap,
         Rect.new(0,(@battler.status-1)*iconheight,@statuses.bitmap.width,iconheight))
    end
		# ###
    # Draw HP bar (boss)
		# ###
		if @battler.boss
			hpgauge = (@battler.totalhp==0) ? 0 : gaugePercentage(self.hp) * @hpbarBoss.width
			hpgauge = 2 if hpgauge<2 && self.hp>0
			
			currentBar = (self.hp.to_f / (@battler.totalhp / @battler.hpMultiplier)).ceil - 1
			currentBar = currentBar < 0 ? 0 : currentBar
			# Draw next bar in BG
			#Log.v("BOSS","Draw bar n^ #{currentBar-1} [#{@battler.hp}/#{@battler.totalhp / @battler.hpMultiplier}] [#{@battler.totalhp} - #{@battler.hpMultiplier}]")
			if currentBar > 0
				self.bitmap.blt(@spritebaseX+102,40,@hpbarBoss,
					Rect.new(0,(currentBar-1)*HPBAR_HEIGHT,@hpbarBoss.width,HPBAR_HEIGHT),
					150)
			end	
			#~ if @animatingHP && self.hp>0   # fill with black (shows what the HP used to be)
				#~ self.bitmap.fill_rect(@spritebaseX+102,40,
					 #~ @starthp*@hpbar.bitmap.width/@battler.totalhp,@hpbar.bitmap.height/3,Color.new(0,0,0,100))
			#~ end
			Log.v("BOSS","hpgauge = #{hpgauge}")
			self.bitmap.blt(@spritebaseX+102,40,@hpbarBoss,
				Rect.new(0,currentBar*HPBAR_HEIGHT,hpgauge,HPBAR_HEIGHT))
			
			# Draw dots
			for i in 0..@battler.hpMultiplier-2
				Log.d("BOSS", "Draw dot number #{i}/#{@battler.hpMultiplier-2} [X: #{@spritebaseX+102+i*DOTS_WIDTH}]")
				self.bitmap.blt(@spritebaseX+72+i*(DOTS_WIDTH+DOTS_SPACE),48,@hpdot,
					i < currentBar ? Rect.new((i+1)*DOTS_WIDTH,0,DOTS_WIDTH,@hpdot.height) : Rect.new(0,0,DOTS_WIDTH,@hpdot.height))
			end
			
		else
			# Draw HP bar (not boss)
			hpgauge = (@battler.totalhp==0) ? 0 : self.hp*@hpbar.bitmap.width/@battler.totalhp
			hpgauge = 2 if hpgauge<2 && self.hp>0
			hpzone = 0
			hpzone = 1 if self.hp<=(@battler.totalhp/2).floor
			hpzone = 2 if self.hp<=(@battler.totalhp/4).floor
			if @animatingHP && self.hp>0   # fill with black (shows what the HP used to be)
				self.bitmap.fill_rect(@spritebaseX+102,40,
					 @starthp*@hpbar.bitmap.width/@battler.totalhp,@hpbar.bitmap.height/3,Color.new(0,0,0))
			end
			self.bitmap.blt(@spritebaseX+102,40,@hpbar.bitmap,
				 Rect.new(0,hpzone*@hpbar.bitmap.height/3,hpgauge,@hpbar.bitmap.height/3))
			# Draw Exp bar
			if @showexp
				self.bitmap.blt(@spritebaseX+6,76,@expbar.bitmap,
					 Rect.new(0,0,self.exp,@expbar.bitmap.height))
			end
			pbDrawImagePositions(self.bitmap,imagepos)
		end
		
    # Draw Exp bar
    if @showexp
      self.bitmap.blt(@spritebaseX+6,76,@expbar.bitmap,
         Rect.new(0,0,self.exp,@expbar.bitmap.height))
    end
    pbDrawImagePositions(self.bitmap,imagepos)
  end

	# Change the animation time of the HP bar on bosses
	def update
    super
    @frame = (@frame+1)%24
    # Animate HP bar
    if @animatingHP
			if @battler.boss
				if @currenthp<@endhp
					@currenthp += [1,(@battler.totalhp/(96*@battler.hpMultiplier*2) / @battler.hpMultiplier).floor].max
					@currenthp = @endhp if @currenthp>@endhp
				elsif @currenthp>@endhp
					@currenthp -= [1,(@battler.totalhp/(96*@battler.hpMultiplier*2) / @battler.hpMultiplier).floor].max
					@currenthp = @endhp if @currenthp<@endhp
				end
			else
				if @currenthp<@endhp
					@currenthp += [1,(@battler.totalhp/96).floor].max
					@currenthp = @endhp if @currenthp>@endhp
				elsif @currenthp>@endhp
					@currenthp -= [1,(@battler.totalhp/96).floor].max
					@currenthp = @endhp if @currenthp<@endhp
				end
			end
      @animatingHP = false if @currenthp==@endhp
      refresh
    end
		
    # Animate Exp bar
    if @animatingEXP
      if !@showexp
        @currentexp = @endexp
      elsif @currentexp<@endexp   # Gaining Exp
        if @endexp>=192 ||
           @endexp-@currentexp>=192/4
          @currentexp += 4
        else
          @currentexp += 2
        end
        @currentexp = @endexp if @currentexp>@endexp
      elsif @currentexp>@endexp   # Losing Exp
        if @endexp==0 ||
           @currentexp-@endexp>=192/4
          @currentexp -= 4
        elsif @currentexp>@endexp
          @currentexp -= 2
        end
        @currentexp = @endexp if @currentexp<@endexp
      end
      refresh
      if @currentexp==@endexp
        if @currentexp==192
          if @expflash==0
            pbSEPlay("Pkmn exp full")
            self.flash(Color.new(64,200,248),8)
            @expflash = 8
          else
            @expflash -= 1
            if @expflash==0
              @animatingEXP = false
              refreshExpLevel
            end
          end
        else
          @animatingEXP = false
        end
      end
    end
    # Move data box onto the screen
    if @appearing
      if (@battler.index&1)==0 # if player's Pokémon
        self.x -= 12
        self.x = @spriteX if self.x<@spriteX
        @appearing = false if self.x<=@spriteX
      else
        self.x += 12
        self.x = @spriteX if self.x>@spriteX
        @appearing = false if self.x>=@spriteX
      end
      self.y = @spriteY
      return
    end
    self.x = @spriteX
    self.y = @spriteY
    # Data box bobbing while Pokémon is selected
    if @selected==1 || @selected==2   # Choosing commands/targeted or damaged
      if (@frame/6).floor==1
        self.y = @spriteY-2
      elsif (@frame/6).floor==3
        self.y = @spriteY+2
      end
    end
  end

end

# Shortcut method to start boss battle
def pbBossBattle(species, level, hpMultiplier, result=nil, escape=false, canlose=false)
	$BossMultiplier = hpMultiplier
	res = pbWildBattle(species, level, result, escape, canlose)
  return res
end

Events.onWildPokemonCreate += proc {|sender,e|
  pokemon=e[0]
  if $BossMultiplier > 0
    pokemon.setBoss($BossMultiplier,nil)
		Log.d("BOSS","HP totali: #{pokemon.totalhp}")
		$BossMultiplier = 0
  end
}