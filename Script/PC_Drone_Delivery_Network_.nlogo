;;;This is a model for PC DP optimization
;C. Emeka, J. Stewart, G. Craig
;;create "classes"
;

breed [drones drone]
breed [rtDrones rtDrone] ;deprecated
breed [trucks truck]
breed [houses house]
breed [warehouses warehouse]

;;class attributes
drones-own[
     destination
     load-status
     takeoff-status
     balogna ;;im using this for a super balogna reason,, don't hate its adequately named i cant get the if else to work lol.
     collision  
     altitude
     secondary
     dsp
    
     
]


;truck stuff
trucks-own[
  destination
  load-status
  takeoff-status
  balogna
  secondary
  ]


;returing drones so the ATMS can distinguis between returning and delivering drones
;I really wish NetLogo had a get turtles at patches at patch method, then this wouldnt be neccessary
rtDrones-own[
      destination
     load-status
     takeoff-status
     balogna ;;im using this for a super balogna reason,, don't hate chinny its adequately named i cant get the if else to work lol.
     collision  
     altitude
     secondary
  ]

warehouses-own[
  tarmac
]

;;create global variables
globals[
 ;routes is a list of all networked drones routes 
 routes 
 LastPos ;; postion for collision detection 
 collision-count ; collision count - includes at least 2 drones
 alt ; should be a local variable but i don't know how to make those
 colCount ; should be local, but don't know how to mske those
 chance; global for random? WTF ARE THERE NO LOCAL VARIABLES in the POS???,, let chance random xx   doesnt work
 baseY ; this is the y cord of the base/warehouse
 baseX ; this is the x cord of the base/warehouse
 totes ; totes is totes the number of drones
 drone-Count ; needed for the number of drones begining deliveries
 ATMS;
 locX; used for kink ATMS
 locY; used for kink ATMS
 ;maxDrones ; slider can be used to set the max number of drones
 curDrones  ; number of drones in the air currently
 flightTime ; total flight time
 flightTotes ; cause locals dont work,, groan
 
 ;;truck globals
 truck-Count
 truckTotes
 curTrucks
 
]

;setup method called on setup button pressed
to setup
  clear-all
  set flightTime 0;
  set curDrones 0
  setup-patches
  set-default-shape houses "house"
  set-default-shape trucks "truck" 
  set totes 1
  ;; CREATE-ORDERED-<BREEDS> distributes the houses evenly
  create-houses number-of-houses
    [ setxy random-xcor random-ycor
      fd max-pxcor 
      ]
   set-default-shape warehouses "bug"
   
   create-warehouses 1
   [setxy random-xcor random-ycor
      fd max-pxcor 
      
      ] 
    ask warehouses[
      set baseY ycor
      set baseX xcor
      ]
   
   ;create-drones number-of-drones [
   ; setxy random-xcor random-ycor
   ; set color red
   ; set destination one-of houses
   ; set load-status "en-route"
   ; set takeoff-status false
   ; face destination
   ; set collision false
   ; ;give an arbitrary height for now
   ; set chance random 5
   ; set altitude chance * 100
   ; set secondary false
  ;]
   set ATMS true; 
  reset-ticks
end


;;reset drones on the warehouse
to reset-drones
  set totes 1 ; I'm making it one to avoid the divide by zero error.  *****************************ALL FINAL CALCS MUST ACCOUNT FOR TGIS or not cause 
  set collision-count 0
  set flightTime 0
  ask drones[die] 
  
  set curDrones 0
  reset-ticks
end

;;sets up patches, called from setup method
to setup-patches
  ask patches[set pcolor green]
end

;this method uses the delivery frequency to randomly have houses make a request form the warehouse. 
;and by that I mean that the percent is used to caluclalate a number of houses going to request and then a corespondinng number of drones are made
;make-Drones creates the requested number of drones with a random house as a destination
;also checks if the maxDroneOnIsOne is one to see if there is a limit to the number of drones
;the no limit is most useful to see the general movement pattern of a DP
to request-delivery
  set drone-Count 0
  ask houses[
    set chance random 10000
    if-else maxDroneOnIsOne = 1[
    if houseFrequency > chance and curDrones < maxDrones[
      set drone-Count drone-Count + 1
      ;set curDrones curDrones + 1
    ]]
  ;else maxDroneOnIsOne is not one, so there is no drone limit
  [
     if houseFrequency > chance [
      set drone-Count drone-Count + 1
      ;set curDrones curDrones + 1
    ]]
  ]
  set totes drone-Count + totes ; set the total number of drones
  make-Drones
  
end  

to make-Drones
  set curDrones curDrones + drone-Count ; this sets the current num
  create-drones drone-Count [
        set xcor baseX 
        set ycor baseY 
        set color red
   ; set destination one-of houses
    set load-status "en-route"
    set takeoff-status false
   ; face destination
    set collision false
   ; ;give an arbitrary height for now
    set chance random 5
    set altitude chance * 100
    set secondary false
        set destination one-of houses
        face destination
       
    set dsp random 3
    set dsp dsp * 10   
       ]
end

to countFlight
  ;each drone flying will add a flight time
  ;beware, flight time will be better for a network where lots of drones crash, as they wil stop flying. This statistic is deceptive
  set flightTotes 0
  ask drones[
    set flightTotes flightTotes + 1
    
    ]
  set flightTime flightTotes + flightTime
end

