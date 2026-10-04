package com.navtrack.nav_track.location

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class LocationMethodHandler(
    private val context: Context,
    private var activity: Activity?
) : MethodChannel.MethodCallHandler, PluginRegistry.RequestPermissionsResultListener {

    private val fusedLocationClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)

    private var pendingPermissionResult: MethodChannel.Result? = null
    private val LOCATION_PERMISSION_REQUEST_CODE = 1001

    fun setActivity(act: Activity?) {
        this.activity = act
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCurrentLocation" -> getCurrentLocation(result)
            "checkPermission" -> checkPermission(result)
            "requestPermission" -> requestPermission(result)
            "openAppSettings" -> openAppSettings(result)
            "isLocationServiceEnabled" -> isLocationServiceEnabled(result)
            else -> result.notImplemented()
        }
    }

    private fun isLocationServiceEnabled(result: MethodChannel.Result) {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val isGpsEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
        val isNetworkEnabled = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        result.success(isGpsEnabled || isNetworkEnabled)
    }

    private fun checkPermission(result: MethodChannel.Result) {
        val fineLocationPermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
        val coarseLocationPermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )

        if (fineLocationPermission == PackageManager.PERMISSION_GRANTED ||
            coarseLocationPermission == PackageManager.PERMISSION_GRANTED
        ) {
            result.success("granted")
            return
        }

        val act = activity
        if (act != null) {
            val showRationale = ActivityCompat.shouldShowRequestPermissionRationale(
                act,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
            // If rationale is false and permission is not granted, user might have denied permanently or never asked.
            // Flutter will distinguish using rationale after a request attempt.
            if (!showRationale) {
                // Note: could be permanently denied or initial state.
                result.success("denied")
            } else {
                result.success("denied")
            }
        } else {
            result.success("denied")
        }
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val finePermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
        if (finePermission == PackageManager.PERMISSION_GRANTED) {
            result.success("granted")
            return
        }

        val act = activity
        if (act == null) {
            result.error("NO_ACTIVITY", "Activity is not available to request permissions", null)
            return
        }

        if (pendingPermissionResult != null) {
            result.error("ALREADY_REQUESTING", "A permission request is already in progress", null)
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            act,
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ),
            LOCATION_PERMISSION_REQUEST_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != LOCATION_PERMISSION_REQUEST_CODE) {
            return false
        }

        val result = pendingPermissionResult ?: return false
        pendingPermissionResult = null

        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            result.success("granted")
        } else {
            val act = activity
            if (act != null && !ActivityCompat.shouldShowRequestPermissionRationale(
                    act,
                    Manifest.permission.ACCESS_FINE_LOCATION
                )
            ) {
                result.success("permanently_denied")
            } else {
                result.success("denied")
            }
        }
        return true
    }

    private fun openAppSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("CANNOT_OPEN_SETTINGS", e.localizedMessage, null)
        }
    }

    private fun getCurrentLocation(result: MethodChannel.Result) {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val isGpsEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
        val isNetworkEnabled = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)

        if (!isGpsEnabled && !isNetworkEnabled) {
            result.error(
                LocationError.LOCATION_DISABLED,
                "Location services are disabled on device",
                null
            )
            return
        }

        val finePermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
        val coarsePermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )

        if (finePermission != PackageManager.PERMISSION_GRANTED &&
            coarsePermission != PackageManager.PERMISSION_GRANTED
        ) {
            result.error(
                LocationError.PERMISSION_DENIED,
                "Location permission is not granted",
                null
            )
            return
        }

        try {
            val cancellationTokenSource = CancellationTokenSource()
            fusedLocationClient.getCurrentLocation(
                Priority.PRIORITY_HIGH_ACCURACY,
                cancellationTokenSource.token
            ).addOnSuccessListener { location: Location? ->
                if (location != null) {
                    result.success(locationToMap(location))
                } else {
                    // Fallback to lastLocation if getCurrentLocation yields null
                    fusedLocationClient.lastLocation.addOnSuccessListener { lastLoc: Location? ->
                        if (lastLoc != null) {
                            result.success(locationToMap(lastLoc))
                        } else {
                            result.error(
                                LocationError.LOCATION_UNAVAILABLE,
                                "Failed to retrieve location fix",
                                null
                            )
                        }
                    }.addOnFailureListener { e ->
                        result.error(
                            LocationError.LOCATION_UNAVAILABLE,
                            e.localizedMessage ?: "Unknown location error",
                            null
                        )
                    }
                }
            }.addOnFailureListener { e ->
                result.error(
                    LocationError.LOCATION_UNAVAILABLE,
                    e.localizedMessage ?: "Location fetch failed",
                    null
                )
            }
        } catch (e: SecurityException) {
            result.error(
                LocationError.PERMISSION_DENIED,
                "SecurityException: permission denied",
                null
            )
        }
    }

    companion object {
        fun locationToMap(location: Location): Map<String, Any> {
            return mapOf(
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "altitude" to location.altitude,
                "speed" to location.speed,
                "bearing" to location.bearing,
                "accuracy" to location.accuracy,
                "timestamp" to location.time
            )
        }
    }
}
