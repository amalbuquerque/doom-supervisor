class ElixirZombieMan : ZombieMan
{
    string pid;
    property pid : pid;

    Default
    {
        ElixirZombieMan.pid "pid_unset"; // defines the default value for the variable
    }

    States
    {
    Death:
        // TNT1 is an internal name for a null sprite with special handling (the actor’s rendering will be disabled when using this sprite).
        TNT1 A 0
        {
            Spawner.PushElixirMessage(self.GetClassName(), pid, "died", pos);
        }
        goto super::Death;
    }
}

class Spawner : Actor
{
    static Actor SpawnWithPid(string monsterToSpawn, string pid, vector3 position, uint flags)
    {
        array<string> monstersWithPid = {"ElixirCacodemon", "ElixirDemon", "ElixirDoomImp", "ElixirCyberdemon", "ElixirZombieMan", "ElixirFatso", "ElixirHellKnight"};

        // array.Find() returns array.Size() if element not found
        if (monstersWithPid.Find(monsterToSpawn) == monstersWithPid.Size())
        {
            console.printf("Spawning vanilla %s", monsterToSpawn);

            return Spawn(monsterToSpawn, position, ALLOW_REPLACE);
        }

        Actor toReturn = null;

        if (monsterToSpawn == "ElixirZombieMan")
        {
            let monster = ElixirZombieMan(Spawn(monsterToSpawn, position, flags));
            monster.pid = pid;

            toReturn = monster;
        }

        if (toReturn != null)
        {
            Spawner.PushElixirMessage(monsterToSpawn, pid, "spawned", position);
        }

        return toReturn;
    }

    static void PushElixirMessage(string className, string pid, string event, vector3 position)
    {
        console.printf("**ELIXIR** %s %s %s at (%d, %d, %d)", pid, className, event, position.X, position.Y, position.Z);
    }
}