;;Below is the most basic Drone Protocol strategy, using randomly assigned flight altitudes. There are 5 options. 100, 200, 300, 400 and 500 ft. GPS altitude accuracy is within this slot system
;;When a new altitude is randomly selected at takeoff from warehouse, over time all aircraft will ALWAYS crash (except if there is an odd number)
to go
  countFlight
  request-delivery
  ask drones[
    ;; if at target, either return home or go to new house
    if distance destination = 0 
     
      [ set takeoff-status true
        
        set balogna  true
        ;if you are at your destination and returning, the drone is done delvering,, die and decrease count
        if load-status = "return"
        [
        die
        set curDrones curDrones - 1 ;
        ]
        if load-status = "en-route" and balogna = true
        [
        set color black
        set destination one-of warehouses
        face destination
        set load-status "return"
        fd 2
      
         ]
       ]

    ;; move towards target.  once the distance is more than 1,
    ;; use move-to to land exactly on the target.
    if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]
      
      ;;check for collisons btwn other drones if the drones have not landed
      ;set global LastPos to current patch and collision to false. If this patch
      set collision false
      set LastPos patch-here 
      set alt altitude 
      set colCount  0
      if count drones-here > 1[
        ask drones [
          if patch-here = LastPos and alt = altitude[
            set colCount colCount + 1]
          if colCount > 1[
            set collision true
            
            ]
          ]
        ]   
      if collision = true[
      set collision-count collision-count + 1
      ask drones[
        if patch-here =  LastPos and altitude = alt[
         die ]]]
     
  ]
  tick
end



;This is a simple routing strategy for drones. Drones traveling "East", or 0 to 180 degrees, will fly at 200 ft, drones with routes above 180 degrees wil be at 400
;The main issue here is that drones aproaching the warehouse crash as they converge. A routing system to bring them to the warehouse in a convieient fashion is needed

to goSimpleRouting
  countFlight
  request-delivery
  ask drones[
    ;set altitude based off heading, if going mostly east cruise at 200, if west cruise 400
    if-else heading <= 180[set altitude 200][set altitude 400]
    ;; if at target, either return home or go to new house
    if distance destination = 0 
    
      [ set takeoff-status true
        
        set balogna  true
        if load-status = "return"
        [
       die
       
        set curDrones curDrones - 1 ;
        ]
        if load-status = "en-route" and balogna = true
        [
        set color black
        set destination one-of warehouses
        face destination
        set load-status "return"
        fd 2
      
         ]
       ]

    ;; move towards target.  once the distance is more than 1,
    ;; use move-to to land exactly on the target.
    if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]
      
      ;;check for collisons btwn other drones if the drones have not landed
      ;set global LastPos to current patch and collision to false. If this patch
      set collision false
      set LastPos patch-here 
      set alt altitude 
      set colCount  0
      if count drones-here > 1[
        ask drones [
          if patch-here = LastPos and alt = altitude[
            set colCount colCount + 1]
          if colCount > 1[
            set collision true
            
            ]
          ]
        ]   
      if collision = true[
      set collision-count collision-count + 1
      ask drones[
        if patch-here =  LastPos and altitude = alt[
         die ]]]
     
  ]
  tick
end


;;this is an autonomous routing DP where drones deliver to their destination in a direct fashion, flying at 200 if going east and 400 at west
;when they are returning to the warehouse however, they can only fly directly North or South until they reach the latitude (x axis) of the warehouse. North at 100, South 300
;When they reach the latitude of their home base they will turn to it, returning to the east/west altitude 

to goNSReturnRouting
  countFlight
  request-delivery
  ask drones[
    ;if delivering, set altitude based off heading, if going mostly east cruise at 200, if west cruise 400
    if load-status = "en-route"[
    if-else heading <= 180[set altitude 200][set altitude 400]]
    ;; if at target, either return home or go to new house
    if distance destination = 0 
    
      [ set takeoff-status true
        
        set balogna  true
        if load-status = "return"
        [
       die
      
        set curDrones curDrones - 1 ;
        ]
        if load-status = "en-route" and balogna = true
        [
        set color black
        set destination one-of warehouses
        face destination
        ;;this sets a north direction if the drone needs to go north
        if heading < 90 or heading > 270[set heading 0
          set altitude 100]
        ;;this sets a southern direction if the drone needs to go south
        if heading > 90 and heading < 270[set heading 180
          set altitude 300]
        set load-status "return"
        fd 2
      
         ]
       ]

    ;; move towards target directly if en-route n if the distance is more than 1,
    ;; use move-to to land exactly on the target.
    if-else load-status = "en-route"[
    if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]
    ] 
    ;else this is return, check if on latutude of warehouse n turn to face it if u are
    [
      
      if-else abs (ycor - baseY) < 1
      [face destination
        if-else heading <= 180[set altitude 200][set altitude 400]
        
            if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]]
      ;else return to N/S
      [
        if heading < 90 or heading > 270[set heading 0]
        ;;this sets a southern direction if the drone needs to go south
        if heading > 90 and heading < 270[set heading 180]
            if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
 
      
      if distance destination >= 1
      [
        fd 1
        ]
        ]
      ]
    
      ;;check for collisons btwn other drones if the drones have not landed
      ;set global LastPos to current patch and collision to false. If this patch
      set collision false
      set LastPos patch-here 
      set alt altitude 
      set colCount  0
      if count drones-here > 1[
        ask drones [
          if patch-here = LastPos and alt = altitude[
            set colCount colCount + 1]
          if colCount > 1[
            set collision true
            
            ]
          ]
        ]   
      if collision = true[
      set collision-count collision-count + 1
      ask drones[
        if patch-here =  LastPos and altitude = alt[
         die ]]]
     
  ]
  tick
end



