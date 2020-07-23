;; Pareto_Schelling_Mobility Model ver. 3.0

;; Changes from ver 2.5b - The code for checking the health state of the agents has been modified.  Agents now report whether they are healthy or unhealthy
;; based on the desired number of red agents in a 4 patch radius around them, instead of only checking immediate neighbors.  Graph plots have been updated
;; to reflect the changes made.

;; Changes from ver 2.4 - The movement behavior of the middle agents has been modified.  Middle agents seek rich.  If no rich are in their movability radius,
;; the agent checks to see if the desired number of middle agents (determined by the middle-settle slider) are in their movability radius.  If there are,
;; the agent remains where it is.  If the number of other middle agents is below the desired number, the agent will move toward the nearest middle agent in
;; it's movability radius. 

;; Changes from ver 2.3 - The movement behavior of the middle and poor agents has been modified.  If a middle agent does not have any of the desired
;; breed within their movabilty radius, they will move toward other middle agents that are within the movability radius.  If there are no middle
;; agents in the radius, then movement is random. If a poor agent does not have any of the desired breed within their movabilty radius, then the poor
;; agent does not move.

;; Changes from ver 2.2 - The movement of the agents is no longer random as they seek happiness.  If the agent sees other agents of the desired breed within
;; its movability radius, it will move toward the nearest agent of the desired type.  If there are no agents of the desired type with the radius, then
;; movement is random.
 
;; Changes from ver. 2.1 - The health check now reports 4 different levels of health based on the number of desired agents of a specific breed as neighbors.
;; Graph plots have been cleaned up and consolidated to better show outcome results.

breed [rich richperson] ;; Rich, middle and poor are breeds of turtle. 
breed [middle middleperson]
breed [poor poorperson]

globals [
  percent-unhappy ;; Percentage of all agents that are unhappy.
  unhappy-rich  ;; Percentage of all rich agents that are unhappy.
  unhappy-middle  ;; Percentage of all middle agents that are unhappy.
  unhappy-poor   ;; Percentage of all poor agents that are unhappy.
  unhealthy-rich  ;; Percentage of all rich agents that are unhealthy.
  unhealthy-middle  ;; Percentage of all middle agents that are unhealthy
  unhealthy-poor  ;; Percentage of all poor agents that are unhealthy
  percent-unhealthy  ;; Percentage of all agents that are unhealthy.
  ]
  
turtles-own [
  happy? ;; Indicates if happy with neighbors based on preference rate.
  healthy? ;; Indicates if agent has perfect health based on type/number of neighbors.
  preference-count ;; Counts how many preferred neighbors a breed has.
  movability ;; Controls the distance the turtles can move each iteration.
  health-count  ;; Counts how many neighbors for health check.
  rich-group  ;;Agent subset for middle seek.
  same-group  ;;Agent subset for rich seek.
  middle-group ;;Agent subset for poor seek.
  middle-settle-group  ;;Agent subset for middle with no rich nearby.
  middle-settle-count  ;;Counts number of turtles in middle-settle-group.
  nearest-same  ;;Nearest agent in the same-group.
  nearest-rich  ;;Nearest agent in the rich-group.
  nearest-middle  ;;Nearest agent in the middle-group.
  nearest-settle-middle  ;; Nearest agent in the middle-settle-group.
  ]


to setup ;; Clear previous run and setup initial agent locations.
  clear-all
  pop-check
  setup-agents
  initial-happy
  healthy-check
  update-globals
  do-plots
end

to go ;; Run the simulation.
  if all? turtles [happy?] [ stop ] ;; if all the turtles are happy then the model breaks out of the go loop.
  happy-check
  healthy-check 
  update-globals
  do-plots
  tick  
end



to pop-check  ;; Make sure total population does not exceed total number of patches.
  if initial-number-rich + initial-number-middle + initial-number-poor > count patches
    [ user-message (word "This Pareto Universe only has room for " count patches " agents.")
      stop ]
end

to setup-agents ;; Create the desired number of each breed on random patches.
  set-default-shape rich "person"
  set-default-shape middle "person"
  set-default-shape poor "person"
  
  ask n-of initial-number-rich patches
    [ sprout-rich 1
      [ set color red ] ]
      
  ask n-of initial-number-middle patches
    [ sprout-middle 1
      [ set color blue ] ]
      
  ask n-of initial-number-poor patches
    [ sprout-poor 1
      [ set color green ] ]
