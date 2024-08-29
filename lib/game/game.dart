import 'package:sorcerers_core/change_notifier.dart';
import 'package:sorcerers_core/online/messages/game_messages_client.dart';

import 'cards.dart';

const lobbyMinNumberOfPlayers = 2; // TODO 3

class Deck {
  final List<GameCard> cards;

  static int get size =>
      NumberCard.highest * CardColor.values.length + numberOfWizardCards + numberOfJesterCards;
  static int numberOfWizardCards = 4;
  static int numberOfJesterCards = 4;

  Deck() : cards = generateCards();

  static List<GameCard> generateCards() {
    var cardId = 0;

    final cards = [
      for (final color in CardColor.values)
        for (var i = 1; i <= NumberCard.highest; i++) NumberCard(cardId++, i, color),
      for (var i = 0; i < numberOfWizardCards; i++) WizardCard(cardId++),
      for (var i = 0; i < numberOfJesterCards; i++) JesterCard(cardId++),
    ];
    cards.shuffle();
    return cards;
  }
}

class Player extends PlayerState {
  Player(String id, String name) : super(id, name, {});

  GameCard playCard(CardId cardId) {
    return hand.remove(cardId)!;
  }

  void drawCard(GameCard card) {
    hand[card.cardId] = card;
  }

  void clearHand() {
    hand.clear();
  }
}

class CardOnTable {
  final Player player;
  final GameCard card;

  CardOnTable(this.player, this.card);
}

class Game with ChangeNotifier {
  Game(this.players) : initialPlayerIndex = 0 {
    startNewRound(incrementRound: false);
  }

  final List<Player> players;
  final int initialPlayerIndex;
  late int roundStartPlayerIndex = initialPlayerIndex;
  final GameScore gameScore = GameScore();
  int get totalRoundsCount => (Deck.size / players.length).floor();
  bool get finished => gameScore.length >= totalRoundsCount;

  // Round
  int roundNumber = 0;
  int get cardsForRound => roundNumber + 1;
  Deck? deck;
  Map<Player, RoundScore> roundScores = {};
  RoundStage roundStage = RoundStage.shuffle;

  // Trick
  final List<CardOnTable> cardsOnTable = [];
  int get trickNumber => cardsOnTable.length;
  late int currentPlayerIndex;
  Player get currentPlayer => players[currentPlayerIndex];

  GameCard? trump;
  CardColor? trumpColor;

  CardColor? get leadColor {
    for (final cardOnTable in cardsOnTable) {
      final card = cardOnTable.card;
      switch (card) {
        case NumberCard():
          return card.color;
        case WizardCard():
          return trumpColor;
        case JesterCard():
          continue; // Is defined by the next card
      }
    }
    return null;
  }

  void startNewRound({required bool incrementRound}) {
    if (incrementRound) {
      if (roundStage != RoundStage.finished) {
        throw Exception("Round not finished");
      }

      gameScore.addRound(roundNumber, roundScores);

      if (roundNumber < totalRoundsCount) {
        roundNumber += 1;
      }
    }

    cardsOnTable.clear();
    roundStartPlayerIndex = (initialPlayerIndex + roundNumber) % players.length;
    currentPlayerIndex = roundStartPlayerIndex;

    roundScores = {};
    roundStage = RoundStage.shuffle;
    notifyListeners();
  }

  void shuffleAndGiveCards() {
    final deck = Deck();

    for (final player in players) {
      player.clearHand();
      for (var i = 0; i < cardsForRound; i++) {
        player.drawCard(deck.cards.removeLast());
      }
    }

    roundStage = RoundStage.bidding;

    final trump = deck.cards.removeLast();
    switch (trump) {
      case NumberCard():
        trumpColor = trump.color;
      case WizardCard():
        roundStage = RoundStage.mustChooseTrumpColor;
      case JesterCard():
        trumpColor = null; // No trump color for this round
    }
    this.trump = trump;

    this.deck = deck;
    _nextPlayer();
    roundStartPlayerIndex = currentPlayerIndex;

    notifyListeners();
  }

  void setTrumpColor(CardColor color) {
    if (roundStage != RoundStage.mustChooseTrumpColor) {
      throw Exception("Not in the mustChooseTrumpColor stage");
    }

    trumpColor = color;
    roundStage = RoundStage.bidding;

    notifyListeners();
  }

  void setBid(PlayerId playerId, int bid) {
    if (roundStage != RoundStage.bidding) {
      throw Exception("Not in the bidding stage");
    }

    if (playerId != currentPlayer.id) {
      throw Exception("Not the player's turn");
    }

    roundScores[currentPlayer] = RoundScore(currentPlayer.id, bid);

    if (roundScores.length == players.length) {
      roundStage = RoundStage.playing;
      currentPlayerIndex = roundStartPlayerIndex;
    } else {
      _nextPlayer();
    }

    notifyListeners();
  }

