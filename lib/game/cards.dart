import 'package:sorcerers_core/utils.dart';

typedef CardId = int;

sealed class GameCard {
  final CardId cardId;

  GameCard(this.cardId);

  bool beats(GameCard highest, CardColor? trump);

  bool canBePlayed(CardColor? lead);

  String get description;

  Map<String, dynamic> toJson();

  static GameCard fromJson(Map<String, dynamic> map) {
    final id = map["id"]!;

    switch (id) {
      case "NumberCard":
        return NumberCard.fromJson(map);
      case "WizardCard":
        return WizardCard.fromJson(map);
      case "JesterCard":
        return JesterCard.fromJson(map);
      default:
        throw DeserializationError("Unknown card id: $id");
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is GameCard) {
      return cardId == other.cardId;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => cardId.hashCode;
}

enum CardColor {
  red,
  yellow,
  green,
  blue;

  static CardColor fromJson(String color) {
    return CardColor.values.firstWhere((element) => element.name == color);
  }
}

class NumberCard extends GameCard {
  final int number; // 1-13
  final CardColor color;

  NumberCard(super.cardId, this.number, this.color);

  static int highest = 13;

  @override
  bool beats(GameCard highest, CardColor? trump) {
    switch (highest) {
      case NumberCard():
        if (color == highest.color) {
          return number > highest.number;
        } else if (color == trump) {
          return true;
        } else {
          return false;
        }
      case WizardCard():
        return false;
      case JesterCard():
        return true;
    }
  }

  @override
  bool canBePlayed(CardColor? lead) {
    return lead == null || lead == color;
  }

  @override
  String get description => number.toString();

  @override
  Map<String, dynamic> toJson() => {
        "id": "NumberCard",
        "number": number,
        "color": color.name,
        "cardId": cardId,
      };

  static GameCard fromJson(Map<String, dynamic> map) {
    return NumberCard(
      map["cardId"]!,
      map["number"]!,
      CardColor.fromJson(map["color"]!),
    );
  }
}

class WizardCard extends GameCard {
  WizardCard(super.cardId);

  @override
  bool beats(GameCard highest, CardColor? trump) {
    switch (highest) {
      case NumberCard():
        return true;
      case WizardCard():
        return false;
      case JesterCard():
        return true;
    }
  }

  @override
  bool canBePlayed(CardColor? lead) => true;

  @override
  String get description => "Wizard";

  @override
  Map<String, dynamic> toJson() => {
        "id": "WizardCard",
        "cardId": cardId,
      };

  static GameCard fromJson(Map<String, dynamic> map) {
    return WizardCard(map["cardId"]!);
  }
}

class JesterCard extends GameCard {
  JesterCard(super.cardId);

  @override
  bool beats(GameCard highest, CardColor? trump) {
    return highest is JesterCard; // Jester only beats previous Jester
  }

  @override
  bool canBePlayed(CardColor? lead) => true;

  @override
  String get description => "Jester";

  @override
  Map<String, dynamic> toJson() => {
        "id": "JesterCard",
        "cardId": cardId,
      };

  static GameCard fromJson(Map<String, dynamic> map) {
    return JesterCard(map["cardId"]!);
  }
}
