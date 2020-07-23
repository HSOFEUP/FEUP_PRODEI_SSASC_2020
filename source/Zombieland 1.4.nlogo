;; Zombieland Model ver 1.4 - a basic simulation of a zombie attack with seek and flee
;; functions for agents.  Movement speed and vision radius are also adjustable.  The user
;; can draw buildings in the environment to provide obstacles for the agents. Added
;; clear-turtles and clear-all buttons to user interface. User can now add weapon caches
;; to the environment.  When a human agent lands on a weapon cache, he becomes armed and
;; morphs into a new type of agent - Billybob.  Billybob agents can shoot and kill zombies
;; that come within their shooting radius. Bullets can't tell the difference between humans
;; and zombies, so if a human's path crosses a bullet, they die as well.



breed [human] ;;The poor sods that are getting eaten.
breed [zombie] ;;Brains!!!!!!!!!
breed [billybob] ;;Human with a gun.
breed [gun] ;;Weapon cache agent.
breed [bullet] ;; to kill agents.
breed [dead]  ;; Agent used to leave corpse of killed agents.

globals [
  total-human  ;;Total number of agents that are human.
  total-zombie  ;;Total number of agents that are zombies.
  total-billybob  ;;Total number of agents that are billybobs.
  ]

turtles-own [
  speed  ;;How fast the agents can move.
  scared ;;Agent-subset consisting of zombies within vision radius of a single human.
  seek1 ;;Agent-subset consisting of humans within vision radius of a single zombie.
  seek2 ;;Agent-subset consisting of billybobs within vision radius of a single zombie.
  brains  ;;Agent-subset consisting of humans and billybobs within vision radius of a single zombie.
  nearest-brains  ;;Variable that holds the target human for a single zombie.
  nearest-zombie  ;;Variable that holds the target zombie for a single human.
  turn-check  ;;Holds the random variable for the wander sub-routine.
  wall-turn-check  ;;Holds the random variable for the wall sub-routine.
  aim-check  ;;VHolds the random variable for the shoot sub-routine.
  energy ;; Variable to limit distance bullets travel.
  ]

to building-draw
  if mouse-down?     ;; Use the mouse to draw buildings.
    [
      ask patch mouse-xcor mouse-ycor
        [ set pcolor yellow ]]
end  

to Setup  ;;Clear previous run and setup initial agent locations.
  pop-check
  setup-agents
  update-globals
end

to go  ;;Run the simulation.
   scared-check
  repeat human-speed [ ask human [ fd 0.2 ] display ] ;;Controls the speed of humans, zombies,
  repeat zombie-speed [ ask zombie [ fd 0.2 ] display ] ;;and bullets. it also smooths the
  repeat human-speed [ ask billybob [ fd 0.2 ] display ] ;;  motion in simulation.
  repeat human-speed + 1 [ ask bullet [ fd 0.2 ] display ]
  update-globals
  tick
end

to setup-agents ;; Create the desired number of each breed on random patches.
  set-default-shape zombie "person"
  set-default-shape human "person"
  set-default-shape gun "gun"
  set-default-shape billybob "redneck"
  set-default-shape bullet "dot"
  set-default-shape dead "caterpillar"
  
  ask n-of initial-zombies patches with [pcolor  = black]
     [ sprout-zombie 1
      [ set color red ] ]
      
  ask n-of initial-humans patches with [pcolor = black]
    [ sprout-human 1
      [ set color blue ] ]
      
  ask n-of weapon-cache patches with [pcolor = black]
    [ sprout-gun 1
      [ set color orange ] ]
end  

to scared-check ;; Test if humans are near a zombie and have them run away if they are.
  ask human [
    if any? other turtles-here with [color = orange]
    [lock-n-load]
    zombies-near
    ifelse any? scared
    [run-away]
    [wander]
  ]
  
  ask billybob [ ;; Test if billybobs are near a zombie and have them run away if they are.
    zombies-near
    ifelse any? scared
    [defend]
    [wander]
  ]
  
      ;; Test if zombies are near a human and have them chase them if they are.
  ask zombie [
    if any? other turtles-here with [color = blue]
    [convert]
     if any? other turtles-here with [color = green]
    [convert]
    seek-brains
    ifelse any? brains
    [run-toward]
    [wander]   
  ]
  
  ask bullet [ ;;bullet movement, wall check, target check, and remove bullet after energy = 0.
     if [pcolor] of patch-ahead 1 != black
     [die]
    if energy < 14
    [
      if any? other turtles-here with [color = red]
     [kill]
    if any? other turtles-here with [color = blue]
     [kill]
    if any? other turtles-here with [color = green]
     [kill]
    ]
    set energy energy - 1
    if energy = 0
     [die]  
  ]
