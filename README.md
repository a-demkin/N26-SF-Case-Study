# N26 Salesforce Case Study

## Task 1 - Lightning Component (LWC) for showing Product Information

Several approaches could be implemented to achieve the goal and the decision to choose one should be made only after careful discussion with stakeholders, business analysts and solution architects.
I've chosen an option with creating a custom juntion object between Contact and Product named "Card Service" (as for the moment information in tables looks like Card Service Fee). Actually, Pricebooks could also be used for the same purpose, but there is no way (at least for Winter 22 Release) to customize the process of adding products to pricebooks.
Additional fields could be added to the object metadata and then passed to Field Set without code modification and they would be shown by the component.

## Task 2 - Apex Web Service for sharing Contact Information

The decision to choose SOAP or REST web service should be based on the details of 3rd-party system which will use the endpoint and some additional requirements from business. A lot should be discussed before the implementation, lots of details should be clarified.
I decided to implement REST Web Service which takes a list of UUIDs separated by `,` sign.
Custom Metadata Types could be used to declaratively configure fields mapping (TBD).
Connected App is required to establish authorized connection between SF and external system.
