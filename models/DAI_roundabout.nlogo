;; ==========================================================
;; Roundabout Pedestrian Dynamics — Floor Field Model (CA)
;; DAI Project — Extension from bidirectional corridor
;; ==========================================================
;;
;; Based on: Burstedde, Klauck, Schadschneider, Zittartz (2001)
;;           "Simulation of pedestrian dynamics using a 2D cellular automaton"
;;           Physica A 295, pp. 507-525
;;
;; Extended to a 4-way roundabout geometry with 4 pedestrian flows.
;; Destinations: 0=West (red), 1=East (blue), 2=North (green), 3=South (orange)

globals [
  E1                     ; repulsion coefficient on current cell
  E2                     ; repulsion coefficient on neighbor cells
  max-S-global           ; max static field value (visualization normalization)
  phi                    ; lane segregation index (0.25=none, 1.0=perfect)
  phi-max                ; maximum observed phi
  throughput-total       ; cumulative exits across all directions
  throughput-per-tick    ; exits in the last tick
  exits-west             ; cumulative exits westbound
  exits-east             ; cumulative exits eastbound
  exits-north            ; cumulative exits northbound
  exits-south            ; cumulative exits southbound
  total-exit-time        ; sum of (exit-tick - entry-tick) across all exits
  exit-count-for-time    ; number of completed timed journeys
  phi-stabilization-tick ; first tick where phi >= 0.9 (-1 = never)
]

turtles-own [
  gender                 ; "male" / "female" (stored for analysis)
  speed                  ; nominal speed (kept for API compatibility)
  destination            ; 0=West, 1=East, 2=North, 3=South
  transition-probabilities  ; list of 9 values (Moore neighborhood + stay)
  previous-patch         ; patch before last move
  move-count             ; ticks where this turtle actually moved
  entry-tick             ; tick of last spawn (for exit-time tracking)
  step-prob              ; per-tick probability of attempting movement (speed heterogeneity)
]

patches-own [
  D0 D1 D2 D3           ; dynamic floor fields (one per destination)
  S0 S1 S2 S3           ; static floor fields (attractivity, high near exit)
  R                      ; repulsive floor field
  is-wall                ; true = impassable
]

;; ==========================================================
;; SETUP
;; ==========================================================

to setup
  clear-all
  resize-world 0 40 0 40

  set E1 0.6
  set E2 0.2
  set throughput-total 0
  set throughput-per-tick 0
  set exits-west 0  set exits-east 0
  set exits-north 0 set exits-south 0
  set phi 0.25
  set phi-max 0.25
  set total-exit-time 0
  set exit-count-for-time 0
  set phi-stabilization-tick -1

  setup-patches

  crt num-pedestrians
  setup-pedestrians

  update-repulsion-field
  reset-ticks
end

to setup-patches
  let cx (max-pxcor / 2)
  let cy (max-pycor / 2)
  let R-inner roundabout-radius
  let R-outer (roundabout-radius + lane-width)

  ;; 1. All patches start as walls
  ask patches [
    set is-wall true
    set pcolor 2
    set D0 0  set D1 0  set D2 0  set D3 0
    set S0 0  set S1 0  set S2 0  set S3 0
    set R 0
  ]

  ;; 2. Carve roundabout ring
  ask patches [
    let d distancexy cx cy
    if d >= R-inner and d <= R-outer [
      set is-wall false
      set pcolor white
    ]
  ]

  ;; 3. Carve horizontal corridor (West-East)
  ask patches [
    if pycor >= (cy - corridor-half-width) and pycor <= (cy + corridor-half-width) [
      if pxcor < (cx - R-inner) or pxcor > (cx + R-inner) [
        set is-wall false
        set pcolor white
      ]
    ]
  ]

  ;; 4. Carve vertical corridor (North-South)
  ask patches [
    if pxcor >= (cx - corridor-half-width) and pxcor <= (cx + corridor-half-width) [
      if pycor < (cy - R-inner) or pycor > (cy + R-inner) [
        set is-wall false
        set pcolor white
      ]
    ]
  ]

  ;; 5. BFS flood-fill for static floor fields (one per exit)
  compute-static-field (patches with [pxcor = 0 and not is-wall])          "S0"
  compute-static-field (patches with [pxcor = max-pxcor and not is-wall])  "S1"
  compute-static-field (patches with [pycor = max-pycor and not is-wall])  "S2"
  compute-static-field (patches with [pycor = 0 and not is-wall])          "S3"

  ;; 6. Max S for visualization normalization
  let walkable patches with [not is-wall]
  ifelse any? walkable [
    set max-S-global max [max (list S0 S1 S2 S3)] of walkable
  ][
    set max-S-global 1
  ]
  if max-S-global = 0 [ set max-S-global 1 ]

  ;; 7. Show static field if selected
  if show-field = "static" [ visualize-static-field ]