end
  
to wander ;; If an agent is not fleeing or chasing, have them wander around aimlessly.
    set turn-check random 20
    if turn-check > 15
    [right-turn]
    if turn-check < 5
    [left-turn]
     if [pcolor] of patch-ahead 1 != black
     [wall]
    ask zombie [ 
      if any? other turtles-here
      [ convert] ]
end  

to wall ;;turn agent away from wall
    set wall-turn-check random 10
    if wall-turn-check >= 6
    [wall-right-turn]
    if wall-turn-check <= 5
    [wall-left-turn]
end

to wall-right-turn ;;Generate a random degree of turn for the wall sub-routine.
  rt 150
end

to wall-left-turn ;;Generate a random degree of turn for the wall sub-routine.
  lt 150
end
   
to right-turn ;;Generate a random degree of turn for the wander sub-routine.
  rt random-float 10
end

to left-turn   ;;Generate a random degree of turn for the wander sub-routine.
  lt random-float 10
end
  
to convert ;;When a zombie lands on patch occupied by human, eat brains and turn human or billybob into zombie.
  ask human-on patch-here[set breed zombie]
  ask billybob-on patch-here[set breed zombie]
  ask zombie-on patch-here [set color red]
end

to zombies-near  ;;adds all zombies in vision radius of human to an agent subset for that agent.
  set scared zombie in-radius human-vision
end

to run-away ;;Make human flee the zombie closest to it.
  set nearest-zombie min-one-of scared [distance myself]
  face nearest-zombie
  rt 180
   if [pcolor] of patch-ahead 1 != black
     [wall]
end

to seek-brains  ;;adds all humans and billybobs in vision radius of zombie to an agent subset for that agent.
  set seek1 human in-radius Zombie-vision
  set seek2 billybob in-radius zombie-vision
  set brains (turtle-set seek1 seek2)
end

to run-toward  ;;Make a zombie chase the human or billybob closest to it.
  set nearest-brains min-one-of brains [distance myself]
  face nearest-brains
  if any? other turtles-here
    [convert]
  if [pcolor] of patch-ahead 1 != black
    [wall]
end  

to lock-n-load ;;When a human lands on patch occupied by a weapon cache, give him a gun.
  ask human-on patch-here[set breed billybob]
  ask billybob-on patch-here [set color green]
end

to defend  ;;Make Billybob shoot at nearest Zombie.
   set nearest-zombie min-one-of scared [distance myself]
   face nearest-zombie
   shoot
   rt 180
   if [pcolor] of patch-ahead 1 != black
     [wall]
end

to shoot ;;Fire that gun, Billy Bob.
  set aim-check random 100
  if aim-check < shot-accuracy
  [
      hatch-bullet 1
      [
        set size .5
        set color white
        set energy 15
      ]
    ]
end
  
to kill ;;When a bullet lands on patch occupied by another, kill the agent and the bullet.
   ask zombie-on patch-here
  [
    set breed dead
    set color white
    ]
  ask human-on patch-here
  [
    set breed dead
    set color pink
    ]
  ask billybob-on patch-here
  [
    set breed dead
    set color green
    ]
   
  die
end

to update-globals ;;Set globals to current values for reporters.
  set total-human (count human)
  set total-zombie (count zombie)
  set total-billybob (count billybob)
end
  
to pop-check  ;; Make sure total population does not exceed total number of patches.
  if initial-zombies + initial-humans > count patches
    [ user-message (word "This Zombieland only has room for " count patches " agents.")
      stop ]
end

    

; *** NetLogo 4.1 Model Copyright Notice ***
;
; Copyright 2010 by Michael D. Ball.  All rights reserved.
;
; Permission to use, modify or redistribute this model is hereby granted,
; provided that both of the following requirements are followed:
; a) this copyright notice is included.
; b) this model will not be redistributed for profit without permission
;    from Michael D. Ball.
; Contact Michael D. Ball for appropriate licenses for redistribution for
; profit.
;
; To refer to this model in academic publications, please use:
; Ball, M. (2010).  Zombieland Model ver. 1.4.
; http://www.personal.kent.edu/~mdball/netlogo_models.htm.
; The Center for Complexity in Health,
; Kent State University at Ashtabula, Ashtabula, OH.
;
; In other publications, please use:
; Copyright 2010 Michael D. Ball.  All rights reserved.
; See http://www.personal.kent.edu/~mdball/netlogo_models.htm
; for terms of use.
;
; *** End of NetLogo 4.1 Model Copyright Notice ***

