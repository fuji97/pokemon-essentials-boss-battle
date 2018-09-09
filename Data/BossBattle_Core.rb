################################################################################
# BOSS BATTLE - CORE
# For Pokèmon Essentials v17.2
# ######
# Version: 1.0 (5)
# Date: 09/09/2018
# Developer: Fuji97 (https://github.com/fuji97)
# Based on original code from Pokémon Xenoverse by WEEDle Team
# All rights reserved.
################################################################################

################################# REQUIREMENTS #################################
# Advanced Log
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
		@boss = pkmn.boss
		@hpMultiplier = pkmn.hpMultiplier
		@bossBg = nil #pkmn.bossBg
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