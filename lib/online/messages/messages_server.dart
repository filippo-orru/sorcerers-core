import 'package:sorcerers_core/game/game.dart';
import 'package:sorcerers_core/utils.dart';

sealed class ServerMessage {
  final String id;

  ServerMessage(this.id);

  Map<String, dynamic> toJson();

  static ServerMessage fromJson(Map<String, dynamic> map) {
    final id = map["id"] as String;
    switch (id) {
      case "StateUpdate":
        return StateUpdate.fromJsonImpl(map);
      default:
        throw DeserializationError("Unknown message id: $id");
    }
  }
}

class StateUpdate extends ServerMessage {
  final LobbyState lobbyState;

  StateUpdate(this.lobbyState) : super("StateUpdate");

  static ServerMessage fromJsonImpl(Map<String, dynamic> map) {
    final lobbyState = LobbyState.fromJson(map["lobbyState"] as Map<String, dynamic>);

    return StateUpdate(lobbyState);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "lobbyState": lobbyState.toJson(),
    };
  }
}

sealed class LobbyState {
  static LobbyState fromJson(Map<String, dynamic> map) {
    final id = map["id"] as String;

    switch (id) {
      case "Idle":
        return LobbyStateIdle.fromJsonImpl(map);
      case "InLobby":
        return InLobby.fromJsonImpl(map);
      case "Playing":
        return LobbyStatePlaying.fromJsonImpl(map);
      default:
        throw DeserializationError("Unknown lobby state id: $id");
    }
  }

  Map<String, dynamic> toJson();
}

class LobbyStateIdle extends LobbyState {
  final List<LobbyData> lobbies;

  LobbyStateIdle(this.lobbies);

  @override
  Map<String, dynamic> toJson() {
    return {
      "id": "Idle",
      "lobbies": lobbies.map((it) => it.toJson()).toList(),
    };
  }

  static LobbyState fromJsonImpl(Map<String, dynamic> map) {
    return LobbyStateIdle(
      (map["lobbies"] as List<dynamic>).map((it) => LobbyData.fromJson(it)).toList(),
    );
  }
}

class LobbyData {
  final String name;
  final int playerCount;

  LobbyData(this.name, this.playerCount);

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "playerCount": playerCount,
    };
  }

  static LobbyData fromJson(Map<String, dynamic> map) {
    final name = map["name"] as String;
    final playerCount = map["playerCount"] as int;

    return LobbyData(name, playerCount);
  }
}

class InLobby extends LobbyState {
  final Map<PlayerId, PlayerInLobby> players;

  InLobby(this.players);

  static LobbyState fromJsonImpl(Map<String, dynamic> map) {
    final players = map["players"] as Map<String, dynamic>;

    final playerMap = <String, PlayerInLobby>{};
    players.forEach((key, value) {
      if (value is! Map<String, dynamic>) {
        return;
      }

      final name = value["name"];
      final ready = value["ready"];
      if (name == null || ready == null) {
        return;
      }

      playerMap[key] = PlayerInLobby(name, ready);
    });

    return InLobby(playerMap);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "id": "InLobby",
      "players": players.map((key, playerInLobby) => MapEntry(key, playerInLobby.toJson())),
    };
  }
}

class PlayerInLobby {
  final String name;
  final bool ready;

  PlayerInLobby(this.name, this.ready);
  // final bool me;

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "ready": ready,
    };
  }
}

class LobbyStatePlaying extends LobbyState {
  final GameState gameState;

  LobbyStatePlaying(this.gameState);

  static LobbyState fromJsonImpl(Map<String, dynamic> map) {
    final gameState = map["gameState"] as Map<String, dynamic>;

    return LobbyStatePlaying(GameState.fromJson(gameState));
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "id": "Playing",
      "gameState": gameState.toJson(),
    };
  }
}
