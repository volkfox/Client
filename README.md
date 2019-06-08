# Client


  Thundr Brainstorming App client for IOS



  Usage: 
  
  1. Launch web app on https:thundrweb.herokuapp.com to start a [new brainstorm](https:thundrweb.herokuapp.com/)
         or [join existing brainstorm.](https:thundrweb.herokuapp.com/session/MPUZKX)
  2. Scan QR code IOS in-app or launch it via IOS camera to join the brainstorm
  3. Submit new ideas via voice dictation
  4. Operate web interface to switch channels (tabs) or start voting (click on thumbup button in the upper left corner)
  5. Free webappp hosting at heroku can be slow or aggressively unloading. Reload webscreen if vote counts freeze.
    
APIs in use:
    - **SIRIKit**
    - **AVFoundation**
    - **Google Firebase**

Other IOS functions:
    - **NSNotifications**
    - **NWPathMonitor**
    - **URL scheme**

  --------------
  Build:
  
  
          This project uses cocoa pods for the Firebase support, use 'pod install' to fill dependencies
          open .xcworkspace to build the project

  --------------
  Attribitions:
  
  
        Project uses code snippets from Abhilash KM for QR scanning https:github.com/abhimuralidharan
        Voice recognition code is modeled largely Jeff Rames voice tutorial, https:www.raywenderlich.com
        Dismiss keyboard extension uses technique discussed on stackexchange, no author could be found.


