# All Your Fault

This sample project uses US Geological Survey data to animate earthquakes on a map.

This project is written in Swift 1.2. You need Xcode 6.4 to build and run it. The app supports iPhones and iPads running iOS 8.

USGS offers the last month of seismic recording data. When you pan or zoom the map, the app loads the 100 most severe recorded earthquakes in the past month for that area. Earthquakes ("Features") are shown both on the map and on a timeline. From there you can play and pause an animation spanning the month. You can also drag or swipe the timeline view, and the animation will keep up. Animations even work while you pan and zoom the map, so long as you don't lift up your finger and cause a load.

In addition to all these custom views, the app has a from-scratch model layer including object mapping, failure handling, and repeatable requests. I heard JSON parsing is all the rage.

If you're interested to see how I planned this project and built it, my working notes are in [Plan.md](./Plan.md).

Enjoy! -Kevin Conner
