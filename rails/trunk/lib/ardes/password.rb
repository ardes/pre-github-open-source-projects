module Ardes
  class Password
    
    VOWEL = 0
    CONSONANT = 1
    
    def self.generate
      Password.new.generate
    end
    
    def initialize
      @vowels = %w(a e i o u y 3 4)
      @consonants = ('a'..'z').to_a - @vowels
      @consonants.delete('l')
      @consonants << '7' << '9' << '5'
    end

    def generate
      password = ''
      while (password.length < 10) do
        password += generate_phrase
      end
      password
    end
      
    def generate_phrase
      phrase = ''
      @last = VOWEL
      (2 + rand(3)).times do
        phrase += generate_letter
      end
      phrase.capitalize
    end
    
    def generate_letter
      case (@last)
        when VOWEL
          case rand(10)
            when 0..7:  random_consonant
            when 8..9:  random_vowel
          end
        
        when CONSONANT
          case rand(10)
            when 0:     random_consonant
            when 1..9:  random_vowel
          end
      end
    end
    
    def random_consonant
      @last = CONSONANT
      @consonants[rand(@consonants.size)]
    end
    
    def random_vowel
      @last = VOWEL
      @vowels[rand(@vowels.size)]
    end
  end
end