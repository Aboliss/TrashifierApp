package com.aboliss.trashifier

import android.content.Context
import android.util.Log
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

/**
 * Periodically redraws the widget so the day count and next pickup stay
 * current without opening the app.
 *
 * The widget's `updatePeriodMillis` alone is not enough: some launchers
 * (HyperOS) rarely deliver those updates, while WorkManager jobs still run.
 */
class WidgetUpdateWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    override fun doWork(): Result {
        return try {
            TrashifierWidget.updateWidget(applicationContext)
            Result.success()
        } catch (e: Exception) {
            Log.w(TAG, "Widget update failed", e)
            Result.failure()
        }
    }

    companion object {
        private const val TAG = "WidgetUpdateWorker"
        private const val WORK_NAME = "trashifier_widget_update"

        // Keep in sync with updatePeriodMillis in trashifier_widget_info.xml.
        private const val UPDATE_INTERVAL_HOURS = 6L

        /**
         * Safe to call repeatedly: UPDATE keeps the current schedule and only
         * applies a changed interval.
         */
        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
                UPDATE_INTERVAL_HOURS, TimeUnit.HOURS
            ).build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.UPDATE,
                request
            )
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }
}
