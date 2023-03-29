class Spawner : Actor
{
    static Actor SpawnWithPid(string monsterToSpawn, string pid, vector3 position, uint flags)
    {
        let monster = Actor.Spawn(monsterToSpawn, position, flags);
        monster.SetTag(pid);

        console.printf("The tag I've set is %s", monster.GetTag());

        Spawner.PushElixirMessage(monsterToSpawn, pid, "spawned", position);

        return monster;
    }

    static void PushElixirMessage(string className, string pid, string event, vector3 position)
    {
        console.printf("**ELIXIR** %s %s %s at (%d, %d, %d)", pid, className, event, position.X, position.Y, position.Z);
    }
}