end

;; BFS from target-patches; result inverted so high value = close to target
to compute-static-field [target-patches field-name]
  ask patches [ set-field field-name 9999 ]

  let queue []
  ask target-patches [
    set-field field-name 0
    set queue lput self queue
  ]

  ;; BFS with 8-connectivity (Moore neighborhood matches movement model)
  while [not empty? queue] [
    let current first queue
    set queue but-first queue
    let d-current [get-field field-name] of current
    
    let cx (max-pxcor / 2)
    let cy (max-pycor / 2)

    ask [neighbors] of current [
      if not is-wall [
        let cost 1
        ;; PENALTY TRICK: Induce CCW rotation by making 'left' paths longer
        if (field-name = "S0" and pycor > cy) [ set cost 10 ] ; Westbound: penalize North
        if (field-name = "S1" and pycor < cy) [ set cost 10 ] ; Eastbound: penalize South
        if (field-name = "S2" and pxcor > cx) [ set cost 10 ] ; Northbound: penalize East
        if (field-name = "S3" and pxcor < cx) [ set cost 10 ] ; Southbound: penalize West

        if get-field field-name > (d-current + cost) [
          set-field field-name (d-current + cost)
          set queue lput self queue
        ]
      ]
    ]
  ]

  ;; Invert: S = max_dist - dist (high near target for exp(Ks * S))
  let reachable patches with [get-field field-name < 9999]
  if any? reachable [
    let max-dist max [get-field field-name] of reachable
    ask reachable [
      set-field field-name (max-dist - get-field field-name)
    ]
  ]

  ;; Unreachable patches get 0
  ask patches with [get-field field-name >= 9999] [
    set-field field-name 0
  ]
end

to set-field [field-name val]
  if field-name = "S0" [ set S0 val ]
  if field-name = "S1" [ set S1 val ]
  if field-name = "S2" [ set S2 val ]
  if field-name = "S3" [ set S3 val ]
end

to-report get-field [field-name]
  if field-name = "S0" [ report S0 ]
  if field-name = "S1" [ report S1 ]
  if field-name = "S2" [ report S2 ]
  if field-name = "S3" [ report S3 ]
  report 9999
end

to setup-pedestrians
  let n-per-dir (num-pedestrians / 4)

  ask turtles [
    ;; Balanced destination assignment
    (ifelse
      who < n-per-dir         [ set destination 0  set color red ]
      who < (2 * n-per-dir)   [ set destination 1  set color blue ]
      who < (3 * n-per-dir)   [ set destination 2  set color green ]
      [                         set destination 3  set color orange ])

    set gender one-of ["male" "female"]
    set speed 1
    set transition-probabilities [0 0 0 0 0 0 0 0 0]
    set move-count 0
    set entry-tick 0
    ;; 70% normal (1.0), 20% slow (0.7), 10% fast (never skip = 1.0 but already covered)
    set step-prob one-of [1.0 1.0 1.0 1.0 1.0 1.0 1.0 0.7 0.7 0.5]

    ;; Place on walkable patch without collision
    let target one-of patches with [not is-wall and not any? turtles-here]
    ifelse target != nobody [
      move-to target
    ][
      move-to one-of patches with [not is-wall]
    ]
  ]
end

;; ==========================================================
;; MAIN SIMULATION LOOP
;; ==========================================================

