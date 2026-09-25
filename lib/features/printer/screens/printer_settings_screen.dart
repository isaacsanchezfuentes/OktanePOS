import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../services/thermal_printer_service.dart';

class PrinterSettingsScreen extends StatefulWidget {
  final ThermalPrinterService? printerService;

  const PrinterSettingsScreen({
    super.key,
    this.printerService,
  });

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  late final ThermalPrinterService _printerService;

  List<BluetoothInfo> _devices = [];
  bool _isLoading = true;
  bool _isConnected = false;
  String? _selectedMac;
  String? _selectedName;

  @override
  void initState() {
    super.initState();
    _printerService = widget.printerService ?? ThermalPrinterService();
    _loadPrinterData();
  }

  Future<void> _loadPrinterData() async {
    setState(() => _isLoading = true);

    try {
      final connected = await _printerService.isConnected();
      final savedMac = await _printerService.getSavedPrinterMac();
      final savedName = await _printerService.getSavedPrinterName();
      final devicesList = await _printerService.getPairedDevices();

      if (mounted) {
        setState(() {
          _isConnected = connected;
          _selectedMac = savedMac;
          _selectedName = savedName;
          _devices = devicesList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _connectDevice(BluetoothInfo device) async {
    setState(() => _isLoading = true);

    final success = await _printerService.connect(device.macAdress, name: device.name);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isConnected = success;
        _selectedMac = device.macAdress;
        _selectedName = device.name;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? '✅ Conectado a ${device.name}' 
                : '❌ No se pudo conectar a ${device.name}',
          ),
          backgroundColor: success ? Colors.green[700] : Colors.red[700],
        ),
      );
    }
  }

  Future<void> _disconnectDevice() async {
    setState(() => _isLoading = true);

    await _printerService.disconnect();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isConnected = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impresora desconectada')),
      );
    }
  }

  Future<void> _sendTestTicket() async {
    setState(() => _isLoading = true);

    final success = await _printerService.printTestTicket();

    if (mounted) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? '✅ Ticket de prueba enviado exitosamente' 
                : '❌ Falló el envío del ticket de prueba',
          ),
          backgroundColor: success ? Colors.green[700] : Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impresora Térmica', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Buscar Impresoras',
            onPressed: _loadPrinterData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Active Status Banner
                _buildStatusBanner(),

                // Header title
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.bluetooth, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Dispositivos Bluetooth Vinculados',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // List of Devices
                Expanded(
                  child: _devices.isEmpty
                      ? _buildEmptyDevicesState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _devices.length,
                          itemBuilder: (context, index) {
                            final device = _devices[index];
                            final isCurrentSelected = _selectedMac == device.macAdress;

                            return Card(
                              elevation: isCurrentSelected ? 3 : 1,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isCurrentSelected ? Colors.blue : Colors.grey[300]!,
                                  width: isCurrentSelected ? 2 : 1,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isCurrentSelected
                                      ? Colors.blue[100]
                                      : Colors.grey[200],
                                  child: Icon(
                                    Icons.print,
                                    color: isCurrentSelected ? Colors.blue[900] : Colors.grey[700],
                                  ),
                                ),
                                title: Text(
                                  device.name.isEmpty ? 'Dispositivo Desconocido' : device.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('MAC: ${device.macAdress}'),
                                trailing: isCurrentSelected && _isConnected
                                    ? Chip(
                                        avatar: const Icon(Icons.check_circle, color: Colors.white, size: 16),
                                        label: const Text('Conectado', style: TextStyle(color: Colors.white, fontSize: 12)),
                                        backgroundColor: Colors.green[700],
                                      )
                                    : ElevatedButton(
                                        onPressed: () => _connectDevice(device),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Conectar'),
                                      ),
                              ),
                            );
                          },
                        ),
                ),

                // Bottom Action Button: Send Test Ticket
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isConnected ? _sendTestTicket : null,
                      icon: const Icon(Icons.receipt_long),
                      label: const Text(
                        'ENVIAR TICKET DE PRUEBA',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusBanner() {
    final statusColor = _isConnected ? Colors.green[700]! : Colors.orange[800]!;

    return Container(
      width: double.infinity,
      color: statusColor.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.print : Icons.print_disabled,
            color: statusColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected
                      ? 'Impresora Conectada: ${_selectedName ?? 'Térmica'}'
                      : 'Sin Impresora Conectada',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  _selectedMac != null
                      ? 'MAC predeterminada: $_selectedMac'
                      : 'Seleccione una impresora vinculada para guardar',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          if (_isConnected)
            TextButton(
              onPressed: _disconnectDevice,
              child: const Text('Desconectar', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyDevicesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_disabled, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text(
            'No se encontraron impresoras vinculadas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Vincule su impresora en los ajustes de Bluetooth de Android',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadPrinterData,
            icon: const Icon(Icons.refresh),
            label: const Text('Buscar de nuevo'),
          ),
        ],
      ),
    );
  }
}
