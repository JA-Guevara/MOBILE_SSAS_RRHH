import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ssas_rrhh/features/auth/screens/suscripcion_page.dart';
import 'package:mobile_ssas_rrhh/features/auth/services/staff_api.dart';

class _SubscriptionApi extends StaffApi {
  _SubscriptionApi() : super(baseUrl: 'https://example.test/api/v1');

  int loads = 0;
  String? selectedPlan;
  String checkoutUrl = 'https://checkout.stripe.com/c/pay/cs_test_123';
  bool activePaid = false;

  @override
  Future<Map<String, dynamic>> subscription() async {
    loads++;
    return {
      'estado': 'PRUEBA',
      'plan': {
        'id': 'basic',
        'nombre': 'Básico',
        'precio_mensual': '10.00',
        'moneda': 'USD',
      },
      'stripe_customer_id': activePaid ? 'cus_123' : null,
      'stripe_subscription_id': activePaid ? 'sub_123' : null,
      'fecha_proximo_cobro': null,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> subscriptionPlans() async => [
    {
      'id': 'basic',
      'nombre': 'Básico',
      'precio_mensual': '10.00',
      'moneda': 'USD',
      'max_usuarios': 5,
      'max_vacantes_activas': 2,
      'stripe_price_id': 'price_123',
    },
  ];

  @override
  Future<Map<String, dynamic>> subscriptionConsumption() async => {
    'usuarios': {'usado': 1, 'limite': 5},
    'vacantes_activas': {'usado': 0, 'limite': 2},
    'almacenamiento_mb': {'usado': 0, 'limite': 100},
  };

  @override
  Future<String> createSubscriptionCheckout(String planId) async {
    selectedPlan = planId;
    return checkoutUrl;
  }

  @override
  Future<String> createSubscriptionPortal() async =>
      'https://billing.stripe.com/p/session/test';
}

void main() {
  testWidgets('abre Checkout y actualiza al volver al APK', (tester) async {
    final api = _SubscriptionApi();
    addTearDown(api.close);
    Uri? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: SuscripcionPage(
          api: api,
          permissions: const {'suscripcion:ver', 'suscripcion:contratar'},
          openUrl: (url) async {
            opened = url;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mi suscripción'), findsOneWidget);
    expect(find.text('Básico'), findsWidgets);
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir plan'));
    await tester.pumpAndSettle();

    expect(api.selectedPlan, 'basic');
    expect(opened?.host, 'checkout.stripe.com');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(api.loads, greaterThan(1));
  });

  testWidgets('no ofrece compra sin permiso', (tester) async {
    final api = _SubscriptionApi();
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: SuscripcionPage(
          api: api,
          permissions: const {'suscripcion:ver'},
          openUrl: (_) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Básico'), findsWidgets);
    expect(find.text('Elegir plan'), findsNothing);
  });

  testWidgets('rechaza una URL de pago ajena a Stripe', (tester) async {
    final api = _SubscriptionApi()
      ..checkoutUrl = 'https://example.test/checkout';
    addTearDown(api.close);
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SuscripcionPage(
          api: api,
          permissions: const {'suscripcion:ver', 'suscripcion:contratar'},
          openUrl: (_) async {
            opened = true;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir plan'));
    await tester.pumpAndSettle();

    expect(opened, isFalse);
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('dirección de pago no es válida'),
      findsOneWidget,
    );
  });

  testWidgets('plan pagado se administra sin crear otra suscripción', (
    tester,
  ) async {
    final api = _SubscriptionApi()..activePaid = true;
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: SuscripcionPage(
          api: api,
          permissions: const {
            'suscripcion:ver',
            'suscripcion:contratar',
            'suscripcion:gestionar_pago',
          },
          openUrl: (_) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Elegir plan'), findsNothing);
    expect(find.text('Administrar pago'), findsOneWidget);
  });
}
