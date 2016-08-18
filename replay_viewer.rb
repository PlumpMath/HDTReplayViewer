require 'json'
require 'pry'

file = File.open("replays/replay.json", "r")
replay_arr = JSON.parse(file.read, symbolize_names: true)

module HDT

  module Zone
    PLAY = 1
    DECK = 2
    HAND = 3
    SECRET,
    GRAVEYARD,
    SETASIDE,
    REMOVEDFROMGAME = nil
  end

  class Replay
    attr_reader :data, :timeline
    def initialize(arr)
      @data = arr
      @timeline = arr.map { |kp| State.new(kp) }
    end

    def turns
      @timeline.group_by {|state| state.turn}.map {|_, v| v}
    end

    def winner

    end

    def players

    end
  end

  class State

    attr_reader :turn, :entities

    def initialize(hash)
      @entities = hash[:Data].map {|entity| EntityGenerator.generate(entity, self)}
      @turn = hash[:Turn]
    end

    def entities_in_zone(zone)
      @entities.select {|entity| entity.zone == zone}
    end

    def entities_in_play
      entities_in_zone(Zone::PLAY)
    end

  end

  class Entity
    attr_reader :name, :zone, :id, :data
    def initialize(entity)
      @data = entity
      @info = entity[:Info]
      @id = entity[:Tags][:ENTITY_ID]
      @name = entity[:Name]
      @entity_name
      @zone = entity[:Tags][:ZONE]
    end

    def inspect
      @data[:Tags].to_s
    end
  end

  class Game < Entity
    attr_reader :turn
    def initialize(entity)
      @state = entity[:Tags][:STATE]
      @turn = entity[:Tags][:TURN]
      @attacker = entity[:Tags][:PROPOSED_ATTACKER]
      @defender = entity[:Tags][:PROPOSED_DEFENDER]
      super
    end

    def inspect
      "Turn: #{@turn}, Attacker: #{@attacker}, Defender: #{@defender}"
    end
  end

  class Player < Entity
    def initialize(entity)
      @max_hand_size = entity[:Tags][:MAXHANDSIZE]
      @start_hand_size = entity[:Tags][:STARTHANDSIZE]
      @player_id = entity[:Tags][:PLAYER_ID]
      @controller = entity[:Tags][:CONTROLLER]
      @max_resources = entity[:Tags][:MAXRESOURCES]
      @current_player = !!entity[:Tags][:CURRENT_PLAYER]
      @first_player = !!entity[:Tags][:FIRST_PLAYER]
      super
    end

    def inspect
      "Player: #{name}, ID: #{id}"
    end
  end

  class Hero < Entity
    def initialize(entity)
      @health = entity[:Tags][:HEALTH]
      @damage = entity[:Tags][:DAMAGE] || 0
      @controller = entity[:Tags][:CONTROLLER]
      @hero_type = entity[:CardId]
      super
    end

    def health
      @health - @damage
    end

    def inspect
      "Hero: #{@hero_type}, Health: #{@health}, ID: #{id}"
    end
  end

  class HeroPower < Entity
    def initialize(entity)
      @cost = entity[:Tags][:COST]
      @controller = entity[:Tags][:CONTROLLER]
      @creator = entity[:Tags][:CREATOR]
      @last_cost = entity[:Tags][:TAG_LAST_KNOWN_COST_IN_HAND]
      super
    end

    def inspect
      "Hero Power: #{@data[:CardId]}, ID: #{id}"
    end
  end

  class Card < Entity
    def initialize(entity)
      @card_id = entity[:CardId]
      @health = entity[:Tags][:HEALTH] || 0
      @damage = entity[:Tags][:DAMAGE] || 0
      super
    end

    def inspect
      "Card: #{@card_id}, Health: #{health}, ID: #{id}"
    end

    def health
      @health - @damage
    end
  end

  class EntityGenerator
    def self.generate(entity, state)
      case
      when entity[:Name] == "GameEntity"
        Game.new(entity)
      when entity[:Tags][:HERO_ENTITY]
        Player.new(entity)
      when entity[:Tags][:SHOWN_HERO_POWER]
        Hero.new(entity)
      when entity[:IsHeroPower]
        HeroPower.new(entity)
      when entity[:HasCardId]
        Card.new(entity)
      else
        Entity.new(entity)
      end
    end
  end

  class EntityOverTime
    attr_reader :points
    def initialize(replay, entity_id)
      @points = replay.timeline.map {|rpk| rpk.entities.find {|e| e.id == entity_id}}.flatten
    end
  end

end

replay = HDT::Replay.new(replay_arr)

puts replay
binding.pry