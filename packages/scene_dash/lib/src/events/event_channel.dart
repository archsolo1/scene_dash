/// A buffered, multi-reader event channel for events of type [T].
///
/// Events are appended by writers and read by any number of [EventReader]s,
/// each of which keeps its own independent cursor. One reader consuming events
/// never advances another reader's cursor.
///
/// [update] reclaims the prefix of events that every registered reader has
/// already observed, so the buffer does not grow without bound.
final class EventChannel<T> {
  final List<T> _events = <T>[];

  /// Absolute index of `_events[0]` in the channel's lifetime numbering.
  int _base = 0;

  final List<EventReader<T>> _readers = <EventReader<T>>[];

  /// Absolute index just past the last event (one more than the newest).
  int get _end => _base + _events.length;

  /// Appends an event to the channel.
  void send(T event) => _events.add(event);

  /// Creates a reader positioned at the current end (it will only observe
  /// events sent after this call).
  EventReader<T> reader() {
    final reader = EventReader<T>._(this).._cursor = _end;
    _readers.add(reader);
    return reader;
  }

  /// Creates a writer bound to this channel.
  EventWriter<T> writer() => EventWriter<T>._(this);

  /// Drops the prefix of events that all readers have already consumed.
  ///
  /// If there are no readers, every event is dropped.
  void update() {
    if (_readers.isEmpty) {
      _base = _end;
      _events.clear();
      return;
    }
    var minCursor = _end;
    for (final reader in _readers) {
      if (reader._cursor < minCursor) minCursor = reader._cursor;
    }
    final drop = minCursor - _base;
    if (drop > 0) {
      _events.removeRange(0, drop);
      _base += drop;
    }
  }
}

/// A cursor-based reader over an [EventChannel].
///
/// Each call to [drain] returns the events sent since the previous call and
/// advances this reader's cursor to the channel's current end.
final class EventReader<T> {
  final EventChannel<T> _channel;
  int _cursor = 0;

  EventReader._(this._channel);

  /// Whether unread events are available for this reader.
  bool get hasUnread => _cursor < _channel._end;

  /// Invokes [callback] for every unread event without allocating a result
  /// list, then advances this reader's cursor.
  ///
  /// If [callback] throws, the cursor is left unchanged so the unread events can
  /// be retried.
  void forEach(void Function(T event) callback) {
    final from = _cursor - _channel._base;
    final start = from < 0 ? 0 : from;
    final end = _channel._events.length;
    for (var i = start; i < end; i++) {
      callback(_channel._events[i]);
    }
    _cursor = _channel._end;
  }

  /// Returns and consumes all events this reader has not yet seen.
  List<T> drain() {
    final from = _cursor - _channel._base;
    final start = from < 0 ? 0 : from;
    final result = _channel._events.sublist(start);
    _cursor = _channel._end;
    return result;
  }
}

/// A handle that appends events to an [EventChannel].
final class EventWriter<T> {
  final EventChannel<T> _channel;

  EventWriter._(this._channel);

  /// Sends [event] to all readers of the channel.
  void send(T event) => _channel.send(event);
}
