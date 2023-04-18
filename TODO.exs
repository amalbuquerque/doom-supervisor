"""
TODO NEXT
16. Stretch goal 2: Show text above each monster with the Actor.Tag (process PID)


DONE
1. parse elixirPosition into vector3
2. allow spawning monsters in specific position from Elixir
3. Kill monster by PID checks if it's alive first
4. Spawn and stop
5. Implement Monster GenServer that receives name
6. Implement custom registry delegating to Registry on register_name/2 and unregister_name/1, so we can know when a process spawns or dies (to send the action to the game)
  * Check https://levelup.gitconnected.com/genserver-dynamicsupervisor-and-registry-the-elixir-triad-to-manage-processes-a65d4c3351c1 for an example of how to use the Registry
7. DoomSupervisor.Registry logs message when register/unregister happens
8. Implement GameServer.spawn_supervised_monster(monster(), number(), pid()), depending on the number calculate its position in the game
9. Implement Supervisor
10. Killing a supervised process will send a NetEvent "kill monster with pid" message
  * Registry.unregister_name/1 wasn't being called, I had to make the GameServer monitor the processes being spawned under supervision, for us to receive the :DOWN message, and kill the corresponding monster
11. Killing a supervised monster will cause a process with that pid to be killed
12. Process.sleep/1 between process being killed and spawned again, to better show process dying and being respawned again
14. Start game inside window
17. Cleanup of bodies after a while
13. (Move ahead each respawned monster 50 steps in the Y axis - no need after corpses cleanup)
15. Stretch goal 1: Basic LiveView app with a single screen, that allows someone to spawn monsters inside the game
"""

"""
Positions for supervised monsters
1. {1050, -199, -32}
2. {950, -199, -32}
3. {850, -199, -32}
4. {750, -199, -32}
5. {650, -199, -32}
6. {550, -199, -32}
7. {450, -199, -32}
8. {350, -199, -32}
"""

dist = 100
start = 1050

for i <- 1..8 do
  pos = {start - i * dist, -199, -32}

  DoomSupervisor.GameServer.spawn_monster_at(:mancubus, "id123#{i}", pos)
end
