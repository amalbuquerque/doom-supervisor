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

class MySpawnMonsterEventHandler : EventHandler
{
    // NetworkEvent handler
    override void NetworkProcess (ConsoleEvent e)
    {
        // payload of the format spawn:cacodemon:id123
        string payload = e.Name;
        Array<String> actionMonsterPid;
        e.Name.Split(actionMonsterPid, ":");
        string spawn = actionMonsterPid[0];
        string monster = actionMonsterPid[1];
        string pid = actionMonsterPid[2];

        let player = players [e.Player].mo;
        let position = player.Vec3Offset(FRandom(256,-256), FRandom(256,-256), 0);

        Spawner.SpawnWithPid(monster, pid, position, ALLOW_REPLACE);
    }
}

class MyThingDiedEventHandler : EventHandler
{
    // WorldEvent is a https://zdoom-docs.github.io/staging/Api/Events/WorldEvent.html
    // WorldEvent.Thing is an Actor
    override void WorldThingDied (WorldEvent e)
    {
        let monster = e.Thing;

        Spawner.PushElixirMessage(monster.GetClassName(), monster.GetTag(), "died with handler", monster.Pos);
    }
}