@#$#@#$#@
GRAPHICS-WINDOW
205
10
644
470
16
16
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks

BUTTON
19
26
83
59
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
110
25
173
58
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
15
225
187
258
Initial-humans
Initial-humans
0
100
80
1
1
NIL
HORIZONTAL

SLIDER
15
265
187
298
Initial-zombies
Initial-zombies
0
100
5
1
1
NIL
HORIZONTAL

SLIDER
15
305
187
338
Zombie-speed
Zombie-speed
1
10
1
1
1
NIL
HORIZONTAL

SLIDER
15
345
187
378
Human-speed
Human-speed
1
10
2
1
1
NIL
HORIZONTAL

SLIDER
15
385
187
418
Zombie-vision
Zombie-vision
1
5
5
1
1
NIL
HORIZONTAL

SLIDER
15
425
187
458
human-vision
human-vision
1
5
4
1
1
NIL
HORIZONTAL

BUTTON
45
65
152
98
Draw Buildings
building-draw
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
5
105
107
138
Clear Turtles
clear-turtles
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
115
105
192
138
Clear All
clear-all
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
15
185
187
218
weapon-cache
weapon-cache
0
10
3
1
1
NIL
HORIZONTAL

SLIDER
15
145
188
178
shot-accuracy
shot-accuracy
0
100
22
1
1
%
HORIZONTAL

MONITOR
15
480
97
525
# of Humans
total-human
17
1
11

MONITOR
100
480
182
525
# of Zombies
total-zombie
17
1
11

MONITOR
185
480
307
525
# of Armed Humans
total-billybob
17
1
11

@#$#@#$#@
WHAT IS IT?
-----------
Zombies!!


HOW IT WORKS
------------
Eat Brains!!!  (Seriously - see the code for information - it is fully notated.)


HOW TO USE IT
-------------
1. Click the Draw Buildings button to enable the mouse to create buildings in the world.
2. Left click and drag the mouse to draw.
3. Set initial number of zombies, humans and weapon caches.
4. Set speed for Humans and Zombies.
5. Set Shot Accuracy for weapon use.
6. Set vision radius for Humans and Zombies.
7. Push Setup to get ready to eat brains!
8. Push Go to eat brains!

Use Clear Turtles button to restart simulation with existing buildings.
Use Clear All button to start from scratch.


THINGS TO NOTICE
----------------
Zombies now seek brains and Humans run away if they see a Zombie near them.
Modified the movement code to smooth the motion of agents.
Zombies and Humans both treat yellow patches as buildings and will not cross that patch.
The Humans can fight back now. If a Human lands on a weapon cache, he becomes armed (Go, Billy Bob!) and can shoot Zombies. If a Human is hit by a bullet, they will die too.


THINGS TO TRY
-------------
Start with just 1 zombie. Slow Zombies will eventually catch faster humans.


EXTENDING THE MODEL
-------------------
Super Zombies! Humans that hide!


NETLOGO FEATURES
----------------
The simulation runs smoother if the model is set to continuous update instead of update on ticks.


RELATED MODELS
--------------
None that I know of.


CREDITS AND REFERENCES
----------------------
Michael Ball, Research Coordinator, Computational Modeling & IT Resources at The Center for Complexity in Health - KSUA
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

caterpillar
true
0
Polygon -7500403 true true 165 210 165 225 135 255 105 270 90 270 75 255 75 240 90 210 120 195 135 165 165 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 60 225 105 225 135 210 150 210 165 195 195 180 210
Line -16777216 false 135 255 90 210
Line -16777216 false 165 225 120 195
Line -16777216 false 135 165 180 210
Line -16777216 false 150 150 201 186
Line -16777216 false 165 135 210 150
Line -16777216 false 165 120 225 120
Line -16777216 false 165 106 221 90
Line -16777216 false 157 91 210 60
Line -16777216 false 150 60 180 45
Line -16777216 false 120 30 96 26
Line -16777216 false 124 0 135 15

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

gun
false
2
Rectangle -955883 true true 45 120 255 150
Rectangle -955883 true true 45 150 105 240
Rectangle -955883 true true 105 150 225 165
Polygon -955883 true true 255 120 240 105 240 120 225 135
Rectangle -955883 true true 255 120 270 135
Rectangle -16777216 true false 45 120 60 150
Polygon -16777216 true false 45 240 60 150 45 150 45 240
Polygon -16777216 true false 105 240 105 165 90 240
Circle -955883 false true 99 159 42

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

redneck
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Rectangle -7500403 true true 90 15 150 30
Line -7500403 true 30 90 90 210
Polygon -7500403 true true 90 210 75 225 60 165 30 105 30 90 90 210

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 4.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@
