typedef VoidCallback = void Function();

mixin class ChangeNotifier {
  int _count = 0;
  static final List<VoidCallback?> _emptyListeners = List<VoidCallback?>.filled(0, null);
  List<VoidCallback?> _listeners = _emptyListeners;
  int _notificationCallStackDepth = 0;
  int _reentrantlyRemovedListeners = 0;
  bool _debugDisposed = false;

  static bool debugAssertNotDisposed(ChangeNotifier notifier) {
    assert(() {
      if (notifier._debugDisposed) {
        throw Exception(
          'A ${notifier.runtimeType} was used after being disposed.\n'
          'Once you have called dispose() on a ${notifier.runtimeType}, it '
          'can no longer be used.',
        );
      }
      return true;
    }());
    return true;
  }

  bool get hasListeners => _count > 0;

  void addListener(VoidCallback listener) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));

    if (_count == _listeners.length) {
      if (_count == 0) {
        _listeners = List<VoidCallback?>.filled(1, null);
      } else {
        final List<VoidCallback?> newListeners =
            List<VoidCallback?>.filled(_listeners.length * 2, null);
        for (int i = 0; i < _count; i++) {
          newListeners[i] = _listeners[i];
        }
        _listeners = newListeners;
      }
    }
    _listeners[_count++] = listener;
  }

  void _removeAt(int index) {
    _count -= 1;
    if (_count * 2 <= _listeners.length) {
      final List<VoidCallback?> newListeners = List<VoidCallback?>.filled(_count, null);

      for (int i = 0; i < index; i++) {
        newListeners[i] = _listeners[i];
      }

      for (int i = index; i < _count; i++) {
        newListeners[i] = _listeners[i + 1];
      }

      _listeners = newListeners;
    } else {
      for (int i = index; i < _count; i++) {
        _listeners[i] = _listeners[i + 1];
      }
      _listeners[_count] = null;
    }
  }

  void removeListener(VoidCallback listener) {
    for (int i = 0; i < _count; i++) {
      final VoidCallback? listenerAtIndex = _listeners[i];
      if (listenerAtIndex == listener) {
        if (_notificationCallStackDepth > 0) {
          _listeners[i] = null;
          _reentrantlyRemovedListeners++;
        } else {
          _removeAt(i);
        }
        break;
      }
    }
  }

  void dispose() {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    assert(
      _notificationCallStackDepth == 0,
      'The "dispose()" method on $this was called during the call to '
      '"notifyListeners()". This is likely to cause errors since it modifies '
      'the list of listeners while the list is being used.',
    );
    assert(() {
      _debugDisposed = true;
      return true;
    }());
    _listeners = _emptyListeners;
    _count = 0;
  }

  @pragma('vm:notify-debugger-on-exception')
  void notifyListeners() {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (_count == 0) {
      return;
    }

    _notificationCallStackDepth++;

    final int end = _count;
    for (int i = 0; i < end; i++) {
      _listeners[i]?.call();
    }

    _notificationCallStackDepth--;

    if (_notificationCallStackDepth == 0 && _reentrantlyRemovedListeners > 0) {
      final int newLength = _count - _reentrantlyRemovedListeners;
      if (newLength * 2 <= _listeners.length) {
        final List<VoidCallback?> newListeners = List<VoidCallback?>.filled(newLength, null);

        int newIndex = 0;
        for (int i = 0; i < _count; i++) {
          final VoidCallback? listener = _listeners[i];
          if (listener != null) {
            newListeners[newIndex++] = listener;
          }
        }

        _listeners = newListeners;
      } else {
        for (int i = 0; i < newLength; i += 1) {
          if (_listeners[i] == null) {
            int swapIndex = i + 1;
            while (_listeners[swapIndex] == null) {
              swapIndex += 1;
            }
            _listeners[i] = _listeners[swapIndex];
            _listeners[swapIndex] = null;
          }
        }
      }

      _reentrantlyRemovedListeners = 0;
      _count = newLength;
    }
  }
}