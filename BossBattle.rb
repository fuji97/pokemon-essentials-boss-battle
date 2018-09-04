################################################################################
# BOSS BATTLE
# For Pokèmon Essentials v17.2
# ######
# Version: 0.2 (2)
# Date: 04/09/2018
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
	
	alias :pbInitPokemonBb :pbInitPokemon
	def pbInitPokemon(pkmn,pkmnIndex)
		pbInitPokemonBb(pkmn,pkmnIndex)
		@boss = pkmn.boss
		@hpMultiplier = pkmn.hpMultiplier
		@bossBg = false #pkmn.bossBg
		@normalHp = pkmn.normalHp
		Log.v("BOSS", "Normal HP: #{@normalHp}")
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
		initializeBoss(battler,doublebattle,viewport)
		if @battler.boss
			@hpbar = AnimatedBitmap.new(_INTL("Graphics/Pictures/Battle/boss_hp"))
		end
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
    # Draw HP bar (boss)
		if @battler.boss
			hpgauge = (@battler.totalhp==0) ? 0 : gaugePercentage(self.hp) * @hpbar.bitmap.width
			hpgauge = 2 if hpgauge<2 && self.hp>0
			
			currentBar = (self.hp.to_f / (@battler.totalhp / @battler.hpMultiplier)).ceil - 1
			currentBar = currentBar < 0 ? 0 : currentBar
			# Draw next bar in BG
			#Log.v("BOSS","Draw bar n^ #{currentBar-1} [#{@battler.hp}/#{@battler.totalhp / @battler.hpMultiplier}] [#{@battler.totalhp} - #{@battler.hpMultiplier}]")
			if currentBar > 0
				self.bitmap.blt(@spritebaseX+102,40,@hpbar.bitmap,
					Rect.new(0,(currentBar-1)*HPBAR_HEIGHT,@hpbar.bitmap.width,HPBAR_HEIGHT),
					150)
			end	
			#~ if @animatingHP && self.hp>0   # fill with black (shows what the HP used to be)
				#~ self.bitmap.fill_rect(@spritebaseX+102,40,
					 #~ @starthp*@hpbar.bitmap.width/@battler.totalhp,@hpbar.bitmap.height/3,Color.new(0,0,0,100))
			#~ end
			Log.v("BOSS","hpgauge = #{hpgauge}")
			self.bitmap.blt(@spritebaseX+102,40,@hpbar.bitmap,
				Rect.new(0,(currentBar)*HPBAR_HEIGHT,hpgauge,HPBAR_HEIGHT))
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


