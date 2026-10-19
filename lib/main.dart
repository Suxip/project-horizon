import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}
const double LEFT_INDENT = 25;

class MainApp extends StatefulWidget {
  const MainApp({super.key});
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp>{
  ///
  // Main app is stateful so that it can own the stream (has initState())
  late final TestStreamSource source;
  late final Stream<String> statusStream;

  @override
  void initState() { // need to add stream
    super.initState();
    source = TestStreamSource();
    statusStream = source.messages;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column (
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(LEFT_INDENT+10, 50, 0, 0), // placement with respect to edge
                child: Text(
                  "Live output", 
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // 3 boxes
            HardwareStatus(),
            ModelStatus(),
            StreamStatusBox(stream: statusStream),
            // text box here
          ],
        )
      ),
    );
  }
}

/*
  Box 1: Hardware status
  Currently has placeholder button to change box color, later we would want to have red/green circle icon
  instead of the button and functionality to change color upon trigger (which would be connection success)
*/
class HardwareStatus extends StatefulWidget {
  const HardwareStatus({super.key});
  @override
  State<HardwareStatus> createState() => _HardwareStatusState();
}

class _HardwareStatusState extends State<HardwareStatus> {
  // etc
  Color boxcol = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(LEFT_INDENT, 15, 100, 5), // distance from edge (left/right edges == screen edge; top/bottom edges == Text/ModelStatus widgets)
      decoration: BoxDecoration(
        color: boxcol,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(width: 2, color: Colors.black),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // aligns children to the left
        crossAxisAlignment: CrossAxisAlignment.center, // vertical alignment
        children: [
          Container(     
            padding: EdgeInsets.fromLTRB(25, 25, 15, 25), // distance from box edges    
            child: Align(alignment: Alignment.centerLeft, child: Text("Hardware Status", style:TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          ),
          Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                boxcol = boxcol == Colors.red ? Colors.blue : Colors.red;
              });
              print("CHANGE COLOR wooaaaa");
            },
            icon: const Icon(Icons.circle),
            iconSize: 40,
          )
        ],
      )
    );
  }
}

class ModelStatus extends StatefulWidget { // copy of hardware status state
  const ModelStatus({super.key});
  @override
  State<ModelStatus> createState() => _ModelStatusState();
}

class _ModelStatusState extends State<ModelStatus> {
  // etc
  Color boxcol = Colors.green;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(LEFT_INDENT, 5, 100, 5), // distance from edge (left/right edges == screen edge; top/bottom edges == ModelStatus/StreamStatus widgets)
      decoration: BoxDecoration(
        color: boxcol,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(width: 2, color: Colors.black),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // aligns children to the left
        crossAxisAlignment: CrossAxisAlignment.center, // vertical alignment
        children: [
          Container(     
            padding: EdgeInsets.fromLTRB(25, 25, 15, 25), // distance from box edges     
            child: Align(alignment: Alignment.centerLeft, child: Text("Model Status", style:TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          ),
          Spacer(), // dynamic fill of space btwn Text and Button
          IconButton(
            onPressed: () {
              setState(() {
                boxcol = boxcol == Colors.red ? Colors.green : Colors.red;
              });
              print("CHANGE COLOR wooaaaa");
            },
            icon: const Icon(Icons.circle),
            iconSize: 40,
          )
        ],
      )
    );
  }
}

class TestStreamSource { // to replace w sensor output, just outputs tests[i] on 1.5s intervals
  late final Stream<String> messages = _generateMessages();
  final Duration delay = Duration(seconds: 1, milliseconds: 500);

  Stream<String> _generateMessages() async* {
    List<String> tests = ["test test test", "table ahead", "beep boop", "Anna is standing 10 feet ahead facing you", "Halt!"];
    int ind = 0;
    while (ind < tests.length) {
      await Future<void>.delayed(delay); // wait delay
      yield tests[ind];
      ind++;
    }
    // close stream? won't be necessary when we actually have a stream since we want it to stay open
  }
}

class StreamStatusBox extends StatelessWidget{
  const StreamStatusBox({super.key, required this.stream});
  final Stream<String> stream; // input stream will be yolo output?
  // need a stream to connect yolo model and bluetooth output

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 10, LEFT_INDENT, 25), // 25 pixels of spacing below SizedBox 
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(width: 2, color: Colors.black),
      ),
      child: SizedBox(
        width: 325, // experimental values
        height: 400,
        child: Container(
          margin: EdgeInsets.all(20), // text spacing from edges of SizedBox
          child: Align(
            alignment: Alignment.topLeft,
            child: StreamBuilder<String>(
              stream: stream,
              builder: (context, snapshot) { 
                // upon post to stream, this is called with BuildContext context and AsyncSnapshot<String> which has the string in .data (maybe timestamp in .timestamp?)
                return Text(
                  snapshot.data ?? "hi",
                  style: TextStyle(fontSize: 24),
                );
              }
            ) 
          ),
        ), // this container is for spacing from edges of box
      ),
    );
  }
}

