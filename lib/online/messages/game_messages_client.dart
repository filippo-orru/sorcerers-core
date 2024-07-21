import 'package:sorcerers_core/game/cards.dart';
import 'package:sorcerers_core/utils.dart';

sealed class GameMessageClient {
  final String id;

  GameMessageClient(this.id);

  Map<String, dynamic> toJsonImpl();
  Map<String, dynamic> toJson() {
    return {
      "id": runtimeType.toString(),
      ...toJsonImpl(),
    };
  }

  static GameMessageClient fromJson(Map<String, dynamic> json) {
    final id = json["id"];
    switch (id) {
      case "StartNewRound":
        return StartNewRound();
      case "ShuffleDeck":
        return ShuffleDeck();
      case "SetTrumpColor":
        return SetTrumpColor(CardColor.values.firstWhere((e) => e.name == json["color"]));
      case "SetBid":
        return SetBid(json["bid"]);
      case "PlayCard":
        return PlayCard(json["cardId"]);
      case "ReadyForNextTrick":
        return ReadyForNextTrick();
      case "LeaveGame":
        return LeaveGame();
      default:
        throw DeserializationError("Unknown message id: $id");
    }
  }
}

class StartNewRound extends GameMessageClient {
  StartNewRound() : super("StartNewRound");

  @override
  Map<String, dynamic> toJsonImpl() {
    return {};
  }
}

class ShuffleDeck extends GameMessageClient {
  ShuffleDeck() : super("ShuffleDeck");

  @override
  Map<String, dynamic> toJsonImpl() {
    return {};
  }
}

class SetTrumpColor extends GameMessageClient {
  final CardColor color;

  SetTrumpColor(this.color) : super("SetTrumpColor");

  @override
  Map<String, dynamic> toJsonImpl() {
    return {
      "color": color.toString(),
    };
  }
}

class SetBid extends GameMessageClient {
  final int bid;

  SetBid(this.bid) : super("SetBid");

  @override
  Map<String, dynamic> toJsonImpl() {
    return {
      "bid": bid,
    };
  }
}

class PlayCard extends GameMessageClient {
  final int cardId;

  PlayCard(this.cardId) : super("PlayCard");

  @override
  Map<String, dynamic> toJsonImpl() {
    return {
      "cardId": cardId,
    };
  }
}

class ReadyForNextTrick extends GameMessageClient {
  ReadyForNextTrick() : super("ReadyForNextTrick");

  @override
  Map<String, dynamic> toJsonImpl() {
    return {};
  }
}

class LeaveGame extends GameMessageClient {
  LeaveGame() : super("LeaveGame");

  @override
  Map<String, dynamic> toJsonImpl() {
    return {};
  }
}