end

to happy-check ;; Test if agents are happy and move them if not.
  ask rich [
    set preference-count count (turtles-on neighbors) with [breed = rich ]
    set movability movability-rich
    set happy? preference-count >= number-of-rich-preferred-by-rich
    ]
    ask rich with [ not happy? ] 
      [ rich-find-new-spot ]
   
  ask middle [
    set preference-count count (turtles-on neighbors) with [breed = rich ]
    set movability movability-middle
    set happy? preference-count >= number-of-rich-preferred-by-middle
    ]
    ask middle with [ not happy? ] 
      [ middle-find-new-spot ]
  
  ask poor [
    set preference-count count (turtles-on neighbors) with [breed = middle ]
    set movability movability-poor
    set happy? preference-count >= number-of-middle-preferred-by-poor
    ]
    ask poor with [ not happy? ] 
      [ poor-find-new-spot ]
      
end   

to healthy-check  ;; Test if agents are healthy.
  ask turtles [
    set health-count count (turtles in-radius 4) with [breed = rich ]
    set healthy? health-count >= 3
    ]
    
end

to initial-happy  ;; Check the happiness state of all agents before the simulation begins.
  ask rich [
    set preference-count count (turtles-on neighbors) with [breed = rich ]
    set movability movability-rich
    set happy? preference-count >= number-of-rich-preferred-by-rich
    ]
     
  ask middle [
    set preference-count count (turtles-on neighbors) with [breed = rich ]
    set movability movability-middle
    set happy? preference-count >= number-of-rich-preferred-by-middle
    ]
  
  ask poor [
    set preference-count count (turtles-on neighbors) with [breed = middle ]
    set movability movability-poor
    set happy? preference-count >= number-of-middle-preferred-by-poor
    ]
end

to wander ;; Pick the patch the unhappy agent moves to if not actively seeking.
    rt random-float 360
    fd random-float movability
    move-to patch-here
    if any? other turtles-here
    [wander]
  
end

to rich-find-new-spot  ;;Seek routine for unhappy rich agents.
  seek-same
  ifelse any? same-group
  [move-toward-same]
  [wander]
end

to middle-find-new-spot  ;;Seek routine for unhappy middle agents.
  seek-rich
  settle-for-middle
  ifelse any? rich-group
  [move-toward-rich]
  [settle-check]
end

to poor-find-new-spot  ;;Seek routine for unhappy poor agents.
  seek-middle
  if any? middle-group
  [move-toward-middle]
end

to move-toward-same  ;;Move rich agent toward nearest rich agent.
  set nearest-same min-one-of same-group [distance myself]
  face nearest-same
  fd random-float distance nearest-same - 1
   move-to patch-here
  if any? other turtles-here
    [wander]
end

to move-toward-rich  ;;Move middle agent toward nearest rich agent.
  set nearest-rich min-one-of rich-group [distance myself]
  face nearest-rich
  fd random-float distance nearest-rich - 1
   move-to patch-here
  if any? other turtles-here
    [wander]
end

to move-toward-middle  ;;Move poor agent toward nearest middle agent.
  set nearest-middle min-one-of middle-group [distance myself]
  face nearest-middle
  fd random-float distance nearest-middle - 1
   move-to patch-here
  if any? other turtles-here
    [wander]
end

to settle-toward-middle  ;;Move middle agent toward nearest middle agent.
  set nearest-settle-middle min-one-of middle-settle-group [distance myself]
  face nearest-settle-middle
  fd random-float distance nearest-settle-middle - 1
   move-to patch-here
  if any? other turtles-here
    [wander]
end

to settle-check  ;;If middle agent has less than desired number of middle agents around it, have agent move toward nearest other middle agent.
  if middle-settle-count < middle-settle
  [settle-toward-middle]
end

to seek-same  ;;adds all rich in vision radius of rich to an agent subset for that agent.
  set same-group other rich in-radius (movability-rich + 1)
 
end

to seek-rich  ;;adds all rich in vision radius of rich to an agent subset for that agent.
  set rich-group rich in-radius (movability-middle + 1)
end

