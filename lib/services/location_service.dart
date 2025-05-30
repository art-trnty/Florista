import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<String> getCurrentAddress() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return 'Layanan lokasi nonaktif';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Izin lokasi ditolak';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return 'Izin lokasi ditolak permanen';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.street}, ${place.subLocality}, ${place.locality}";
      } else {
        return 'Alamat tidak ditemukan';
      }
    } catch (e) {
      print('❌ Gagal mendapatkan lokasi: $e');
      return 'Gagal mengambil lokasi';
    }
  }
}
