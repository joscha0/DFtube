package com.joscha0.dftube

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.webkit.WebView
import androidx.appcompat.app.AppCompatActivity
import com.izikode.izilib.veinview.VeinView
import com.izikode.izilib.veinview.defaultClient


class MainActivity : AppCompatActivity() {
    private val veinView: VeinView by lazy { findViewById(R.id.veinview) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        WebView.setWebContentsDebuggingEnabled(true)

        veinView.setVeinViewClient(defaultClient { injector, page ->
            injector.injectCSS(R.raw.style)
        })

        veinView.setInitialScale(1)


        veinView.settings.apply {
            loadWithOverviewMode = true
            useWideViewPort = true
        }

        veinView.loadUrl("https://m.youtube.com/")

        handleIntent(intent)
    }

    override fun onBackPressed() {
        if (veinView.canGoBack()) {
            veinView.goBack()
        } else {
            super.onBackPressed()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val appLinkAction = intent.action
        val appLinkData: Uri? = intent.data
        if (Intent.ACTION_VIEW == appLinkAction) {
            veinView.loadUrl(appLinkData.toString())
        }
    }


}