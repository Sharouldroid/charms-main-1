import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Disable OpenGL error logging in debug
        if (BuildConfig.DEBUG) {
            System.setProperty("log.tag.libEGL", "ASSERT")
        }
        super.onCreate(savedInstanceState)
    }
}