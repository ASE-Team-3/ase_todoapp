package com.example.app

import android.os.Bundle
import com.google.android.gms.security.ProviderInstaller
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState) // Corrected syntax

        // Fallback for updating security provider
        updateSecurityProvider()
    }

    private fun updateSecurityProvider() {
        try {
            // This installs or updates the security provider if needed
            ProviderInstaller.installIfNeeded(this)
        } catch (e: Exception) {
            e.printStackTrace()
            // Optionally log or handle the error
        }
    }
}
