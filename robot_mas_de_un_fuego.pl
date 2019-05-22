:-[firerobot].

/* Predicates that this particular agent will use */
:-dynamic fact/1.
:-dynamic fire/1.
:-dynamic obstacles/1.
:-dynamic world_size/1.

/* Usually, we want all of them clean before starting... */
things_to_vanish([(fact,1),(fire,1),(obstacles,1),(world_size,1)]).

/* Facts that we want to be true before starting... */
initial_facts([at_start]).

/* This is the list of action that will be executed sequentially at the beginning of each cycle, even before than the test
   of the conditions in the LHS, so if these actions change the conditions, rule firing will be altered accordingly. 
   The actions must be prolog predicates to be invoked without arguments. */
starting_actions([read_sensors]).

/* Now, two things you must know:

   When the rule interpreter starts, the fact 'fact(at_start)' exists in the database so the condition
   at_start will succeed.
   Use it to set things up in one rule (the first to be applied) and then, erase it if you want (you SHOULD want...).

   Also, don't forget to add to the RHS of at least one rule the action insert(at_end) to
   let the robot (and the program) stop. Otherwise, your program will run forever... 
*/

rule stop:
  [1: at_end]
  ==>
  [do([stop])].

rule suicide:
  [1: sensor(batt,dead)]
  ==>
  [insert(at_end)].

rule init:
  [1: at_start]
  ==>
  [eliminate(1),
   true_as_is(world_size(10)),
   true_as_is(obstacles([[2,3],[7,8],[6,3]])),
   insert(no_fire)
  ].

/* REGLAS DE COMPORTAMIENTO */
%% Base
%% Si acabamos de recargar salimos del estado lowbattery y salimos de la base
rule exit_base_low:
  [1: lowbattery,
   2: sensor(cell, base)]
  ==>
  [eliminate(1)].
%% Salimos de la base al empezar
rule exit_base:
  [1: sensor(cell, base)]
  ==>
  [do([fwd])].

%% Lowbattery
%% Nos movemos hacia delante si estamos en una fila o columna de celdas negras
rule go_forward_black_batt:
  [1: lowbattery,
   2: sensor(light, dark),
   3: sensor(prox, false)]
  ==>
  [do([fwd])].
%% Nos damos la vuelta si la base esta detras nuestra
rule turn_black_batt:
  [1: lowbattery,
   2: sensor(prox, true),
   3: sensor(cell, black),
   4: sensor(light, dark)]
  ==>
  [do([turnR, turnR])].
%% Al entrar en una celda negra, nos giramos para seguir la fila de celdas negras
rule turn_towards_base_batt:
  [1: lowbattery,
   2: sensor(cell, black),
   3: sensor(light, normal)]
  ==>
  [do([turnR])].
%% Si nos encontramos una pared mientras estamos buscando la base nos damos la vuelta
rule dodge_wall_batt:
  [1: lowbattery,
   2: sensor(prox, true),
   3: sensor(light, dark)]
  ==>
  [do([turnL, turnL])].
%% Si s encontramos un obstaculo giramos
rule turn_batt:
  [1: lowbattery,
   2: sensor(prox, true)]
  ==>
  [do([turnR])].
%% Si aun no estamos en una celda negra o un obstaculo vamos hacia delante
rule go_forward_batt:
  [1: lowbattery,
   2: sensor(prox, false),
   3: sensor(light, normal)]
  ==>
  [do([fwd])].
%% Apagamos el fuego si nos lo encontramos delante
rule put_out_batt:
  [1: lowbattery,
   2: sensor(light, bright)]
  ==>
  [do([put-out])].

%% Insert low battery
%% Si la bateria esta en low pasamos al estado lowbattery
rule low_batt:
  [1: sensor(batt, low)]
  ==>
  [insert(lowbattery)].
%% Si la bateria esta en medium y tenemos una celda negra delante pasamos al estado lowbattery
rule medium_batt:
  [1: sensor(batt, medium),
   2: sensor(light, dark),
   3: sensor(prox, false)]
  ==>
  [insert(lowbattery)].

%% Search fire
%% Apagamos el fuego si lo tenemos delante y pasamos al estado lowbattery
rule put_out_fire: 
  [1: sensor(light, bright)]
  ==>
  [do([put-out]),
   insert(lowbattery)].
%% Si estamos en la misma fila o columna que el fuego nos giramos
%% Hemos puesto esta regla arriba para que se aplique cuando solo hay fuegos en la misma columna o la misma
%% fila que el robot, para que pueda encontrar hacia que direccion se tiene que mover
rule turn_fire:
  [1: sensor(temp, equal)]
  ==>
  [do([turnR])].
%% Nos movemos hacia delante si el fuego esta hacia delante y no hay obstaculos
rule go_forward_fire:
  [1: sensor(temp, up),
   2: sensor(prox, false)]
  ==>
  [do([fwd])].
%% Si el fuego esta detras nuestra nos damos la vuelta
%% Hemos puesto esta regla arriba porque si teniamos dos fuegos y estamos en la misma columna que un fuego
%% y el otro esta detras del robot, el robot daba la vuelta y entraba en un ciclo porque siempre tenia el 
%% fuego detras
rule turn_back_fire:
  [1: sensor(temp, down)]
  ==>
  [do([turnR])].
%% Esquivamos un obstaculo rodeandolo
rule dodge_fire:
  [1: sensor(prox, true),
   2: sensor(light, normal)]
  ==>
  [do([turnL, fwd, turnR])].