#~ class PokeBattle_Battle
  #~ alias pbStartBattleCore_ebs pbStartBattleCore unless self.method_defined?(:pbStartBattleCore_ebs)
  #~ def pbStartBattleCore(canlose)
    #~ if !@fullparty1 && @party1.length > MAXPARTYSIZE
      #~ raise ArgumentError.new(_INTL("Party 1 has more than {1} Pokémon.",MAXPARTYSIZE))
    #~ end
    #~ if !@fullparty2 && @party2.length > MAXPARTYSIZE
      #~ raise ArgumentError.new(_INTL("Party 2 has more than {1} Pokémon.",MAXPARTYSIZE))
    #~ end
    #~ #$smAnim = false if ($smAnim && @doublebattle) || EBUISTYLE!=2
    #~ $smAnim = true if $game_switches[85] && !@doublebattle
    #~ if !@opponent
    #~ #========================
    #~ # Initialize wild Pokémon
    #~ #========================
      #~ if @party2.length==1
        #~ if @doublebattle
          #~ raise _INTL("Only two wild Pokémon are allowed in double battles")
        #~ end
        #~ wildpoke=@party2[0]
        #~ @battlers[1].pbInitialize(wildpoke,0,false)
        #~ @peer.pbOnEnteringBattle(self,wildpoke)
        #~ pbSetSeen(wildpoke)
        #~ @scene.pbStartBattle(self)
        #~ @scene.sendingOut=true
				#~ ###
				#~ if wildpoke.boss
					#~ pbDisplayPaused(_INTL("Prepare your anus! The Pokémon boss {1} wants to battle!",wildpoke.name))
          #~ @scene.vsBossSequence2_end
          #~ @scene.vsBossSequence2_sendout
        #~ else
					#~ pbDisplayPaused(_INTL("Wild {1} appeared!",wildpoke.name))
				#~ end
				#~ ###
      #~ elsif @party2.length==2
        #~ if !@doublebattle
          #~ raise _INTL("Only one wild Pokémon is allowed in single battles")
        #~ end
        #~ @battlers[1].pbInitialize(@party2[0],0,false)
        #~ @battlers[3].pbInitialize(@party2[1],0,false)
        #~ @peer.pbOnEnteringBattle(self,@party2[0])
        #~ @peer.pbOnEnteringBattle(self,@party2[1])
        #~ pbSetSeen(@party2[0])
        #~ pbSetSeen(@party2[1])
        #~ @scene.pbStartBattle(self)
        #~ pbDisplayPaused(_INTL("Wild {1} and\r\n{2} appeared!",
           #~ @party2[0].name,@party2[1].name))
      #~ else
        #~ raise _INTL("Only one or two wild Pokémon are allowed")
      #~ end
    #~ elsif @doublebattle
    #~ #=======================================
    #~ # Initialize opponents in double battles
    #~ #=======================================
      #~ if @opponent.is_a?(Array)
        #~ if @opponent.length==1
          #~ @opponent=@opponent[0]
        #~ elsif @opponent.length!=2
          #~ raise _INTL("Opponents with zero or more than two people are not allowed")
        #~ end
      #~ end
      #~ if @player.is_a?(Array)
        #~ if @player.length==1
          #~ @player=@player[0]
        #~ elsif @player.length!=2
          #~ raise _INTL("Player trainers with zero or more than two people are not allowed")
        #~ end
      #~ end
      #~ @scene.pbStartBattle(self)
      #~ @scene.sendingOut=true
      #~ if @opponent.is_a?(Array)
        #~ pbDisplayPaused(_INTL("{1} and {2} want to battle!",@opponent[0].fullname,@opponent[1].fullname))
        #~ sendout1=pbFindNextUnfainted(@party2,0,pbSecondPartyBegin(1))
        #~ raise _INTL("Opponent 1 has no unfainted Pokémon") if sendout1 < 0
        #~ sendout2=pbFindNextUnfainted(@party2,pbSecondPartyBegin(1))
        #~ raise _INTL("Opponent 2 has no unfainted Pokémon") if sendout2 < 0
        #~ @scene.vsSequenceSM_end if $smAnim
        #~ @battlers[1].pbInitialize(@party2[sendout1],sendout1,false)
        #~ @battlers[3].pbInitialize(@party2[sendout2],sendout2,false)
        #~ pbDisplayBrief(_INTL("{1} sent\r\nout {2}! {3} sent\r\nout {4}!",@opponent[0].fullname,getBattlerPokemon(@battlers[1]).name,@opponent[1].fullname,getBattlerPokemon(@battlers[3]).name))
        #~ pbSendOutInitial(@doublebattle,1,@party2[sendout1],3,@party2[sendout2])
      #~ else
        #~ pbDisplayPaused(_INTL("{1}\r\nvuole combattere!",@opponent.fullname))
        #~ sendout1=pbFindNextUnfainted(@party2,0)
        #~ sendout2=pbFindNextUnfainted(@party2,sendout1+1)
        #~ if sendout1 < 0 || sendout2 < 0
          #~ raise _INTL("Opponent doesn't have two unfainted Pokémon")
        #~ end
        #~ @scene.vsSequenceSM_end if $smAnim
        #~ @battlers[1].pbInitialize(@party2[sendout1],sendout1,false)
        #~ @battlers[3].pbInitialize(@party2[sendout2],sendout2,false)
        #~ pbDisplayBrief(_INTL("{1} sent\r\nout {2} and {3}!",
           #~ @opponent.fullname,getBattlerPokemon(@battlers[1]).name,getBattlerPokemon(@battlers[3]).name))
        #~ pbSendOutInitial(@doublebattle,1,@party2[sendout1],3,@party2[sendout2])
      #~ end
    #~ else
    #~ #======================================
    #~ # Initialize opponent in single battles
    #~ #======================================
      #~ sendout=pbFindNextUnfainted(@party2,0)
      #~ raise _INTL("Trainer has no unfainted Pokémon") if sendout < 0
      #~ if @opponent.is_a?(Array)
        #~ raise _INTL("Opponent trainer must be only one person in single battles") if @opponent.length!=1
        #~ @opponent=@opponent[0]
      #~ end
      #~ if @player.is_a?(Array)
        #~ raise _INTL("Player trainer must be only one person in single battles") if @player.length!=1
        #~ @player=@player[0]
      #~ end
      #~ trainerpoke=@party2[0]
      #~ @battlers[1].pbInitialize(trainerpoke,sendout,false)
      #~ @scene.pbStartBattle(self)
      #~ @scene.sendingOut=true
      #~ pbDisplayPaused(_INTL("{1}\r\nvuole combattere!",@opponent.fullname))
      #~ @scene.vsSequenceSM_end if $smAnim
      #~ pbDisplayBrief(_INTL("{1} sent\r\nout {2}!",@opponent.fullname,getBattlerPokemon(@battlers[1]).name))
      #~ pbSendOutInitial(@doublebattle,1,trainerpoke)
    #~ end
    #~ #=====================================
    #~ # Initialize players in double battles
    #~ #=====================================
    #~ if @doublebattle
      #~ @scene.sendingOut=true
      #~ if @player.is_a?(Array)
        #~ sendout1=pbFindNextUnfainted(@party1,0,pbSecondPartyBegin(0))
        #~ raise _INTL("Player 1 has no unfainted Pokémon") if sendout1 < 0
        #~ sendout2=pbFindNextUnfainted(@party1,pbSecondPartyBegin(0))
        #~ raise _INTL("Player 2 has no unfainted Pokémon") if sendout2 < 0
        #~ @battlers[0].pbInitialize(@party1[sendout1],sendout1,false)
        #~ @battlers[2].pbInitialize(@party1[sendout2],sendout2,false)
        #~ pbDisplayBrief(_INTL("{1} sent\r\nout {2}!  Go! {3}!",
           #~ @player[1].fullname,getBattlerPokemon(@battlers[2]).name,getBattlerPokemon(@battlers[0]).name))
        #~ pbSetSeen(@party1[sendout1])
        #~ pbSetSeen(@party1[sendout2])
      #~ else
        #~ sendout1=pbFindNextUnfainted(@party1,0)
        #~ sendout2=pbFindNextUnfainted(@party1,sendout1+1)
        #~ if sendout1 < 0 || sendout2 < 0
          #~ raise _INTL("Player doesn't have two unfainted Pokémon")
        #~ end
        #~ @battlers[0].pbInitialize(@party1[sendout1],sendout1,false)
        #~ @battlers[2].pbInitialize(@party1[sendout2],sendout2,false)
        #~ pbDisplayBrief(_INTL("Go! {1} and {2}!",getBattlerPokemon(@battlers[0]).name,getBattlerPokemon(@battlers[2]).name))
      #~ end
      #~ pbSendOutInitial(@doublebattle,0,@party1[sendout1],2,@party1[sendout2])
    #~ else
    #~ #====================================
    #~ # Initialize player in single battles
    #~ #====================================
      #~ @scene.sendingOut=true
      #~ sendout=pbFindNextUnfainted(@party1,0)
      #~ if sendout < 0
        #~ raise _INTL("Player has no unfainted Pokémon")
      #~ end
      #~ playerpoke=@party1[sendout]
      #~ @battlers[0].pbInitialize(playerpoke,sendout,false)
      #~ pbDisplayBrief(_INTL("Go! {1}!",getBattlerPokemon(@battlers[0]).name))
      #~ pbSendOutInitial(@doublebattle,0,playerpoke)
    #~ end
    #~ #==================
    #~ # Initialize battle
    #~ #==================
    #~ if @weather==PBWeather::SUNNYDAY
      #~ pbDisplay(_INTL("The sunlight is strong."))
    #~ elsif @weather==PBWeather::RAINDANCE
      #~ pbDisplay(_INTL("It is raining."))
    #~ elsif @weather==PBWeather::SANDSTORM
      #~ pbDisplay(_INTL("A sandstorm is raging."))
    #~ elsif @weather==PBWeather::HAIL
      #~ pbDisplay(_INTL("Hail is falling."))
    #~ elsif PBWeather.const_defined?(:HEAVYRAIN) && @weather==PBWeather::HEAVYRAIN
      #~ pbDisplay(_INTL("It is raining heavily."))
    #~ elsif PBWeather.const_defined?(:HARSHSUN) && @weather==PBWeather::HARSHSUN
      #~ pbDisplay(_INTL("The sunlight is extremely harsh."))
    #~ elsif PBWeather.const_defined?(:STRONGWINDS) && @weather==PBWeather::STRONGWINDS
      #~ pbDisplay(_INTL("The wind is strong."))
    #~ end
    #~ pbOnActiveAll   # Abilities
    #~ @turncount=0
    #~ loop do   # Now begin the battle loop
      #~ PBDebug.log("***Round #{@turncount+1}***") if $INTERNAL
      #~ if @debug && @turncount >=100
        #~ @decision=pbDecisionOnTime()
        #~ PBDebug.log("***[Undecided after 100 rounds]")
        #~ pbAbort
        #~ break
      #~ end
      #~ PBDebug.logonerr{
         #~ pbCommandPhase
      #~ }
      #~ break if @decision > 0
      #~ PBDebug.logonerr{
         #~ pbAttackPhase
      #~ }
      #~ break if @decision > 0
      #~ @scene.clearMessageWindow
      #~ PBDebug.logonerr{
         #~ pbEndOfRoundPhase
      #~ }
      #~ break if @decision > 0
      #~ @turncount+=1
    #~ end
    #~ return pbEndOfBattle(canlose)
  #~ end
