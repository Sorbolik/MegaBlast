package com.sorbolik.megablast;

import android.app.Activity;
import android.app.GameManager;
import android.content.Context;
import android.os.Build;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.view.Display;
import android.view.HapticFeedbackConstants;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;

// Quello che il gioco chiede ad Android, chiamato da client/vibra/src/vibra.cpp.
public class Vibra {
    // La micro-vibrazione del sistema, la stessa dei tasti della tastiera: corta e
    // leggera, segue le impostazioni del telefono ("vibrazione al tocco").
    public static void tocco(final Activity attivita) {
        attivita.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                View vista = attivita.getWindow().getDecorView();
                vista.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP);
            }
        });
    }

    // Il colpo di un'esplosione: ms millisecondi a forza da 1 a 255 (sui telefoni
    // senza la forza regolabile vibra e basta). Permesso VIBRATE nel manifest.
    public static void colpo(final Activity attivita, int ms, int forza) {
        Vibrator v = (Vibrator) attivita.getSystemService(Context.VIBRATOR_SERVICE);
        if (v == null || !v.hasVibrator()) return;
        if (Build.VERSION.SDK_INT >= 26) {
            int f = v.hasAmplitudeControl() ? Math.max(1, Math.min(255, forza)) : VibrationEffect.DEFAULT_AMPLITUDE;
            v.vibrate(VibrationEffect.createOneShot(ms, f));
        } else {
            v.vibrate(ms);
        }
    }

    // Lo schermo alla frequenza più alta che ha (90 o 120 Hz), alla stessa risoluzione.
    public static void altaFrequenza(final Activity attivita) {
        if (Build.VERSION.SDK_INT < 23) return;
        attivita.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Window finestra = attivita.getWindow();
                Display schermo = attivita.getWindowManager().getDefaultDisplay();
                Display.Mode ora = schermo.getMode();
                Display.Mode meglio = ora;
                for (Display.Mode m : schermo.getSupportedModes()) {
                    if (m.getPhysicalWidth() == ora.getPhysicalWidth()
                            && m.getPhysicalHeight() == ora.getPhysicalHeight()
                            && m.getRefreshRate() > meglio.getRefreshRate()) {
                        meglio = m;
                    }
                }
                WindowManager.LayoutParams p = finestra.getAttributes();
                p.preferredDisplayModeId = meglio.getModeId();
                finestra.setAttributes(p);
            }
        });
    }

    // La modalità di gioco scelta nel pannello dei giochi del telefono (Android 12+):
    // 0 non c'è, 1 normale, 2 prestazioni, 3 risparmio batteria.
    public static int modoGioco(final Activity attivita) {
        if (Build.VERSION.SDK_INT < 31) return 0;
        GameManager gm = (GameManager) attivita.getSystemService(Context.GAME_SERVICE);
        return gm == null ? 0 : gm.getGameMode();
    }
}