to go
  ;; Reset visualization for clean updates
  if show-field = "none" or show-field = "static" [
    ask patches with [not is-wall] [ set pcolor white ]
    ask patches with [is-wall] [ set pcolor 2 ]
  ]

  ;; 1. Diffusion and decay of dynamic floor fields
  update-dynamic-field

  ;; 2. Pedestrian movement
  ;;
  ;;  0(NW) | 1(N)  | 2(NE)
  ;;  3(W)  | 4(stay)| 5(E)
  ;;  6(SW) | 7(S)  | 8(SE)

  let tick-exits 0

  ask turtles [
    ;; Check exit BEFORE movement
    let at-exit false
    if destination = 0 and pxcor = 0          [ set at-exit true ]
    if destination = 1 and pxcor = max-pxcor   [ set at-exit true ]
    if destination = 2 and pycor = max-pycor   [ set at-exit true ]
    if destination = 3 and pycor = 0           [ set at-exit true ]

    ifelse at-exit [
      ;; Count exit
      set tick-exits (tick-exits + 1)
      set throughput-total (throughput-total + 1)
      if destination = 0 [ set exits-west  (exits-west + 1)  ]
      if destination = 1 [ set exits-east  (exits-east + 1)  ]
      if destination = 2 [ set exits-north (exits-north + 1) ]
      if destination = 3 [ set exits-south (exits-south + 1) ]

      ;; Record journey time (only if turtle has moved at all this trip)
      if ticks > entry-tick [
        set total-exit-time (total-exit-time + (ticks - entry-tick))
        set exit-count-for-time (exit-count-for-time + 1)
      ]

      ;; Respawn at opposite entry
      let spawn nobody
      if destination = 0 [ set spawn one-of patches with [pxcor = max-pxcor and not is-wall and not any? turtles-here] ]
      if destination = 1 [ set spawn one-of patches with [pxcor = 0 and not is-wall and not any? turtles-here] ]
      if destination = 2 [ set spawn one-of patches with [pycor = 0 and not is-wall and not any? turtles-here] ]
      if destination = 3 [ set spawn one-of patches with [pycor = max-pycor and not is-wall and not any? turtles-here] ]

      if spawn != nobody [
        move-to spawn
        set move-count 0
        set entry-tick ticks
      ]
    ][
      ;; Normal movement

      ;; P(4) stay: n=0 because own cell is not "occupied by other"
      let p4 transition-probability 0 destination patch-here

      ;; P(0..8) for 8 neighboring directions
      let p0 transition-probability (get-n (patch-at-heading-and-distance 315 1)) destination (patch-at-heading-and-distance 315 1)
      let p1 transition-probability (get-n (patch-at-heading-and-distance 0   1)) destination (patch-at-heading-and-distance 0   1)
      let p2 transition-probability (get-n (patch-at-heading-and-distance 45  1)) destination (patch-at-heading-and-distance 45  1)
      let p3 transition-probability (get-n (patch-at-heading-and-distance 270 1)) destination (patch-at-heading-and-distance 270 1)
      let p5 transition-probability (get-n (patch-at-heading-and-distance 90  1)) destination (patch-at-heading-and-distance 90  1)
      let p6 transition-probability (get-n (patch-at-heading-and-distance 225 1)) destination (patch-at-heading-and-distance 225 1)
      let p7 transition-probability (get-n (patch-at-heading-and-distance 180 1)) destination (patch-at-heading-and-distance 180 1)
      let p8 transition-probability (get-n (patch-at-heading-and-distance 135 1)) destination (patch-at-heading-and-distance 135 1)

      ;; Normalize
      let total (p0 + p1 + p2 + p3 + p4 + p5 + p6 + p7 + p8)
      if total = 0 [ set total 1  set p4 1 ]

      set transition-probabilities (list
        (p0 / total) (p1 / total) (p2 / total)
        (p3 / total) (p4 / total) (p5 / total)
        (p6 / total) (p7 / total) (p8 / total))

      ;; Stochastic selection
      let rand random-float 1
      let i 0
      let accum item 0 transition-probabilities
      while [rand > accum and i < 8] [
        set i (i + 1)
        set accum (accum + item i transition-probabilities)
      ]

      ;; Execute movement
      set previous-patch patch-here

      if i != 4 [
        let headings-list [315 0 45 270 0 90 225 180 135]
        set heading item i headings-list
        let target-patch patch-at-heading-and-distance heading 1

        if target-patch != nobody and not [is-wall] of target-patch [
          ;; step-prob gate: slow pedestrians skip some ticks
          if random-float 1 < step-prob [
            ;; Deposit dynamic trace before moving
            if destination = 0 [ ask patch-here [ set D0 (D0 + 1) ] ]
            if destination = 1 [ ask patch-here [ set D1 (D1 + 1) ] ]
            if destination = 2 [ ask patch-here [ set D2 (D2 + 1) ] ]
            if destination = 3 [ ask patch-here [ set D3 (D3 + 1) ] ]

            move-to target-patch
            set move-count (move-count + 1)
          ]
        ]
      ]
    ]
  ]

  set throughput-per-tick tick-exits

  ;; 3. Update repulsive field
  update-repulsion-field

  ;; 4. Static field visualization
  if show-field = "static" [ visualize-static-field ]

  ;; 5. Compute segregation index
  set phi calculate-segregation-index
  if phi > phi-max [ set phi-max phi ]
  if phi-stabilization-tick = -1 and phi >= 0.9 [
    set phi-stabilization-tick ticks
  ]

  tick