  void playCard(PlayerId playerId, int cardId) {
    if (roundStage != RoundStage.playing) {
      throw Exception("Not in the playing stage");
    }

    if (playerId != currentPlayer.id) {
      throw Exception("Not the player's turn");
    }

    if (!currentPlayer.hand.containsKey(cardId)) {
      throw Exception("Player doesn't have this card");
    }

    final card = currentPlayer.playCard(cardId);
    cardsOnTable.add(CardOnTable(currentPlayer, card));

    if (cardsOnTable.length == players.length) {
      // End of the trick
      final Player winner = getTrickWinner()!;
      roundScores[winner]!.wonTrick();
      currentPlayerIndex = players.indexOf(winner);
    } else {
      _nextPlayer();
    }

    if (players.every((player) => player.hand.isEmpty)) {
      // End of the round
      roundStage = RoundStage.finished;
    }

    notifyListeners();
  }

  Player? getTrickWinner() {
    if (cardsOnTable.length < players.length) {
      return null;
    }
    return getStrongestCard()?.player;
  }

  CardOnTable? getStrongestCard() {
    CardOnTable? winningCard;
    for (final cardOnTable in cardsOnTable) {
      if (winningCard == null) {
        winningCard = cardOnTable;
      } else {
        final card = cardOnTable.card;
        if (card.beats(winningCard.card, trumpColor, leadColor)) {
          winningCard = cardOnTable;
        }
      }
    }
    return winningCard;
  }

  void readyForNextTrick() {
    // TODO everyone has to be ready
    cardsOnTable.clear();
    notifyListeners();
  }

  void stop() {
    // TODO
  }

  GameState toState(PlayerId me) {
    return GameState(
      Map.fromEntries(
        players
            .map((player) => MapEntry(player.id, PlayerState(player.id, player.name, player.hand))),
      ),
      roundNumber,
      gameScore,
      roundStage,
      cardsOnTable
          .map((cardOnTable) => CardOnTableState(cardOnTable.player.id, cardOnTable.card))
          .toList(),
      me,
      currentPlayer.id,
      trump,
      trumpColor,
      leadColor,
      roundScores.map((player, v) => MapEntry(player.id, v)),
    );
  }

  void _nextPlayer() => currentPlayerIndex = (currentPlayerIndex + 1) % players.length;

  void onMessage({required PlayerId fromPlayerId, required GameMessageClient message}) {
    var _ = switch (message) {
      PlayCard() => playCard(fromPlayerId, message.cardId),
      StartNewRound() => startNewRound(incrementRound: true),
      ShuffleDeck() => shuffleAndGiveCards(),
      SetTrumpColor() => setTrumpColor(message.color),
      SetBid() => setBid(fromPlayerId, message.bid),
      ReadyForNextTrick() => readyForNextTrick(),
      LeaveGame() => stop(),
    };
  }
}

class GameScore {
  final Map<int, Map<PlayerId, RoundScore>> _scores;

  GameScore({Map<int, Map<PlayerId, RoundScore>>? scores}) : _scores = scores ?? {};

  int get length => _scores.length;

  void addRound(int roundNumber, Map<Player, RoundScore> scores) {
    _scores[roundNumber] = scores.map((player, score) => MapEntry(player.id, score));
  }

  int getTotalPointsFor(PlayerId playerId) {
    int result = 0;
    _scores.forEach((i, scores) => result += scores[playerId]!.getPoints());
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      "scores": _scores.map((key, value) => MapEntry(
            key.toString(),
            value.map((key, value) => MapEntry(
                  key,
                  value.toJson(),
                )),
          )),
    };
  }

  static GameScore fromJson(Map<String, dynamic> map) {
    final scores = map["scores"];
    if (scores == null || scores is! Map<String, dynamic>) {
      return GameScore();
    }

    final scoreMap = <int, Map<PlayerId, RoundScore>>{};
    scores.forEach((key, value) {
      if (value is! Map<String, dynamic>) {
        return;
      }

      final roundScores = <PlayerId, RoundScore>{};
      value.forEach((key, value) {
        if (value is! Map<String, dynamic>) {
          return;
        }

        final score = RoundScore.fromJson(value)!;
        roundScores[score.playerId] = score;
      });

      scoreMap[int.parse(key)] = roundScores;
    });

    return GameScore(scores: scoreMap);
  }
}

enum RoundStage {
  shuffle,
  mustChooseTrumpColor,
  bidding,
  playing,
  finished,
}

class RoundScore {
  final PlayerId playerId;
  final int bid;

  RoundScore(this.playerId, this.bid, {this.currentScore = 0});

  int currentScore;

  void wonTrick() {
    currentScore += 1;
  }

  int getPoints() {
    if (currentScore == bid) {
      return 20 + currentScore * 10;
    } else {
      return -10 * (currentScore - bid).abs();
    }
  }

  static RoundScore? fromJson(Map<String, dynamic> map) {
    final playerId = map["playerId"];
    final bid = map["bid"];
    final currentScore = map["currentScore"];
    if (playerId == null || bid == null || currentScore == null) {
      return null;
    }

    return RoundScore(playerId, bid, currentScore: currentScore);
  }

