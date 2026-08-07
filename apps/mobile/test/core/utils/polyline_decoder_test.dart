import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/utils/polyline_decoder.dart";

void main() {
  group("decodePolyline", () {
    test("decodes the canonical Google polyline-algorithm example", () {
      // https://developers.google.com/maps/documentation/utilities/polylinealgorithm
      // — encodes (38.5,-120.2), (40.7,-120.95), (43.252,-126.453), the
      // same precision-5 format OSRM's `geometries=polyline` returns.
      final points = decodePolyline(r"_p~iF~ps|U_ulLnnqC_mqNvxq`@");

      expect(points, hasLength(3));
      expect(points[0].latitude, closeTo(38.5, 1e-5));
      expect(points[0].longitude, closeTo(-120.2, 1e-5));
      expect(points[1].latitude, closeTo(40.7, 1e-5));
      expect(points[1].longitude, closeTo(-120.95, 1e-5));
      expect(points[2].latitude, closeTo(43.252, 1e-5));
      expect(points[2].longitude, closeTo(-126.453, 1e-5));
    });

    test("returns an empty list for an empty string", () {
      expect(decodePolyline(""), isEmpty);
    });

    test("decodes a single-point polyline", () {
      final points = decodePolyline(r"_p~iF~ps|U");
      expect(points, hasLength(1));
      expect(points.single.latitude, closeTo(38.5, 1e-5));
      expect(points.single.longitude, closeTo(-120.2, 1e-5));
    });

    test("honors a non-default precision", () {
      // Re-encoding (38.5, -120.2) at precision 6 shifts the scale factor
      // by 10x — same string shape, different meaning without the
      // `precision` parameter.
      final points = decodePolyline(r"_p~iF~ps|U", precision: 6);
      expect(points.single.latitude, closeTo(3.85, 1e-4));
      expect(points.single.longitude, closeTo(-12.02, 1e-4));
    });

    group("malformed input", () {
      test("throws a FormatException for a string truncated mid-chunk "
          "(regression — previously threw an incidental RangeError)", () {
        // A valid single-point encoding (r"_p~iF~ps|U", 10 chars) with its
        // final character dropped — every character but the true last one
        // of a complete number has its continuation bit set, so this still
        // asks for "one more character" that never comes.
        final String truncated = r"_p~iF~ps|U".substring(0, 9);

        expect(
          () => decodePolyline(truncated),
          throwsA(isA<FormatException>()),
        );
      });

      test("throws a FormatException for a single continuation-bit-set "
          "character with nothing following it", () {
        expect(() => decodePolyline("_"), throwsA(isA<FormatException>()));
      });

      test("throws a FormatException for a character below the valid "
          "encoded-polyline range (code below 63, the '?' character)", () {
        expect(() => decodePolyline(" "), throwsA(isA<FormatException>()));
      });

      test("throws a FormatException for a character above the valid "
          "encoded-polyline range (code above 126, the '~' character)", () {
        final String tooHigh = String.fromCharCode(200);
        expect(() => decodePolyline(tooHigh), throwsA(isA<FormatException>()));
      });

      test("does not silently produce garbage coordinates for an invalid "
          "leading character — it throws instead", () {
        expect(
          () => decodePolyline(" _p~iF~ps|U"),
          throwsA(isA<FormatException>()),
        );
      });
    });
  });
}
