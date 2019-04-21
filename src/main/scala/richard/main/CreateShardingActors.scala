package richard.main

import java.util.UUID

import akka.actor.{ActorSystem, Props}
import akka.cluster.sharding.{ClusterSharding, ClusterShardingSettings}
import akka.pattern.ask
import akka.util.Timeout
import com.typesafe.config.ConfigFactory
import richard.backend.actor.IdActor

import scala.concurrent.ExecutionContext
import scala.concurrent.duration._
import scala.util.{Failure, Success}

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
      (shardRegion ? IdActor.Create(uuid.toString)).mapTo[String].onComplete{
        case Success(_) => println("Success creating " + uuid)
        case Failure(e) => println("Failed creating " + uuid, e)
      }
    }

    system.terminate()
  }
}
