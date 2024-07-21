import 'package:sorcerers_core/utils.dart';

sealed class GameCard {
  bool beats(GameCard previous, CardColor? trump, CardColor? lead);

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

  NumberCard(this.number, this.color);

  static int highest = 13;

  @override
  bool beats(GameCard previous, CardColor? trump, CardColor? lead) {
    switch (previous) {
      case NumberCard():
        if (color == previous.color) {
          return number > previous.number;
        } else if (color == trump) {
          return true;
        } else if (color == lead) {
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
      };

  static GameCard fromJson(Map<String, dynamic> map) {
    final number = map["number"]!;
    final color = map["color"]!;
    return NumberCard(number, CardColor.fromJson(color));
  }
}

class WizardCard extends GameCard {
  @override
  bool beats(GameCard previous, CardColor? trump, CardColor? lead) {
    switch (previous) {
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
      };

  static GameCard fromJson(Map<String, dynamic> map) {
    return WizardCard();
  }
}

class JesterCard extends GameCard {
  @override
  bool beats(GameCard previous, CardColor? trump, CardColor? lead) {
    return false;
  }

  @override
  bool canBePlayed(CardColor? lead) => true;

  @override
  String get description => "Jester";

  @override
  Map<String, dynamic> toJson() => {
        "id": "JesterCard",
      };

  static GameCard fromJson(Map<String, dynamic> map) {
    return JesterCard();
  }
}
