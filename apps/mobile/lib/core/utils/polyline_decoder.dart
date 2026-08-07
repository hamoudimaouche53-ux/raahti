import "dart:math" as math;

import "../../features/map_discovery/domain/entities/coordinates.dart";

/// Decodes a Google/OSRM "encoded polyline" (precision-5 by default — OSRM's
/// own default, and the `geometries=polyline` format requested by
/// `RouteRemoteDataSource`/the backend's `OsrmRouteProvider`) into a plain
/// list of [Coordinates].
///
/// Pure algorithm, no `flutter_map`/`latlong2` dependency — lives in
/// `core/utils` (like `external_navigation_launcher.dart`) rather than
/// inside `map_discovery`'s data layer, since decoding is generic polyline
/// math, not itself a wire-format DTO concern; `RouteDto.toEntity()` is this
/// function's only caller today.
///
/// Throws a [FormatException] — rather than an incidental [RangeError] or
/// silently-wrong coordinates — for malformed input: a string that ends
/// mid-chunk (truncated), or one containing a character outside the valid
/// `?`(63)–`~`(126) encoded-polyline range. Every character must fall in
/// that range by construction of the algorithm (a 6-bit chunk, offset by
/// 63); anything else means the payload isn't a valid encoded polyline.
List<Coordinates> decodePolyline(String encoded, {int precision = 5}) {
  final List<Coordinates> points = <Coordinates>[];
  final double factor = math.pow(10, precision).toDouble();
  int index = 0;
  int lat = 0;
  int lng = 0;

  int nextDelta() {
    int shift = 0;
    int result = 0;
    int chunk;
    do {
      if (index >= encoded.length) {
        throw FormatException(
          "Truncated encoded polyline — expected more characters",
          encoded,
          index,
        );
      }
      chunk = encoded.codeUnitAt(index) - 63;
      if (chunk < 0 || chunk > 63) {
        throw FormatException(
          "Invalid encoded-polyline character",
          encoded,
          index,
        );
      }
      index++;
      result |= (chunk & 0x1f) << shift;
      shift += 5;
    } while (chunk >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  }

  while (index < encoded.length) {
    lat += nextDelta();
    lng += nextDelta();
    points.add(Coordinates(latitude: lat / factor, longitude: lng / factor));
  }

  return points;
}