to seek-middle  ;;adds all middle in vision radius of poor to an agent subset for that agent.
  set middle-group middle in-radius (movability-poor + 1)
end

to settle-for-middle  ;;adds all middle in vision radius of middle to an agent subset for that agent.
  set middle-settle-group middle in-radius (movability-middle + 1)
  set middle-settle-count count (middle-settle-group)
end


to update-globals ;; Calculate agent states each tick.
  set percent-unhappy (count turtles with [not happy?]) / (count turtles) * 100
  set unhappy-rich (count rich with [not happy?]) / (count rich) * 100
  set unhappy-middle (count middle with [not happy?]) / (count middle) * 100
  set unhappy-poor (count poor with [not happy?]) / (count poor) * 100
  set unhealthy-rich (count rich with [not healthy?]) / (count turtles) * 100
  set unhealthy-middle (count middle with [not healthy?]) / (count turtles) * 100
  set unhealthy-poor (count poor with [not healthy?]) / (count turtles) * 100
  set percent-unhealthy (count turtles with [ not healthy?]) / (count turtles) * 100

end

to do-plots ;; Update graphs.
  set-current-plot "Percent Unhappy"
  set-current-plot-pen "Unhappy-Rich"
  plot unhappy-rich
  set-current-plot-pen "Unhappy-Middle"
  plot unhappy-middle
  set-current-plot-pen "Unhappy-Poor"
  plot unhappy-poor
  set-current-plot "Health Levels"
  set-current-plot-pen "Unhealthy-Rich"
  plot unhealthy-rich
  set-current-plot-pen "Unhealthy-Middle"
  plot unhealthy-middle
  set-current-plot-pen "Unhealthy-Poor"
  plot unhealthy-poor

end

; *** NetLogo 4.1 Model Copyright Notice ***
;
; Copyright 2010 by Dr. Brian Castellani, Michael D. Ball, & Kenneth Carvalho.  All rights reserved.
;
; Permission to use, modify or redistribute this model is hereby granted,
; provided that both of the following requirements are followed:
; a) this copyright notice is included.
; b) this model will not be redistributed for profit without permission
;    from Dr. Brian Castellani, Michael D. Ball, & Kenneth Carvalho.
; Contact Dr. Brian Castellani & Michael D. Ball for appropriate licenses for redistribution for
; profit.
;
; To refer to this model in academic publications, please use:
; Castellani, B., Ball, M., Carvalho, C. (2010).  Pareto_Schelling_Mobility Model ver. 3.0.
; http://www.personal.kent.edu/~mdball/pareto_schelling_mobility.htm.
; KSUAC Center for Complexity in Health,
; Kent State University at Ashtabula, Ashtabula, OH.
;
; In other publications, please use:
; Copyright 2010 Dr. Brian Castellani, Michael D. Ball, & Kenneth Carvalho.  All rights reserved.
; See http://www.personal.kent.edu/~mdball/pareto_schelling_mobility.htm
; for terms of use.
;
; *** End of NetLogo 4.1 Model Copyright Notice ***

@#$#@#$#@
GRAPHICS-WINDOW
248
36
615
424
25
25
7.0
1
10
1
1
1
0
1
1
1
-25
25
-25
25
0
0
1
ticks

BUTTON
41
10
121
43
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

SLIDER
18
54
239
87
initial-number-rich
initial-number-rich
1
1000
111
10
1
NIL
HORIZONTAL

SLIDER
18
94
240
127
initial-number-middle
initial-number-middle
1
1000
311
10
1
NIL
HORIZONTAL

SLIDER
18
133
241
166
initial-number-poor
initial-number-poor
1
1000
581
10
1
NIL
HORIZONTAL

BUTTON
148
10
212
44
NIL
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
24
306
238
339
number-of-rich-preferred-by-rich
number-of-rich-preferred-by-rich
1
8
2
1
1
NIL
HORIZONTAL

SLIDER
24
349
237
382
number-of-rich-preferred-by-middle
number-of-rich-preferred-by-middle
1
8
2
1
1
NIL
HORIZONTAL

SLIDER
24
390
238
423
number-of-middle-preferred-by-poor
number-of-middle-preferred-by-poor
1
8
2
1
1
NIL
HORIZONTAL

