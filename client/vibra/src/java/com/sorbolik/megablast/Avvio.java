package com.sorbolik.megablast;

import android.app.Dialog;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Window;
import android.view.WindowManager;

import com.dynamo.android.DefoldActivity;

// La finestra del gioco (client/android/AndroidManifest.xml): quella di Defold più un
// pannello Ruggine con Favilla (res/drawable/avvio_fondo.xml) sopra il secondo di nero
// in cui il motore si accende (Sergio, 23 nov). Il pannello è una finestra a parte
// perché Defold disegna da solo sulla sua: non prende tocchi né fuoco, e sfuma quando
// il gioco ha disegnato i primi fotogrammi (vibra.cpp chiama pronto()).
public class Avvio extends DefoldActivity {
    private static Avvio attiva;
    private Dialog pannello;

    @Override
    protected void onCreate(Bundle stato) {
        super.onCreate(stato);
        attiva = this;
        int tema = getResources().getIdentifier("AvvioPannello", "style", getPackageName());
        pannello = new Dialog(this, tema);
        Window w = pannello.getWindow();
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
        pannello.setCancelable(false);
        pannello.show();
        // se il gioco non lo chiude (un errore all'avvio), sparisce comunque
        new Handler(Looper.getMainLooper()).postDelayed(new Runnable() {
            @Override
            public void run() { chiudi(); }
        }, 8000);
    }

    private void chiudi() {
        final Dialog d = pannello;
        pannello = null;
        if (d == null || !d.isShowing()) return;
        d.getWindow().getDecorView().animate().alpha(0f).setDuration(250).withEndAction(new Runnable() {
            @Override
            public void run() {
                if (d.isShowing()) d.dismiss();
            }
        });
    }

    @Override
    protected void onDestroy() {
        if (pannello != null && pannello.isShowing()) pannello.dismiss();
        pannello = null;
        if (attiva == this) attiva = null;
        super.onDestroy();
    }

    // Il gioco ha disegnato: il pannello sfuma (dal thread del motore).
    public static void pronto() {
        final Avvio a = attiva;
        if (a == null) return;
        a.runOnUiThread(new Runnable() {
            @Override
            public void run() { a.chiudi(); }
        });
    }
}