end

;; ==========================================================
;; FIELD UPDATE PROCEDURES
;; ==========================================================

to update-dynamic-field
  ;; Zero walls before diffusion (prevent leaking through walls)
  ask patches with [is-wall] [
    set D0 0  set D1 0  set D2 0  set D3 0
  ]

  ;; Diffusion (spreads to 8 neighbors)
  diffuse D0 diffusion
  diffuse D1 diffusion
  diffuse D2 diffusion
  diffuse D3 diffusion

  ;; Zero walls after diffusion (absorbing boundary)
  ask patches with [is-wall] [
    set D0 0  set D1 0  set D2 0  set D3 0
  ]

  ;; Decay on walkable patches
  ask patches with [not is-wall] [
    set D0 (D0 * (1 - decay))  if D0 < 0.001 [ set D0 0 ]
    set D1 (D1 * (1 - decay))  if D1 < 0.001 [ set D1 0 ]
    set D2 (D2 * (1 - decay))  if D2 < 0.001 [ set D2 0 ]
    set D3 (D3 * (1 - decay))  if D3 < 0.001 [ set D3 0 ]
  ]

  ;; Visualization
  if show-field = "dynamic" [
    ask patches with [not is-wall] [
      let vals (list D0 D1 D2 D3)
      let m max vals
      ifelse m > 0.01 [
        let idx position m vals
        if idx = 0 [ set pcolor scale-color red    m 0 3 ]
        if idx = 1 [ set pcolor scale-color blue   m 0 3 ]
        if idx = 2 [ set pcolor scale-color green  m 0 3 ]
        if idx = 3 [ set pcolor scale-color orange m 0 3 ]
      ][
        set pcolor white
      ]
    ]
  ]
end

to update-repulsion-field
  ask patches [ set R 0 ]

  ask turtles [
    ask patch-here [ set R (R + E1) ]
    ask neighbors with [not is-wall] [ set R (R + E2) ]
  ]

  if show-field = "repulsion" [
    let Rmax max [R] of patches
    if Rmax > 0 [
      ask patches with [not is-wall] [
        set pcolor scale-color grey R 0 (Rmax * 1.5)
      ]
    ]
  ]
end

to visualize-static-field
  ;; Color each walkable patch by its closest exit direction
  ask patches with [not is-wall] [
    let vals (list S0 S1 S2 S3)
    let m max vals
    if m > 0 and max-S-global > 0 [
      let idx position m vals
      let intensity (m / max-S-global)
      if idx = 0 [ set pcolor scale-color red    intensity 0.2 1.2 ]
      if idx = 1 [ set pcolor scale-color blue   intensity 0.2 1.2 ]
      if idx = 2 [ set pcolor scale-color green  intensity 0.2 1.2 ]
      if idx = 3 [ set pcolor scale-color orange intensity 0.2 1.2 ]
    ]
  ]
end

;; ==========================================================
;; REPORTERS
;; ==========================================================

to-report transition-probability [n dest patch-xy]
  ;; Returns unnormalized transition probability for moving to patch-xy
  if patch-xy = nobody [ report 0 ]
  if [is-wall] of patch-xy [ report 0 ]

  ;; Static field: attractivity toward this destination's exit
  let Sxy 0
  if dest = 0 [ set Sxy [S0] of patch-xy ]
  if dest = 1 [ set Sxy [S1] of patch-xy ]
  if dest = 2 [ set Sxy [S2] of patch-xy ]
  if dest = 3 [ set Sxy [S3] of patch-xy ]

  ;; Dynamic field: own direction minus others (lane following effect)
  let D 0
  if dest = 0 [ set D [D0] of patch-xy - ([D1] of patch-xy + [D2] of patch-xy + [D3] of patch-xy) ]
  if dest = 1 [ set D [D1] of patch-xy - ([D0] of patch-xy + [D2] of patch-xy + [D3] of patch-xy) ]
  if dest = 2 [ set D [D2] of patch-xy - ([D0] of patch-xy + [D1] of patch-xy + [D3] of patch-xy) ]
  if dest = 3 [ set D [D3] of patch-xy - ([D0] of patch-xy + [D1] of patch-xy + [D2] of patch-xy) ]

  ;; P = (1 - n) * exp(Kd * D) * exp(Ks * S) / exp(Kr * R)
  report ((1 - n) * (exp (Kd * D)) * (exp (Ks * Sxy))) / (exp (Kr * ([R] of patch-xy)))
