import 'package:flutter/material.dart';
import 'package:mobile_ssas_rrhh/features/auth/services/staff_api.dart';
import 'package:mobile_ssas_rrhh/shared/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

typedef PaymentUrlOpener = Future<bool> Function(Uri url);

class SuscripcionPage extends StatefulWidget {
  const SuscripcionPage({
    super.key,
    required this.api,
    required this.permissions,
    this.openUrl,
  });

  final StaffApi api;
  final Set<String> permissions;
  final PaymentUrlOpener? openUrl;

  @override
  State<SuscripcionPage> createState() => _SuscripcionPageState();
}

class _SuscripcionPageState extends State<SuscripcionPage>
    with WidgetsBindingObserver {
  late Future<_SubscriptionData> _future;
  bool _busy = false;
  bool _returningFromPayment = false;
  String? _message;

  bool get _canBuy => widget.permissions.contains('suscripcion:contratar');
  bool get _canManage =>
      widget.permissions.contains('suscripcion:gestionar_pago');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _future = _fetch();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _returningFromPayment) {
      _reload();
    }
  }

  Future<_SubscriptionData> _fetch() async {
    final subscription = await widget.api.subscription();
    final plans = await widget.api.subscriptionPlans();
    Map<String, dynamic>? consumption;
    try {
      consumption = await widget.api.subscriptionConsumption();
    } on StaffApiException {
      // El estado y los planes siguen disponibles aunque falle el consumo.
    }
    return _SubscriptionData(subscription, plans, consumption);
  }

  void _reload() => setState(() {
    _future = _fetch();
  });

  Future<void> _openPayment(
    Future<String> Function() createUrl,
    String expectedHost,
  ) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final url = Uri.tryParse(await createUrl());
      if (url == null || url.scheme != 'https' || url.host != expectedHost) {
        throw const FormatException('La dirección de pago no es válida.');
      }
      final opened =
          await (widget.openUrl?.call(url) ??
              launchUrl(url, mode: LaunchMode.externalApplication));
      if (!opened) {
        throw const FormatException('No se pudo abrir el navegador.');
      }
      if (mounted) {
        setState(() {
          _returningFromPayment = true;
          _message = 'Al volver del pago, actualiza para consultar su estado.';
        });
      }
    } on StaffApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on Exception {
      if (mounted) {
        setState(() => _message = 'No se pudo abrir la página de pago.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(Object? value) {
    if (value is! String) return 'Sin programar';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'Sin programar';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mi suscripción'),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _busy ? null : _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<_SubscriptionData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudo cargar la suscripción.'),
                TextButton(onPressed: _reload, child: const Text('Reintentar')),
              ],
            ),
          );
        }
        final data = snapshot.data!;
        final subscription = data.subscription;
        final currentPlan = subscription['plan'] as Map<String, dynamic>;
        final status = '${subscription['estado'] ?? 'PENDIENTE'}';
        final activePaid =
            subscription['stripe_subscription_id'] != null &&
            (status == 'ACTIVA' || status == 'PRUEBA');
        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            try {
              await _future;
            } on Exception {
              // FutureBuilder muestra el error y permite reintentar.
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _message!,
                    style: const TextStyle(color: AppColors.azul700),
                  ),
                ),
              Text(
                'Plan actual',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${currentPlan['nombre'] ?? 'Sin plan'}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text('Estado: $status'),
              Text(
                'Precio: ${currentPlan['precio_mensual'] ?? '0'} '
                '${currentPlan['moneda'] ?? ''} / mes',
              ),
              Text(
                'Próximo cobro: ${_date(subscription['fecha_proximo_cobro'])}',
              ),
              if (_canManage && subscription['stripe_customer_id'] != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _openPayment(
                          widget.api.createSubscriptionPortal,
                          'billing.stripe.com',
                        ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Administrar pago'),
                ),
              ],
              if (data.consumption != null) ...[
                const Divider(height: 32),
                Text('Consumo', style: Theme.of(context).textTheme.titleMedium),
                _usage('Usuarios', data.consumption!['usuarios']),
                _usage(
                  'Vacantes activas',
                  data.consumption!['vacantes_activas'],
                ),
                _usage(
                  'Almacenamiento MB',
                  data.consumption!['almacenamiento_mb'],
                ),
              ],
              const Divider(height: 32),
              Text(
                'Planes disponibles',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (activePaid)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Para cambiar un plan activo, usa Administrar pago.',
                  ),
                ),
              for (final plan in data.plans)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${plan['nombre'] ?? 'Plan'}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (plan['id'] == currentPlan['id'])
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.verde600,
                              ),
                          ],
                        ),
                        if (plan['descripcion'] is String &&
                            (plan['descripcion'] as String).isNotEmpty)
                          Text(plan['descripcion'] as String),
                        const SizedBox(height: 8),
                        Text(
                          '${plan['precio_mensual'] ?? '0'} '
                          '${plan['moneda'] ?? ''} / mes',
                        ),
                        Text(
                          '${plan['max_usuarios'] ?? 0} usuarios · '
                          '${plan['max_vacantes_activas'] ?? 0} vacantes',
                        ),
                        if (_canBuy &&
                            !activePaid &&
                            plan['stripe_price_id'] != null) ...[
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _openPayment(
                                    () => widget.api.createSubscriptionCheckout(
                                      '${plan['id']}',
                                    ),
                                    'checkout.stripe.com',
                                  ),
                            icon: const Icon(Icons.credit_card),
                            label: const Text('Elegir plan'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );

  Widget _usage(String title, Object? value) {
    if (value is! Map) return const SizedBox.shrink();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: Text('${value['usado'] ?? 0} / ${value['limite'] ?? 0}'),
    );
  }
}

class _SubscriptionData {
  const _SubscriptionData(this.subscription, this.plans, this.consumption);

  final Map<String, dynamic> subscription;
  final List<Map<String, dynamic>> plans;
  final Map<String, dynamic>? consumption;
}
