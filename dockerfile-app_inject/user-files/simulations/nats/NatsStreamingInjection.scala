/*******************************************************************************
 * Copyright (c) 2016-2017 Logimethods
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the MIT License (MIT)
 * which accompanies this distribution, and is available at
 * http://opensource.org/licenses/MIT
 *******************************************************************************/

package com.logimethods.smartmeter.inject

import akka.actor.{ActorRef, Props}
import io.gatling.core.Predef._
import io.gatling.core.action.builder.ActionBuilder

import com.logimethods.connector.gatling.to_nats._

import scala.concurrent.duration._
import java.util.Properties
import com.logimethods.smartmeter.generate._

class NatsStreamingInjection extends Simulation {

//  println("System properties: " + System.getenv())

try {
    val natsUrl = System.getenv("NATS_URI")
    val clusterID = System.getenv("NATS_CLUSTER_ID")

    var subject = System.getenv("GATLING_TO_NATS_SUBJECT")
    if (subject == null) {
      println("No Subject has been defined through the 'GATLING_TO_NATS_SUBJECT' Environment Variable!!!")
    } else {
      println("Will emit messages to " + subject)
      val natsProtocol = NatsStreamingProtocol(natsUrl, clusterID, subject)

      val usersPerSec = System.getenv("GATLING_USERS_PER_SEC").toDouble
      val duration = System.getenv("GATLING_DURATION").toInt
      val streamingDuration = System.getenv("STREAMING_DURATION").toInt
      val slot = System.getenv("TASK_SLOT").toInt
      val randomness = System.getenv("RANDOMNESS").toFloat
      val predictionLength = System.getenv("PREDICTION_LENGTH").toInt
      val timeRoot = System.getenv("TIME_ROOT").toInt
      TimeProvider.config = Some(timeRoot)

      val natsScn = scenario("smartmeter_"+slot).exec(
          NatsStreamingBuilder(new ConsumerInterpolatedVoltageProvider(slot, usersPerSec, streamingDuration,
                                                                       randomness, predictionLength)))
      setUp(
        natsScn.inject(constantUsersPerSec(usersPerSec) during (duration minute))
      ).protocols(natsProtocol)
    }
  } catch {
    case e: Exception => {
      println(e.toString())
      e.printStackTrace()
    }
  }
}
