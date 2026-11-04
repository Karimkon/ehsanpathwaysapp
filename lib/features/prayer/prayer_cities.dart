import 'package:ehsan_pathways/core/services/prayer_times_service.dart';

/// A city users can pick when they would rather not share their location.
/// Prayer times are calculated on the device, so this works offline.
class PrayerCity {
  const PrayerCity(
    this.name,
    this.country,
    this.lat,
    this.lng,
    this.method, {
    this.hanafi = false,
  });

  final String name;
  final String country;
  final double lat;
  final double lng;

  /// The calculation method customary in that region.
  final PrayerCalculationMethod method;

  /// Whether Hanafi Asr is the local norm.
  final bool hanafi;

  String get label => '$name, $country';
}

const _mwl = PrayerCalculationMethod.muslimWorldLeague;
const _isna = PrayerCalculationMethod.northAmerica;
const _egypt = PrayerCalculationMethod.egyptian;
const _uaq = PrayerCalculationMethod.ummAlQura;
const _karachi = PrayerCalculationMethod.karachi;
const _kuwait = PrayerCalculationMethod.kuwait;
const _qatar = PrayerCalculationMethod.qatar;
const _sg = PrayerCalculationMethod.singapore;
const _turkey = PrayerCalculationMethod.turkey;
const _tehran = PrayerCalculationMethod.tehran;

