package richard.main

import java.util.UUID

import akka.actor.{ActorSystem, Props}
import akka.cluster.sharding.{ClusterSharding, ClusterShardingSettings}
import akka.pattern.ask
import akka.util.Timeout
import com.typesafe.config.ConfigFactory
import richard.backend.actor.IdActor

import scala.concurrent.duration._
import scala.concurrent.{Await, ExecutionContext}

object CreateShardingActors {
  def main(args: Array[String]): Unit = {
    val numShardActors: Int =
      if(args.length > 0 && args(0).isInstanceOf[Int]) args(0).asInstanceOf[Int]
      else 100

    val config = ConfigFactory.load("create-sharding-actors.conf")
    val system = ActorSystem(config.getString("actor-system-name"), config)

    val shardRegion = ClusterSharding(system).start(
      typeName = "IdActor",
      entityProps = Props[IdActor],
      settings = ClusterShardingSettings(system),
      extractEntityId = IdActor.extractEntityId,
      extractShardId = IdActor.extractShardId
    )

    implicit val timeout: Timeout = 1.second
    implicit val ec: ExecutionContext = system.dispatcher
    for (_ <- 1 to numShardActors) {
      val uuid = UUID.randomUUID()
      val asking = shardRegion ? IdActor.Create(uuid.toString)

      try {
        Await.result(asking.mapTo[String], 1.second)
        println("Successfully created " + uuid)
      } catch {
        case _: Throwable => println("Failed to create " + uuid)
      }

    }

    system.terminate()
  }
}
