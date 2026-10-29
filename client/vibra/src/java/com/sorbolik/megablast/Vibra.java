package com.sorbolik.megablast;

import android.app.Activity;
import android.view.HapticFeedbackConstants;
import android.view.View;

// La micro-vibrazione del sistema, la stessa dei tasti della tastiera: corta e
// leggera, non serve nessun permesso e segue le impostazioni del telefono
// ("vibrazione al tocco"). La chiama client/vibra/src/vibra.cpp.
public class Vibra {
    public static void tocco(final Activity attivita) {
        attivita.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                View vista = attivita.getWindow().getDecorView();
                vista.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP);
            }
        });
    }
}
