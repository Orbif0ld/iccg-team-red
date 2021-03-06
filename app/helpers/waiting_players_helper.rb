module WaitingPlayersHelper
  def game_for_current_user
    reader = Reader.where(user_id: current_user.id).joins(:game).where.not(games: {state: 'game_over'}).limit(1)
    guesser = Guesser.where(user_id: current_user.id).joins(:game).where.not(games: {state: 'game_over'}).limit(1)
    judge = Judge.where(user_id: current_user.id).joins(:game).where.not(games: {state: 'game_over'}).limit(1)
    game = reader[0] || guesser[0] || judge[0]
    @game = Game.find(game.game_id) unless game.nil?
  end
  
  def current_user_waiting?
    user = WaitingPlayer.find_by(user_id: current_user.id, active: true)
    return false if user.nil?
    user.user_id == current_user.id
  end
  
  def game_setup
    queue = WaitingPlayer.where(active: true).where.not(user_id: current_user.id).limit(2)
    if queue.count >= 2
      players = [current_user.id]
      queue.each {|x| players.push(x.user_id)}
      players.shuffle!
      document = get_free_document
      return nil if document.empty?
      @game = set_new_game(document.first, players)
      players.each {|x| WaitingPlayer.find_by(user_id: x).update_attributes(active: false) } if @game
      return @game
    else
      return nil
    end
  end

  def select_player_to_play
    WaitingPlayer.where(active: true).where.not(user_id: current_user.id).first.user_id
  end
  
  def get_free_document
    document = Document.left_outer_joins(:games).where(games: {document_id: nil}).limit(1)
    return document
  end
  
  def set_new_game(document, players)
    @game = Game.create(document_id: document.id)
    @game.setup(players[0], players[1], players[2]) if @game
    return @game
  end
end
