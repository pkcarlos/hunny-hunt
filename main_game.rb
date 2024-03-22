require 'yaml'
DIALOGUE = YAML.load_file('ttt.yml')
ROUNDS_TO_WIN = 2

module Displayable
  def dialogue(msg)
    DIALOGUE[msg]
  end

  def display_welcome_message
    clear
    prompt "Welcome to Pooh's Hunny Hunt: Tic-Tac-Toe in the Hundred Acre Wood!"
    prompt ""
  end

  # rubocop:disable Layout/LineLength
  def display_opening
    prompt dialogue('opening')
    prompt "POOH:"
    prompt "Oh, look, #{human.name}. There's #{computer.name}. Just the friend I was looking for."
    prompt "#{computer.name} has agreed to lead us to the hunny if we play a game."
    prompt ""
    prompt "#{computer.name.upcase}:"
    prompt dialogue('dialogue')
  end
  # rubocop:enable Layout/LineLength

  def display_rules(input)
    clear
    prompt dialogue('rules') if input == 'y'
  end

  def display_goodbye_message
    clear
    prompt dialogue('goodbye')
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  # rubocop:disable Metrics/AbcSize
  def display_board(clear_brd = true)
    clear if clear_brd
    prompt "#{human.name}'s marker: #{human.marker}"
    prompt "#{computer.name}'s marker: #{computer.marker}"
    prompt ""
    prompt "#{human.name}'s winning rounds: #{human.wins}"
    prompt "#{computer.name}'s winning rounds: #{computer.wins}"
    prompt "You need #{ROUNDS_TO_WIN} wins to get to the hunny!"
    prompt ""
    board.draw
    prompt ""
  end
  # rubocop:enable Metrics/AbcSize

  def display_start_play
    clear
    prompt "#{computer.name.upcase}:"
    prompt "Let's play!"
    prompt "If you win #{ROUNDS_TO_WIN} rounds, I'll take you to the hunny!"
    prompt ""
  end

  def display_first_player
    if first_player == human.marker
      prompt "You go first!"
    else
      prompt "#{computer.name} goes first!"
    end
    pause
  end

  def display_result
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker
      prompt "You won!"
    when computer.marker
      prompt "#{computer.name} won!"
    else
      prompt "It's a tie!"
    end
  end

  def display_overall_winner
    pause
    clear
    if human.wins == ROUNDS_TO_WIN
      prompt "Hooray! You won #{ROUNDS_TO_WIN} rounds!"
      prompt "Straight to the hunny we go!"
      prompt dialogue('honeypot')
    else
      prompt dialogue('lose')
    end
  end

  def display_play_again_msg
    prompt "Splendid! Let's play again!"
    pause
  end
end

module Formatable
  def clear
    system("clear")
  end

  def prompt(msg)
    puts msg
  end

  def pause
    sleep(2)
  end

  def joinor(arr, delimiter1=', ', delimiter2="or")
    case arr.size
    when 1 then arr.first
    when 2 then arr.join(' or ')
    else
      last_el = arr.pop
      arr.join(delimiter1).to_s + ' ' + delimiter2 + ' ' + last_el.to_s
    end
  end
end

class Board # board state
  include Formatable
  attr_reader :squares

  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] +
                  [[1, 5, 9], [3, 5, 7]]

  def initialize
    @squares = {} # current board state
    reset
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def draw
    prompt ""
    prompt "[1]    |[2]     |[3]"
    prompt "       |        |   "
    prompt "   #{@squares[1]}   |   #{@squares[2]}    |   #{@squares[3]}"
    prompt "       |        |"
    prompt "-------+--------+------"
    prompt "[4]    |[5]     |[6]"
    prompt "       |        |"
    prompt "   #{@squares[4]}   |   #{@squares[5]}    |   #{@squares[6]}"
    prompt "       |        |"
    prompt "-------+--------+-------"
    prompt "[7]    |[8]     |[9]"
    prompt "       |        |"
    prompt "   #{@squares[7]}   |   #{@squares[8]}    |   #{@squares[9]}"
    prompt "       |        |"
    prompt ""
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def []=(num, marker)
    @squares[num].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != 3
    markers.min == markers.max
  end
end

