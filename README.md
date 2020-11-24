# Safe-Bavaria, MVVM design pattern, developed using Swift 5.3 and Swift Package Manager.

This is a region monitoring app that pulls data from a server that contains number of cases in the last 7 days per 100,000 people were recorded and displays guidelines depending on the number of cases. There are 4 different alert levels, each containing different guidelines that are in effect:

- Green
- Yellow
- Red
- Dark red

The region being monitored is - Bavaria

On launch:
-------------------------------------------------
- Display several health related guidelines that are in effect to keep users healthy.
- Display colored controls that indicate current level of severity. The buttons are assigned different colors, according to the alert level.
- Request permission to send notifications. 
- Add an observer to listen to the notification that gets posted after user device was located.
- Start 10 minute timer. In case when the app stays open, the app will automatically update the UI every 10 minutes.

foreground:
---------------
- Request permission to use location services
- Locate user using Core Location - Utility.configureLocationManager(manager:, delegate:)
- A notification is posted to the notification center as soon as the location manager calls its didUpdateLocations method
- Verify that the user is located within the region being monitored using reverse geolocation - Utility.findLocationRegion(location:, completion:)
- Send a request to the back-end server asking for the number of cases in the last 7 days in the region - Utility.getCasesData(handler:), "cases7_bl_per_100k" & "last_update" arguments are part of the request
- Use the # of cases to identify current alert level (green, yellow, red or dark red) - Utility.getGuidelines(using cases:)
- Pull guidelines associated with the current alert level from a local (could be remote) file in JSON format - Utility.getGuidelines(using cases:)
- The UI is updated based on newly available data from server - displayData(using message:, time lastUpdated:)

background:
-------------------------------------
- The app runs a background task to locate the device, fetch data from server and update UI every 10 minutes. This is done in the AppDelegate 
- If the alert level changes, the app will send a notification asking the user to review the new guidelines and update the UI.

Localization:
---------------
- With the help of Google translate, the app has been localized for devices with german interface - Localizable.strings 

Challenges:
-------------
The most time consuming was debugging the background app refresh. The issue is that the operating system does not wake the app to perform refresh exactly when intended. There are many factors in play, including: 
    - how often and when the app gets launched by users. (The neural engine learns the routine and gives the app time to perform refresh just before user launches it again).
    - how busy the device resources (memory, cpu) are
    - how efficiently the app uses time allotted 

Resolution:
-------------
It is posible to force the app to perform a background app refresh in simulator using: e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"TASK_IDENTIFIER"]

However, this produced some false positives. It became necessary to leave the app attached to Xcode overnight and study the logs printed out in the console.

Room for improvement:
---------------------------
- Two objects are being set up as CLLocationManagerDelegate - AppDelegate & ViewController. I decided to do it this way because one needs to receive callbacks in background and one in foreground (with visual alerts if there is an error). I believe this can be achieved with just one.
- The guidelines are being displayed using animation in a UITextVIew, it might look better if it were a UITableView were each cell represents 1 guideline.


