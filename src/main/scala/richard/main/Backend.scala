package richard.main

import akka.actor.{ActorSystem, Props}
import akka.cluster.sharding.{ClusterSharding, ClusterShardingSettings}
import akka.discovery.Discovery
import com.typesafe.config.ConfigFactory
import richard.backend.actor.IdActor

import scala.io.Source

object Backend {
  def main(args: Array[String]): Unit = {
    val config = ConfigFactory.load("backend.conf")
    val system = ActorSystem(config.getString("actor-system-name"), config)
    val serviceDiscovery = Discovery(system).discovery
    val shardRegion = ClusterSharding(system).start(
      typeName = "IdActor",
      entityProps = Props[IdActor],
      settings = ClusterShardingSettings(system),
      extractEntityId = IdActor.extractEntityId,
      extractShardId = IdActor.extractShardId
    )

    val source = Source.fromFile("data/uuids.json")
    val lines = source.getLines()
    lines.foreach { uuid =>
      shardRegion ! IdActor.Create(uuid)
    }
    source.close()

    if(scala.io.StdIn.readLine() != null)
      system.terminate()
  }
}