class Square # square state
  INITIAL_MARKER = ' '

  attr_accessor :marker

  def initialize(marker=INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end
end

class Player
  include Displayable
  include Formatable

  attr_accessor :marker, :name, :wins

  def initialize
    @wins = 0
  end
end

class Human < Player
  def set_name
    input = nil
    prompt "What is your name?"
    loop do
      input = gets.chomp.upcase
      clear
      break unless input.empty? || input.squeeze == ' '
      prompt "Whoopsie. Please try again."
    end

    self.name = input
  end

  def appoint_marker
    input = nil
    loop do
      prompt "Choose a marker from A to Z."
      input = gets.chomp.upcase
      clear
      break if ('A'..'Z').to_a.include?(input)
      clear
      prompt "Whoops. Try again."
    end
    self.marker = input
  end
end

class Computer < Player
  attr_accessor :difficulty

  def set_name
    self.name = ['Christopher Robin', 'Piglet', 'Tigger', 'Eeyore', 'Kanga', 'Roo', 'Owl'].sample
  end

  def appoint_marker(human_marker)
    self.marker = if human_marker == "O"
                    (('A'..'Z').to_a - [human_marker]).sample
                  else
                    "O"
                  end
  end
end

class TTTGame
  include Displayable
  include Formatable

  attr_reader :board, :human, :computer
  attr_accessor :first_player, :current_marker

  def initialize
    @board = Board.new
    @human = Human.new
    @computer = Computer.new
  end

  def play
    game_setup
    main_game
    display_goodbye_message
  end

  private

  def main_game
    loop do
      game_play
      display_overall_winner
      break unless play_again?
      reset_main_game
    end
  end

  def game_play
    loop do
      display_board
      player_move
      store_result!
      display_result
      break if human.wins == ROUNDS_TO_WIN || computer.wins == ROUNDS_TO_WIN
      pause
      reset_board!
    end
  end

  def reset_main_game
    display_play_again_msg
    reset_board!
    reset_wins!
    choose_difficulty
  end

  def game_setup
    display_welcome_message
    set_player_names
    display_opening
    prompt_rules
    choose_difficulty
    display_start_play
    set_player_markers
    choose_first_player
    display_first_player
  end

  def set_player_names # this seems unnecessary if only to appease rubocop
    human.set_name
    computer.set_name
  end

  def set_player_markers # same as above (?)
    human.appoint_marker
    computer.appoint_marker(human.marker)
  end

  def prompt_rules
    input = nil
    loop do
      prompt "Would you like to know the rules? (y/n)"
      input = gets.chomp.downcase
      break if %w(y n).include?(input)
      clear
      prompt "Sorry, I didn't quite catch that."
    end

    display_rules(input)
  end

  def choose_difficulty
    input = nil
    prompt "#{computer.name}:"
    prompt "I've become quite good at this game."
    loop do
      prompt dialogue('difficulty')
      input = gets.to_i
      clear
      break if [1, 2].include?(input)
      prompt "Sorry, I didn't quite catch that."
    end

    computer.difficulty = input
  end

  def easy_gameplay
    board[board.unmarked_keys.sample] = computer.marker
  end

  def hard_gameplay
    if offensive_square?
      offensive_move
    elsif defensive_square?
      defensive_move
    elsif board.squares[5].marker == ' '
      board[5] = computer.marker
    else
      board[board.unmarked_keys.sample] = computer.marker
    end
  end

  def who_goes_first(input)
    case input
    when 1 then self.first_player = human.marker
    when 2 then self.first_player = computer.marker
    when 3 then self.first_player = [human.marker, computer.marker].sample
    end

    self.current_marker = first_player
  end

  # rubocop:disable Metrics/MethodLength
  def choose_first_player
    input = nil
    loop do
      prompt "You're playing against #{computer.name}."
      prompt "You'll take turns going first."
      prompt "Who is going first?"
      prompt "[1] - You"
      prompt "[2] - #{computer.name}"
      prompt "[3] - Choose for me!"
      input = gets.to_i
      break if [1, 2, 3].include?(input)
      clear
      prompt "Whoops. Please try again."
    end

    who_goes_first(input)
  end
  # rubocop:enable Metrics/MethodLength

  def current_player_moves
    if human_turn?
      human_moves
      @current_marker = computer.marker
    else
      computer_moves
      @current_marker = human.marker
    end
  end

  def human_turn?
    @current_marker == human.marker
  end

  def player_move
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      clear_screen_and_display_board if human_turn?
    end
  end

  def human_moves
    square = nil
    prompt "Your turn."
    loop do
      prompt "Choose a square (#{joinor(board.unmarked_keys, ', ')}):"
      square = gets.to_i
      clear_screen_and_display_board
      break if board.unmarked_keys.include?(square)
      prompt "Oh dear, please pick again."
    end

    board[square] = human.marker
    display_board
  end

  def computer_moves
    prompt "#{computer.name}'s turn."
    pause

    computer.difficulty == 1 ? easy_gameplay : hard_gameplay
  end

  def offensive_square?
    Board::WINNING_LINES.each do |line|
      return true if two_computer_markers?(line) && empty_space?(line)
    end

    false
  end

  def two_human_markers?(line)
    board.squares.values_at(*line).map(&:marker).count(human.marker) == 2
  end

  def two_computer_markers?(line)
    board.squares.values_at(*line).map(&:marker).count(computer.marker) == 2
  end

  def empty_space?(line)
    board.squares.values_at(*line).map(&:marker).include?(' ')
  end

  def defensive_square?
    Board::WINNING_LINES.each do |line| # array
      return true if two_human_markers?(line) && empty_space?(line)
    end

    false
  end

  def defensive_move
    move_options = []
    Board::WINNING_LINES.each do |line|
      if two_human_markers?(line) && empty_space?(line)
        defensive_sq = line.select { |key| board.squares[key].marker == ' ' }[0]
        move_options << defensive_sq
      end
    end

    board[move_options.sample] = computer.marker
  end

  def offensive_move
    move_options = []
    Board::WINNING_LINES.each do |line|
      if two_computer_markers?(line) && empty_space?(line)
        offensive_sq = line.select { |key| board.squares[key].marker == ' ' }[0]
        move_options << offensive_sq
      end
    end

    board[move_options.sample] = computer.marker
  end

  def store_result!
    case board.winning_marker
    when human.marker then human.wins += 1
    when computer.marker then computer.wins += 1
    end
  end

  def reset_board!
    board.reset
    clear
  end

  def reset_wins!
    human.wins = 0
    computer.wins = 0
  end

  def play_again?
    answer = nil
    loop do
      prompt "Would you like to play again (y/n)?"
      answer = gets.chomp.downcase
      break if %w(y n).include?(answer)
      clear
      prompt "I didn't quite catch that."
    end

    clear
    answer == 'y'
  end
end

TTTGame.new.play