;;this is a method that uses 4 quadrants to route drones
;yessssss
;it happens to form a symbol that is very triggering to a great deal of people
to goNSEWReturnRouting
  countFlight
  request-delivery
  ask drones[
    ;if delivering, set altitude based off heading, if going mostly east cruise at 200, if west cruise 400
    if load-status = "en-route"[
    if-else heading <= 180[set altitude 200][set altitude 400]
    
    ]
    ;; if at target, either return home or go to new house
    if distance destination = 0 
    
      [ set takeoff-status true
        
        set balogna  true
        if load-status = "return"
        [
          
        set curDrones curDrones - 1 ;
        die
        ]
        if load-status = "en-route" and balogna = true
        [
        set color black
        set destination one-of warehouses
        face destination
        
        
        ;this would be a great time for an if else else else statement but netlogo is totally weak sometimes
        ;;if heading is less than 90, then it is in lower left queadrant,, go east than north
        if heading < 90  ;
        [set heading 90
         set altitude 200
         set secondary true] 
        ;;if drone is in top left quadrant w/ heading greater than 90 but less than 180, go south than east
        if heading >= 90 and heading < 180 and secondary = false[set heading 180
          set altitude 300
          set secondary true]
        ;;if in the top righ quarant go west than south
        if heading >= 180 and heading < 270 and secondary = false[
          set heading 270
          set altitude 400
          set secondary true
          ]
        ;if in bottom right, go north than west
        if heading >= 270 and secondary = false[
          set heading 0
          set altitude 100
          set secondary true
          ]
        set load-status "return"
       ; fd 2
      
         ]
       ]

    ;; move towards target directly if en-route n if the distance is more than 1,
    ;; use move-to to land exactly on the target.
    if-else load-status = "en-route"[
    if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]
    ]
    ;else this is return, check if on latutude/longitude of warehouse n turn to face it
    [
      ;;if u are in vicinity of warehouse turn to 
      if-else abs (ycor - baseY) < .5 or abs (xcor - baseX) < .5
      [face destination
        ;;now the drone is in the second leg
        ;;its heading should be set perfectly so set altitude accordingly
        if abs (heading - 90) < 5 [set altitude 200]
        if abs (heading - 180) < 5[set altitude 300]
        if abs (heading - 270) < 5 [set altitude 400]
        if heading < 5 or abs (heading - 360) < 5[set altitude 100]
        
            if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]]
      ;else return to N/S NOT NEEDED>>????
      [
        ;if heading < 90 or heading > 270[set heading 0]
        ;;this sets a southern direction if the drone needs to go south
        ;if heading > 90 and heading < 270[set heading 180]
            if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]
        ]
      ]
    
      ;;check for collisons btwn other drones if the drones have not landed
      ;set global LastPos to current patch and collision to false. If this patch
      set collision false
      set LastPos patch-here 
      set alt altitude 
      set colCount  0
      if count drones-here > 1[
        ask drones [
          if patch-here = LastPos and alt = altitude[
            set colCount colCount + 1]
          if colCount > 1[
            set collision true
            
            ]
          ]
        ]   
      if collision = true[
      set collision-count collision-count + 1
      ask drones[
        if patch-here =  LastPos and altitude = alt[
         die ]]]
     
  ]
  tick
end


to goNSReturnRoutingDP
  countFlight
  request-delivery
  ask drones[
    ;if delivering, set altitude based off heading, if going mostly east cruise at 200, if west cruise 400
    if load-status = "en-route"[
    if-else heading <= 180[set altitude 200][set altitude 400]]
    ;; if at target, either return home or go to new house
    if distance destination = 0 
    
      [ set takeoff-status true
        
        set balogna  true
        if load-status = "return"
        [
        set color red
        set load-status "en-route"
        set destination one-of houses
        face destination 
        set balogna  false
        
        fd 2
      
        ]
        if load-status = "en-route" and balogna = true
        [
        set color black
        set destination one-of warehouses
        face destination
        ;;this sets a north direction if the drone needs to go north
        if heading < 90 or heading > 270[set heading 0
          set altitude 100]
        ;;this sets a southern direction if the drone needs to go south
        if heading > 90 and heading < 270[set heading 180
          set altitude 300]
        set load-status "return"
        fd 2
      
         ]
       ]

    ;; move towards target directly if en-route n if the distance is more than 1,
    ;; use move-to to land exactly on the target.
    if-else load-status = "en-route"[
    if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]
    ]
    ;else this is return, check if on latutude of warehouse n turn to face it
    [
      
      if-else abs (ycor - baseY) < 1
      [face destination
        if-else heading <= 180[set altitude 200][set altitude 400]
        
            if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]]
      ;else return to N/S
      [
        if heading < 90 or heading > 270[set heading 0]
        ;;this sets a southern direction if the drone needs to go south
        if heading > 90 and heading < 270[set heading 180]
            if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]
        ]
      ]
    
      ;;check for collisons btwn other drones if the drones have not landed
      ;set global LastPos to current patch and collision to false. If this patch
      set collision false
      set LastPos patch-here 
      set alt altitude 
      set colCount  0
      if count drones-here > 1[
        ask drones [
          if patch-here = LastPos and alt = altitude[
            set colCount colCount + 1]
          if colCount > 1[
            set collision true
            
            ]
          ]
        ]   
      if collision = true[
      set collision-count collision-count + 1
      ask drones[
        if patch-here =  LastPos and altitude = alt[
         die ]]]
     
  ]
  tick
end

