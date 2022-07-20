;;
;; Extensiones Netlogo
;;
extensions [array]   ; Para manejo de arregos

;;
;; Variables globales
;;
globals [
  q-size-objeto
  q-size-drone
  id-primer-drone ;
  q-size-torre-control
  q-visibles                 ; Cantidad de turtles totales (drones + objetos NO nocivos + objetos nocivos)
  k-lejania-borde
  k-lejanía-torre-control
  b-primer-paso-simulacion
  k-perimetro-radar          ; el radio
  x-initial-position-drone
  y-initial-position-drone
]

;;
;; Propiedades para los turtles
;;
turtles-own [
  tipo               ; torre-control, objeto o drone
  subtipo            ; solo para tipo objeto: NO-nocivo o nocivo
  id-origen          ; solo para tipo drone, contiene el id del último objeto asignado en la ruta (origen)
  id-destino         ; solo para tipo drone, contiene el id del último objeto asignado en la ruta (destino)
  id-drone-asignado  ; solo para tipo objeto, contiene el id del drone asignado
  estado             ; Para tipo drone y objeto
  distancia          ; solo para tipo objetos
  distancia-recorrida ; solo para tipo drone
  b-en-perimetro-radar ; solo para tipo objeto
]

;;
;; Propiedades para los links
;;
links-own [
  id-origen-link
  id-destino-link
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;; SIMULACIÓN
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;
;; GO !!!
;;
to go
  main-simulation
  tick
end

;;
;; 1 tick on-demmand
;;
to go-1-tick
  go
end

;;
;; Simulación
;;
to main-simulation
  ; movimiento de los objetos
  ask turtles with [tipo = "object" and estado = "non-inspected"][
    forward 0.4

    ; determinar si está en el perimetro del radar
    ifelse (F-dentro-del-perimetro xcor ycor)[
      set b-en-perimetro-radar true
      set color black
    ]
    [
      set b-en-perimetro-radar false
      set color gray
    ]

    ; determinar si llegó a los bordes para hacerlo rebotar
    ; superior
    if (ycor > max-pycor - k-lejania-borde)[
        set heading (random 180) + 90
    ]
    ; inferior
    if (ycor * -1 > max-pycor - k-lejania-borde)[
      ifelse (random(100) < 50)[
        set heading (random 90)
      ]
      [
        set heading (random 90) + 270
      ]
    ]
    ; derecha
    if (xcor > max-pxcor - k-lejania-borde)[
        set heading (random 180) + 180
    ]
    ; izquierda
    if (xcor * -1 > max-pxcor - k-lejania-borde)[
        set heading (random 180)
    ]
  ]

  ; movimiento de los objetos referenciales
  ask turtles with [tipo = "object" and estado = "inspected-referential"][
    forward 0.4
  ]

  ; recorremos los drones en ruta para que avancen a su objetivo
  let b-actualiza-estadisticas false
  ;ask turtles with [tipo = "drone" and subtipo = "inspector" and estado = "en-ruta"][
  ask turtles with [tipo = "drone" and subtipo = "inspector"][
    if estado = "en-ruta" [
      set distancia-recorrida distancia-recorrida + 1
      set b-actualiza-estadisticas true
    ]
    pendown
    set pen-size 3.5
    forward 1
    let tmp-xcor-drone xcor
    let tmp-ycor-drone ycor
    let tmp-id-drone who
    let tmp-id-origen id-origen
    let tmp-id-destino id-destino
    let tmp-color color
    let b-aterrizar false
    let tmp-estado "en-ruta"
    let b-ajustar-heading false
    let tmp-heading -1
    let tmp-xcor-destino -1
    let tmp-ycor-destino -1
    ask turtle id-destino [
      set tmp-xcor-destino xcor
      set tmp-ycor-destino ycor
      ifelse (F-rango round(tmp-xcor-drone) round(tmp-ycor-drone) xcor ycor 2)[  ; Drone llegó al objeto ?
        ; si el drone llega a su punto origen, lo aterrizamos
        ifelse (tmp-id-drone - q-drones = tmp-id-destino) [ ; regresó a la torre de control ?
          set b-aterrizar true
          set tmp-estado "ruta-finalizada"
          set tmp-xcor-drone xcor
          set tmp-ycor-drone ycor

          ; Borrar link del objeto anterior al drone
          ;F-elimina-link tmp-id-origen tmp-id-drone

          ; crear link del objeto actual al drone
          ;F-crea-link tmp-id-origen tmp-id-drone tmp-color 1.5

          ; aterrizarlo mirando al norte
          ask turtles with [who = tmp-id-drone][
            set heading 0 ; Finaliza mirando al norte
          ]
        ]
        [ ; else, implica que encontró un objeto
          ;
          ; Inspeccionarlo para determinar nivel de nocividad
          ;
          set estado "inspected"

          ; determinar nocividad en base a una probabilidad
          ifelse (random(100) <= probabilidad-nocividad) [
            set subtipo "nocive"
            set color red
            F-dibuja-circulo xcor ycor q-size-drone / 2 color 1.5 true ; lo marcamos con un cículo rojo
          ]
          [
            set subtipo "non-nocive"
            set color green - 1
            set size q-size-drone / 3
            F-dibuja-circulo xcor ycor q-size-drone / 3 color 1 true ; lo marcamos con un cículo rojo
          ]
          let tmp-subtipo subtipo

          ;
          ; Ajustar links
          ;

          ; Crear link desde el objeto anterior al actual
          ;F-crea-link tmp-id-origen tmp-id-destino tmp-color 1.5

          ; Borrar link del objeto anterior al drone
          ;F-elimina-link tmp-id-origen tmp-id-drone

          ; crear link del objeto actual al drone
          ;F-crea-link tmp-id-destino tmp-id-drone tmp-color 0.4

          ; el destino inspeccionado ahora pasa a ser el origen
          ask turtles with [who = tmp-id-drone][
            set id-origen tmp-id-destino
          ]

          ;
          ; hablitar objeto referencial asociado que continue el movimiento
          ;
          if (tmp-subtipo = "nocive")[
            let tmp-heading-al-inspeccionar heading
            ask turtle (who + q-objetos) [
              set estado "inspected-referential"
              set xcor tmp-xcor-destino
              set ycor tmp-ycor-destino
              set heading tmp-heading-al-inspeccionar
              set shape "boat 3"
              ifelse tmp-subtipo = "nocive" [
                set color red
              ]
              [
                set color grey + 1
              ]
              show-turtle
            ]

            ; crear link entre el objeto inspeccionado y su referencial
            ifelse (subtipo = "nocive")[
              F-crea-link tmp-id-destino tmp-id-destino + q-objetos red + 1 0.1 "discontinuo"
            ]
            [
              F-crea-link tmp-id-destino tmp-id-destino + q-objetos grey + 1 0.1 "discontinuo"
            ]
          ]
        ]
      ]
      [ ; como no ha llegado el drone a destino, ajustamos precisión en su dirección
        set b-ajustar-heading true
        set tmp-heading F-direction tmp-xcor-drone tmp-ycor-drone tmp-xcor-destino tmp-ycor-destino
      ]
      ;
      ; buscar nuevo objetivo, ajustar rutas y calibrar direcciones
      ;
      F-asigna-mas-cercano-OBJ
    ]
    if (b-aterrizar)[
      set estado tmp-estado
      set xcor tmp-xcor-drone
      set ycor tmp-ycor-drone
    ]
    if (b-ajustar-heading)[
      set estado tmp-estado
      set heading tmp-heading
    ]
  ]
  ; actualiza estadísticas
  if (b-actualiza-estadisticas)[
    let tmp-distancia-recorrida-total 0
    ask turtles with [tipo = "drone" and subtipo = "inspector"][
      set tmp-distancia-recorrida-total tmp-distancia-recorrida-total + distancia-recorrida
    ]
    set distancia-recorrida-total tmp-distancia-recorrida-total
    set promedio precision (distancia-recorrida-total / q-drones) 1
    set desviacion-estandar precision (standard-deviation [distancia-recorrida] of turtles with [tipo = "drone" and subtipo = "inspector"]) 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;; CONFIGURACIÓN INICIAL
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-all
  setup_globals
  setup_turtles
  setup_drones_to_objetos
  reset-ticks
end

;;
;; Configuracion de variables iniciales
;;
to setup_globals
  ; comportamiento
  set q-size-objeto 11
  set q-size-drone 10
  set q-size-torre-control 20
  set id-primer-drone 1 + q-objetos * 2 + q-drones
  show id-primer-drone
  set k-lejania-borde 5
  set k-lejanía-torre-control 35
  set b-primer-paso-simulacion false
  set k-perimetro-radar max-pxcor - k-lejania-borde * 2

  ; posición inicial de drones
  ; abscisa (x) posición inicial drones
  set x-initial-position-drone array:from-list n-values 5 [0]
  array:set x-initial-position-drone 0 -8
  array:set x-initial-position-drone 1 8
  array:set x-initial-position-drone 2 -6
  array:set x-initial-position-drone 3 6
  array:set x-initial-position-drone 4 0
  ; ordenada (y) posición inicial drones
  set y-initial-position-drone array:from-list n-values 5 [0]
  array:set y-initial-position-drone 0 q-size-drone * -1.5
  array:set y-initial-position-drone 1 q-size-drone * -1.5
  array:set y-initial-position-drone 2 q-size-drone * 1.6
  array:set y-initial-position-drone 3 q-size-drone * 1.6
  array:set y-initial-position-drone 4 q-size-drone * -2.5

  ; mundo
  ask patches [set pcolor white - 3]
  ;ask patches [set pcolor 86]

  ; Cantidades de objetos
  ;set q-objetos-nocivos round(q-objetos-NO-nocivos * porc-objetos-nocivos / 100)
  ;set q-objetos q-objetos-NO-nocivos + q-objetos-nocivos
  set q-visibles 1 + q-drones + q-objetos
end

;;
;; Configuración de turtles
;;
to setup_turtles
  ;; Torre de control
  create-turtles 1 [
    set tipo "torre-control"
    set subtipo ""
    setxy 0 0
    set color gray - 3
    set size q-size-torre-control
    set shape "torre-control"
  ]

  ;; Objetos
  let rec 0
  create-turtles q-objetos [
    set tipo "object"
    set subtipo ""
    set id-drone-asignado -1
    set size q-size-objeto
    move-to one-of patches
    ; Ubicarlo en posición permitida
    while [not F-coordenada-permitida xcor ycor][
      ;set xcor random max-pxcor * 2 - max-pxcor
      ;set ycor random max-pycor * 2 - max-pycor
      move-to one-of patches
    ]
    set estado "non-inspected"
    set distancia max-pxcor * 4 ; distancia grande para que entre la primera vez
    set shape "boat 3"
    ; determinar si está en el perimetro del radar
    ifelse (F-dentro-del-perimetro xcor ycor)[
      set b-en-perimetro-radar true
      set color black
    ]
    [
      set b-en-perimetro-radar false
      set color gray
    ]
    set rec rec + 1
  ]

  ;; Objetos referenciales
  set rec 0
  create-turtles q-objetos [
    set tipo "object"
    set subtipo "referential"
    set size q-size-objeto / 2
    set estado "non-inspected-referential"
    set shape "boat 3"
    hide-turtle
  ]

  ; crear drones de marca inicial
  let q-old-turtles count turtles + 1
  create-turtles q-drones [
    set tipo "drone"
    set subtipo "initial"
    set color gray + 1
    set size q-size-drone
    ;set xcor q-drones / -2 * q-size-drone + (who + 1 - q-old-turtles + 0.5) * q-size-drone
    ;set ycor q-size-drone * -1.5
    set xcor array:item x-initial-position-drone (who - q-objetos * 2 - 1)
    set ycor array:item y-initial-position-drone (who - q-objetos * 2 - 1)

    set heading 0 ; comienza mirando al norte
    set shape "drone4"
  ]

  ;; Drones oficiales
  create-turtles q-drones [
    set tipo "drone"
    set subtipo "inspector"
    set color F-color-ruta (who + 1 - q-old-turtles - q-drones)
    set size q-size-drone
    ;set xcor q-drones / -2 * q-size-drone + (who + 1 - q-old-turtles - q-drones + 0.5) * q-size-drone * 3
    ;set ycor q-size-drone * -1.5
    let tmp-xcor -1
    let tmp-ycor -1
    ask turtle (who - q-drones)[
      set tmp-xcor xcor
      set tmp-ycor ycor
    ]
    set xcor tmp-xcor
    set ycor tmp-ycor
    set shape "drone4"

    ; primera asignación
    set id-origen (who - q-drones) ; El initial correspondiente a cada drone, el destino se determinará por distancia
    set estado "en-ruta"
    set heading 0 ; comienza mirando al norte
    set distancia-recorrida 0
    ; crea link de comunicaciones
    F-crea-link who 0 gray + 3 0.2 "discontinuo"
  ]

  ;; Para dibujos
  create-turtles 1 [
    set tipo "dibujo"
    set subtipo ""
    ;hide-turtle
  ]

  ; dibujar perímetro de la torre de control
  ;F-dibuja-circulo 0 0 k-lejanía-torre-control - 2 gray - 1 1 false

  ; dibuja buque
  F-dibuja-buque

  ; dibujar perímetro del radar
  F-dibuja-circulo 0 0 k-perimetro-radar - 2 black 1 false
end

;;
;; Asignar drones a objetos - planificación de rutas (el más cerca primero)
;;
to setup_drones_to_objetos
  ; primer link entre inspector e initial
;  ask turtles with [tipo = "drone" and subtipo = "inspector"][
;    F-crea-link id-origen who color 1
;  ]

  ; asignar el drone más cercano a cada objeto
  F-asigna-mas-cercano-OBJ

  ; inician mirando al norte
  ask turtles with [tipo = "drone" and subtipo = "inspector"][
      set heading 0 ; comienza mirando al norte
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;;  FUNCIONES
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;
;; Asigna objeto más cercano
;;
to F-asigna-mas-cercano-OBJ
  ; para cada objeto determinamos cual es el dron más cercano
  ask turtles with [tipo = "object" and estado = "non-inspected" and b-en-perimetro-radar][
    let tmp-xcor-objeto xcor
    let tmp-ycor-objeto ycor
    let b-entro false
    let distancia-menor max-pxcor * 4 ; distancia grande para que entre la primera vez
    let tmp-id-drone-a-asignar -1
    ; recorremos los drones para determinar el más cercano
    ask turtles with [tipo = "drone" and subtipo = "inspector"][
      let distancia-objeto-a-drone F-distancia-2coordenadas tmp-xcor-objeto tmp-ycor-objeto xcor ycor ; obtenemos la distancia efectiva entre el objeto y cada drone
      if distancia-objeto-a-drone < distancia-menor [
        set distancia-menor distancia-objeto-a-drone
        set tmp-id-drone-a-asignar who
        set b-entro true
      ]
    ]
    if (b-entro)[
      ; asignamos al objeto el drone
      set id-drone-asignado tmp-id-drone-a-asignar
      set distancia distancia-menor
      ;set label (word who " dr: " id-drone-asignado)
    ]
  ]

  ; ahora para cada drone determinamos cual es el objeto más cercano
  ask turtles with [tipo = "drone" and subtipo = "inspector"][
    let tmp-id-drone who
    let b-entro false
    let distancia-menor max-pxcor * 4 ; distancia grande para que entre la primera vez
    let tmp-id-objeto-a-asignar -1
    ask turtles with [tipo = "object" and estado = "non-inspected" and b-en-perimetro-radar and id-drone-asignado = tmp-id-drone][
      if distancia < distancia-menor [
        set distancia-menor distancia
        set tmp-id-objeto-a-asignar who
        set b-entro true
      ]
    ]
    ifelse (b-entro)[
      ; asignamos al drone el objeto
      set id-destino tmp-id-objeto-a-asignar
      ;set label (word who " ob: " id-destino)
      let tmp-xcor-destino -1
      let tmp-ycor-destino -1
      ask turtles with [who = tmp-id-objeto-a-asignar][ ; todo: no funciona con id-destino (revisar porque)
        set tmp-xcor-destino xcor
        set tmp-ycor-destino ycor
      ]

      ; asignamos el ánuglo de recorrido (desde el eje y (norte) hacia la izquierda (este)
      set heading F-direction xcor ycor tmp-xcor-destino tmp-ycor-destino
    ]
    [
      ; Como no tiene más objetos, lo hacemos volver a la torre de control
      set tmp-id-objeto-a-asignar who - q-drones
      ; asignamos al drone el objeto
      set id-destino tmp-id-objeto-a-asignar
      let tmp-xcor-destino -1
      let tmp-ycor-destino -1
      ask turtles with [who = tmp-id-objeto-a-asignar][ ; todo: no funciona con id-destino (revisar porque)
        set tmp-xcor-destino xcor
        set tmp-ycor-destino ycor
      ]

      ; asignamos el ánuglo de recorrido (desde el eje y (norte) hacia la izquierda (este)
      set heading F-direction xcor ycor tmp-xcor-destino tmp-ycor-destino
    ]
  ]
end

;;
;; Calcula la dirección en que se debe dirigir un drone
;;
to-report F-direction [x1 y1 x2 y2]
  let dir-direction -1
  ; exceciones para calcular la dirección en casos en que y1 = y2 o x2 = x1
  ifelse (x1 = x2)[
    ifelse (y1 < y2)[
      set dir-direction 0
    ]
    [
      set dir-direction 180
    ]
  ]
  [
    ifelse (y1 = y2)[
      ifelse (x1 < x2)[
        set dir-direction 90
      ]
      [
        set dir-direction 270
      ]
    ]
    [
      ; saltadas las excepciones calculamos basado en arcotangente.  Para Netlogo los ángulos comienzan desde el norte hacia el este
      set dir-direction atan (x2 - x1) (y2 - y1)
    ]
  ]
  report dir-direction
end

;;
;; Función para establecer color de ruta para cada drone
;;
to-report F-color-ruta [rec-drone]
  let tmp-color-ruta random 140
  ifelse rec-drone = 0 [
    set tmp-color-ruta 26 ; naranjo
  ]
  [
    ifelse rec-drone = 1 [
      set tmp-color-ruta yellow
    ]
    [
      ifelse rec-drone = 2 [
        set tmp-color-ruta violet
      ]
      [
        ifelse rec-drone = 3 [
          set tmp-color-ruta green
        ]
        [
          if rec-drone = 4 [
            set tmp-color-ruta blue
          ]
        ]
      ]
    ]
  ]
  report tmp-color-ruta
end

;;
;; Devuelve true si la posición es permitida sino false
;;
to-report F-coordenada-permitida [x y]
  let coordenada-permitida true
  ; abscisas (x) no permitidas cerca del borde
  if (x > max-pxcor - k-lejania-borde or x < max-pxcor * -1 + k-lejania-borde)[
    set coordenada-permitida false
  ]
  ; ordenadas (y) no permitidas cerca del borde
  if (y > max-pycor - k-lejania-borde or y < max-pycor * -1 + k-lejania-borde)[
    set coordenada-permitida false
  ]
  ; coordenadas no permitidas cerca del perímetro del la torre de control
  if (x >= 0 and x < k-lejanía-torre-control and y >= 0 and y < k-lejanía-torre-control) or (x >= 0 and x < k-lejanía-torre-control and y <= 0 and y > k-lejanía-torre-control * -1) or (x <= 0 and x > k-lejanía-torre-control * -1 and y >= 0 and y < k-lejanía-torre-control) or (x <= 0 and x > k-lejanía-torre-control * -1 and y <= 0 and y > k-lejanía-torre-control * -1)[
    set coordenada-permitida false
  ]
  report coordenada-permitida
end

;;
;; Dibuja un círculo
;;
to F-dibuja-circulo [x y radio color-perimetro size-perimetro linea-continua]
;  create-turtles 1 [
;    set tipo "tmp"
;    set xcor x + radio
;    set ycor y
;    set heading 0
;  ]
  ask turtles with [tipo = "dibujo"][
    let n-discontinuo 3
    penup
    set xcor x + radio
    set ycor y
    set heading 0
    pendown
    set color color-perimetro
    set pen-size size-perimetro
    let i 0
    let switch-pen true
    repeat 360 [
      if (not linea-continua)[
        if (int(i / n-discontinuo) = i / n-discontinuo)[
          set switch-pen not switch-pen
          ifelse (switch-pen)[
            penup
          ]
          [
            pendown
          ]
        ]
      ]
      forward 0.175 * radio / 10
      left 1
      set i i + 1
    ]
  ]
  ask turtles with[tipo = "tmp"][
    die
  ]
end

to F-dibuja-buque
  ask turtles with [tipo = "dibujo"][
    set color black
    penup

;    set xcor 0
;    set ycor 35
;    pendown
;    set heading 90
;    forward 10
;    penup


    set xcor -7
    set ycor -35
    set pen-size 2
    pendown
    set heading 90
    forward 14
    penup

    set xcor 0
    set ycor 35
    pendown
    set heading 135
    repeat 81 [
      forward 0.95
      right 1
    ]
    penup

    set xcor 0
    set ycor 35
    pendown
    set heading 225
    repeat 80 [
      forward 0.95
      left 1
    ]
    penup

    ;pendown
    ;forward 15
  ]
end

;;
;; Creación de links
;;
to F-crea-link [lnk-id-origen lnk-id-destino lnk-color lnk-thinkness lnk-shape]
  ask turtle lnk-id-origen [
    create-link-with turtle lnk-id-destino [
      set id-origen-link lnk-id-origen
      set id-destino-link lnk-id-destino
      set color lnk-color
      set thickness lnk-thinkness
      set shape lnk-shape
    ]
  ]
end

;;
;; Eliminación de links
;;
to F-elimina-link [lnk-id-origen lnk-id-destino]
  ask links with [id-origen-link = lnk-id-origen and id-destino-link = lnk-id-destino][
    die
  ]
end

;;
;; Función distancia entre 2 puntos
;;
to-report F-distancia-2coordenadas [x1 y1 x2 y2]
  ;show (word x1 " " y1 " " x2 " " y2)
  report sqrt(((x2 - x1) ^ 2) + ((y2 - y1) ^ 2))
end
;;
;; evalaur siun dron está cerca de un objeto
;;
to-report F-rango [x-drone y-drone x-obj y-obj rango]
  report (x-obj >= x-drone - rango and x-obj <= x-drone + rango) and (y-obj >= y-drone - rango and y-obj <= y-drone + rango)
end

;;
;; Determinar si un obejto está dentro del perímetro del radar
;;
to-report F-dentro-del-perimetro [x y]
  let b-report false
  if (F-distancia-2coordenadas x y 0 0 <= k-perimetro-radar)[
    set b-report true
  ]
  report b-report
end
@#$#@#$#@
GRAPHICS-WINDOW
226
11
1005
791
-1
-1
3.0
1
15
1
1
1
0
0
0
1
-128
128
-128
128
1
1
1
ticks
30.0

BUTTON
13
17
77
50
NIL
Setup
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
81
17
145
50
NIL
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

BUTTON
149
17
213
50
1 tick
go-1-tick
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
14
63
212
96
q-drones
q-drones
1
5
5.0
1
1
NIL
HORIZONTAL

SLIDER
14
102
211
135
q-objetos
q-objetos
5
200
50.0
1
1
NIL
HORIZONTAL

SLIDER
15
142
211
175
probabilidad-nocividad
probabilidad-nocividad
0
100
5.0
1
1
%
HORIZONTAL

PLOT
1018
12
1544
372
Metros Recorridos
Ticks
Metros
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"orange" 1.0 0 -955883 true "" "ask turtle id-primer-drone [plot distancia-recorrida]"
"yellow" 1.0 0 -1184463 true "" "ask turtle (id-primer-drone + 1) [plot distancia-recorrida]"
"violet" 1.0 0 -8630108 true "" "ask turtle (id-primer-drone + 2) [plot distancia-recorrida]"
"green" 1.0 0 -10899396 true "" "ask turtle (id-primer-drone + 3) [plot distancia-recorrida]"
"blue" 1.0 0 -13345367 true "" "ask turtle (id-primer-drone + 4) [plot distancia-recorrida]"

INPUTBOX
1019
376
1174
436
distancia-recorrida-total
2514.0
1
0
Number

INPUTBOX
1206
377
1362
437
promedio
502.8
1
0
Number

INPUTBOX
1388
377
1544
437
desviacion-estandar
155.3
1
0
Number

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

boat 3
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

box 1
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -13840069 false 150 285 150 135
Line -13840069 false 150 135 15 75
Line -13840069 false 150 135 285 75
Line -13840069 false 15 75 150 15
Line -13840069 false 150 15 285 75
Line -13840069 false 15 75 15 225
Line -13840069 false 15 225 150 285
Line -13840069 false 150 285 285 225
Line -13840069 false 285 75 285 225

box 2
false
0
Polygon -7500403 true true 150 285 270 225 270 90 150 150
Polygon -13791810 true false 150 150 30 90 150 30 270 90
Polygon -13345367 true false 30 90 30 225 150 285 150 150

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

drone
false
0
Circle -7500403 true true 13 13 92
Circle -16777216 true false 26 26 67
Circle -7500403 true true 193 13 92
Circle -16777216 true false 206 26 67
Circle -7500403 true true 13 193 92
Circle -7500403 true true 193 193 92
Circle -16777216 true false 206 206 67
Circle -16777216 true false 26 206 67
Rectangle -7500403 true true 120 75 180 225
Polygon -7500403 true true 90 210 120 195 120 210 105 225 90 210
Polygon -7500403 true true 210 210 180 195 180 210 195 225 210 210
Polygon -7500403 true true 210 90 180 105 180 90 195 75 210 90
Polygon -7500403 true true 90 90 120 105 120 90 105 75 90 90

drone 5
true
0
Circle -7500403 true true 0 0 148
Circle -16777216 true false 30 30 88
Circle -7500403 true true 148 -2 152
Circle -16777216 true false 180 30 88
Circle -7500403 true true 0 150 148
Circle -7500403 true true 148 148 152
Circle -16777216 true false 180 180 88
Circle -16777216 true false 30 180 88
Rectangle -7500403 true true 120 45 180 225
Rectangle -16777216 true false 135 135 165 195
Line -7500403 true 0 75 300 75
Line -7500403 true 75 0 75 270
Line -7500403 true 225 15 225 270
Line -7500403 true 15 225 270 225
Line -7500403 true 120 195 30 255
Line -7500403 true 45 195 105 255
Line -7500403 true 30 30 105 105
Line -7500403 true 45 105 105 45
Line -7500403 true 195 45 255 105
Line -7500403 true 180 105 270 45
Line -7500403 true 180 180 255 255
Line -7500403 true 195 255 255 195
Polygon -7500403 true true 120 45 150 0 180 45 120 45

drone 6
true
0
Circle -7500403 true true 0 15 148
Circle -16777216 true false 30 45 88
Circle -7500403 true true 148 13 152
Circle -16777216 true false 180 45 88
Circle -7500403 true true 0 150 148
Circle -7500403 true true 148 148 152
Circle -16777216 true false 180 180 88
Circle -16777216 true false 30 180 88
Rectangle -7500403 true true 120 45 180 225
Rectangle -16777216 true false 135 135 165 195
Line -7500403 true 0 90 300 90
Line -7500403 true 75 15 75 270
Line -7500403 true 225 15 225 270
Line -7500403 true 15 225 270 225
Line -7500403 true 120 195 30 255
Line -7500403 true 30 180 105 255
Line -7500403 true 30 45 105 120
Line -7500403 true 45 120 105 60
Line -7500403 true 180 45 255 120
Line -7500403 true 180 120 270 60
Line -7500403 true 180 180 255 255
Line -7500403 true 195 255 255 195
Polygon -7500403 true true 120 45 150 0 180 45 120 45

drone3
false
0
Circle -7500403 true true -2 -2 152
Circle -16777216 true false 41 41 67
Circle -7500403 true true 150 0 148
Circle -16777216 true false 191 41 67
Circle -7500403 true true 0 150 148
Circle -7500403 true true 150 150 148
Circle -16777216 true false 191 191 67
Circle -16777216 true false 41 191 67
Rectangle -7500403 true true 120 75 180 225
Rectangle -16777216 true false 135 120 165 195
Line -7500403 true 15 75 300 75
Line -7500403 true 75 15 75 285
Line -7500403 true 225 15 225 270
Line -7500403 true 30 225 270 225
Line -7500403 true 120 195 30 255
Line -7500403 true 45 195 105 255
Line -7500403 true 45 45 105 105
Line -7500403 true 45 105 105 45
Line -7500403 true 195 45 255 105
Line -7500403 true 195 105 255 45
Line -7500403 true 195 195 255 255
Line -7500403 true 195 255 255 195

drone4
true
0
Circle -7500403 true true -2 -2 152
Circle -16777216 true false 30 30 88
Circle -7500403 true true 150 0 148
Circle -16777216 true false 180 30 88
Circle -7500403 true true 0 150 148
Circle -7500403 true true 150 150 148
Circle -16777216 true false 180 180 88
Circle -16777216 true false 30 180 88
Rectangle -7500403 true true 120 75 180 225
Rectangle -16777216 true false 135 120 165 195
Line -7500403 true 15 75 300 75
Line -7500403 true 75 15 75 285
Line -7500403 true 225 15 225 270
Line -7500403 true 30 225 270 225
Line -7500403 true 120 195 30 255
Line -7500403 true 30 180 105 255
Line -7500403 true 30 30 105 105
Line -7500403 true 45 105 105 45
Line -7500403 true 180 30 255 105
Line -7500403 true 180 105 255 45
Line -7500403 true 180 180 255 255
Line -7500403 true 195 255 255 195
Rectangle -7500403 true true 135 150 180 180

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

hexagonal prism
false
0
Rectangle -7500403 true true 90 90 210 270
Polygon -1 true false 210 270 255 240 255 60 210 90
Polygon -13345367 true false 90 90 45 60 45 240 90 270
Polygon -11221820 true false 45 60 90 30 210 30 255 60 210 90 90 90

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

torre-control
false
0
Polygon -7500403 true true 150 45 240 270 225 285 150 45
Polygon -7500403 true true 150 45 60 270 75 285 150 45
Line -7500403 true 90 255 210 225
Line -7500403 true 105 195 210 225
Line -7500403 true 105 195 195 165
Line -7500403 true 120 135 195 165
Line -7500403 true 120 135 180 120
Line -7500403 true 135 90 180 120
Line -7500403 true 135 90 165 60
Polygon -7500403 true true 195 45 195 45 195 30 180 15 165 15 165 30 180 45 165 60 165 75 180 75 195 60 195 30
Polygon -7500403 true true 105 45 105 45 105 30 120 15 135 15 135 30 120 45 135 60 135 75 120 75 105 60 105 30
Polygon -7500403 true true 195 0 195 0 210 0 240 30 240 60 210 90 195 90 195 75 210 75 225 60 225 30 210 15 195 15 195 0
Polygon -7500403 true true 105 0 105 0 90 0 60 30 60 60 90 90 105 90 105 75 90 75 75 60 75 30 90 15 105 15 105 0

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
NetLogo 6.2.1
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

comunicacion
10.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

discontinuo
0.0
-0.2 1 4.0 4.0
0.0 1 4.0 4.0
0.2 1 4.0 4.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
