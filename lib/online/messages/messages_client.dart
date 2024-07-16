import 'package:sorcerers_core/game/game.dart';

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
  ReadyToPlay() : super("ReadyToPlay");

  @override
  Map<String, dynamic> toJsonImpl() {
    return {};
  }
}

class GameMessage extends ClientMessage {
  final Player player; // TODO is player really the best idea?
  final GameMessageClient gameMessage;

  GameMessage(this.player, this.gameMessage) : super("GameMessage");

  @override
  Map<String, dynamic> toJsonImpl() {
    return {
      "player": player.id,
      "gameMessage": gameMessage.toJson(),
    };
  }
}