end

to-report get-n [patch-xy]
  ;; 1 if cell is blocked (wall/occupied/nobody), 0 if free
  if patch-xy = nobody [ report 1 ]
  if [is-wall] of patch-xy [ report 1 ]
  ifelse any? turtles-on patch-xy [ report 1 ] [ report 0 ]
end

to-report calculate-segregation-index
  ;; Dominance of strongest D field per active patch
  ;; 0.25 = uniform (no lanes), 1.0 = perfect lane separation
  let active patches with [not is-wall and (D0 + D1 + D2 + D3) > 0.01]
  ifelse any? active [
    let total-dom sum [
      ifelse-value ((D0 + D1 + D2 + D3) > 0)
        [(max (list D0 D1 D2 D3)) / (D0 + D1 + D2 + D3)]
        [0.25]
    ] of active
    report total-dom / (count active)
  ][
    report 0.25
  ]
end

;; Fraction of ticks where this turtle actually moved (true effective speed)
to-report effective-speed
  ifelse ticks > 0 [ report move-count / ticks ] [ report 0 ]
end

;; Mean journey time across all completed exits this run
to-report mean-exit-time
  ifelse exit-count-for-time > 0
    [ report total-exit-time / exit-count-for-time ]
    [ report 0 ]
end
@#$#@#$#@
GRAPHICS-WINDOW
420
10
920
510
-1
-1
12.0
1
10
1
1
1
0
0
0
0
0
40
0
40
0
0
1
ticks
30.0

SLIDER
10
10
200
43
roundabout-radius
roundabout-radius
2
12
6.0
1
1
NIL
HORIZONTAL

SLIDER
205
10
400
43
num-pedestrians
num-pedestrians
4
500
120.0
4
1
NIL
HORIZONTAL

SLIDER
10
48
200
81
lane-width
lane-width
2
12
8.0
1
1
NIL
HORIZONTAL

SLIDER
205
48
400
81
corridor-half-width
corridor-half-width
2
10
6.0
1
1
NIL
HORIZONTAL

SLIDER
10
86
200
119
diffusion
diffusion
0
1
0.11
0.01
1
NIL
HORIZONTAL

SLIDER
205
86
400
119
decay
decay
0
1
0.15
0.01
1
NIL
HORIZONTAL

INPUTBOX
10
127
75
187
Ks
1.0
1
0
Number

INPUTBOX
80
127
145
187
Kd
2.0
1
0
Number

INPUTBOX
150
127
215
187
Kr
1.0
1
0
Number

CHOOSER
225
127
400
172
show-field
show-field
"static" "dynamic" "repulsion" "none"
3

BUTTON
10
195
90
228
NIL
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
95
195
175
228
step
go
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
180
195
270
228
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
10
240
200
390
Lane Segregation
ticks
phi
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"phi" 1.0 0 -2674135 true "" "plot phi"

PLOT
210
240
400
390
Throughput
ticks
exits/tick
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"rate" 1.0 0 -13345367 true "" "plot throughput-per-tick"

MONITOR
10
395
110
440
phi-max
phi-max
3
1
11

MONITOR
115
395
225
440
total exits
throughput-total
0
1
11

MONITOR
230
395
350
440
exits/tick
throughput-per-tick
0
1
11

@#$#@#$#@
## CHE COS'E'

Simulazione della dinamica pedonale in una **rotonda a 4 bracci** basata sul Floor Field Model (automi cellulari). Estensione del modello corridoio bidirezionale.

Quattro flussi di pedoni (Ovest, Est, Nord, Sud) attraversano un ambiente con un'isola centrale circolare che forza il flusso tangenziale, prevenendo lo scontro frontale diretto.

**Riferimento:** Burstedde, Klauck, Schadschneider, Zittartz (2001) — *Simulation of pedestrian dynamics using a 2D cellular automaton*, Physica A 295, 507-525.

## COME FUNZIONA

Ogni pedone sceglie la prossima cella in base a tre campi sovrapposti:

