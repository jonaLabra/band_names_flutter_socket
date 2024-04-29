import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket!.on('active-bands', _handleActiveBands);
    super.initState();
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket!.off('active-bands');
    super.dispose();
  }

  _handleActiveBands(dynamic payload) {
    bands = (payload as List).map((band) => Band.fromMap(band)).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: socketService.serverStatus == ServerStatus.Online
                ? const Icon(
                    Icons.check_circle_sharp,
                    color: Colors.blue,
                  )
                : const Icon(
                    Icons.offline_bolt,
                    color: Colors.red,
                  ),
          )
        ],
        title: const Text(
          'BAND NAMES',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _showGraph(),
          Expanded(
            child: ListView.builder(
                itemCount: bands.length,
                itemBuilder: (context, i) =>
                    _bandTile(bands[i], socketService)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          elevation: 1, onPressed: addNewBand, child: const Icon(Icons.add)),
    );
  }

  Widget _bandTile(Band band, SocketService socketService) => Dismissible(
        key: Key(band.id!),
        direction: DismissDirection.startToEnd,
        onDismissed: (_) => socketService.emit('delete-band', {'id': band.id}),
        background: Container(
          padding: const EdgeInsets.only(left: 8.0),
          color: Colors.red,
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Delete Band',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(band.name!.substring(0, 2)),
          ),
          title: Text(band.name!),
          trailing: Text(
            '${band.votes}',
            style: const TextStyle(fontSize: 20),
          ),
          onTap: () => socketService.emit('vote-band', {'id': band.id}),
        ),
      );

  addNewBand() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    final textController = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog.adaptive(
              title: const Text('New Band Name:'),
              content: Material(
                child: TextField(
                  controller: textController,
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Add'),
                  onPressed: () =>
                      addBandToList(textController.text, socketService),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Dismiss'),
                )
              ],
            ));
  }

  void addBandToList(String name, SocketService socketService) {
    if (name.length > 1) {
      socketService.emit('add-band', {'name': name});
    }

    Navigator.pop(context);
  }

  Widget _showGraph() {
    Map<String, double> dataMap = {};

    for (var band in bands) {
      dataMap.putIfAbsent(band.name!, () => band.votes!.toDouble());
    }
    return dataMap.isNotEmpty
        ? Container(
            padding: const EdgeInsets.only(top: 10),
            width: double.infinity,
            height: 200,
            child: PieChart(
              dataMap: dataMap,
              animationDuration: const Duration(milliseconds: 800),
              chartLegendSpacing: 32,
              chartRadius: MediaQuery.of(context).size.width / 3.2,
              //colorList: colorList,
              initialAngleInDegree: 0,
              chartType: ChartType.ring,
              ringStrokeWidth: 32,
              //centerText: "HYBRID",
              legendOptions: const LegendOptions(
                showLegendsInRow: false,
                legendPosition: LegendPosition.right,
                showLegends: true,
                legendShape: BoxShape.circle,
                legendTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              chartValuesOptions: const ChartValuesOptions(
                showChartValueBackground: true,
                showChartValues: true,
                showChartValuesInPercentage: false,
                showChartValuesOutside: false,
                decimalPlaces: 1,
              ),
            ))
        : const Center(
            child: CircularProgressIndicator.adaptive(),
          );
  }
}