SLIDER
46
181
218
214
movability-rich
movability-rich
1
6
6
1
1
NIL
HORIZONTAL

SLIDER
46
221
218
254
movability-middle
movability-middle
1
6
3
1
1
NIL
HORIZONTAL

SLIDER
47
259
219
292
movability-poor
movability-poor
1
6
1
1
1
NIL
HORIZONTAL

PLOT
622
11
1097
161
Percent Unhappy
Time
%
0.0
5.0
0.0
100.0
true
true
PENS
"Unhappy-Rich" 1.0 0 -2674135 true
"Unhappy-Middle" 1.0 0 -13345367 true
"Unhappy-Poor" 1.0 0 -10899396 true

MONITOR
625
166
735
211
Total % Unhappy
percent-unhappy
2
1
11

MONITOR
741
166
846
211
% Rich Unhappy
unhappy-rich
2
1
11

MONITOR
854
166
971
211
% Middle Unhappy
unhappy-middle
2
1
11

MONITOR
979
166
1087
211
% Poor Unhappy
unhappy-poor
2
1
11

PLOT
625
223
1100
373
Health Levels
Time
%
0.0
10.0
0.0
100.0
true
true
PENS
"Unhealthy-Rich" 1.0 0 -2674135 true
"Unhealthy-Middle" 1.0 0 -13345367 true
"Unhealthy-Poor" 1.0 0 -10899396 true

MONITOR
621
379
738
424
Total % Unhealthy
percent-unhealthy
2
1
11

MONITOR
994
379
1108
424
% Poor Unhealthy
unhealthy-poor
2
1
11

MONITOR
739
379
868
424
% Rich Unhealthy
unhealthy-rich
2
1
11

MONITOR
869
379
993
424
% Middle Unhealthy
unhealthy-middle
2
1
11

SLIDER
43
434
215
467
middle-settle
middle-settle
2
5
4
1
1
NIL
HORIZONTAL

@#$#@#$#@
WHAT IS IT?
-----------
This model explores the relationship between Pareto's 80/20 rule and Schelling's segregation threshold.  The model is a 51X51 lattice structure, upon which a randomly distributed set of upwardly-mobile rich, middle-class, and poor agents roam.  Three rules govern the behavior of these agents: preference, preference-degree, and movability.

PREFERENCE is a modification of Schelling’s segregation rules.  Unlike the original Schelling model, wherein agents seek their own kind, preference concerns upwardly mobile agents seeking agents of a higher status.  In our model, rich agents seek rich agents; middle-class agents seek rich agents; and poor agents seek middle-class agents.

PREFERENCE-DEGREE determines the number of higher status agents around which others prefer to live.  In a 2-D lattice structure, “neighbors” is defined as the total number of spaces available around an individual agent, which range from 0 to 8.

MOVABILITY (which ranges from 0 to 10) determines the number of spaces an agent can move per iteration. 


BACKGROUND
---------
Two important principles governing upward social mobility are Pareto’s 80/20 rule and Schelling’s segregation threshold.  Pareto shows that wealth follows a power law, where a few have the most.  Schelling shows that neighborhood preference (beyond a certain threshold) leads to spatial segregation.  The link between these two principles, however, remains undeveloped—particularly in relation to the current U.S. financial crisis (circa 2008).  To explore this link, we created an agent-based, Pareto universe of rich, middle and poor agents.  The rules for this universe follow Schelling, with a slight modification: while rich agents seek their own, middle and poor agents do not; instead (pursuing upward mobility), middle agents seek rich agents and poor agents seek middle agents.  Congruent with the current U.S. financial crisis, our model finds that, in a log-normal wealth distribution with a power-tail, moderate upward social mobility produces spatial segregation, instability and, in particular, unhappiness on the part of middle-class and poor agents.  We call this insight the upward social mobility rule (MR).  Unexpectedly, the MR also provides a corrective: it appears that, at threshold, upward social mobility leads to integrated, stable neighborhoods with very high rates of happiness.  The MR therefore suggests that the U.S. financial/housing crisis might be effectively addressed for the greater good of all if upward social mobility is controlled and regulated, even on the part of poor households.  
  

