package com.example.smart_trainer

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Native step counter with walking-pattern validation.
 *
 * Uses TYPE_STEP_DETECTOR for per-step events, then applies a smart
 * validation algorithm to filter out false positives (phone shakes,
 * hand movements while sitting, etc.).
 *
 * ALGORITHM:
 *   1. Raw step events enter a "candidate buffer"
 *   2. When 4+ candidates arrive within 3 seconds → walking confirmed
 *   3. Once walking, every step counts immediately
 *   4. Walking stops after 2.5 seconds of no step events
 *   5. When walking stops, steps go back to candidate mode
 *
 * This eliminates random phone movements while preserving
 * real-time responsiveness during actual walking.
 */
class MainActivity : FlutterActivity(), SensorEventListener {

    companion object {
        private const val METHOD_CHANNEL = "com.smart_trainer/steps"
        private const val EVENT_CHANNEL  = "com.smart_trainer/steps_stream"

        // ── Tuning ──
        private const val WARMUP_STEPS     = 4       // steps needed to confirm walking
        private const val WARMUP_WINDOW_MS = 3000L   // must arrive within this window
        private const val COOLDOWN_MS      = 2500L   // no-step gap to exit walking mode
        private const val MIN_STEP_GAP_MS  = 250L    // ignore steps closer than this (max ~4 steps/sec)
    }

    private var sensorManager: SensorManager? = null
    private var stepDetector: Sensor? = null

    // ── Validated step count ──
    private var confirmedSteps: Int = 0
    private var eventSink: EventChannel.EventSink? = null

    // ── Walking detection state ──
    private var isWalking = false
    private var candidateTimestamps = mutableListOf<Long>()  // timestamps of unconfirmed steps
    private var candidateCount = 0                           // how many unconfirmed steps
    private var lastStepTimeMs: Long = 0L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepDetector = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)

        // ── MethodChannel ──
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSteps"    -> result.success(confirmedSteps)
                    "resetSteps"  -> {
                        confirmedSteps = 0
                        candidateTimestamps.clear()
                        candidateCount = 0
                        isWalking = false
                        lastStepTimeMs = 0L
                        result.success(null)
                    }
                    "isAvailable" -> result.success(stepDetector != null)
                    else          -> result.notImplemented()
                }
            }

        // ── EventChannel (real-time stream) ──
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    startListening()
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    stopListening()
                }
            })
    }

    private fun startListening() {
        if (stepDetector != null) {
            sensorManager?.registerListener(
                this,
                stepDetector,
                SensorManager.SENSOR_DELAY_FASTEST,
                0  // maxReportLatencyUs = 0 → no batching
            )
        }
    }

    private fun stopListening() {
        sensorManager?.unregisterListener(this)
    }

    override fun onSensorChanged(event: SensorEvent?) {
        event ?: return
        if (event.sensor.type != Sensor.TYPE_STEP_DETECTOR) return

        val now = System.currentTimeMillis()
        val timeSinceLastStep = now - lastStepTimeMs

        // ── Anti-bounce: ignore steps that are too close together ──
        if (lastStepTimeMs > 0 && timeSinceLastStep < MIN_STEP_GAP_MS) return
        lastStepTimeMs = now

        // ── If walking but long gap since last step → user stopped walking ──
        if (isWalking && timeSinceLastStep > COOLDOWN_MS) {
            isWalking = false
            candidateTimestamps.clear()
        }

        if (isWalking) {
            // ── WALKING MODE: count every step immediately ──
            confirmedSteps++
            eventSink?.success(confirmedSteps)
        } else {
            // ── CANDIDATE MODE: accumulate and validate ──
            candidateTimestamps.add(now)

            // Remove old candidates outside the warmup window
            candidateTimestamps.removeAll { now - it > WARMUP_WINDOW_MS }

            if (candidateTimestamps.size >= WARMUP_STEPS) {
                // Walking confirmed! Count all candidates + this step
                isWalking = true
                confirmedSteps += candidateTimestamps.size
                candidateTimestamps.clear()
                eventSink?.success(confirmedSteps)
            }
        }
    }

    /**
     * Called periodically or when we need to check if walking has stopped.
     * We hook into onSensorChanged timing: if walking and no step for COOLDOWN_MS,
     * we switch back to candidate mode on the next step event.
     */
    private fun checkCooldown(now: Long): Boolean {
        return now - lastStepTimeMs > COOLDOWN_MS
    }

    // Override to also check cooldown
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // No-op
    }

    override fun onResume() {
        super.onResume()
        // Restart sensor when app comes back to foreground
        if (eventSink != null) {
            startListening()
        }
    }

    override fun onPause() {
        // Keep listening even when paused for step counting
        super.onPause()
    }

    override fun onDestroy() {
        stopListening()
        super.onDestroy()
    }
}
