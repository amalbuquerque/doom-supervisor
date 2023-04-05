class AllMonstersHandler : EventHandler
{
    array<Actor> g_allMonsters;

    static void RegisterMonster(Actor monster)
    {
        let allMonstersHandler = AllMonstersHandler(EventHandler.Find("AllMonstersHandler"));

        if (allMonstersHandler)
        {
            allMonstersHandler.g_allMonsters.Push(monster);
            console.printf("AllMonstersHandler has %d monsters", allMonstersHandler.g_allMonsters.Size());
        }
    }

    static Actor KillMonsterByPid(string pid)
    {
        let allMonstersHandler = AllMonstersHandler(EventHandler.Find("AllMonstersHandler"));

        Actor monsterToKill = null;

        if (allMonstersHandler)
        {
            for (int i = 0; i < allMonstersHandler.g_allMonsters.Size(); i++)
            {
                monsterToKill = allMonstersHandler.g_allMonsters[i];
                // Double-check the pointer isn't null
                if (monsterToKill && monsterToKill.GetTag() == pid)
                {

                    console.printf("Killing %s with %s ...", monsterToKill.GetClassName(), monsterToKill.GetTag());
                    monsterToKill.A_Die();
                    break;
                }
            }
        }

        return monsterToKill;
    }
}

class Helper : Actor
{
    static Actor SpawnWithPid(string monsterToSpawn, string pid, vector3 position, uint flags)
    {
        let monster = Actor.Spawn(monsterToSpawn, position, flags);
        monster.SetTag(pid);

        console.printf("Tagged new %s as '%s'", monsterToSpawn, monster.GetTag());

        Helper.PushElixirMessage(monsterToSpawn, pid, "spawned", position);

        AllMonstersHandler.RegisterMonster(monster);

        return monster;
    }

    static void GetPlayerPos()
    {
        let player = players[0].mo;

        PushElixirMessage("Player", "Supervisor", "getPos", player.Pos);
    }

    static void PushElixirMessage(string className, string pid, string event, vector3 position)
    {
        console.printf("**ELIXIR** %s %s %s at (%d, %d, %d)", pid, className, event, position.X, position.Y, position.Z);
    }
}
