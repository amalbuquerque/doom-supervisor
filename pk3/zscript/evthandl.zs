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
        // action:class:identifier:position
        // Examples:
        // spawn:cacodemon:pid123:notUsed
        // kill:notUsed:pid123:notUsed
        // get_pos:notUsed:notUsed:notUsed
        string payload = e.Name;
        Array<String> actionMonsterPid;
        e.Name.Split(actionMonsterPid, ":");
        string actionToPerform = actionMonsterPid[0];
        string monster = actionMonsterPid[1];
        string pid = actionMonsterPid[2];
        // TODO: parse elixirPosition into vector3
        string elixirPosition = actionMonsterPid[3];

        let position = Helper.RandomPositionAroundPlayer(256);

        if (actionToPerform == "spawn") {
            Helper.SpawnWithPid(monster, pid, position, ALLOW_REPLACE);
        } else if (actionToPerform == "kill") {
            AllMonstersHandler.KillMonsterByPid(pid);
        } else if (actionToPerform == "get_pos") {
            Helper.GetPlayerPos();
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

        Helper.PushElixirMessage(monster.GetClassName(), monster.GetTag(), "died", monster.Pos);
    }
}
