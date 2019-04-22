package richard.backend.actor

import akka.actor.Actor
import akka.cluster.sharding.ShardRegion
import akka.event.Logging

class IdActor extends Actor {
  import richard.backend.actor.IdActor._
  val log = Logging(context.system, this)
  var _id: String = ""

  log.info(s"Initialized IdActor")

  def receiveUninitialized: Receive = {
    case Create(i) =>
      log.info(s"Create(${i}) is received by ${self.path}. Changing Actor's `receive` to receiveInitialized")
      _id = i
      context.become(receiveInitialized)
      sender() ! "Created"
    case msg =>
      log.info(s"Unexpected message ${msg} is received by ${self.path}. So stopping this Actor itself.")
      context.stop(self)
  }

  def receiveInitialized: Receive = {
    case Get(i) =>
      log.info(s"Get(${i}) is received by ${self.path}. Returning the ${_id} back to the sender")
      sender() ! _id
  }

  def receive: Receive = receiveUninitialized
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
    case Create(id) => (id.hashCode % numberOfShards).toString
    case Get(id) => (id.hashCode % numberOfShards).toString
  }
}
