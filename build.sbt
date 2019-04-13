enablePlugins(JavaAppPackaging)

ThisBuild / scalaVersion     := "2.12.8"
ThisBuild / version          := "0.1.0-SNAPSHOT"
ThisBuild / organization     := "com.example"
ThisBuild / organizationName := "example"

val JackSonVersion = "2.9.8"
val AkkaVersion = "2.5.20"
val AkkaHttpVersion = "10.1.7"
val SprayJsonVersion = "1.3.5"

lazy val root = (project in file("."))
  .settings(
    name := "akka-perf-cluster-sharding-get",
    libraryDependencies ++= Seq(
      "com.fasterxml.jackson.core" % "jackson-databind" % JackSonVersion,
      "com.fasterxml.jackson.module" %% "jackson-module-scala" % JackSonVersion,
      "com.typesafe.akka" %% "akka-cluster" % AkkaVersion,
      "com.typesafe.akka" %% "akka-cluster-sharding" % AkkaVersion,
      "com.typesafe.akka" %% "akka-stream" % AkkaVersion,
      "com.typesafe.akka" %% "akka-http"   % AkkaHttpVersion,
      "com.typesafe.akka" %% "akka-http-spray-json" % AkkaHttpVersion,
      "io.spray" %%  "spray-json" % SprayJsonVersion
    )
  )

// See https://www.scala-sbt.org/1.x/docs/Using-Sonatype.html for instructions on how to publish to Sonatype.