  Map<String, dynamic> toJson() {
    return {
      "playerId": playerId,
      "bid": bid,
      "currentScore": currentScore,
    };
  }
}

typedef PlayerId = String;

class PlayerState {
  final PlayerId id;
  final String name;
  final Map<CardId, GameCard> hand;

  PlayerState(this.id, this.name, this.hand);

  bool canPlayCard(GameCard card, CardColor? leadColor) {
    if (leadColor == null || card.canBePlayed(leadColor)) {
      // If there is no lead color, any card can be played
      return true;
    } else {
      // If the player has no card of the lead color, they can play any card
      final hasLeadColorCard =
          hand.values.any((handCard) => handCard is NumberCard && handCard.color == leadColor);
      return !hasLeadColorCard;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "hand": hand.values.map((card) => card.toJson()).toList(),
    };
  }

  static PlayerState fromJson(Map<String, dynamic> map) {
    return PlayerState(
      map["id"] as String,
      map["name"] as String,
      Map.fromEntries((map["hand"] as List<dynamic>).map((map) {
        final card = GameCard.fromJson(map);
        return MapEntry(card.cardId, card);
      })),
    );
  }
}

class CardOnTableState {
  final PlayerId playerId;
  final GameCard card;

  CardOnTableState(this.playerId, this.card);

  Map<String, dynamic> toJson() {
    return {
      "playerId": playerId,
      "card": card.toJson(),
    };
  }
}

/// Game state is always from the perspective of [myPlayerId]
class GameState {
  final bool isLoading;
  final Map<PlayerId, PlayerState> players;
  final int roundNumber;
  int get cardsForRound => roundNumber + 1;
  final GameScore gameScore;

  final PlayerId myPlayerId;
  final PlayerId currentPlayerId;
  final RoundStage roundStage;
  final List<CardOnTableState> cardsOnTable;
  final GameCard? trump;
  final CardColor? trumpColor;
  final CardColor? leadColor;
  final Map<PlayerId, RoundScore?> roundScores;

  GameState(
    this.players,
    this.roundNumber,
    this.gameScore,
    this.roundStage,
    this.cardsOnTable,
    this.myPlayerId,
    this.currentPlayerId,
    this.trump,
    this.trumpColor,
    this.leadColor,
    this.roundScores, {
    this.isLoading = false,
  });

  static GameState loading() {
    return GameState(
      {"": PlayerState("", "", {})},
      0,
      GameScore(),
      RoundStage.bidding,
      [],
      "",
      "",
      null,
      null,
      null,
      {},
      isLoading: true,
    );
  }

  PlayerId? getTrickWinner() {
    if (cardsOnTable.length < players.length) {
      return null;
    }
    return getStrongestCard()?.playerId;
  }

  CardOnTableState? getStrongestCard() {
    CardOnTableState? winningCard;
    for (final cardOnTable in cardsOnTable) {
      if (winningCard == null) {
        winningCard = cardOnTable;
      } else {
        final card = cardOnTable.card;
        if (card.beats(winningCard.card, trumpColor, leadColor)) {
          winningCard = cardOnTable;
        }
      }
    }
    return winningCard;
  }

  Map<String, dynamic> toJson() {
    return {
      "players": players.values.map((playerState) => playerState.toJson()).toList(),
      "roundNumber": roundNumber,
      "gameScore": gameScore.toJson(),
      "roundStage": roundStage.name,
      "cardsOnTable": cardsOnTable.map((cardOnTable) => cardOnTable.toJson()).toList(),
      "myPlayerId": myPlayerId,
      "currentPlayerId": currentPlayerId,
      "trump": trump?.toJson(),
      "trumpColor": trumpColor?.name,
      "leadColor": leadColor?.name,
      "roundScores":
          roundScores.map((playerId, roundScore) => MapEntry(playerId, roundScore?.toJson())),
    };
  }

  static GameState fromJson(Map<String, dynamic> gameState) {
    return GameState(
      Map.fromEntries(
        (gameState["players"] as List<dynamic>).map((map) {
          final playerState = PlayerState.fromJson(map);
          return MapEntry(playerState.id, playerState);
        }),
      ),
      gameState["roundNumber"],
      GameScore.fromJson(gameState["gameScore"]),
      RoundStage.values.firstWhere((s) => s.name == gameState["roundStage"]),
      (gameState["cardsOnTable"] as List<dynamic>)
          .map((cardOnTable) =>
              CardOnTableState(cardOnTable["playerId"], GameCard.fromJson(cardOnTable["card"])))
          .toList(),
      gameState["myPlayerId"] as String,
      gameState["currentPlayerId"] as String,
      gameState["trump"] == null ? null : GameCard.fromJson(gameState["trump"]),
      gameState["trumpColor"] == null ? null : CardColor.fromJson(gameState["trumpColor"]),
      gameState["leadColor"] == null ? null : CardColor.fromJson(gameState["leadColor"]),
      (gameState["roundScores"] as Map<String, dynamic>).map(
        (playerId, map) => MapEntry(playerId, RoundScore.fromJson(map)),
      ),
    );
  }
}
