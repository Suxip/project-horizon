Progress Report: 
11/21/26, Ben

My objective this week was to get the functionality for Bluetooth transmission available for RPI to desktop app. 
I implemented computer bluetooth data reception in the Serial Transport class and set up the app so that (this is untested) upon transfer button click, we will listen for a stream on the desktop COM3 port using bluetooth (can change to another port). Upon completion of the photo bytes being sent over, it should save to our temp directory.

For moving forward, I'd like if we could test with the RPI sending an image, and then multiple images over. For multiple image functionality, some minor restructuring needs to be done (see Transfer Coordinator notes). After that it needs to be adjusted to be functional on Android which would require switching to the Bluetooth Transport class. 
For now I'd like to see us getting the same functionality the other way: sending audio from app to RPI. It'd be similar implementation but only this time in reverse: we'd need to implement streaming from app and reception on RPI. As well I would say we should work on getting ML functionality online next, going from a saved image file to text output in the app.

---
Some more low level details (not super important):
Photo Transport (which is an interface) contains the input stream, for example in Serial Transport it is the stream from the port and in Mock Transport it is a stream constructed from a local file. Provided some parameters (e.g. port name), its only job is to output a stream that contains all of the data for the transfer ('receive()').
Photo Receiver takes in the output file and importantly it expects data to be passed in chunks which it will then write to the output file. 'startTransfer' must be called first using the filename and expectedBytes information from the 8-bit header, and only then should 'receiveChunk' be called.
Transfer Coordinator connects the Photo Transport and Receiver: Contains both objects. In its 'receivePhoto' method, it takes in a PhotoTransport; it then initializes a Photo Receiver, parses the first 8 bytes, and sends the rest of the chunks from the stream to the receiver. This process may need refactoring upon sending more than one image because here we use the stream closing as the sign that transfer is complete.