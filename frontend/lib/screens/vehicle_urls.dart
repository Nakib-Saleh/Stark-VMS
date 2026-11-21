import '../models/vehicle.dart';
import '../providers/vehicle_providers.dart';

/// The register's place lives in the URL (DESIGN.md rule 9), so refresh and Back keep it.
/// `?page=` is 1-based for people; [VehicleQuery.page] is 0-based like the API.
VehicleQuery vehicleQueryFromUri(Uri uri) {
  final p = uri.queryParameters;
  final page = int.tryParse(p['page'] ?? '') ?? 1;
  final q = p['q']?.trim();
  return (
    page: page < 1 ? 0 : page - 1,
    q: q == null || q.isEmpty ? null : q,
    status: VehicleStatus.values.where((s) => s.name == p['status']).firstOrNull,
  );
}

/// [path] with the register's place kept, e.g. `/vehicles/5?page=2&q=toyota`.
String vehiclesUrl(VehicleQuery query, {String path = '/vehicles'}) {
  final params = {
    if (query.page > 0) 'page': '${query.page + 1}',
    if (query.q != null) 'q': query.q!,
    if (query.status != null) 'status': query.status!.name,
  };
  return Uri(path: path, queryParameters: params.isEmpty ? null : params).toString();
}

const VehicleQuery firstPage = (page: 0, q: null, status: null);
