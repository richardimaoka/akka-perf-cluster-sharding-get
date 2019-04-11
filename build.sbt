enablePlugins(JavaAppPackaging)

ThisBuild / scalaVersion     := "2.12.8"
ThisBuild / version          := "0.1.0-SNAPSHOT"
ThisBuild / organization     := "com.example"
ThisBuild / organizationName := "example"

lazy val root = (project in file("."))
  .settings(
    name := "akka-perf-cluster-sharding-get",
    libraryDependencies ++= Seq(
      "com.fasterxml.jackson.core" % "jackson-databind" % "2.9.8",
      "com.fasterxml.jackson.module" %% "jackson-module-scala" % "2.9.8",
      "com.typesafe.akka" %% "akka-cluster" % "2.5.20",
      "com.typesafe.akka" %% "akka-cluster-sharding" % "2.5.20",
      "com.typesafe.akka" %% "akka-stream" % "2.5.20",
      "com.typesafe.akka" %% "akka-http"   % "10.1.7",
      "com.typesafe.akka" %% "akka-http-spray-json" % "10.1.7",
      "io.spray" %%  "spray-json" % "1.3.5"
    )
  )

// See https://www.scala-sbt.org/1.x/docs/Using-Sonatype.html for instructions on how to publish to Sonatype.
