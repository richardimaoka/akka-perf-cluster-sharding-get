package richard.main

import akka.actor.ActorSystem
import com.typesafe.config.ConfigFactory

object SeedNode {
  def main(args: Array[String]): Unit = {
    val config = ConfigFactory.load("seed-node.conf")
    val system = ActorSystem(config.getString("actor-system-name"), config)

    if(scala.io.StdIn.readLine() != null)
      system.terminate()
  }
}