- **Campo Statico (S0-S3):** calcolato via BFS da ogni uscita. Alto vicino all'uscita target. Guida il pedone verso la destinazione.
- **Campo Dinamico (D0-D3):** tracce "feromone" lasciate dai pedoni in movimento. Diffondono e decadono. Causa la **Lane Formation**: i pedoni seguono le tracce di chi va nella stessa direzione.
- **Campo Repulsivo (R):** repulsione da altri pedoni. Previene collisioni.

**Formula di transizione:**
```
P(cella) = (1 - n) * exp(Kd * D) * exp(Ks * S) / exp(Kr * R)
```
dove `n=1` se la cella e' occupata/muro, `0` altrimenti.

I pedoni che raggiungono l'uscita vengono "riciclati" all'ingresso opposto (flusso continuo).

## COME USARLO

**Geometria:**
- `roundabout-radius`: raggio dell'isola centrale
- `lane-width`: larghezza dell'anello stradale
- `corridor-half-width`: meta' della larghezza di ogni braccio

**Popolazione:**
- `num-pedestrians`: numero totale (diviso equamente tra 4 direzioni)

**Campi:**
- `Ks`: peso del campo statico (attrazione verso uscita)
- `Kd`: peso del campo dinamico (effetto lane formation)
- `Kr`: peso del campo repulsivo (evitamento collisioni)
- `diffusion`: frazione di D diffusa ai vicini ogni tick
- `decay`: frazione di D che decade ogni tick

**Visualizzazione (show-field):**
- `static`: mappa a 4 colori della regione di attrazione di ogni uscita
- `dynamic`: tracce feromone colorate per direzione
- `repulsion`: densita' locale (scuro = affollato)
- `none`: nessun campo, solo pedoni

## COSE DA OSSERVARE

1. **Lane Formation nell'anello:** i pedoni si auto-organizzano in corsie tangenziali. Il grafico "Lane Segregation" mostra quanto sono separati i flussi (0.25=caos, 1.0=corsie perfette).

2. **Effetto della rotonda:** l'isola centrale impedisce lo scontro frontale che causa gridlock negli incroci semplici. I flussi perpendicolari si trasformano in flussi tangenziali.

3. **Throughput:** il grafico mostra quanti pedoni raggiungono l'uscita per tick. Un throughput costante indica flusso stabile.

4. **Congestione:** con troppi pedoni, il throughput cala e phi crolla verso 0.25 (i flussi si mescolano).

## COSE DA PROVARE

- Aumentare `num-pedestrians` gradualmente e osservare la transizione ordine-disordine
- `Kd = 0`: nessun campo dinamico, nessuna lane formation
- `Kd` alto (3-5): lane formation molto forte
- `roundabout-radius` piccolo: collo di bottiglia nell'anello
- `roundabout-radius` grande: piu' spazio, flusso piu' fluido
- Confrontare `diffusion = 0` (tracce non si diffondono) vs `diffusion = 0.3`

## ESTENSIONI

- Aggiungere ostacoli nell'anello (semafori, strisce pedonali)
- Flussi non bilanciati (piu' pedoni in una direzione)
- Velocita' variabile per genere (probabilita' di muoversi per tick)
- Confronto con incrocio senza rotonda (stessa geometria senza isola)
- BehaviorSpace per sweep parametrico automatico

## RIFERIMENTI

- Burstedde et al. (2001) — Floor Field Model originale
- Helbing & Molnar (1995) — Social Force Model (confronto)
- Kirchner & Schadschneider (2002) — Estensioni bioniche del CA
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
NetLogo 7.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments><experiment name="Exp4_RepulsionImpact" repetitions="5" runMetricsEveryStep="false"><setup>setup</setup><go>go</go><timeLimit steps="1000" /><metric>mean [effective-speed] of turtles</metric><metric>mean-exit-time</metric><metric>throughput-per-tick</metric><enumeratedValueSet variable="num-pedestrians"><value value="160" /></enumeratedValueSet><enumeratedValueSet variable="Kd"><value value="2.0" /></enumeratedValueSet><enumeratedValueSet variable="Ks"><value value="1.0" /></enumeratedValueSet><enumeratedValueSet variable="Kr"><value value="0.5" /><value value="1.0" /><value value="2.0" /><value value="5.0" /></enumeratedValueSet><enumeratedValueSet variable="roundabout-radius"><value value="10" /></enumeratedValueSet></experiment></experiments>
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
