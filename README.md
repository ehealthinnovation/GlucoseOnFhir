# GlucoseOnFhir

This application demonstrates acquiring data from a Glucose Profile-compliant glucose meter, and uploading all necessary resources to a FHIR server.

###### Discovery of local FHIR server

If you wish to use your own FHIR server instance, run the following from a terminal window: 'dns-sd -R "fhir" _http._tcp . 8080'
This will advertise the server on the local network using mDNS. The application will then allow you to select either the local FHIR instance, or the UHN FHIR test server.
