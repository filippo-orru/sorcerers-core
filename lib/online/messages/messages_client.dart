import 'package:sorcerers_core/game/game.dart';
import 'package:sorcerers_core/utils.dart';

import 'game_messages/game_messages_client.dart';

sealed class ClientMessage {
  final String id;

  ClientMessage(this.id);

  Map<String, dynamic> toJsonImpl();

  Map<String, dynamic> toJson() {
    final json = toJsonImpl();
    json.addAll({"id": id});
    return json;
  }

  static ClientMessage fromJson(Map<String, dynamic> json) {
    final id = json["id"];
    switch (id) {
      case "Hello":
        return Hello(json["reconnectId"]);
      case "SetName":
        return SetName(json["playerName"]);
      case "CreateLobby":
        return CreateLobby(json["lobbyName"]);
      case "JoinLobby":
        return JoinLobby(json["lobbyName"]);
      case "LeaveLobby":
        return LeaveLobby();
      case "ReadyToPlay":
        return ReadyToPlay(json["ready"]);
      case "GameMessage":
        return GameMessage(json["playerId"], GameMessageClient.fromJson(json["gameMessage"]));
      default:
        throw Exception("Unknown message id: $id");
    }
  }
}

class Hello extends ClientMessage {
  final ReconnectId? reconnectId;

  Hello(this.reconnectId) : super("Hello");

  @override
  Map<String, dynamic> toJsonImpl() {
    return {
      "reconnectId": reconnectId,
    };
  }
}

class SetName extends ClientMessage {
  final String playerName;

  SetName(this.playerName) : super("SetName");

  @override
  Map<String, dynamic> toJsonImpl() {
    return {
      "playerName": playerName,
    };
  }
}

class CreateLobby extends ClientMessage {
  final String lobbyName;

  CreateLobby(this.lobbyName) : super("CreateLobby");

  @override
  Map<String, dynamic> toJsonImpl() {
    return {
      "lobbyName": lobbyName,
    };
  }
}

class JoinLobby extends ClientMessage {
  final String lobbyName;

  JoinLobby(this.lobbyName) : super("JoinLobby");

  @override
  Map<String, dynamic> toJsonImpl() {
    return {
      "lobbyName": lobbyName,
    };
  }
}

class LeaveLobby extends ClientMessage {
  LeaveLobby() : super("LeaveLobby");

  @override
  Map<String, dynamic> toJsonImpl() {
    return {};
  }
}

class ReadyToPlay extends ClientMessage {
  final bool ready;

  ReadyToPlay(this.ready) : super("ReadyToPlay");

  @override
  Map<String, dynamic> toJsonImpl() {
    return {
      "ready": ready,
    };
  }
}

class GameMessage extends ClientMessage {
  final PlayerId playerId;
  final GameMessageClient gameMessage;

  GameMessage(this.playerId, this.gameMessage) : super("GameMessage");

  @override
  Map<String, dynamic> toJsonImpl() {
    return {
      "playerId": playerId,
      "gameMessage": gameMessage.toJson(),
    };
  }
}