THE UPWARD SOCIAL MOBILITY RULE
-------------------------------
In a Pareto universe, once preference (p) for upward social mobility passes a certain threshold (x), the spatial segregation of wealth (S) emerges.  We can state this rule more generally: when (p < or = x), segregation approaches zero; however, once (p > x), segregation approaches near completion.  Furthermore, as (p) moves past threshold, segregation increases—although the relationship between (S) and (p) is nonlinear, levelling off across time (t) at about (p = 3). 

S --> 0 if p < or = x                           	                     
S --> 1 if p > x                   

In this first formula, the MR defines upward social mobility as an agent’s preference and movability to improve its economic status within a Pareto wealth distribution.  Together, movability and preference create a likelihood of happiness distribution (L).  At any given moment, an agent’s likelihood for happiness—that is, the agent’s movability to secure upward social mobility—is expressed as follows:
 
L(H) = (s / (t-h) ) (c/c')				                       

Where H = happiness; s = neighborhood spaces available around the higher status agents being sought; t = total population of agents seeking a particular set of spaces; h = similar seeking agents that have already secured a position of happiness; c = an agent’s actual movability to move randomly at any given point in time; and c' = the agent’s ideal movability.  Furthermore, in this second formula, s is determined, in part, by preference (p), which defines the type and number of empty spaces agents are seeking.  For example, if rich agents seek spaces with p = 2 neighbors, only those empty spaces are sought by rich agents; s for each of the three agent types is also dependent upon the number of spaces already taken by other agents.  

In our model, we simplify the likelihood of happiness into a basic prevalence rate of unhappiness—which we obtain by plotting the prevalence rate of unhappy rich, middle and poor agents at each moment in time, along with an overall unhappiness rating.

 
HOW TO USE IT
-------------
1. Determine the number of red, blue and green agents.  RED are rich agents; BLUE are middle-class agents; and GREEN are poor agents.  

2. PARETO DISTRIBUTION: Use the sliders to determine population estimates.  In a Pareto universe, RED agents are few (e.g., 90 to 100); BLUE agents are perhaps double in size or more (e.g., 300 to 320) and GREEN agents are the largest group (e.g., 700 to 750).  You can try any Pareto estimate you want or try other arrangements, perhaps based on a log-normal distribution or Guassian (bell shaped) distribution.

3. PREFERENCE DEGREE: Use the sliders to determine the number of higher status agents each color is seeking. In our model, A) RED seek other RED; B) BLUE seek other RED and C) GREEN seek other BLUE.  The higher the preference-degree is for each agent type, the harder it will be for those agents to secure a position of upward mobility.

4. MOVABILITY: Use the sliders to determine the movability of RED, BLUE and GREEN agents.  Movability determines how many spaces an agent can mover per iteration.  In the real world, RED agents have the greatest movability to move because of their wealth.  Poor agents have the least movability to move because of their lack of wealth.  Try different movability combinations to see what impact it has on mobility.

5. SETUP: Once you have completed the above four steps, hit SETUP and you are ready to go.  All you need to do next is hit GO.  When you want the model to stop hit GO again.


--------------------Click GO to start the simulation.--------------------------------- 

FINDINGS
-------------
To test the MR, we used the BehaviorSpace tool in Netlogo to run 27 different preference-degree combinations, starting with  r1,m1,p1 (rich seek one rich agent; middle seek one rich agent and poor seek one middle agent) and ending with r3,m3,p3 (rich seek three rich, middle seek 3 rich; poor seek 3 middle).  We tested each combination 100 times for a total of 2,700 runs.

1. We found that, in a Pareto universe, the spatial segregation of wealth is a function of some type of social mobility rule—which can be mapped, across time, as a series of unhappiness distributions.

2. More specifically, it appears that the (r1,m1,p1)combination has the best happiness ratings. 

3.  The degree of unhappiness in our Pareto universe is best explained in systems terms—that is, the 27 different combinations of micro-level behaviors we examined lead to unintended and, in some instances, unexpected macro-level patterns.  Two systems issues are of particular importance.

The first has to do with the behavior of rich agents.  We found that the upward mobility of rich agents at (p =2) negatively impacts the happiness of middle and poor agents.  Rich agents close-out middle agents because of their increased mild preference (p = 2), which causes a rippling effect wherein the lack of spaces for middle agents causes instability, which makes it harder for poor agents to secure a stable place to live.  

