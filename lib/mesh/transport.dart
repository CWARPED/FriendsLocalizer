// lib/mesh/transport.dart
import 'dart:typed_data';

/// Canal de diffusion abstrait. `send` diffuse une trame aux voisins immédiats.
/// La couche BLE native (Plan 3) et le simulateur (ce plan) l'implémentent.
abstract class MeshTransport {
  void send(Uint8List frame);
}