#~ end

#~ class NextGenDataBox  <  SpriteWrapper
	#~ alias :initialize_bb :initialize
	#~ def initialize(battler,doublebattle,viewport=nil,player=nil,scene=nil,boss=true,bossMul=4)
		#~ initialize_bb(battler,doublebattle,viewport,player,scene)
		#~ @boss = @battler.boss
		#~ @bossMultiplier = @battler.hpMoltiplier
	#~ end
	
	#~ def setUp
    #~ # reset of the set-up procedure
    #~ @loaded = false
    #~ @showing = false
    #~ @second = false
    #~ pbDisposeSpriteHash(@sprites)
    #~ @sprites.clear
    #~ # initializes all the necessary components
		#~ @sprites["bg"] = Sprite.new(@viewport)
		#~ if @battler.boss && !@battler.bossBg.nil?
			#~ @sprites["bg"].bitmap = pbBitmap(@path+"bgs/"+@battler.bossBg)
		#~ end
		
    #~ @sprites["mega"] = Sprite.new(@viewport)
    #~ @sprites["mega"].opacity = 0
    
    #~ @sprites["gender"] = Sprite.new(@viewport)
    
    #~ @sprites["layer1"] = Sprite.new(@viewport)
    #~ @sprites["layer1"].bitmap = pbBitmap(@path+"layer1")
    #~ @sprites["layer1"].src_rect.height = 64 if !@showexp
    #~ @sprites["layer1"].mirror = !@playerpoke
    
    #~ @sprites["shadow"] = Sprite.new(@viewport)
    #~ @sprites["shadow"].bitmap = Bitmap.new(@sprites["layer1"].bitmap.width,@sprites["layer1"].bitmap.height)
    #~ @sprites["shadow"].z = -1
    #~ @sprites["shadow"].opacity = 255*0.25
    #~ @sprites["shadow"].color = Color.new(0,0,0,255)
    
		#~ if @boss
			#~ @hpBars = Array.new
			#~ echoln("#{@bossMultiplier-1}")
			#~ for i in 0...@bossMultiplier
				#~ @hpBars[i] = pbBitmap(@path+"bossBars/"+i.to_s)
			#~ end
			#~ @sprites["hp2"] = Sprite.new(@viewport)
			#~ @hpBarBmp = pbBitmap(@path+"hpBar")
			#~ @sprites["hp2"].bitmap = Bitmap.new(@hpBarBmp.width,@hpBarBmp.height)
			#~ @sprites["hp2"].mirror = !@playerpoke
			#~ @sprites["hp2"].opacity = 100
			
			#~ @sprites["hp"] = Sprite.new(@viewport)
			#~ @sprites["hp"].bitmap = Bitmap.new(@hpBarBmp.width,@hpBarBmp.height)
			#~ @sprites["hp"].mirror = !@playerpoke
			
			#~ @sprites["hp_point"] = BossArray.new
			#~ @pointsBitmap = Array.new
			#~ @noPointBitmap = pbBitmap(@path+"points/no")
			#~ for i in 0...@bossMultiplier-1
				#~ @pointsBitmap[i] = pbBitmap(@path+"points/"+i.to_s)
				#~ @sprites["hp_point"][i] = Sprite.new(@viewport)
				#~ @sprites["hp_point"][i].bitmap = Bitmap.new(@noPointBitmap.width,@noPointBitmap.height)
			#~ end
		#~ else
			#~ @sprites["hp"] = Sprite.new(@viewport)
			#~ @hpBarBmp = pbBitmap(@path+"hpBar")
			#~ @sprites["hp"].bitmap = Bitmap.new(@hpBarBmp.width,@hpBarBmp.height)
			#~ @sprites["hp"].mirror = !@playerpoke
		#~ end
    
    #~ @sprites["exp"] = Sprite.new(@viewport)
    #~ @sprites["exp"].bitmap = pbBitmap(@path+"expBar")
    #~ @sprites["exp"].src_rect.y = @sprites["exp"].bitmap.height*-1 if !@showexp
    
    #~ @sprites["text"] = Sprite.new(@viewport)
    #~ @sprites["text"].bitmap = Bitmap.new(@sprites["layer1"].bitmap.width,@sprites["layer1"].bitmap.height)
    #~ @sprites["text"].z = 9
    #~ pbSetSystemFont(@sprites["text"].bitmap)
    
    #~ #self.opacity = 255
  #~ end
	
	#~ def updateHpBar
		#~ if (@boss)
			#~ # updates the current state of the HP bar
			#~ # the bar's colour hue gets dynamically adjusted (i.e. not through sprites)
			#~ # HP bar is mirrored for opposing Pokemon
			#~ #hpbar = @battler.totalhp==0 ? 0 : (1.0*(self.hp % (@bossMultiplier-1)-1)*@sprites["hp"].bitmap.width/(@battler.totalhp / @bossMultiplier)).ceil
			#~ normalHp = (1.0 * @battler.totalhp / @bossMultiplier)
      #~ currHp = self.hp%normalHp==0 ? self.hp / @bossMultiplier : self.hp%normalHp
			#~ hpbar = @battler.totalhp==0 ? 0 : (1.0*currHp*@sprites["hp"].bitmap.width/normalHp).ceil
			#~ remainingPoints = (self.hp / normalHp).ceil.to_i - 1
			#~ #echoln("#{remainingPoints.to_s} - #{self.hp.to_s}/#{normalHp.to_s}")
			
			#~ @sprites["hp_point"].each_index do |i|
				#~ @sprites["hp_point"][i].bitmap.clear
				#~ if (remainingPoints > i)
					#~ #echoln("Remain: #{remainingPoints.to_s} - i: #{i.to_s} - #{@pointsBitmap[i].to_s}")
					#~ #echoln("Array: #{@pointsBitmap.inspect}")
					#~ @sprites["hp_point"][i].bitmap.blt(0,0,@pointsBitmap[i],Rect.new(0,0,@noPointBitmap.width,@noPointBitmap.height))
				#~ else
					#~ @sprites["hp_point"][i].bitmap.blt(0,0,@noPointBitmap,Rect.new(0,0,@noPointBitmap.width,@noPointBitmap.height))
				#~ end
			#~ end
			#~ @sprites["hp"].src_rect.x = @sprites["hp"].bitmap.width - hpbar if !@playerpoke
			#~ @sprites["hp"].src_rect.width = hpbar
			#~ hue = (0-120)*(1-(self.hp.to_f/@battler.totalhp))
			#~ @sprites["hp"].bitmap.clear
			#~ @sprites["hp"].bitmap.blt(0,0,@hpBars[remainingPoints],Rect.new(0,0,@hpBarBmp.width,@hpBarBmp.height))
			#~ # @sprites["hp"].bitmap.hue_change(hue)

			#~ # Set the bar bg (brutto)
			#~ if remainingPoints > 0
				#~ @sprites["hp2"].src_rect.x = @sprites["hp"].bitmap.width - 188 if !@playerpoke
				#~ @sprites["hp2"].src_rect.width = 188
				#~ @sprites["hp2"].bitmap.clear
				#~ @sprites["hp2"].bitmap.blt(0,0,@hpBars[remainingPoints-1],Rect.new(0,0,@hpBarBmp.width,@hpBarBmp.height))
				#~ @sprites["hp2"].visible = true
			#~ else
				#~ @sprites["hp2"].visible = false
			#~ end
		#~ else
			#~ # updates the current state of the HP bar
			#~ # the bar's colour hue gets dynamically adjusted (i.e. not through sprites)
			#~ # HP bar is mirrored for opposing Pokemon
			#~ hpbar = @battler.totalhp==0 ? 0 : (1.0*self.hp*@sprites["hp"].bitmap.width/@battler.totalhp).ceil
			#~ @sprites["hp"].src_rect.x = @sprites["hp"].bitmap.width - hpbar if !@playerpoke
			#~ @sprites["hp"].src_rect.width = hpbar
			#~ hue = (0-120)*(1-(self.hp.to_f/@battler.totalhp))
			#~ @sprites["hp"].bitmap.clear
			#~ @sprites["hp"].bitmap.blt(0,0,@hpBarBmp,Rect.new(0,0,@hpBarBmp.width,@hpBarBmp.height))
			#~ @sprites["hp"].bitmap.hue_change(hue)
		#~ end
  #~ end
	
	#~ alias :x_old :x=
	#~ def x=(val)
		#~ return if !@loaded
		#~ x_old(val)
		#~ if @boss
			#~ @sprites["bg"].x = @sprites["layer1"].x
			#~ @sprites["hp2"].x = @sprites["layer1"].x + 23 + (!@playerpoke ? 4 : 0)
			#~ @sprites["hp_point"].each_index do |i|
				#~ @sprites["hp_point"][i].x = @sprites["layer1"].x + 28 + (!@playerpoke ? 4 : 0) + (i * 18)
			#~ end
		#~ end
	#~ end
	
	#~ alias :y_old :y=
	#~ def y=(val)
		#~ return if !@loaded
		#~ y_old(val)
		#~ if @boss
			#~ @sprites["bg"].y = @sprites["layer1"].y
			#~ @sprites["hp2"].y = @sprites["layer1"].y + 50
			#~ @sprites["hp_point"].each_index do |i|
				#~ @sprites["hp_point"][i].y = @sprites["layer1"].y + 64
			#~ end
		#~ end
	#~ end
	
#~ end

def pbBossBattle(species, level, hpMultiplier, result=nil, escape=false, canlose=false)
	$BossMultiplier = hpMultiplier
	res = pbWildBattle(species, level, result, escape, canlose)
  return res
end

# Shortcut method to start boss battle
Events.onWildPokemonCreate += proc {|sender,e|
  pokemon=e[0]
  if $BossMultiplier > 0
    pokemon.setBoss($BossMultiplier,nil)
		Log.d("BOSS","HP totali: #{pokemon.totalhp}")
		$BossMultiplier = 0
  end

}