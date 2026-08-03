import "dart:convert";

import "package:http/http.dart" as http;

import "../../domain/repositories/payment_repository.dart";
import "../dtos/transaction_dto.dart";

/// Calls `POST {baseUrl}/v1/access-sessions/{id}/payments` per
/// docs/api/openapi.yaml — same `baseUrl`-injected pattern as
/// `AccessSessionRemoteDataSource`.
///
/// Per `PaymentRepository`'s doc comment, this is a single call: the
/// backend orchestrates authorize → capture → unlock-order issuance
/// within this one request/response, so there is nothing else for this
/// data source to call.
class PaymentRemoteDataSource {
  const PaymentRemoteDataSource(this._client, {required this._baseUrl});

  final http.Client _client;
  final String? _baseUrl;

  Future<TransactionDto> requestPayment({
    required String accessSessionId,
    required String? paymentMethodId,
    required bool applyEmergencyDiscount,
    required String idempotencyKey,
  }) async {
    final String? baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw const PaymentApiNotConfiguredFailure();
    }

    final Uri uri = Uri.parse(
      "$baseUrl/v1/access-sessions/$accessSessionId/payments",
    );
    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: <String, String>{
              "Content-Type": "application/json",
              "Idempotency-Key": idempotencyKey,
            },
            body: jsonEncode(<String, dynamic>{
              "paymentMethodId": paymentMethodId,
              "applyEmergencyDiscount": applyEmergencyDiscount,
            }),
          )
          // Longer than the other data sources' 10s — this call holds
          // open through the backend's full authorize → capture →
          // unlock-order → ack-wait sequence (sequence-diagrams.md §1),
          // not just a single fast read/write. Deliberately looser than
          // ADR-0026 Decision 1's 30s UI-level give-up bound — that
          // policy is this story's caller's job (US-04.4), not this HTTP
          // client's; this timeout only guards against a truly hung
          // connection, not a slow-but-alive one.
          .timeout(const Duration(seconds: 40));
    } catch (e) {
      throw PaymentRequestFailure("Could not reach the backend: $e");
    }

    if (response.statusCode == 402) {
      throw PaymentDeclinedFailure(
        "Backend declined the payment for $uri (402).",
      );
    }
    // Not in docs/api/openapi.yaml's documented response set for this
    // endpoint (only 200/402 are listed there) — modeled per
    // docs/architecture/sequence-diagrams.md §1's refund-on-unlock-failure
    // branch and `UnlockFailedRefundedFailure`'s own doc comment, a
    // documented spec gap, not an invented status code.
    if (response.statusCode == 502) {
      throw UnlockFailedRefundedFailure(
        "Unlock failed after payment capture; backend issued a refund "
        "for $uri (502).",
      );
    }
    if (response.statusCode != 200) {
      throw PaymentRequestFailure(
        "Backend returned HTTP ${response.statusCode} for $uri",
      );
    }

    return TransactionDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
