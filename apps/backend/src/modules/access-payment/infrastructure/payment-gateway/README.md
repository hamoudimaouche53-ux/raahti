# access-payment/infrastructure/payment-gateway

Provider-agnostic PaymentGateway port (interface, defined in domain/) and its adapter implementations. Holds the MockPaymentGatewayAdapter used until a real provider is approved (ADR-0014). The only place any future provider SDK code may appear.

