/// Mirrors `Transaction.status` in docs/erd/erd.md §3.10 and the
/// [Transaction] schema in docs/api/openapi.yaml.
enum TransactionStatus { pending, authorized, captured, failed, refunded }
