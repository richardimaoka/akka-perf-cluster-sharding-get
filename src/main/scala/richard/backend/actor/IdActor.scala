package richard.backend.actor

import akka.actor.Actor
import akka.cluster.sharding.ShardRegion

class IdActor extends Actor {
  import richard.backend.actor.IdActor._
  var _id: String = ""

  def receive: Receive = {
    case Create(i) =>
      _id = i
      //println(s"IdActor(${_id}) started")
    case Get(_) => sender() ! _id
  }
}

object IdActor {
  sealed trait Message
  case class Create(id: String) extends Message
  case class Get(id: String) extends Message

  val numberOfShards = 100
  val extractEntityId: ShardRegion.ExtractEntityId = {
    case msg @ Create(id) => (id, msg)
    case msg @ Get(id) => (id, msg)
  }
  val extractShardId: ShardRegion.ExtractShardId = {
    case msg @ Create(id) => (id.hashCode % numberOfShards).toString
    case msg @ Get(id) => (id.hashCode % numberOfShards).toString
  }
}