;;different from other NSEW routing due to the ATMS, which prevents collisions when enetering the landing pattern
to ATMSgoNSEWReturnRouting
  countFlight
  request-delivery
  ask drones[
    ;if delivering, set altitude based off heading, if going mostly east cruise at 200, if west cruise 400
    if load-status = "en-route"[
    if-else heading <= 180[set altitude 200][set altitude 400]
    
    ]
    ;; if at target, either return home or go to new house
    if distance destination = 0 
    
      [ set takeoff-status true
        
        set balogna  true
        if load-status = "return"
        [
          
        set curDrones curDrones - 1 ;
        die
        ]
        if load-status = "en-route" and balogna = true
        [
        set color black
        set destination one-of warehouses
        face destination
        
        
        ;this would be a great time for an if else else else statement but netlogo is totally weak sometimes
        ;;if heading is less than 90, then it is in lower left queadrant,, go east than north
        if heading < 90  ;
        [set heading 90
         set altitude 200
         set secondary true] 
        ;;if drone is in top left quadrant w/ heading greater than 90 but less than 180, go south than east
        if heading >= 90 and heading < 180 and secondary = false[set heading 180
          set altitude 300
          set secondary true]
        ;;if in the top righ quarant go west than south
        if heading >= 180 and heading < 270 and secondary = false[
          set heading 270
          set altitude 400
          set secondary true
          ]
        ;if in bottom right, go north than west
        if heading >= 270 and secondary = false[
          set heading 0
          set altitude 100
          set secondary true
          ]
        set load-status "return"
       ; fd 2
      
         ]
       ]

    ;; move towards target directly if en-route n if the distance is more than 1,
    ;; use move-to to land exactly on the target.
    if-else load-status = "en-route"[
    if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]
    ]
    ;else this is return, check if on latutude/longitude of warehouse n turn to face it
    [
      ;;if u are in vicinity of warehouse turn to 
      if-else abs (ycor - baseY) < .5 or abs (xcor - baseX) < .5
      [face destination
        ;;now the drone is in the second leg
        ;;its heading should be set perfectly so set altitude accordingly
        if abs (heading - 90) < 5 [set altitude 200]
        if abs (heading - 180) < 5[set altitude 300]
        if abs (heading - 270) < 5 [set altitude 400]
        if heading < 5 or abs (heading - 360) < 5[set altitude 100]
        
            if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]]
      ;else return to N/S NOT NEEDED>>????
      [
        ;if heading < 90 or heading > 270[set heading 0]
        ;;this sets a southern direction if the drone needs to go south
        ;if heading > 90 and heading < 270[set heading 180]
            if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        set ATMS true;
        ;;only move forward if no drone is on the landing route 
        ask patch-ahead 1 [if count drones-here > 0[set ATMS false] ]
    
        if ATMS = true [fd 1]
        ]
        ]
      ]
    
      ;;check for collisons btwn other drones if the drones have not landed
      ;set global LastPos to current patch and collision to false. If this patch
      set collision false
      set LastPos patch-here 
      set alt altitude 
      set colCount  0
      if count drones-here > 1[
        ask drones [
          if patch-here = LastPos and alt = altitude[
            set colCount colCount + 1]
          if colCount > 1[
            set collision true
            
            ]
          ]
        ]   
      if collision = true[
      set collision-count collision-count + 1
      ask drones[
        if patch-here =  LastPos and altitude = alt[
         die ]]]
     
  ]
  tick
end



;this method gets a lil kinky tbh fam
;breeding and dying drones and returning drones all over the place
;which is neccessary for the returning drones to distinguish 
;;different from other NSEW routing due to the ATMS, which prevents collisions when enetering the landing pattern
to MultiATMSgoNSEWReturnRouting
  request-delivery
  ask drones[
    ;if delivering, set altitude based off heading, if going mostly east cruise at 200, if west cruise 400
    if load-status = "en-route"[
    if-else heading <= 180[set altitude 200][set altitude 400]
    
    ]
    ;; if at target, either return home or go to new house
    if distance destination = 0 
    
      [ set takeoff-status true
        
        set balogna  true
        if load-status = "return"
        [
          
        set curDrones curDrones - 1 ;
        die
        ]
        if load-status = "en-route" and balogna = true
        [
        set color black
        set destination one-of warehouses
        face destination
        
        
        ;this would be a great time for an if else else else statement but netlogo is totally weak sometimes
        ;;if heading is less than 90, then it is in lower left queadrant,, go east than north
        if heading < 90  ;
        [set heading 90
         set altitude 200
         set secondary true] 
        ;;if drone is in top left quadrant w/ heading greater than 90 but less than 180, go south than east
        if heading >= 90 and heading < 180 and secondary = false[set heading 180
          set altitude 300
          set secondary true]
        ;;if in the top righ quarant go west than south
        if heading >= 180 and heading < 270 and secondary = false[
          set heading 270
          set altitude 400
          set secondary true
          ]
        ;if in bottom right, go north than west
        if heading >= 270 and secondary = false[
          set heading 0
          set altitude 100
          set secondary true
          ]
        set load-status "return"
       ; fd 2
      
         ]
       ]

    ;; move towards target directly if en-route n if the distance is more than 1,
    ;; use move-to to land exactly on the target.
    if-else load-status = "en-route"[
    if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]
    ]
    ;else this is return, check if on latutude/longitude of warehouse n turn to face it
    [
      ;;if u are in vicinity of warehouse turn to 
      if-else abs (ycor - baseY) < .5 or abs (xcor - baseX) < .5
      [face destination
        ;;now the drone is in the second leg
        ;;its heading should be set perfectly so set altitude accordingly
        if abs (heading - 90) < 5 [set altitude 200]
        if abs (heading - 180) < 5[set altitude 300]
        if abs (heading - 270) < 5 [set altitude 400]
        if heading < 5 or abs (heading - 360) < 5[set altitude 100]
        
            if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]]
      ;else return to N/S NOT NEEDED>>????
      [
        ;if heading < 90 or heading > 270[set heading 0]
        ;;this sets a southern direction if the drone needs to go south
        ;if heading > 90 and heading < 270[set heading 180]
            if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        set ATMS true;
        ;;only move forward if no drone is on the landing route directly in front
        ;this method is more hardocre in avoidance and checks up to 3 patches ahead
        ask patch-ahead 1 [if count drones-here > 0[set ATMS false] ]
        ask patch-ahead 2 [if count drones-here > 0[set ATMS false] ]
        ask patch-ahead 3 [if count drones-here > 0[set ATMS false] ]
        ;check to the left and right, for drones and avoid if they are there
        ;doing a vairety of precautions to be safe
        ask patch-left-and-ahead 45 1[if count drones-here > 0 [set ATMS false]]
        ask patch-left-and-ahead 45 2[if count drones-here > 0 [set ATMS false]]
        ask patch-left-and-ahead 15 1[if count drones-here > 0 [set ATMS false]]
        ask patch-left-and-ahead 15 2[if count drones-here > 0 [set ATMS false]]
        ask patch-left-and-ahead 60 1[if count drones-here > 0 [set ATMS false]]
        ask patch-left-and-ahead 60 2[if count drones-here > 0 [set ATMS false]]

        ask patch-right-and-ahead 45 1[if count drones-here > 0 [set ATMS false]]
        ask patch-right-and-ahead 45 2[if count drones-here > 0 [set ATMS false]]
        ask patch-right-and-ahead 15 1[if count drones-here > 0 [set ATMS false]]
        ask patch-right-and-ahead 15 2[if count drones-here > 0 [set ATMS false]]
        ask patch-right-and-ahead 60 1[if count drones-here > 0 [set ATMS false]]
        ask patch-right-and-ahead 60 2[if count drones-here > 0 [set ATMS false]]
        if ATMS = true [fd 1]
        ]
        ]
      ]
    
      ;;check for collisons btwn other drones if the drones have not landed
      ;set global LastPos to current patch and collision to false. If this patch
      set collision false
      set LastPos patch-here 
      set alt altitude 
      set colCount  0
      if count drones-here > 1[
        ask drones [
          if patch-here = LastPos and alt = altitude[
            set colCount colCount + 1]
          if colCount > 1[
            set collision true
            
            ]
          ]
        ]   
      if collision = true[
      set collision-count collision-count + 1
      ask drones[
        if patch-here =  LastPos and altitude = alt[
         die ]]]
     
  ]
  tick
