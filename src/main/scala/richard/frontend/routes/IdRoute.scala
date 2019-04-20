package richard.http.routes

import akka.actor.{ActorRef, ActorSystem}
import akka.cluster.sharding.ClusterSharding
import akka.http.scaladsl.server.Directives._
import akka.pattern.ask
import akka.util.Timeout
import richard.backend.actor.IdActor

import scala.concurrent.duration._

class IdRoute(system: ActorSystem, actorIds: List[String]) {

  val proxyShardRegion: ActorRef = ClusterSharding(system).startProxy(
    typeName = "IdActor",
    role = Some("backend"),
    extractEntityId = IdActor.extractEntityId,
    extractShardId = IdActor.extractShardId
  )

  // timeout for the actor ask pattern (i.e. `?` method)
  implicit val timeout: Timeout = 30.seconds
  val route =
    pathPrefix("actors") {
      pathEndOrSingleSlash {
        get {
          complete(actorIds.mkString("\n"))
        }
      } ~
      path(Segment) { uuid =>
        get {
          val ret = (proxyShardRegion ? IdActor.Get(uuid)).mapTo[String]
          complete(ret)
        }
      }
    }
}
