package com.sorbolik.megablast;

import android.app.Activity;
import android.app.Application;
import android.app.Dialog;
import android.content.ContentProvider;
import android.content.ContentValues;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Window;
import android.view.WindowManager;

// Il pannello Ruggine con Favilla (res/drawable/avvio_fondo.xml) sopra il secondo di
// nero in cui il motore si accende (Sergio, 23 nov). È una finestra a parte perché
// Defold disegna da solo sulla sua; non prende tocchi né fuoco e sfuma quando il gioco
// ha disegnato i primi fotogrammi (vibra.cpp chiama pronto()).
// È un ContentProvider (manifests/android/AndroidManifest.xml) solo per partire prima
// della finestra di Defold, che le estensioni non possono estendere: da lì ascolta
// quando la finestra nasce e le apre sopra il pannello.
public class Avvio extends ContentProvider implements Application.ActivityLifecycleCallbacks {
    private static Dialog pannello;

    @Override
    public boolean onCreate() {
        ((Application) getContext().getApplicationContext()).registerActivityLifecycleCallbacks(this);
        return true;
    }

    @Override
    public void onActivityCreated(Activity attivita, Bundle stato) {
        if (pannello != null) return;
        int tema = attivita.getResources().getIdentifier("AvvioPannello", "style", attivita.getPackageName());
        Dialog d = new Dialog(attivita, tema);
        Window w = d.getWindow();
        w.addFlags(WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                | WindowManager.LayoutParams.FLAG_FULLSCREEN
                | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
        w.setLayout(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT);
        if (Build.VERSION.SDK_INT >= 28) {
            WindowManager.LayoutParams p = w.getAttributes();
            p.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
            w.setAttributes(p);
        }
        d.setCancelable(false);
        d.show();
        pannello = d;
        // se il gioco non lo chiude (un errore all'avvio), sparisce comunque
        new Handler(Looper.getMainLooper()).postDelayed(new Runnable() {
            @Override
            public void run() { chiudi(); }
        }, 8000);
    }

    @Override
    public void onActivityDestroyed(Activity attivita) {
        if (pannello == null || pannello.getOwnerActivity() != attivita) return;
        if (pannello.isShowing()) pannello.dismiss();
        pannello = null;
    }

    // dal thread principale: il pannello sfuma e se ne va (una volta sola)
    private static void chiudi() {
        final Dialog d = pannello;
        if (d == null || !d.isShowing() || d.getWindow().getDecorView().getAlpha() < 1f) return;
        d.getWindow().getDecorView().animate().alpha(0f).setDuration(250).withEndAction(new Runnable() {
            @Override
            public void run() {
                if (d.isShowing()) d.dismiss();
            }
        });
    }

    // Il gioco ha disegnato (dal thread del motore).
    public static void pronto() {
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            @Override
            public void run() { chiudi(); }
        });
    }

    @Override public void onActivityStarted(Activity a) {}
    @Override public void onActivityResumed(Activity a) {}
    @Override public void onActivityPaused(Activity a) {}
    @Override public void onActivityStopped(Activity a) {}
    @Override public void onActivitySaveInstanceState(Activity a, Bundle b) {}

    @Override public Cursor query(Uri u, String[] p, String s, String[] a, String o) { return null; }
    @Override public String getType(Uri u) { return null; }
    @Override public Uri insert(Uri u, ContentValues v) { return null; }
    @Override public int delete(Uri u, String s, String[] a) { return 0; }
    @Override public int update(Uri u, ContentValues v, String s, String[] a) { return 0; }
}