const kPrayerCities = <PrayerCity>[
  // Haramayn and the Middle East
  PrayerCity('Makkah', 'Saudi Arabia', 21.4225, 39.8262, _uaq),
  PrayerCity('Madinah', 'Saudi Arabia', 24.4672, 39.6111, _uaq),
  PrayerCity('Riyadh', 'Saudi Arabia', 24.7136, 46.6753, _uaq),
  PrayerCity('Jeddah', 'Saudi Arabia', 21.4858, 39.1925, _uaq),
  PrayerCity('Al-Quds (Jerusalem)', 'Palestine', 31.7683, 35.2137, _mwl),
  PrayerCity('Dubai', 'UAE', 25.2048, 55.2708, _uaq),
  PrayerCity('Abu Dhabi', 'UAE', 24.4539, 54.3773, _uaq),
  PrayerCity('Doha', 'Qatar', 25.2854, 51.5310, _qatar),
  PrayerCity('Kuwait City', 'Kuwait', 29.3759, 47.9774, _kuwait),
  PrayerCity('Manama', 'Bahrain', 26.2285, 50.5860, _uaq),
  PrayerCity('Muscat', 'Oman', 23.5880, 58.3829, _uaq),
  PrayerCity('Amman', 'Jordan', 31.9454, 35.9284, _mwl),
  PrayerCity('Beirut', 'Lebanon', 33.8938, 35.5018, _mwl),
  PrayerCity('Damascus', 'Syria', 33.5138, 36.2765, _egypt),
  PrayerCity('Baghdad', 'Iraq', 33.3152, 44.3661, _mwl),
  PrayerCity('Tehran', 'Iran', 35.6892, 51.3890, _tehran),
  PrayerCity('Istanbul', 'Türkiye', 41.0082, 28.9784, _turkey, hanafi: true),
  PrayerCity('Ankara', 'Türkiye', 39.9334, 32.8597, _turkey, hanafi: true),
  // Africa
  PrayerCity('Cairo', 'Egypt', 30.0444, 31.2357, _egypt),
  PrayerCity('Alexandria', 'Egypt', 31.2001, 29.9187, _egypt),
  PrayerCity('Khartoum', 'Sudan', 15.5007, 32.5599, _egypt),
  PrayerCity('Tripoli', 'Libya', 32.8872, 13.1913, _egypt),
  PrayerCity('Tunis', 'Tunisia', 36.8065, 10.1815, _mwl),
  PrayerCity('Algiers', 'Algeria', 36.7538, 3.0588, _mwl),
  PrayerCity('Casablanca', 'Morocco', 33.5731, -7.5898, _mwl),
  PrayerCity('Rabat', 'Morocco', 34.0209, -6.8416, _mwl),
  PrayerCity('Dakar', 'Senegal', 14.7167, -17.4677, _mwl),
  PrayerCity('Lagos', 'Nigeria', 6.5244, 3.3792, _mwl),
  PrayerCity('Abuja', 'Nigeria', 9.0765, 7.3986, _mwl),
  PrayerCity('Kano', 'Nigeria', 12.0022, 8.5920, _mwl),
  PrayerCity('Accra', 'Ghana', 5.6037, -0.1870, _mwl),
  PrayerCity('Kampala', 'Uganda', 0.3476, 32.5825, _mwl),
  PrayerCity('Nairobi', 'Kenya', -1.2921, 36.8219, _mwl),
  PrayerCity('Mombasa', 'Kenya', -4.0435, 39.6682, _mwl),
  PrayerCity('Dar es Salaam', 'Tanzania', -6.7924, 39.2083, _mwl),
  PrayerCity('Zanzibar', 'Tanzania', -6.1659, 39.2026, _mwl),
  PrayerCity('Mogadishu', 'Somalia', 2.0469, 45.3182, _mwl),
  PrayerCity('Addis Ababa', 'Ethiopia', 8.9806, 38.7578, _mwl),
  PrayerCity(
    'Johannesburg',
    'South Africa',
    -26.2041,
    28.0473,
    _mwl,
    hanafi: true,
  ),
  PrayerCity('Cape Town', 'South Africa', -33.9249, 18.4241, _mwl),
  PrayerCity('Durban', 'South Africa', -29.8587, 31.0218, _mwl, hanafi: true),
  // South and Central Asia
  PrayerCity('Karachi', 'Pakistan', 24.8607, 67.0011, _karachi, hanafi: true),
  PrayerCity('Lahore', 'Pakistan', 31.5204, 74.3587, _karachi, hanafi: true),
  PrayerCity('Islamabad', 'Pakistan', 33.6844, 73.0479, _karachi, hanafi: true),
  PrayerCity('Delhi', 'India', 28.7041, 77.1025, _karachi, hanafi: true),
  PrayerCity('Mumbai', 'India', 19.0760, 72.8777, _karachi, hanafi: true),
  PrayerCity('Hyderabad', 'India', 17.3850, 78.4867, _karachi, hanafi: true),
  PrayerCity('Dhaka', 'Bangladesh', 23.8103, 90.4125, _karachi, hanafi: true),
  PrayerCity('Kabul', 'Afghanistan', 34.5553, 69.2075, _karachi, hanafi: true),
  PrayerCity('Tashkent', 'Uzbekistan', 41.2995, 69.2401, _mwl, hanafi: true),
  // South-East and East Asia
  PrayerCity('Kuala Lumpur', 'Malaysia', 3.1390, 101.6869, _sg),
  PrayerCity('Singapore', 'Singapore', 1.3521, 103.8198, _sg),
  PrayerCity('Jakarta', 'Indonesia', -6.2088, 106.8456, _sg),
  PrayerCity('Surabaya', 'Indonesia', -7.2575, 112.7521, _sg),
  PrayerCity('Manila', 'Philippines', 14.5995, 120.9842, _mwl),
  PrayerCity('Beijing', 'China', 39.9042, 116.4074, _mwl),
  // Europe
  PrayerCity('London', 'United Kingdom', 51.5074, -0.1278, _mwl),
  PrayerCity(
    'Birmingham',
    'United Kingdom',
    52.4862,
    -1.8904,
    _mwl,
    hanafi: true,
  ),
  PrayerCity('Manchester', 'United Kingdom', 53.4808, -2.2426, _mwl),
  PrayerCity('Paris', 'France', 48.8566, 2.3522, _mwl),
  PrayerCity('Berlin', 'Germany', 52.5200, 13.4050, _mwl),
  PrayerCity('Amsterdam', 'Netherlands', 52.3676, 4.9041, _mwl),
  PrayerCity('Brussels', 'Belgium', 50.8503, 4.3517, _mwl),
  PrayerCity('Stockholm', 'Sweden', 59.3293, 18.0686, _mwl),
  PrayerCity('Oslo', 'Norway', 59.9139, 10.7522, _mwl),
  PrayerCity('Madrid', 'Spain', 40.4168, -3.7038, _mwl),
  PrayerCity('Rome', 'Italy', 41.9028, 12.4964, _mwl),
  PrayerCity(
    'Sarajevo',
    'Bosnia and Herzegovina',
    43.8563,
    18.4131,
    _mwl,
    hanafi: true,
  ),
  PrayerCity('Moscow', 'Russia', 55.7558, 37.6173, _mwl, hanafi: true),
  // Americas and Oceania
  PrayerCity('New York', 'United States', 40.7128, -74.0060, _isna),
  PrayerCity('Washington, DC', 'United States', 38.9072, -77.0369, _isna),
  PrayerCity('Chicago', 'United States', 41.8781, -87.6298, _isna),
  PrayerCity('Dearborn', 'United States', 42.3223, -83.1763, _isna),
  PrayerCity('Houston', 'United States', 29.7604, -95.3698, _isna),
  PrayerCity('Los Angeles', 'United States', 34.0522, -118.2437, _isna),
  PrayerCity('Toronto', 'Canada', 43.6532, -79.3832, _isna),
  PrayerCity('Montreal', 'Canada', 45.5019, -73.5674, _isna),
  PrayerCity('São Paulo', 'Brazil', -23.5505, -46.6333, _mwl),
  PrayerCity('Sydney', 'Australia', -33.8688, 151.2093, _mwl),
  PrayerCity('Melbourne', 'Australia', -37.8136, 144.9631, _mwl),
  PrayerCity('Auckland', 'New Zealand', -36.8485, 174.7633, _mwl),
];