The second has to do with the behavior of middle and poor agents.  The rippling effect of the rich is less dramatic when the upward mobility of middle and poor agents is kept at (p = 1).  In other words (and unexpectedly so), middle and poor agents have a much better chance at happiness when they enact a mild level of upward mobility, especially when rich agents begin seeking higher rates of mobility.  

4.  It appears that (r1,m1,p1) is the most spatially integrated of all 27 models.  

5.  Spatial segregation in our Pareto universe is also best explained in systems terms. Again, two systems issues are of particular importance.  

First, higher rates of mobility amongst rich, middle and poor agents lead to higher rates of spatial segregation—both within and between agent types.  More specifically, once preference-degree becomes moderate, reaching p=3, almost everyone in a Pareto universe (from the rich to the poor) has high rates of unhappiness.  

Second, if preference-degree is kept at threshold  ), integrated, stable neighborhoods emerge and unhappiness is low.  For example, because R1 (see note e, Figure 1) remains at threshold, spatial segregation amongst the three agent types is almost absent.  (Note: here preference is expressed as  , where p = preference-degree and n = total neighborhood spaces available, which in our model (n=8).

6. Finally, we found that, in an already segregated model, setting social mobility at (p = 1) functions as a corrective: it improves integration and happiness.  For example, running our model at (r2,m2,p2) we found that, after 1000 iterations, unhappiness was at 61%.  At this point we reset mobility at (r1,m1,p1).  After another 1000 iterations, unhappiness dropped from 61% to 23% and segregation significantly decreased. 


IMPLICATIONS FOR U.S. FINANCIAL/HOUSING CRISIS
-------------------
Congruent with the current U.S. financial crisis, our model suggests that, in a log-normal wealth distribution with a power-tail, moderate upward social mobility produces significant system-wide spatial segregation, instability and, in particular, unhappiness on the part of the middle-class and poor.  
Unexpectedly, however, our model also suggests that, one way to address the current U.S. financial crisis is to slow down mobility to a mild, threshold level.  The important byproduct of this more systemically aware mobility is integrated, stable neighborhoods that have very high rates of happiness.  In other words, Pareto’s law seems more effectively addressed for the greater good of all if upward social mobility is controlled and regulated, even on the part of poor households.  This is particularly true in terms of housing.  

Over the last decade, many Americans and their lenders have used a variety of high-risk housing strategies (sub-prime lending, etc) to obtain higher levels of upward social mobility.  The result has been the increased spatial segregation of wealth: the neighborhood distances from the rich to the poor have geographically increased as upwardly mobile families lost their homes, primarily through failed attempts to gain more than they could financially support.  Within the confines of our model, the failure of this strategy seems evident.  Past a certain threshold, upward social mobility threatens (rather than stabilizes) the system, creating unstable, chaotic mobility patterns amongst the poor and middle-class—which results in increased, rather than decreased, wealth segregation.  

In such a chaotic system, the effects of neighborhood, in particular poverty traps, also make sense—albeit with an important (and unexpected) twist.  As shown in R2, once mobility passes a certain threshold, poor agents (despite their individual efforts) remain stuck.  They cannot improve their position no matter how aggressive their social mobility.  In other words, poverty traps are not strictly a function of neighborhood effects.  Instead, poverty traps and neighborhood effects are the product of something larger: the system, or more specifically, the mobility patterns of the rich, middle-class and poor.

This last finding is perhaps our most important.  Individual micro-level social mobility is not self-regulating.  Contra Adam Smith, our model suggest that there is no invisible hand guiding the role upward social mobility plays in the spatial distribution of wealth.  As the recent U.S. financial/housing crisis shows, and our model seems to concur, in a Pareto Universe, without some type of threshold-based recognition, upward social mobility (even at relatively mild levels) does not promote the good of the community; instead, it supports Schelling-like segregation.


EXTENDING THE MODEL
-------------------
Our model is very basic.  It would therefore be interesting to see what types of additional factors impact our findings.  We welcome researchers to try other types of senarios.

HEALTHY  The program now assigns a healhty state to each agent based on the number/types of agents that are it's neighbors.  The program reports 4 different levels of health: Perfect, Above Average, Average, and Unhealthy.

Agents now actively seek their desired neighbors instead of moving randomly.

The movement behavior of the middle and poor agents has been modified.  If a middle agent does not have any of the desired breed within their movabilty radius, they will move toward other middle agents that are within the movability radius.  If there are no middle agents in the radius, then movement is random. If a poor agent does not have any of the desired breed within their movabilty radius, then the poor agent does not move.

The movement behavior of the middle agents has been modified.  Middle agents seek rich.  If no rich are in their movability radius, the agent checks to see if the desired number of middle agents (determined by the middle-settle slider) are in their movability radius.  If there are, the agent remains where it is.  If the number of other middle agents is below the desired number, the agent will move toward the nearest middle agent in it's movability radius.

The code for checking the health state of the agents has been modified.  Agents now report whether they are healthy or unhealthy based on the desired number of red agents in a 4 patch radius around them, instead of only checking immediate neighbors.  Graph plots have been updated to reflect the changes made. 




NETLOGO REFERENCES
Schelling, T. (1978). Micromotives and Macrobehavior. New York: Norton.
See also a recent Atlantic article:   Rauch, J. (2002). Seeing Around Corners; The Atlantic Monthly; April 2002;Volume 289, No. 4; 35-48. http://www.theatlantic.com/issues/2002/04/rauch.htm

Wilensky, U. (1997).  NetLogo Segregation model.  http://ccl.northwestern.edu/netlogo/models/Segregation.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Wilensky, U. (2005). NetLogo Wolf Sheep Predation (System Dynamics) model. http://ccl.northwestern.edu/netlogo/models/WolfSheepPredation(SystemDynamics). Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

STUDY REFERENCES
1.	Boccara, N. Modeling Complex Systems (Springer, New York, 2004).
2.	Souma, W. Universal structure of the personal income distribution. Fractals-Complex Geometry Patterns and Scaling in Nature and Society 9, 463-470 (2001).
3.	Coelho, R., Richmond, P., Barry, J. & Hutzler, S. Double power laws in income and wealth distributions. Physica A 387, 3847-3851 (2008).
4.	 Bruch, E. E. & Mare, R. D. Neighborhood choice and neighborhood change. AJS 112, 667-709 (2006).
5.	Clark, W. A. V. Residential preferences and neighborhood racial segregation: A test of the Schelling segregation model. Demography 28, 1-19 (1991).
6.	Schiller, R. J. Irrational Exuberance, 2nd edition. Princeton Univ Press, Princeton 2005).
7.	Fujita, M., Krugman, P. & Venables, A.J. The Spatial Economy: Cities, Regions and International Trade. (MIT Press, Boston, 2001).
8.	Surowiecki, J. Going for broke. New Yorker, The Financial page, 7 April 2008.
9.	Soros, G. The New Paradigm for Financial Markets: The Credit Crisis of 2008 and What It Means (Public Affairs, New York, 2008.
10.	Neckerman, K. M. & Torche F. Inequality: causes and consequences. Ann Rev of Soc 33, 335-357.
11.	Krugman, P. The great wealth transfer. Rolling Stone, 30 Nov 2006 (accessed at: www.rollingstone. com/politics/ story/12699486/paul_krugman_on_the_great_wealth_ transfer/print. 
12.	Bowles, S., Durlauf, S. N. & Hoff K. Poverty Traps (Princeton University Press, Princeton, 2006).
13.	Transit Cooperative Research Program. Costs of Sprawl 2000-TCRP Report 74. (National Academy Press, Washington D.C., 2002). (accessed at: onlinepubs.trb.org/Onlinepubs/ tcrp/tcrp_rpt_74-a.pdf).
14.	Robert, S. Socioeconomic position and health: the independent contribution of community socioeconomic context. Ann Rev of Soc 25, 489-516.
15.	Health inequalities and place: A theoretical conception of neighborhood. Soc Science & Med 65, 1839-1852.
16.	Epstein, J. Generative Social Science: Studies in Agent-Based Computational Modeling (Princeton University Press, Princeton, 2007). 
17.	Wilensky, U. NetLogo. (accessed at: ccl.northwestern.edu/netlogo) (Center for Connected Learning and Computer-Based Modeling. Northwestern University, Evanston, IL, 1999).

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
NetLogo 4.1.1
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
