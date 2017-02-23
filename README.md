# GlucoseOnFhir

This application demonstrates acquiring data from a Glucose Profile-compliant glucose meter, and uploading all necessary resources to a FHIR server.

###### Swiftlint
GlucoseOnFhir uses swiftlint during the build process. From a terminal, run 'brew install swiftlint'

###### Discovery of local FHIR server

To run a FHIR server on your own local network, visit: http://hapifhir.io/doc_cli.html

The local FHIR instance must advertise itself to be detected by GlucoseOnFhir. Simply run the following command from a terminal window: 'dns-sd -R "fhir" _http._tcp . 8080'

This will advertise the server on the local network using mDNS. The application will then allow you to select either the local FHIR instance, or the UHN FHIR test server.
