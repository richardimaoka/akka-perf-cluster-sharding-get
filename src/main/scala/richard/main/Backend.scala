package richard.main

import akka.actor.{ActorSystem, Props}
import akka.cluster.sharding.{ClusterSharding, ClusterShardingSettings}
import com.typesafe.config.ConfigFactory
import richard.backend.actor.IdActor

object Backend {
  def main(args: Array[String]): Unit = {
    val config = ConfigFactory.load("backend.conf")
    val system = ActorSystem(config.getString("actor-system-name"), config)

    val shardRegion = ClusterSharding(system).start(
      typeName = "IdActor",
      entityProps = Props[IdActor],
      settings = ClusterShardingSettings(system),
      extractEntityId = IdActor.extractEntityId,
      extractShardId = IdActor.extractShardId
    )

    if(scala.io.StdIn.readLine() != null)
      system.terminate()
  }
}
