package richard.main

import java.util.UUID

import akka.actor.{ActorSystem, Props}
import akka.cluster.sharding.{ClusterSharding, ClusterShardingSettings}
import com.typesafe.config.ConfigFactory
import richard.backend.actor.IdActor

object CreateShardingActors {
  def main(args: Array[String]): Unit = {
    val numShardActors: Int =
      if(args.length > 0 && args(0).isInstanceOf[Int]) args(0).asInstanceOf[Int]
      else 100

    val config = ConfigFactory.load("backend.conf")
    val system = ActorSystem(config.getString("actor-system-name"), config)

    val shardRegion = ClusterSharding(system).start(
      typeName = "IdActor",
      entityProps = Props[IdActor],
      settings = ClusterShardingSettings(system),
      extractEntityId = IdActor.extractEntityId,
      extractShardId = IdActor.extractShardId
    )

    for (_ <- 1 to numShardActors) {
      val uuid = UUID.randomUUID()
      shardRegion ! IdActor.Create(uuid.toString)
    }

    system.terminate()
  }
}
