import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDevice> devices = [];
  bool isConnecting = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _getPairedDevices();
  }

  Future<void> _getPairedDevices() async {
    List<BluetoothDevice> bondedDevices = [];
    try {
      bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      devices = bondedDevices;
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
    });

    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress(
        device.address,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${device.name} 연결 성공!')));
        Navigator.pop(context, connection);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('연결 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('블루투스 기기 연결')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('블루투스 상태'),
            value: _bluetoothState.isEnabled,
            onChanged: (bool value) {
              if (value) {
                FlutterBluetoothSerial.instance.requestEnable();
              } else {
                FlutterBluetoothSerial.instance.requestDisable();
              }
              Future.delayed(
                const Duration(milliseconds: 500),
                _getPairedDevices,
              );
            },
          ),
          ListTile(
            title: const Text('페어링된 기기 목록'),
            subtitle: const Text('라즈베리파이를 기기 블루투스 설정에서 먼저 페어링하세요.'),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _getPairedDevices,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = devices[index];
                return ListTile(
                  title: Text(device.name ?? "알 수 없는 기기"),
                  subtitle: Text(device.address),
                  trailing: isConnecting
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () => _connect(device),
                          child: const Text('연결'),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