end


;this method gets a lil kinky tbh fam
;breeding and dying drones and returning drones all over the place
;which is neccessary for the returning drones to distinguish 
;;different from other NSEW routing due to the ATMS, which prevents collisions when enetering the landing pattern
;the reason i think it is ok to use two types of turtles is that the differing flight heights should preclude a situation where counting the turtles in front and checking for collisions 
to kinkyATMSgoNSEWReturnRouting
  countFlight
  request-delivery
  ask drones[
    ;if delivering, set altitude based off heading, if going mostly east cruise at 200, if west cruise 400
    if load-status = "en-route"[
    if-else heading <= 180[set altitude 200][set altitude 400]
    
    ]
    ;; if at target, either return home or go to new house
    if distance destination = 0 
    
      [ set takeoff-status true
        
        set balogna  true
        if load-status = "return"
        [
          
        set curDrones curDrones - 1 ;
        die
        ]
        if load-status = "en-route" and balogna = true
        [
          
          ;;heres where its gettin kinky
        set locX xcor
        set locY ycor
        ;since we cant create turtles from inside the turtle context, call a method that will do it now that we have locX, locY
        
        
        
        set color black
        set destination one-of warehouses
        face destination
        
        
        ;this would be a great time for an if else else else statement but netlogo is totally weak sometimes
        ;;if heading is less than 90, then it is in lower left queadrant,, go east than north
        if heading < 90  ;
        [set heading 90
         set altitude 200
         set secondary true] 
        ;;if drone is in top left quadrant w/ heading greater than 90 but less than 180, go south than east
        if heading >= 90 and heading < 180 and secondary = false[set heading 180
          set altitude 300
          set secondary true]
        ;;if in the top righ quarant go west than south
        if heading >= 180 and heading < 270 and secondary = false[
          set heading 270
          set altitude 400
          set secondary true
          ]
        ;if in bottom right, go north than west
        if heading >= 270 and secondary = false[
          set heading 0
          set altitude 100
          set secondary true
          ]
        set load-status "return"
       ; fd 2
      
         ]
       ]

    ;; move towards target directly if en-route n if the distance is more than 1,
    ;; use move-to to land exactly on the target.
    if-else load-status = "en-route"[
    if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]
    ]
    ;else this is return, check if on latutude/longitude of warehouse n turn to face it
    [
      ;;if u are in vicinity of warehouse turn to 
      if-else abs (ycor - baseY) < .5 or abs (xcor - baseX) < .5
      [face destination
        ;;now the drone is in the second leg
        ;;its heading should be set perfectly so set altitude accordingly
        if abs (heading - 90) < 5 [set altitude 200]
        if abs (heading - 180) < 5[set altitude 300]
        if abs (heading - 270) < 5 [set altitude 400]
        if heading < 5 or abs (heading - 360) < 5[set altitude 100]
        
            if distance destination < 1
      [ 
        ;added 4 comp
        die
        set curDrones curDrones - 1
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]]
      ;else return to N/S NOT NEEDED>>????
      [
        ;if heading < 90 or heading > 270[set heading 0]
        ;;this sets a southern direction if the drone needs to go south
        ;if heading > 90 and heading < 270[set heading 180]
            if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        let curDrone self
        set ATMS true;
        ;;only move forward if no drone is on the landing route directly in front
        ;this method is more hardocre in avoidance and checks up to 3 patches ahead
        ask patch-ahead 1 [if count drones-here > 0[set ATMS false] ]
        ask patch-ahead 2 [if count drones-here > 0[set ATMS false] ]
        ask patch-ahead 3 [if count drones-here > 0[set ATMS false] ]
        ;check to the left and right, for drones and avoid if they are there
        ;doing a vairety of precautions to be safe
       ; ask patch-left-and-ahead 45 1[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ;ask patch-left-and-ahead 45 2[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ;ask patch-left-and-ahead 15 1[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
       ; ask patch-left-and-ahead 15 2[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ;ask patch-left-and-ahead 60 1[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ;ask patch-left-and-ahead 60 2[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]

        ask patch-right-and-ahead 45 1[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 45 2[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 15 1[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 15 2[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 60 1[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 60 2[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 75 1[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 75 2[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 90 1[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 90 2[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 90 3[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]] 
        
        if ATMS = true [fd 1]
        ]
        ]
      ]
    
      ;;check for collisons btwn other drones if the drones have not landed
      ;set global LastPos to current patch and collision to false. If this patch
      set collision false
      set LastPos patch-here 
      set alt altitude 
      set colCount  0
      if count drones-here > 1[
        ask drones [
          if patch-here = LastPos and alt = altitude[
            set colCount colCount + 1]
          if colCount > 1[
            set collision true
            
            ]
          ]
        ]   
      if collision = true[
      set collision-count collision-count + 1
      ask drones[
        if patch-here =  LastPos and altitude = alt[
         die ]]]
     
  ]
  tick
end

;;helper method to avoid context for the kinky DP
to makeRtDrone
    create-rtDrones 1 [
        set xcor locX 
        set ycor locY 
        set color black
   ; set destination one-of houses
    set load-status "return"
    set takeoff-status false
   ; face destination
    set collision false
   ; ;give an arbitrary height for now
    set chance random 5
    set altitude chance * 100
    set secondary false
        set destination one-of warehouses
        face destination
       ]
end



;;this is a method that uses 4 quadrants to route drones
;yessssss
;it happens to form a symbol that is very triggering to a great deal of people
to StochgoNSEWReturnRouting
  countFlight
  request-delivery
  ask drones[
    ;if delivering, set altitude based off heading, if going mostly east cruise at 200, if west cruise 400
    if load-status = "en-route"[
    if-else heading <= 180[set altitude 200 + dsp][set altitude 400 + dsp]
    
    ]
    ;; if at target, either return home or go to new house
    if distance destination = 0 
    
      [ set takeoff-status true
        
        set balogna  true
        if load-status = "return"
        [
          
        set curDrones curDrones - 1 ;
        die
        ]
        if load-status = "en-route" and balogna = true
        [
        set color black
        set destination one-of warehouses
        face destination
        
        
        ;this would be a great time for an if else else else statement but netlogo is totally weak sometimes
        ;;if heading is less than 90, then it is in lower left queadrant,, go east than north
        if heading < 90  ;
        [set heading 90
         set altitude 200 + dsp
         set secondary true] 
        ;;if drone is in top left quadrant w/ heading greater than 90 but less than 180, go south than east
        if heading >= 90 and heading < 180 and secondary = false[set heading 180
          set altitude 300 + dsp
          set secondary true]
        ;;if in the top righ quarant go west than south
        if heading >= 180 and heading < 270 and secondary = false[
          set heading 270
          set altitude 400 + dsp
          set secondary true
          ]
        ;if in bottom right, go north than west
        if heading >= 270 and secondary = false[
          set heading 0
          set altitude 100 + dsp
          set secondary true
          ]
        set load-status "return"
       ; fd 2
      
         ]
       ]

    ;; move towards target directly if en-route n if the distance is more than 1,
    ;; use move-to to land exactly on the target.
    if-else load-status = "en-route"[
    if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]
    ]
    ;else this is return, check if on latutude/longitude of warehouse n turn to face it
    [
      ;;if u are in vicinity of warehouse turn to 
      if-else abs (ycor - baseY) < .5 or abs (xcor - baseX) < .5
      [face destination
        ;;now the drone is in the second leg
        ;;its heading should be set perfectly so set altitude accordingly
        if abs (heading - 90) < 5 [set altitude 200 + dsp]
        if abs (heading - 180) < 5[set altitude 300 + dsp]
        if abs (heading - 270) < 5 [set altitude 400 + dsp]
        if heading < 5 or abs (heading - 360) < 5[set altitude 100 + dsp]
        
            if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]]
      ;else return to N/S NOT NEEDED>>????
      [
        ;if heading < 90 or heading > 270[set heading 0]
        ;;this sets a southern direction if the drone needs to go south
        ;if heading > 90 and heading < 270[set heading 180]
            if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]
        ]
      ]
    
      ;;check for collisons btwn other drones if the drones have not landed
      ;set global LastPos to current patch and collision to false. If this patch
      set collision false
      set LastPos patch-here 
      set alt altitude 
      set colCount  0
      if count drones-here > 1[
        ask drones [
          if patch-here = LastPos and alt = altitude[
            set colCount colCount + 1]
          if colCount > 1[
            set collision true
            
            ]
          ]
        ]   
      if collision = true[
      set collision-count collision-count + 1
      ask drones[
        if patch-here =  LastPos and altitude = alt[
         die ]]]
     
  ]
  tick
end



;;different from other NSEW routing due to the ATMS, which prevents collisions when enetering the landing pattern
to stochATMSgoNSEWReturnRouting
  countFlight
  request-delivery
  ask drones[
    ;if delivering, set altitude based off heading, if going mostly east cruise at 200, if west cruise 400
    if load-status = "en-route"[
    if-else heading <= 180[set altitude 200 + dsp][set altitude 400 + dsp]
    
    ]
    ;; if at target, either return home or go to new house
    if distance destination = 0 
    
      [ set takeoff-status true
        
        set balogna  true
        if load-status = "return"
        [
          
        set curDrones curDrones - 1 ;
        die
        ]
        if load-status = "en-route" and balogna = true
        [
        set color black
        set destination one-of warehouses
        face destination
        
        
        ;this would be a great time for an if else else else statement but netlogo is totally weak sometimes
        ;;if heading is less than 90, then it is in lower left queadrant,, go east than north
        if heading < 90  ;
        [set heading 90
         set altitude 200 + dsp
         set secondary true] 
        ;;if drone is in top left quadrant w/ heading greater than 90 but less than 180, go south than east
        if heading >= 90 and heading < 180 and secondary = false[set heading 180
          set altitude 300 + dsp
          set secondary true]
        ;;if in the top righ quarant go west than south
        if heading >= 180 and heading < 270 and secondary = false[
          set heading 270
          set altitude 400 + dsp
          set secondary true
          ]
        ;if in bottom right, go north than west
        if heading >= 270 and secondary = false[
          set heading 0
          set altitude 100 + dsp
          set secondary true
          ]
        set load-status "return"
       ; fd 2
      
         ]
       ]

    ;; move towards target directly if en-route n if the distance is more than 1,
    ;; use move-to to land exactly on the target.
    if-else load-status = "en-route"[
    if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]
    ]
    ;else this is return, check if on latutude/longitude of warehouse n turn to face it
    [
      ;;if u are in vicinity of warehouse turn to 
      if-else abs (ycor - baseY) < .5 or abs (xcor - baseX) < .5
      [face destination
        ;;now the drone is in the second leg
        ;;its heading should be set perfectly so set altitude accordingly
        if abs (heading - 90) < 5 [set altitude 200]
        if abs (heading - 180) < 5[set altitude 300]
        if abs (heading - 270) < 5 [set altitude 400]
        if heading < 5 or abs (heading - 360) < 5[set altitude 100 + dsp]
        
            if distance destination < 1
      [ 
        
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        fd 1
        ]]
      ;else return to N/S NOT NEEDED>>????
      [
        ;if heading < 90 or heading > 270[set heading 0]
        ;;this sets a southern direction if the drone needs to go south
        ;if heading > 90 and heading < 270[set heading 180]
            if distance destination < 1
      [ 
        if load-status  = "return"[
          
        set curDrones curDrones - 1 ;
          die]
        move-to destination
        
        
        ]
      
      if distance destination >= 1
      [
        let curDrone self
        set ATMS true;
        ;;only move forward if no drone is on the landing route 
        ask patch-ahead 1 [if count drones-here > 0[set ATMS false] ]
        ask patch-ahead 2  [if count drones-here > 0[set ATMS false] ]
        ask patch-right-and-ahead 45 1[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 45 2[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 15 1[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 15 2[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 60 1[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 60 2[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 75 1[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 75 2[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 90 1[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 90 2[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]]
        ask patch-right-and-ahead 90 3[if count drones-here with [altitude = [altitude] of curDrone] > 0 [set ATMS false]] 
        if ATMS = true [fd 1]
        ]
        ]
      ]
    
      ;;check for collisons btwn other drones if the drones have not landed
      ;set global LastPos to current patch and collision to false. If this patch
      set collision false
      set LastPos patch-here 
      set alt altitude 
      set colCount  0
      if count drones-here > 1[
        ask drones [
          if patch-here = LastPos and alt = altitude[
            set colCount colCount + 1]
          if colCount > 1[
            set collision true
            
            ]
          ]
        ]   
      if collision = true[
      set collision-count collision-count + 1
      ask drones[
        if patch-here =  LastPos and altitude = alt[
         die ]]]
     
  ]
  tick
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This is the truck Stuff my partner was supposed to make
; it is near completion, but commented out because I did not finish it and it makes everything more complicated

;I have made an analog to a truck delivery method
;to goTruck
  
 ; request-truck-delivery
  ;ask trucks[
   ; ;; if at target, either return home or go to new house
    ;if distance destination = 0 
     ; [ set takeoff-status true
      ;  
       ; set balogna  true
        ;;if you are at your destination and returning, the drone is done delvering,, die and decrease count
        ;if load-status = "return"
        ;[
        ;die
        ;set curDrones curDrones - 1 ;
;        ]
  ;      if load-status = "en-route" and balogna = true
 ;       [
;        set color black
 ;       set destination one-of warehouses
  ;      face destination
   ;     set load-status "return"
    ;    fd 2
     ; 
      ;   ]
       ;]

    ;; move towards target.  once the distance is more than 1,
    ;; use move-to to land exactly on the target.
;    if distance destination < 1
 ;     [ 
  ;      
   ;     move-to destination
    ;    
     ;   
      ;  ]
      
      ;if distance destination >= 1
;      [
 ;       face destination
  ;      
   ;     fd 1
    ;    ]
;      
 ; 
  ;   
  ;]
  ;tick
;end




;to request-truck-delivery
  ;-Count 0
 ; ask houses[
  ;  set chance random 10000
    
 ;   if-else maxTruckIsOne = 1[
  ;  if houseFrequency > chance and curTrucks < maxTrucks[
   ;   set truck-Count truck-Count + 1
    ;  set curTrucks curTrucks + 1
;    ]]
  ;else maxDroneOnIsOne is not one, so there is no drone limit
 ; [
   ;  if houseFrequency > chance [
  ;    set truck-Count truck-Count + 1
    ;  set curTrucks curTrucks + 1
;    ]]
 ; ]
  ;set TruckTotes truck-Count + Trucktotes ; set the total number of Trucks
;  make-Trucks
  
;end  

;to make-Trucks
 ; set curTrucks curTrucks + truck-Count ; this sets the current num
  ;create-trucks truck-Count [
   ;     set xcor baseX 
    ;    set ycor baseY 
     ;   set color red
   ; set destination one-of houses
;    set load-status "en-route"
 ;   set takeoff-status false
   ; face destination
    ;set collision false
   ; ;give an arbitrary height for now
    ;set chance random 5
    ;set altitude chance * 100
    ;set secondary false
  ;   set destination one-of houses
   ;  face destination
       
    ;s;et dsp random 3
    ;set dsp dsp * 10   
   ;    ]
;end;


@#$#@#$#@
GRAPHICS-WINDOW
917
34
6400
5538
210
210
13.0
1
11
1
1
1
0
1
1
1
-210
210
-210
210
0
0
1
ticks
30.0

SLIDER
4
277
176
310
number-of-houses
number-of-houses
0
300
300
1
1
NIL
HORIZONTAL

BUTTON
217
384
325
418
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
624
467
685
528
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
221
117
892
368
Collision Count (At least two drones destroyed)
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot  collision-count"

BUTTON
584
537
734
572
Simple Drone Routing
goSimpleRouting
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
611
587
706
622
NS Routing
goNSReturnRouting
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
607
637
710
671
SWAS Route
goNSEWReturnRouting
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
221
421
341
455
reset da drones
reset-drones
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
0
321
185
354
houseFrequency
houseFrequency
0
200
0
1
1
NIL
HORIZONTAL

PLOT
0
474
244
696
Drone Count
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot  totes"

PLOT
4
707
252
915
Percentage of Drones Crashing
NIL
NIL
0.0
10.0
0.0
0.5
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (collision-count /  totes) * 100"

BUTTON
384
484
484
517
ATMS SWAS
ATMSgoNSEWReturnRouting
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
374
527
500
588
Hardcore ATMS SWAS
MultiATMSgoNSEWReturnRouting
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
401
601
464
634
kink
kinkyATMSgoNSEWReturnRouting
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
614
691
712
724
stoch SWAS
StochgoNSEWReturnRouting
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
371
647
505
680
Stoch ATMS SWAS
stochATMSgoNSEWReturnRouting
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
4
417
185
450
maxDrones
maxDrones
0
200
30
5
1
NIL
HORIZONTAL

SLIDER
7
371
179
404
maxDroneOnIsOne
maxDroneOnIsOne
0
1
1
1
1
NIL
HORIZONTAL

PLOT
264
707
534
921
Average Flight Time per DP
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot flightTime / totes"

TEXTBOX
384
434
572
457
Non-Autonomous DP's
15
0.0
1

TEXTBOX
577
437
765
460
Autonomous DP's
15
0.0
1

@#$#@#$#@
## WHAT IS IT?

This is a model designed to compare different Drone Protocols (DP) for a network of delivery drones. These DP's can then be compared to conventional trucking means using the sister model. Future in sky (in aeris) networks could use this to select the apropriate DP for their service.

## HOW IT WORKS

There are 3 major actors in this model: Houses, Warehouses and Drones. Houses request deliveries, which originate at a warehouse and are fulfilled by a drone. The drone is red when delivering to a house, and black when returning. Each button has the drones try a different DP. 

If two drones are on the same patch at the same altitude, they crash and fail to make a delivery.

## HOW TO USE IT

Basics: Hit Setup, then click a button and observe the DP.

Advanced:
After setup, the user can select between a variety of DP's. These are grouped into Autonomous DP's and Non-Autonomous DP's that simulate a comuniation to an Air Traffic Managment System. 

The user has the option to select a limit to the number of drones a warehouse can use to make deliveries. If drones crash, then they are unusable and no longer available. 

Autonomous DP DESCRIPTIONS:
Go - This is the simplest of all DP's. In this protocol, drones decide on one of 5 altitudes for flight and fly at this altitude. Drones fly directly to delivery location and right back to the warehouse

Simple Drone Routing - Drones fly directly to an from the delivery destinations. Their altitudes are based on the direction they are flying, ie. east at 200 ft, West 300 ft.

North South Routing - All drones fly directly to destination. After delivery they fly either North or South towards the latitude of the warehouse. At this point they turn and face it and orderly enter the warehouse. Drones still select altitude based off heading. 

SWAS Routing - All drones fly directly to their destination and return by flying to either the direct N,S,E,W of the warehouse, then turning and enterting the landing pattern. Drones select altitude based on heading.

stoch SWAS - Similar to SWAS routing, however a little stochasity has been added to the altitude. These drone still select altitude based on heading, however when they are generated they select either a 20 40 or 60 ft displacement of their height. This adds a level of randomness to the height they fly at, while still avoiding head on collisions by precluding two oppositely oriented drones from flying at the right height.


NON-Autonomous DP:

ATMS SWAS: Identical to the SWAS method, however these drones check the patches ahead of them and to the right (where other drones are always coming from) for other drones. If they find them they do not move forward. This emulates an ATMS where the  drones query the ATMS for nearby drones locations. 

Hardcore ATMS SWAS: Same as above but checks patches ahead at a greater distance. This would require more transmission bandwidth in an in aeris network than the previous.

KINK: An ultra hardcore ATMS SWAS method. In this, so many patches ahead are checked that drones often get kinked up and become unable to move. 

Stoch ATMS SWAS: A SWAS ATMS method with stochasity added to the altitude.

## THINGS TO NOTICE

Often, collisions occur while retuning to the warehouse. As large numbers of drones converge on an area, this is inevitable. Autonomous DP's in this model often manage the flight altitude of the drones based on the direction they are moving. 


## THINGS TO TRY


The best way to see the general patterns of the DP's is to turn the house-frequency wayyy up and watch thousands of the little guys fly the pattern. 

## EXTENDING THE MODEL

we need to add flight times for drones
performance metrics
DP master control
ReTestable 

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)
1.https://www.researchgate.net/publication/215499161_A_Discrete_Stochastic_Process_for_Coverage_Analysis_of_Autonomous_UAV_Networks
2.http://www.ida.liu.se/labs/rtslab/publications/2006/kuiperICWMC2006.pdf
3.http://ccl.northwestern.edu/netlogo/models/community/DroneNET 
4. http://groups.csail.mit.edu/robotics-center/public_papers/Barry15a.pdf
5. NetLogo itself: Wilensky, U. 1999. NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL.  <- Big shoutout to Uri, thanks for all the work you put into this program. 

## CREDITS AND REFERENCES

John H Stewart did all of it - appdev@tacmap.org
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
