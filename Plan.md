# All Your Fault

## Prompt

Using the API provided by the [USGS Earthquake Hazards Program](http://ehp2-earthquake.wr.usgs.gov/fdsnws/event/1/), create an app that presents a map view to the user with recent earthquake events called out. Details and history would be cool too. You will be judged on beauty, poise and personality. In all seriousness - show us your creativity and your ability to produce top-notch professional software and not just the ability to get it to work.

## Research

### What's in the data?

- Always want to pass "format=geojson" and "jsonerror=true"
- Can limit queries from 1 to 20,000 quake recordings. 20,000 is the maximum.
- But, you can also offset. 1 is the default, so start at 20,001 to get the next page.
- And you can order by time ascending or descending, magnitude ascending or descending.
- There's also a count endpoint you can call first in order to decide how many requests to make.
    - This also sounds useful for calibrating the amount of data to seek for a given view.
    - So, maybe explore fetching by descending magnitude across all time as appropriate to zoom level, and as you zoom in, pull more magnitudes.
- Actually, with no constraints, the count is 8847, so we don't need to think about paging.
    - Fetching everything takes :10 to prepare and then :04-1:20 to transfer. Total data was 6660kb.
- Probably pass "eventtype=earthquake"; other seismic activity would be other "eventtype" values. By default it does not filter.
    - Fetching with eventtype=earthquake only shaved off 100k out of 6.6mb. It didn't seem to make the response slower, besides by producing more cache misses.
- Data is time-limited, can specify start and end times for boundaries.
- Data updated since some time can be fetched, which means we could bake data and fetch only what's updated.
- Data can be constrained with a lat-long box. if it crosses the IDL the horizontal should exceed 180 or -180 rather than flipping inside-out.
- Data can instead be constrained with a center and min/max radius (by spherical degrees or surface kilometers). this means a circle, ring, or everything but a circle.
- Constraining with both patterns will get the intersection, which doesn't sound useful.
- Data can be constrained with min/max depth or magnitude. A wide depth range seems always interesting, but maybe limit magnitude by zoom level or time scale?
- A quake is normally given by its "preferred origin", a seismic recording center, which I think is called a "contributor" in this API. We can get all recordings for a quake, but users probably just care about the preferred one which is the default.
- You can fetch data for a particular recording ("event ID") but I think we're more interested in showing many recordings together.
- Cases
    - 200: success with data
    - 204: success with no data to return
    - Errors: 4xx, 5xx

### Error format

    {
      "type": "FeatureCollection",
      "metadata": {
        "status": 400,
        "generated": 1438628057000,
        "url": "http://ehp2-earthquake.wr.usgs.gov/fdsnws/event/1/count?format=geojson&starttime=garbagevalue&jsonerror=true",
        "title": "Search Error",
        "api": "1.0.13",
        "count": 0,
        "error": "Bad starttime value \"garbagevalue\". Valid values are ISO-8601 timestamps."
      },
      "features": []
    }

### Constants from application.json

    {
      "catalogs": [
        "ak", "at", "ci", "gcmt", "hv", "is", "ismpkansas", "ld", "mb", "nc", "nm", "nn", "pr", "pt", "se", "us", "uu", "uw"
      ],
      "contributors": [
        "ak", "at", "ci", "hv", "ismp", "ld", "mb", "nc", "nm", "nn", "pr", "pt", "se", "us", "uu", "uw"
      ],
      "producttypes": [
        "associate", "cap", "disassociate", "dyfi", "focal-mechanism", "general-link", "general-text", "geoserve", "impact-link", "impact-text", "losspager", "moment-tensor", "nearby-cities", "origin", "phase-data", "scitech-link", "shakemap", "tectonic-summary"
      ],
      "eventtypes": [
        "acoustic noise", "acoustic_noise", "anthropogenic_event", "chemical explosion", "chemical_explosion", "earthquake", "explosion", "landslide", "mining explosion", "mining_explosion", "not_reported", "other_event", "quarry", "quarry blast", "quarry_blast", "rock_burst", "sonicboom", "sonic_boom"
      ],
      "magnitudetypes": [
        "4", "H", "m", "Mb", "MbLg", "mb_Lg", "mc", "Md", "Me", "mh", "Mi", "Ml", "mlg", "Ms", "ms_20", "Mt", "Mw", "Mwb", "Mwc", "Mwp", "Mwr", "Mww", "Unknown"
      ]
    }

## Design

- Ideas
    - Turn back the clock with a springy dial control, animate using annotation views
        - Expanding-and-fading ripples from epicenters, scaled by magnitude or somesuch?
    - Earthquake cartoon effects
        - Screen-shake, disabled if "reduce motion" accessibility setting is on
        - SpriteKit or SceneKit dust particles for big earthquakes
        - Rumble sound effects mixed live
    - Make heat maps of seismic activity in Core Image for each time segment, present as MKOverlay, animate
        - Or do it live with a terrain grid and a shader? This would sacrifice 3D view…
    - I'm not interested in a lot of filtering besides just exploring the time.
    - If annotations are filtered by time, tap one to fire its animation
    - Detail view for a given quake?
    - See underneath the map. Draw concentric blended spheres up to the surface
        - Snapshot image of map view -> SCNPlane
        - SCNSpheres
    - Name must be a pun
        - earthquake theme
            - fault
            - seismic
            - earth
            - plate tectonics
            - lithosphere
            - crust
            - shake
            - ground
            - rumble
            - epicenter
            - richter
            - log scale
            - powers of 10
        - time theme
            - time
            - history
            - clock
            - dial
        - Not My Fault
        - Everyone's Fault
        - All Your Fault (winner! hope it fits on the app icon)
        - Dial-A-Quake
        - Upper Crust
        - Boundary Conditions
        - iCrusties
- Implementation steps
    - Project structure, CocoaPods if I think I'll need it
    - IB storyboard (Just a map view to start)
    - View prototyping
        - SceneKit
            - Snapshot a map view, use as a SCNPlane texture
            - Animate a map point to center and a certain zoom level, then superimpose a SCNView and animate the plane upward. Want to time animations so there is no stuttering.
            - Results:
                - Although the map tells me it is done moving into position and done rendering, it's not done rendering *to the screen*. When I take the snapshot image on my iPhone 6 it is still fading between the original blurry map text and the new, zoomed-in sharp map text. I would have to delay by some arbitrary amount of time before taking the image.
                - When the scene view is shown, there is a flash before the map plane with the snapshot image shows up, during which nothing at all is rendering. I'd have to figure out how to wait until SceneKit has drawn its first frame, and I have never even tried SceneKit.
        - Map annotations
            - As particle/ripple emitters
                - Do they clip to bounds?
            - As fixed-size blank canvases
                - How many blank / hidden canvases can we have on the screen at once?
            - As image views that change images
            - Animations on map annotations
                - Manipulate transformations and alphas of subviews or layers as timestamp changes
                - Use scrollViewDidScroll to fire immediate animation
            - Results:
                - Map annotations don't clip to bounds. You can add subviews, and presumably sublayers, and animate them freely.
                - With 10,000 annotations in the map and in the visible rect, but with 99% of their annotation views hidden, it was still far too much overhead to do the math about which should be on the screen. So, my idea of animating by leaving all earthquakes on the screen and setting them hidden or visible won't work when you zoom all the way out.
                - MKMapView.annotationsInRect() needs to have its rect padded in order to include annotations whose centers are outside its bounds.
                - With 900 blank canvas annotations in the map and all of them visible, each with a blended subview, performance was never rock bottom but not great.
                - Annotations in the map at all should be limited to about 100. That's bad news for long-duration animations that watch several years of progress, because MapKit can't be depended on to add annotation views in sync with interactive main thread animations.
                - So it doesn't matter which of these methods I use if I have to rely on annotation views to do it. And that means I can't animate seismic activity simultaneously with map panning and zooming.
        - Conclusions
            - Maybe it's suitable to fetch the seismic history for a map rect, ordered descending by magnitude and limited to a performant number of annotations. Like, here's the timeline of the top 100 earthquakes in this area. And then I make annotations for each and, so long as you leave the map alone and just play with the timeline, you can animate smoothly within annotation views. That also designs away the problem of animating earthquakes that are off-screen.
            - OK, so I want to superimpose a scroll view that lets you scrub through the recorded event timeline, and a play button that will play through it to the end. The timeline should label years and months, and can have marks in it for seismic events with their magnitudes. I can coordinate an animation among all the annotation views, or just among a pool of layers added over the map view, and move through frames incrementally. (In fact, if I don't use the annotation views but just do map point conversion myself, I don't have to limit it to just so few events.) Animation should be able to run explicitly by a CADisplayLink or by scroll view motion. That should be a good basis to add sound and other effects. I don't think this needs prototyping.
    - Models
        - Model type
        - JSON mapping
        - Performance testing
            - Mapping all 8,713 features in the total data set took 27 seconds on iPhone 6. That bites.
            - Map.array could be a good place to parallelize, but it wouldn't make it work for every possible feature. We will want to do mapping off the main thread anyway.
        - Error type
        - API requests
            - APIRequest class with mock downloads
            - NSURLSession research (no third party libraries this project)
            - NSURLSession requests
            - Apparently if you get a 200 from the HTTP server, that doesn't necessarily mean there wasn't a failure. The response body's .metadata.status is an application-specific status code that I needed to respect even in an HTTP success case.
        - API Endpoint methods to create requests for particular sets of parameters as needed
        - Fetch data for map region
            - The best time to get new data is after the region changes, but users can easily make many requests run at once. A request for the top 100 earthquakes in a map rect takes about ten seconds. Hell, just about any request to the USGS API appears to take right about seconds plus download time. So, when a new request is started the latest is cancelled.
            - I'd like to have a mechanism to cancel this task after the response is received but before result preparation ends. Mapping 100 earthquakes to native objects usually takes 0.18s on device, and that's a wide enough window to get unwanted results. For now I'm using the task identifier to ensure we only use the response for the most recently sent request.
    - User interface
        - Load data as map region changes
        - Data states
        - Annotations for loaded earthquakes
        - Annotation appearance
        - Play/pause button and appearance
        - Custom dial-back-time control
            - Scroll view with start and end time parameters
        - Animations within annotation views
        - Hard part is over; add cool stuff as needed
        - App icon
        - Launch screen
        - Memory, performance, battery, GPS usage testing
        - Unit tests for real, time permitting
