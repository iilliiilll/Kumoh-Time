import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
// ignore: unused_import
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationSelectScreen extends StatefulWidget {
  const LocationSelectScreen({super.key});

  @override
  State<LocationSelectScreen> createState() => _LocationSelectScreenState();
}

class _LocationSelectScreenState extends State<LocationSelectScreen> {
  late NaverMapController _mapController;
  NLatLng? selectedLocation;
  String? selectedLocationName;
  NMarker? currentMarker;
  String? selectedLocationUrl;

  String generateNaverMapUrl(NLatLng location, String locationName) {
    final encodedName = Uri.encodeComponent(locationName.split('\n')[0]);
    return 'https://map.naver.com/v5/search/$encodedName/@${location.longitude},${location.latitude}';
  }

  void shareLocation() {
    if (selectedLocation != null && selectedLocationName != null) {
      final mapUrl =
          generateNaverMapUrl(selectedLocation!, selectedLocationName!);
      setState(() {
        selectedLocationUrl = mapUrl;
      });

      Navigator.pop(context, {
        'location': selectedLocation,
        'address': selectedLocationName,
        'mapUrl': mapUrl,
      });
    }
  }

  Future<String?> getLocationName(NLatLng location) async {
    try {
      final placeUrl = Uri.parse(
          'https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc'
          '?coords=${location.longitude},${location.latitude}'
          '&orders=roadaddr,addr,admcode'
          '&output=json');

      final placeResponse = await http.get(
        placeUrl,
        headers: {
          'X-NCP-APIGW-API-KEY-ID': 'sz6ox5ptsq',
          'X-NCP-APIGW-API-KEY': 'ckR1Ml6JjntgqaZLPIoKcw0Gy0poarvsVVRzc32V',
        },
      );

      if (placeResponse.statusCode == 200) {
        final data = json.decode(placeResponse.body);
        final results = data['results'];

        String address = '';

        final roadAddr = results.firstWhere(
            (result) => result['name'] == 'roadaddr',
            orElse: () => null);

        if (roadAddr != null) {
          final region = roadAddr['region'];
          final land = roadAddr['land'];
          address =
              '${region['area1']['name']} ${region['area2']['name']} ${region['area3']['name']} ${land['name']}';
          if (land['number1'] != null) {
            address += ' ${land['number1']}';
          }
          if (land['building'] != null) {
            address += ' ${land['building']['name']}';
          }
        } else {
          final jibunAddr = results.firstWhere(
              (result) => result['name'] == 'addr',
              orElse: () => null);

          if (jibunAddr != null) {
            final region = jibunAddr['region'];
            final land = jibunAddr['land'];
            address =
                '${region['area1']['name']} ${region['area2']['name']} ${region['area3']['name']} ${land['number1']}';
          }
        }

        return address;
      }
      return '주소를 찾을 수 없습니다';
    } catch (e) {
      return '위치 정보 조회 중 오류가 발생했습니다';
    }
  }

  void updateMarker(NLatLng position) {
    _mapController.clearOverlays();

    currentMarker = NMarker(
      id: 'selected_location',
      position: position,
    );

    _mapController.addOverlay(currentMarker!);
  }

  Widget _buildMap() {
    if (kIsWeb) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('웹에서는 위치 선택을 사용할 수 없습니다.'),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'location': const NLatLng(36.141587443678, 128.39538542686),
                  'address': '기본 위치'
                });
              },
              child: const Text('기본 위치 사용'),
            ),
          ],
        ),
      );
    }

    return NaverMap(
      options: const NaverMapViewOptions(
        indoorEnable: true,
        locationButtonEnable: true,
        initialCameraPosition: NCameraPosition(
          target: NLatLng(36.141587443678, 128.39538542686),
          zoom: 15,
        ),
      ),
      onMapReady: (controller) {
        _mapController = controller;
      },
      onMapTapped: (point, latLng) async {
        setState(() {
          selectedLocation = latLng;
          selectedLocationName = '위치 확인 중...';
        });

        updateMarker(latLng);
        final name = await getLocationName(latLng);
        setState(() {
          selectedLocationName = name;
        });
      },
      onSymbolTapped: (symbol) async {
        final location = symbol.position;
        setState(() {
          selectedLocation = location;
          selectedLocationName = '위치 확인 중...';
        });

        updateMarker(location);
        String name = symbol.caption;
        final address = await getLocationName(location);
        setState(() {
          selectedLocationName = '$name\n$address';
        });
      },
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedLocationName!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_location),
            onPressed: shareLocation,
            tooltip: '위치 공유하기',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('위치 선택'),
        actions: [
          TextButton(
            onPressed: () {
              if (selectedLocation != null || kIsWeb) {
                final mapUrl =
                    selectedLocation != null && selectedLocationName != null
                        ? generateNaverMapUrl(
                            selectedLocation!, selectedLocationName!)
                        : null;
                Navigator.pop(context, {
                  'location': selectedLocation ??
                      const NLatLng(36.141587443678, 128.39538542686),
                  'address': selectedLocationName ?? '선택된 위치',
                  'mapUrl': mapUrl,
                });
              }
            },
            child: const Text('선택', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Stack(
        children: [
          _buildMap(),
          if (selectedLocationName != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildLocationInfo(),
            ),
        ],
      ),
    );
  }
}
