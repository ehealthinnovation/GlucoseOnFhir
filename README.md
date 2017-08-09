<center>
# GlucoseOnFHIR
</center>

GlucoseOnFHIR is an iOS application designed to collect data from a blood glucose meter that complies with the Bluetooth SIG Glucose Profile.

This application uses the CCGlucose iOS library (https://github.com/uhnmdi/CCGlucose), to connect to the meter, and download glucose records.

##### Swiftlint
GlucoseOnFhir uses swiftlint during the build process. From a terminal, run 'brew install swiftlint'. Install swiftlint to ensure the project builds without any warnings.

##### Downloading blood glucose records
Calling 'readNumberOfRecords()' will return the number of stored records on the glucose meter. Records can then be downloaded in a number of different ways:

```
//Download all records 
downloadAllRecords()

//Downloading the first record only
downloadFirstRecord()

//Downloading the last record only
downloadLastRecord()

//Download records within a range (eg. records 1 to 5)
downloadRecordsWithRange(from: 1, to: 5)

//Download records less than and equal to record number (eg. 5)
downloadRecordsLessThanAndEqualTo(recordNumber: 5)

//Download records greater than and equal to record number (eg. 5)
downloadRecordsGreaterThanAndEqualTo(recordNumber: 5)

//Download record number (eg. 5)
downloadRecordNumber(recordNumber: 5)
```

##### Uploading records to a FHIR server
Records can be uploaded to a FHIR server from within the GlucoseOnFHIR application using two different methods. Single records can be uplaoded by tapping on the row in the table. If the upload is successful, an ID will be assigned by the FHIR server, and displayed in the application.

The other method of uploading records is by tapping the 'Upload Records' button. This will upload all of the records as a Bundle to the FHIR server. All records within the application will have their FHIR ID's updated if the upload is successful.



##### Discovery of local FHIR server

Data can be uploaded to either the UHN 'fhirtest' server, or a FHIR server running on the same network as the iOS device. On the initial screen, tap "Select FHIR Server", and select from the list of discovered FHIR servers.

To run your own FHIR server, download hapi-fhir-cli from http://hapifhir.io/doc_cli.html. Extract the archive and run the server from a terminal window using the command 'hapi-fhir-cli run-server'

The FHIR server must advertise itself on the network to be discovered by the sample application. From a terminal window run the following command 'dns-sd -R "fhir" _http._tcp . 8080'
