import 'heading.dart';
import 'sensors.dart';

/// Aucun cap disponible (desktop, émulateur, tests). Flux vide.
class NullHeadingProvider implements HeadingProvider {
  const NullHeadingProvider();

  @override
  Stream<HeadingReading> readings() => const Stream.empty();
}

/// Enrobe une source de caps bruts en lui appliquant un lissage,
/// tout en conservant la précision de chaque mesure.
class StreamHeadingProvider implements HeadingProvider {
  final Stream<HeadingReading> _source;
  final HeadingSmoother _smoother;

  StreamHeadingProvider(this._source, {double alpha = 0.25})
      : _smoother = HeadingSmoother(alpha: alpha);

  /// À appeler une seule fois par instance : le lisseur est à état, des
  /// abonnements multiples partageraient (et corrompraient) ce state.
  @override
  Stream<HeadingReading> readings() => _source.map(
        (r) => HeadingReading(
          _smoother.add(r.degrees),
          accuracyDegrees: r.accuracyDegrees,
        ),
      );
}
