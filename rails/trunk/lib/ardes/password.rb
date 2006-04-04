module Ardes
  class Password
    
    VOWEL = 0
    CONSONANT = 1
    
    def self.generate
      Password.new.generate
    end
    
    def initialize
      @vowels = %w(a e i o u)
      @consonants = ('a'..'z').to_a - @vowels
      @consonants -= ['l', 'k', 'q', 'z', 'y', 'x']
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
        when VOWEL: random_consonant
        when CONSONANT: random_vowel
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