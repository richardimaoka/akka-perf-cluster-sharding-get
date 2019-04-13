package richard.main

import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.stream.ActorMaterializer
import com.typesafe.config.ConfigFactory
import richard.frontend.routes.IdRoute

import scala.io.Source

object Frontend {
  def main(args: Array[String]): Unit = {
    val config = ConfigFactory.load("frontend.conf")

    implicit val system = ActorSystem(config.getString("actor-system-name"), config)
    implicit val materializer = ActorMaterializer()
    implicit val executionContext = system.dispatcher

    val source = Source.fromFile("data/uuids.json")
    val uuids = source.getLines().toList
    source.close()

    val httpRoutes = new IdRoute(system, uuids)
    Http().bindAndHandle(httpRoutes.route, config.getString("akka.remote.netty.tcp.hostname"), 8080)

    if(scala.io.StdIn.readLine() != null)
      system.terminate()
  }
}
