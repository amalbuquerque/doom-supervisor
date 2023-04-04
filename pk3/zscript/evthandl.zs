class HelloWorldHandler : EventHandler
{
    override void WorldLoaded (WorldEvent e)
    {
        console.printf("Hello World!");
    }
}

class MyNetEventHandler : EventHandler
 {
   override void NetworkProcess (ConsoleEvent e)
   {
//     if (e.IsManual)
//       return;

     console.printf("Received NetEvent");
     console.printf(e.Name);
   }
}

class MyNetworkEventHandler : EventHandler
{
    // NetworkEvent handler
    override void NetworkProcess (ConsoleEvent e)
    {
        // payload has the format
        // spawn:cacodemon:pid123
        // kill:<process>:pid123
        string payload = e.Name;
        Array<String> actionMonsterPid;
        e.Name.Split(actionMonsterPid, ":");
        string actionToPerform = actionMonsterPid[0];
        string monster = actionMonsterPid[1];
        string pid = actionMonsterPid[2];

        let player = players [e.Player].mo;
        let position = player.Vec3Offset(FRandom(256,-256), FRandom(256,-256), 0);

        if (actionToPerform == "spawn") {
            Spawner.SpawnWithPid(monster, pid, position, ALLOW_REPLACE);
        } else if (actionToPerform == "kill") {
            AllMonstersHandler.KillMonsterByPid(pid);
        }
    }
}

class MyThingDiedEventHandler : EventHandler
{
    // WorldEvent is a https://zdoom-docs.github.io/staging/Api/Events/WorldEvent.html
    // WorldEvent.Thing is an Actor
    override void WorldThingDied (WorldEvent e)
    {
        let monster = e.Thing;

        Spawner.PushElixirMessage(monster.GetClassName(), monster.GetTag(), "died", monster.Pos);
    }
}
