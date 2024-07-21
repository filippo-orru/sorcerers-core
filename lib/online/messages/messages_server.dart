import 'package:sorcerers_core/game/game.dart';
import 'package:sorcerers_core/utils.dart';

sealed class ServerMessage {
  final String id;

  ServerMessage(this.id);

  Map<String, dynamic> toJson();

  static ServerMessage fromJson(Map<String, dynamic> map) {
    final id = map["id"] as String;
    switch (id) {
      case "HelloResponse":
        return HelloResponse.fromJsonImpl(map);
      case "StateUpdate":
        return StateUpdate.fromJsonImpl(map);
      default:
        throw DeserializationError("Unknown message id: $id");
    }
  }
}

class HelloResponse extends ServerMessage {
  final PlayerId playerId;
  final ReconnectId reconnectId;

  HelloResponse({required this.playerId, required this.reconnectId}) : super("HelloResponse");

  @override
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "reconnectId": reconnectId,
    };
  }

  static ServerMessage fromJsonImpl(Map<String, dynamic> map) {
    return HelloResponse(
      playerId: map["playerId"] as String,
      reconnectId: map["reconnectId"] as String,
    );
  }
}

class StateUpdate extends ServerMessage {
  final LobbyState? lobbyState;

  StateUpdate(this.lobbyState) : super("StateUpdate");

  static ServerMessage fromJsonImpl(Map<String, dynamic> map) {
    final raw = map["lobbyState"];
    if (raw == null) {
      return StateUpdate(null);
    } else {
      final lobbyState = LobbyState.fromJson(raw as Map<String, dynamic>);
      return StateUpdate(lobbyState);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "lobbyState": lobbyState?.toJson(),
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
        return LobbyStateInLobby.fromJsonImpl(map);
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

class LobbyStateInLobby extends LobbyState {
  final String lobbyName;
  final List<PlayerInLobby> players;

  LobbyStateInLobby(this.lobbyName, this.players);

  static LobbyState fromJsonImpl(Map<String, dynamic> map) {
    final players = map["players"] as List<dynamic>;

    return LobbyStateInLobby(
      map["lobbyName"] as String,
      players.map((value) {
        value as Map<String, dynamic>;
        return PlayerInLobby(
          value["id"] as String,
          value["name"] as String,
          value["ready"] as bool,
        );
      }).toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "id": "InLobby",
      "lobbyName": lobbyName,
      "players": players.map((playerInLobby) => playerInLobby.toJson()).toList(),
    };
  }
}

class PlayerInLobby {
  final PlayerId id;
  final String name;
  final bool ready;

  PlayerInLobby(this.id, this.name, this.ready);
  // final bool me;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
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
