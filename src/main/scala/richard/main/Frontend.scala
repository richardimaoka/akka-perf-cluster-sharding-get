package richard.main

import akka.actor.ActorSystem
import akka.http.scaladsl.Http
import akka.stream.ActorMaterializer
import com.typesafe.config.ConfigFactory
import richard.frontend.routes.IdRoute

object Frontend {
  def main(args: Array[String]): Unit = {
    val config = ConfigFactory.load("frontend.conf")

    implicit val system = ActorSystem(config.getString("actor-system-name"), config)
    implicit val materializer = ActorMaterializer()
    implicit val executionContext = system.dispatcher

    val httpRoutes = new IdRoute(system)
    Http().bindAndHandle(httpRoutes.route, "localhost", 8080)

    if(scala.io.StdIn.readLine() != null)
      system.terminate()
  }
}
