# Safe-Bavaria

This is a region monitoring app that pulls data from a server that contains how many cases in the last 7 days per 100,000 people were recorded and displays guidelines depending on the number of cases. There are 4 different alert levels, each containing different guidelines that are in effect and last time they were updated:

- Green
- Yellow
- Red
- Dark red

The region being monitored is - Bavaria

On launch, the app performs several tasks:
-------------------------------------------------
- Display several health related guidelines that are recommended to keep users healthy.
- Display colored controls that indicate current level of severity. The buttons are assigned different colors, according to the alert level.
- Request permission to send notifications. 
- Start 10 minute timer. In case when the app stays open, the app will automatically update the UI every 10 minutes.

Tasks performed after timer starts running (foreground):
---------------
- Request permission to use location services
- Locate user using Core Location - Utility.configureLocationManager(manager:, delegate:)
- Verify that the user is located within the region being monitored - Utility.findLocationRegion()
- Send a request to the back-end server asking for the number of cases in the last 7 days in the region - Utility.getCasesData(handler:)
- Use the # of cases to identify current alert level (gree, yellow, red or dark red) - Utility.getGuidelines(using cases:)
- Pull guidelines associated with the current alert level from a local (could be remote) file in JSON format - Utility.getGuidelines(using cases:)
- The UI is updated based on newly available data from server - displayData(using message:, time lastUpdated:)

Tasks performed in background:
-------------------------------------
- The app runs a background task to fetch data from server and update UI every 10 minutes. This is done in the AppDelegate 
- If the alert level changes, the app will send a notification asking the user to review the new guidelines and update the UI.
