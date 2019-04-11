package richard.main

import java.io.{File, PrintWriter}
import java.util.UUID

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.scala.DefaultScalaModule
import richard.frontend.perf.WrkHttpRequest

object DataGen {
  def main(args: Array[String]): Unit = {
    val wrkRequestFile = new File("data/requests.json")
    val uuidFile = new File("data/uuids.json")

    val objectMapper = new ObjectMapper
    objectMapper.registerModule(DefaultScalaModule)
    val request = new WrkHttpRequest("aaa", "bbb")
    objectMapper.writeValue(wrkRequestFile, request)

    val printWriter = new PrintWriter(uuidFile)
    for(_ <- 1 to 10){
      val uuid = UUID.randomUUID()
      printWriter.println(uuid)
    }

    printWriter.close()
  }
}
