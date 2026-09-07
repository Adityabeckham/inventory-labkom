import '../../../core/network/api_client.dart';
import '../domain/ringkasan.dart';

/// FR-10 Dashboard.
class DashboardRepository {
  const DashboardRepository(this._api);

  final ApiClient _api;

  Future<RingkasanDashboard> ambil() async {
    final data = await _api.get('/api/dashboard') as Map<String, dynamic>;
    return RingkasanDashboard.fromJson(data);
  }
}
