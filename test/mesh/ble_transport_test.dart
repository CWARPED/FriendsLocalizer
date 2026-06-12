import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_localizer/mesh/ble_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const method = MethodChannel('fl/ble');
  const event = EventChannel('fl/ble/events');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(method, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(method, null);
  });

  test('send invoque la méthode broadcast avec la trame', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(method, (call) async {
      calls.add(call);
      return null;
    });
    final t = BleMeshTransport();
    addTearDown(t.dispose);
    final frame = Uint8List.fromList([1, 2, 3, 4]);
    t.send(frame);
    await Future<void>.delayed(Duration.zero);
    expect(calls.single.method, 'broadcast');
    expect(calls.single.arguments, frame);
  });

  test('start invoque la méthode start', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(method, (call) async {
      calls.add(call.method);
      return null;
    });
    final t = BleMeshTransport();
    addTearDown(t.dispose);
    await t.start();
    expect(calls, contains('start'));
  });

  test('route un événement frame entrant vers onFrame', () async {
    final t = BleMeshTransport();
    addTearDown(t.dispose);
    final received = <Uint8List>[];
    t.onFrame = (f) => received.add(f);
    final data = {'type': 'frame', 'data': Uint8List.fromList([9, 8, 7])};
    await _emitEvent(event, data);
    expect(received.single, Uint8List.fromList([9, 8, 7]));
  });

  test('route un événement neighbor vers onNeighbor', () async {
    final t = BleMeshTransport();
    addTearDown(t.dispose);
    var neighbors = 0;
    t.onNeighbor = () => neighbors++;
    await _emitEvent(event, {'type': 'neighbor'});
    expect(neighbors, 1);
  });
}

/// Pousse [data] dans le flux de l'EventChannel comme si le natif l'émettait.
Future<void> _emitEvent(EventChannel channel, Object? data) async {
  const codec = StandardMethodCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  await messenger.handlePlatformMessage(
    channel.name,
    codec.encodeSuccessEnvelope(data),
    (_) {},
  );
}
