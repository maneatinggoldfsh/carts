--#include constants
--#include globals
--#include config

--#include oo
--#include v2
--#include bbox
--#include camera

--#include helpers
--#include tween
--#include coroutines
--#include queues
--#include gfx

--#include interactable

--#include actors
--#include button
--#include room
--#include smoke
--#include particle
--#include player
--#include spring
--#include spawn
--#include spikes
--#include teleporter
--#include power-up-dropper
--#include power-ups
--#include mine
--#include balloon
--#include bomb

--#include fireflies

-- x split into actors / particles / interactables
-- x gravity
-- x downward collision
-- x wall slide
-- x add wall slide smoko
-- x fall down faster
-- x wall jump
-- x variable jump time
-- x test controller input
-- x add ice
-- x springs
-- x wall sliding on ice
-- x player spawn points
-- x spikes
-- x respawn player after death
-- x add ease in for spawn point
-- x add coroutine for spawn point
-- x slippage when changing directions
-- x flip smoke correctly when wall sliding
-- x particles with sprites
-- x add gore particles and gored up tiles
-- x add gore on vertical surfaces
-- x make gore slippery
-- x add gore when dying
-- x vanishing platforms
-- x add second player
-- x add multiple players / spawn points
-- x add death mechanics
-- x add score
-- x camera shake
-- x doppelgangers
-- x remove typ code
-- x bullet time on kill

-- x invincibility
-- x blast mine
-- x superspeed
-- x superjump
-- x gravity tweak
-- x suicide bomber
-- x invisibility
-- x bomb
-- x miniature mode
-- x have players join when pressing action
-- x balloon pulling upwards

--[[
 SFX:
 00 jumping
01 killing sound
02 springboard
03 power up
04 explosion
]]


-- x fix collision bug
-- x 
-- number of player selector menu
-- title screen
-- game end screen (kills or timer)
-- x prettier score display
-- x pretty pass

-- x powerups - item dropper
-- x refactor powerups to have a decent api
-- x visualize power ups
-- x different sprites for different players

-- x multiple players
-- x random player spawns
-- x player collision
-- x player kill
-- x player colors

-- double jump
-- dash
-- meteors
-- flamethrower
-- bullet time
-- whip
-- jetpack
-- lasers
-- gun
-- rope
-- level design

-- go through right and come back left (?)

-- make player selection screen

-- moving platforms
-- laser beam
-- add water
-- add butterflies
-- add flies
-- lookup / lookdown sprites
-- add trailing smoke particles when springing up

-- fades
-- better kill animations
-- x restore ghosts / particles on player
-- x decrease score when dying on spikes
--#include main
