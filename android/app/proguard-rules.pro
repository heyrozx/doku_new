# Room creates database implementations reflectively via their no-arg
# constructor (e.g. WorkManager's WorkDatabase_Impl, used by Google Mobile
# Ads). R8 full mode drops that constructor when only the class is kept,
# which crashes release builds at startup with
# "Failed to create an instance of androidx.work.impl.WorkDatabase".
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}

# WorkManager workers and input mergers are instantiated by class name.
-keep class * extends androidx.work.ListenableWorker {
    <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keep class * extends androidx.work.InputMerger {
    <init>();
}
